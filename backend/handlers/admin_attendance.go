// backend/handlers/admin_attendance.go

package handlers

import (
	"encoding/csv"
	"fmt"
	"net/http"
	"project/backend/models"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// ── Response shapes ───────────────────────────────────────────────────────────

type AdminAttendanceRow struct {
	ID            uint     `json:"id"`
	UserID        uint     `json:"user_id"`
	InternName    string   `json:"intern_name"`
	AvatarURL     string   `json:"avatar_url"`
	Date          string   `json:"date"`
	TimeIn        *string  `json:"time_in"`
	TimeOut       *string  `json:"time_out"`
	HoursRendered *float64 `json:"hours_rendered"`
	Status        string   `json:"status"`
	IsReported    bool     `json:"is_reported"`
	ReportReason  string   `json:"report_reason"`
	ReportType    string   `json:"report_type"`
	ReportedAt    *string  `json:"reported_at"`
	AdminNote     *string  `json:"admin_note"`
}

// ── Timezone helper ───────────────────────────────────────────────────────────

func manilaLoc() *time.Location {
	loc, err := time.LoadLocation("Asia/Manila")
	if err != nil {
		return time.UTC
	}
	return loc
}

// ── Status logic ──────────────────────────────────────────────────────────────

const lateThresholdHour = 8
const lateThresholdMin = 15
const adminAttendanceHoursExpr = `NULL`

func deriveStatus(timeIn *string, timeOut *string, recordDate string) string {
	if timeIn == nil {
		return "Absent"
	}
	if timeOut == nil {
		today := time.Now().In(manilaLoc()).Format("2006-01-02")
		if recordDate == today {
			return "On Shift"
		}
		return "Missed Clock Out"
	}

	var t time.Time
	for _, layout := range []string{"03:04 PM", "3:04 PM"} {
		if parsed, err := time.Parse(layout, *timeIn); err == nil {
			t = parsed
			break
		}
	}
	if t.IsZero() {
		return "Present"
	}

	if t.Hour() > lateThresholdHour ||
		(t.Hour() == lateThresholdHour && t.Minute() > lateThresholdMin) {
		return "Late"
	}
	return "Present"
}

// ── Hours computation ─────────────────────────────────────────────────────────

func computeHours(timeIn *string, timeOut *string, recordDate string) *float64 {
	if timeIn == nil || timeOut == nil {
		return nil
	}

	loc := manilaLoc()

	normalize := func(t string) string {
		return strings.ToUpper(strings.TrimSpace(t))
	}

	tryParse := func(dateStr, timeStr string) (time.Time, error) {
		timeStr = normalize(timeStr)
		for _, layout := range []string{
			"2006-01-02 03:04 PM",
			"2006-01-02 3:04 PM",
		} {
			if t, err := time.ParseInLocation(layout, dateStr+" "+timeStr, loc); err == nil {
				return t, nil
			}
		}
		return time.Time{}, fmt.Errorf("[computeHours] unparseable time: %q (date: %s)", timeStr, dateStr)
	}

	tIn, err1 := tryParse(recordDate, *timeIn)
	tOut, err2 := tryParse(recordDate, *timeOut)
	if err1 != nil || err2 != nil {
		fmt.Printf("[computeHours] parse error — timeIn=%q err=%v | timeOut=%q err=%v\n",
			*timeIn, err1, *timeOut, err2)
		return nil
	}

	cutoff := time.Date(tIn.Year(), tIn.Month(), tIn.Day(), 17, 0, 0, 0, loc)
	if tOut.After(cutoff) {
		tOut = cutoff
	}

	if !tOut.After(tIn) {
		zero := 0.0
		return &zero
	}

	elapsed := tOut.Sub(tIn).Hours()

	lunchStart := time.Date(tIn.Year(), tIn.Month(), tIn.Day(), 12, 0, 0, 0, loc)
	lunchEnd := time.Date(tIn.Year(), tIn.Month(), tIn.Day(), 13, 0, 0, 0, loc)

	overlapStart := tIn
	if lunchStart.After(overlapStart) {
		overlapStart = lunchStart
	}

	overlapEnd := tOut
	if lunchEnd.Before(overlapEnd) {
		overlapEnd = lunchEnd
	}

	if overlapEnd.After(overlapStart) {
		elapsed -= overlapEnd.Sub(overlapStart).Hours()
	}

	if elapsed < 0 {
		elapsed = 0
	}

	return &elapsed
}

// ── Shared raw scan type ──────────────────────────────────────────────────────

type attendanceRaw struct {
	ID            uint     `gorm:"column:id"`
	UserID        uint     `gorm:"column:user_id"`
	InternName    string   `gorm:"column:intern_name"`
	AvatarURL     string   `gorm:"column:avatar_url"`
	Date          string   `gorm:"column:date"`
	TimeIn        *string  `gorm:"column:time_in"`
	TimeOut       *string  `gorm:"column:time_out"`
	HoursRendered *float64 `gorm:"column:hours_rendered"`
	Status        *string  `gorm:"column:status"`
	IsReported    bool     `gorm:"column:is_reported"`
	ReportReason  string   `gorm:"column:report_reason"`
	ReportType    string   `gorm:"column:report_type"`
	ReportedAt    *string  `gorm:"column:reported_at"`
	AdminNote     *string  `gorm:"column:admin_note"`
}

// AFTER
func toResponseRows(rows []attendanceRaw) []AdminAttendanceRow {
	out := make([]AdminAttendanceRow, 0, len(rows))
	for _, r := range rows {
		// Use the admin-persisted status (excused variants) when present;
		// otherwise fall back to deriving it from clock-in/out times.
		status := deriveStatus(r.TimeIn, r.TimeOut, r.Date)
		if r.Status != nil && *r.Status != "" {
			status = *r.Status
		}
		out = append(out, AdminAttendanceRow{
			ID:            r.ID,
			UserID:        r.UserID,
			InternName:    r.InternName,
			AvatarURL:     r.AvatarURL,
			Date:          r.Date,
			TimeIn:        r.TimeIn,
			TimeOut:       r.TimeOut,
			HoursRendered: computeHours(r.TimeIn, r.TimeOut, r.Date),
			Status:        status,
			IsReported:    r.IsReported,
			ReportReason:  r.ReportReason,
			ReportType:    r.ReportType,
			ReportedAt:    r.ReportedAt,
			AdminNote:     r.AdminNote,
		})
	}
	return out
}

// ── SQL select fragment (used by all multi-date queries) ──────────────────────

// internSelectMultiDate uses the cross-join spine of (users × date_series)
// so every intern appears on every date, even with no attendance row.
// internSelectMultiDate — add as the last selected column
const internSelectMultiDate = `
    COALESCE(a.id, 0)                                                                            AS id,
    u.id                                                                                         AS user_id,
    COALESCE(NULLIF(TRIM(CONCAT(u.first_name, ' ', u.last_name)), ''), 'Unknown')               AS intern_name,
    COALESCE(u.avatar_url, '')                                                                   AS avatar_url,
    TO_CHAR(d.day::date, 'YYYY-MM-DD')                                                          AS date,
    TO_CHAR(a.time_in::timestamptz  AT TIME ZONE 'Asia/Manila', 'HH12:MI AM')                  AS time_in,
    TO_CHAR(a.time_out::timestamptz AT TIME ZONE 'Asia/Manila', 'HH12:MI AM')                  AS time_out,
    NULL                                                                                         AS hours_rendered,
    a.status,                                                                                    -- ← ADD
    COALESCE(a.is_reported, false)                                                               AS is_reported,
    COALESCE(a.report_reason, '')                                                                AS report_reason,
    COALESCE(a.report_type, '')                                                                  AS report_type,
    TO_CHAR(a.reported_at AT TIME ZONE 'Asia/Manila', 'YYYY-MM-DD HH12:MI AM')                 AS reported_at,
    a.admin_note
`

// internSelectSingleDate is unchanged — users table is already the spine.
// internSelectSingleDate — same addition
const internSelectSingleDate = `
    COALESCE(a.id, 0)                                                                            AS id,
    u.id                                                                                         AS user_id,
    COALESCE(NULLIF(TRIM(CONCAT(u.first_name, ' ', u.last_name)), ''), 'Unknown')               AS intern_name,
    COALESCE(u.avatar_url, '')                                                                   AS avatar_url,
    CAST(? AS TEXT)                                                                              AS date,
    TO_CHAR(a.time_in::timestamptz  AT TIME ZONE 'Asia/Manila', 'HH12:MI AM')                  AS time_in,
    TO_CHAR(a.time_out::timestamptz AT TIME ZONE 'Asia/Manila', 'HH12:MI AM')                  AS time_out,
    NULL                                                                                         AS hours_rendered,
    a.status,                                                                                    -- ← ADD
    COALESCE(a.is_reported, false)                                                               AS is_reported,
    COALESCE(a.report_reason, '')                                                                AS report_reason,
    COALESCE(a.report_type, '')                                                                  AS report_type,
    TO_CHAR(a.reported_at AT TIME ZONE 'Asia/Manila', 'YYYY-MM-DD HH12:MI AM')                 AS reported_at,
    a.admin_note
`

// ── date range helper ─────────────────────────────────────────────────────────

func periodDateRange(period string, now time.Time) (start, end string) {
	const layout = "2006-01-02"
	switch period {
	case "today":
		d := now.Format(layout)
		return d, d
	case "week":
		weekday := int(now.Weekday())
		sun := now.AddDate(0, 0, -weekday)
		sat := sun.AddDate(0, 0, 6)
		return sun.Format(layout), sat.Format(layout)
	case "month":
		first := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())
		return first.Format(layout), now.Format(layout)
	case "year":
		first := time.Date(now.Year(), 1, 1, 0, 0, 0, 0, now.Location())
		return first.Format(layout), now.Format(layout)
	}
	return "", ""
}

func isValidDate(s string) bool {
	_, err := time.Parse("2006-01-02", s)
	return err == nil
}

// ── multiDateQuery builds the cross-join query for any date range ─────────────
//
// The spine is: generate_series(start, end, '1 day') × active interns
// Then LEFT JOIN attendance so absent days get a NULL attendance row.
// This is the same pattern already used for single-date queries, extended
// to cover arbitrary date ranges.

func (h *Handler) multiDateQuery(
	start, end, search, filterUID string,
	weekdaysOnly bool, // true = skip Saturday/Sunday
) *gorm.DB {
	// generate_series produces one row per calendar day in [start, end].
	// We CROSS JOIN with the intern list so every intern appears on every day.
	// Then LEFT JOIN attendance to pick up actual clock-in/out rows.
	fromClause := `
		(SELECT generate_series(
			?::date,
			?::date,
			'1 day'::interval
		)::date AS day) d
		CROSS JOIN (
			SELECT id, first_name, last_name, avatar_url
			FROM users
			WHERE deleted_at IS NULL
			  AND is_archived = false
			  AND role = 'user'
			  AND position = 'Intern'
		) u
		LEFT JOIN attendance a
			ON a.user_id = u.id
			AND a.date = d.day
	`

	q := h.DB.Table(fromClause, start, end).
		Select(internSelectMultiDate)

	// Skip weekends (Saturday=6, Sunday=0 in PostgreSQL's dow)
	if weekdaysOnly {
		q = q.Where("EXTRACT(DOW FROM d.day) NOT IN (0, 6)")
	}

	if filterUID != "" {
		q = q.Where("u.id = ?", filterUID)
	}
	if search != "" {
		q = q.Where(
			"LOWER(TRIM(CONCAT(u.first_name, ' ', u.last_name))) LIKE ?",
			"%"+strings.ToLower(search)+"%",
		)
	}

	return q
}

// ── GET /api/admin/attendance ─────────────────────────────────────────────────

func (h *Handler) AdminGetAttendance(c *gin.Context) {
	now := time.Now().In(manilaLoc())

	allDates := c.DefaultQuery("all_dates", "false") == "true"
	period := strings.TrimSpace(c.DefaultQuery("period", ""))
	dateStr := strings.TrimSpace(c.DefaultQuery("date", now.Format("2006-01-02")))
	dateFrom := strings.TrimSpace(c.DefaultQuery("date_from", ""))
	dateTo := strings.TrimSpace(c.DefaultQuery("date_to", ""))
	search := strings.TrimSpace(c.DefaultQuery("search", ""))
	statusFilter := strings.TrimSpace(c.DefaultQuery("status", ""))
	filterUID := strings.TrimSpace(c.DefaultQuery("user_id", ""))

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}

	var allRows []attendanceRaw

	switch {

	// ── (1) all_dates — from earliest attendance record to today ──────────────
	case allDates:
		// Use the earliest intern start_date as the floor, so absent rows
		// are generated from the beginning of their internship — not just
		// from when they first clocked in.
		var earliest string
		h.DB.Table("users").
			Select("TO_CHAR(MIN(start_date), 'YYYY-MM-DD')").
			Where("deleted_at IS NULL AND is_archived = false AND role = 'user' AND position = 'Intern'").
			Where("start_date IS NOT NULL").
			Scan(&earliest)

		// Fall back to earliest attendance record if no start_dates are set
		if earliest == "" {
			h.DB.Table("attendance").Select("TO_CHAR(MIN(date), 'YYYY-MM-DD')").Scan(&earliest)
		}
		// Last resort: today
		if earliest == "" {
			earliest = now.Format("2006-01-02")
		}

		fmt.Printf("[DEBUG allDates] using earliest=%s\n", earliest)

		end := now.Format("2006-01-02")
		q := h.multiDateQuery(earliest, end, search, filterUID, true)
		q.Order("d.day DESC, intern_name ASC").Scan(&allRows)
	// ── (2) named period (week / month / year) ────────────────────────────────
	case period != "" && period != "today":
		start, end := periodDateRange(period, now)
		if start == "" {
			c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "invalid period"})
			return
		}
		q := h.multiDateQuery(start, end, search, filterUID, true)
		q.Order("d.day DESC, intern_name ASC").Scan(&allRows)

	// ── (3) custom date range ─────────────────────────────────────────────────
	case dateFrom != "" && dateTo != "":
		if !isValidDate(dateFrom) || !isValidDate(dateTo) {
			c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "invalid date_from or date_to"})
			return
		}
		if dateFrom > dateTo {
			dateFrom, dateTo = dateTo, dateFrom
		}
		q := h.multiDateQuery(dateFrom, dateTo, search, filterUID, false)
		q.Order("d.day DESC, intern_name ASC").Scan(&allRows)

	// ── (4) single date / today ───────────────────────────────────────────────
	default:
		if period == "today" {
			dateStr = now.Format("2006-01-02")
		}
		q := h.DB.Table("users u").
			Select(internSelectSingleDate, dateStr).
			Joins("LEFT JOIN attendance a ON a.user_id = u.id AND a.date = ?", dateStr).
			Where("u.deleted_at IS NULL").
			Where("u.is_archived = ?", false).
			Where("u.role = ?", "user").
			Where("u.position = ?", "Intern")
		if filterUID != "" {
			q = q.Where("u.id = ?", filterUID)
		}
		if search != "" {
			q = q.Where(
				"LOWER(TRIM(CONCAT(u.first_name, ' ', u.last_name))) LIKE ?",
				"%"+strings.ToLower(search)+"%",
			)
		}
		q.Order("intern_name ASC").Scan(&allRows)
	}

	// ── derive status + compute hours ─────────────────────────────────────────
	response := toResponseRows(allRows)

	// ── apply status filter in-memory ─────────────────────────────────────────
	if statusFilter != "" {
		filtered := response[:0]
		for _, r := range response {
			if r.Status == statusFilter {
				filtered = append(filtered, r)
			}
		}
		response = filtered
	}

	total := len(response)

	// ── paginate in-memory ────────────────────────────────────────────────────
	start := (page - 1) * limit
	if start >= total {
		start = total
	}
	end := start + limit
	if end > total {
		end = total
	}
	paginated := response[start:end]

	c.JSON(http.StatusOK, gin.H{
		"ok":      true,
		"records": paginated,
		"total":   total,
		"page":    page,
		"limit":   limit,
	})
}

// ── GET /api/admin/attendance/export ─────────────────────────────────────────

func (h *Handler) AdminExportAttendance(c *gin.Context) {
	now := time.Now().In(manilaLoc())

	allDates := c.DefaultQuery("all_dates", "false") == "true"
	period := strings.TrimSpace(c.DefaultQuery("period", ""))
	dateStr := strings.TrimSpace(c.DefaultQuery("date", now.Format("2006-01-02")))
	dateFrom := strings.TrimSpace(c.DefaultQuery("date_from", ""))
	dateTo := strings.TrimSpace(c.DefaultQuery("date_to", ""))
	search := strings.TrimSpace(c.DefaultQuery("search", ""))
	statusFilter := strings.TrimSpace(c.DefaultQuery("status", ""))

	var allRows []attendanceRaw

	switch {
	case allDates:
		var earliest string
		h.DB.Table("attendance").Select("TO_CHAR(MIN(date), 'YYYY-MM-DD')").Scan(&earliest)
		if earliest == "" {
			earliest = now.Format("2006-01-02")
		}
		end := now.Format("2006-01-02")
		q := h.multiDateQuery(earliest, end, search, "", true)
		q.Order("d.day DESC, intern_name ASC").Scan(&allRows)

	case period != "" && period != "today":
		start, end := periodDateRange(period, now)
		if start == "" {
			c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "invalid period"})
			return
		}
		q := h.multiDateQuery(start, end, search, "", true)
		q.Order("d.day DESC, intern_name ASC").Scan(&allRows)

	case dateFrom != "" && dateTo != "":
		if !isValidDate(dateFrom) || !isValidDate(dateTo) {
			c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "invalid date_from or date_to"})
			return
		}
		if dateFrom > dateTo {
			dateFrom, dateTo = dateTo, dateFrom
		}
		q := h.multiDateQuery(dateFrom, dateTo, search, "", false)
		q.Order("d.day DESC, intern_name ASC").Scan(&allRows)

	default:
		if period == "today" {
			dateStr = now.Format("2006-01-02")
		}
		q := h.DB.Table("users u").
			Select(internSelectSingleDate, dateStr).
			Joins("LEFT JOIN attendance a ON a.user_id = u.id AND a.date = ?", dateStr).
			Where("u.deleted_at IS NULL").
			Where("u.is_archived = ?", false).
			Where("u.role = ?", "user").
			Where("u.position = ?", "Intern")
		if search != "" {
			q = q.Where(
				"LOWER(TRIM(CONCAT(u.first_name, ' ', u.last_name))) LIKE ?",
				"%"+strings.ToLower(search)+"%",
			)
		}
		q.Order("intern_name ASC").Scan(&allRows)
	}

	rows := toResponseRows(allRows)
	if statusFilter != "" {
		filtered := rows[:0]
		for _, r := range rows {
			if r.Status == statusFilter {
				filtered = append(filtered, r)
			}
		}
		rows = filtered
	}

	filename := fmt.Sprintf("attendance_%s.csv", dateStr)
	if dateFrom != "" && dateTo != "" {
		filename = fmt.Sprintf("attendance_%s_to_%s.csv", dateFrom, dateTo)
	}

	c.Header("Content-Disposition", "attachment; filename="+filename)
	c.Header("Content-Type", "text/csv")

	w := csv.NewWriter(c.Writer)
	_ = w.Write([]string{"Intern", "Date", "Time In", "Time Out", "Hours Rendered", "Status"})

	for _, r := range rows {
		timeIn := "--"
		timeOut := "--"
		hours := "--"

		if r.TimeIn != nil {
			timeIn = *r.TimeIn
		}
		if r.TimeOut != nil {
			timeOut = *r.TimeOut
		}
		if r.HoursRendered != nil {
			hh := int(*r.HoursRendered)
			mm := int((*r.HoursRendered - float64(hh)) * 60)
			hours = fmt.Sprintf("%dh %dm", hh, mm)
		}

		_ = w.Write([]string{
			r.InternName,
			r.Date,
			timeIn,
			timeOut,
			hours,
			r.Status,
		})
	}
	w.Flush()
}

// ── PATCH /api/admin/attendance/:id/resolve ───────────────────────────────────

func (h *Handler) ResolveAttendanceReport(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "Invalid record ID"})
		return
	}

	var rec models.Attendance
	if err := h.DB.First(&rec, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"ok": false, "error": "Record not found"})
		return
	}

	if err := h.DB.Model(&rec).Updates(map[string]interface{}{
		"is_reported": false,
		"reported_at": nil,
		"resolution":  "dismissed",
	}).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"ok": false, "error": "Failed to resolve report"})
		return
	}

	adminID, _ := getUserIDFromCtx(c)
	h.logActivity(adminID, "RESOLVE_REPORT",
		fmt.Sprintf("Admin resolved attendance report %d", rec.ID), c.ClientIP())

	c.JSON(http.StatusOK, gin.H{"ok": true})
}

// ── POST /api/admin/attendance/:id/resolve ────────────────────────────────────

func (h *Handler) ResolveAttendanceIssue(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "Invalid record ID"})
		return
	}

	var body struct {
		Resolution     string  `json:"resolution"`
		TimeOut        *string `json:"time_out"`
		AdjustedTimeIn *string `json:"adjusted_time_in"`
		CreditedTimeIn *string `json:"credited_time_in"`
		Note           *string `json:"note"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "Invalid request body"})
		return
	}

	var rec models.Attendance
	if err := h.DB.First(&rec, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"ok": false, "error": "Record not found"})
		return
	}

	loc := manilaLoc()

	baseUpdates := map[string]interface{}{
		"is_reported": false,
		"resolution":  body.Resolution,
	}
	if body.Note != nil && strings.TrimSpace(*body.Note) != "" {
		baseUpdates["admin_note"] = strings.TrimSpace(*body.Note)
	}

	switch body.Resolution {
	case "set_timeout":
		if body.TimeOut == nil {
			c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "time_out is required"})
			return
		}
		t, err := parseAdminTime(rec.Date, *body.TimeOut, loc)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "Invalid time_out, expected HH:MM"})
			return
		}
		baseUpdates["time_out"] = &t

	case "mark_present":
		if rec.TimeIn == nil {
			tIn, _ := parseAdminTime(rec.Date, "08:00", loc)
			baseUpdates["time_in"] = &tIn
		}
		tOut, _ := parseAdminTime(rec.Date, "17:00", loc)
		baseUpdates["time_out"] = &tOut

	case "adjust_timein":
		if body.AdjustedTimeIn == nil {
			c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "adjusted_time_in is required"})
			return
		}
		t, err := parseAdminTime(rec.Date, *body.AdjustedTimeIn, loc)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "Invalid adjusted_time_in, expected HH:MM"})
			return
		}
		baseUpdates["time_in"] = &t

	case "excuse", "no_action":
		// no status override needed

	case "excused_credited":
		baseUpdates["status"] = "Excused – Credited"

		// Use admin-supplied time-in if provided, otherwise fall back to 08:00
		if body.CreditedTimeIn != nil {
			t, err := parseAdminTime(rec.Date, *body.CreditedTimeIn, loc)
			if err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "Invalid credited_time_in"})
				return
			}
			baseUpdates["time_in"] = &t
		} else if rec.TimeIn == nil {
			tIn, _ := parseAdminTime(rec.Date, "08:00", loc)
			baseUpdates["time_in"] = &tIn
		}

		// Use admin-supplied time-out if provided, otherwise fall back to 17:00
		if body.TimeOut != nil {
			t, err := parseAdminTime(rec.Date, *body.TimeOut, loc)
			if err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "Invalid time_out for credited excusal"})
				return
			}
			baseUpdates["time_out"] = &t
		} else if rec.TimeOut == nil {
			tOut, _ := parseAdminTime(rec.Date, "17:00", loc)
			baseUpdates["time_out"] = &tOut
		}

	case "excused_uncredited":
		baseUpdates["status"] = "Excused – Uncredited"

	default:
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "Unknown resolution: " + body.Resolution})
		return
	}

	columns := make([]string, 0, len(baseUpdates))
	for k := range baseUpdates {
		columns = append(columns, k)
	}

	if err := h.DB.Model(&rec).Select(columns).Updates(baseUpdates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"ok": false, "error": "Failed to save resolution"})
		return
	}

	adminID, _ := getUserIDFromCtx(c)
	h.logActivity(adminID, "RESOLVE_ATTENDANCE",
		fmt.Sprintf("Admin resolved attendance record #%d via '%s'", rec.ID, body.Resolution),
		c.ClientIP())

	c.JSON(http.StatusOK, gin.H{"ok": true})
}

func parseAdminTime(recordDate time.Time, hhmm string, loc *time.Location) (time.Time, error) {
	parts := strings.Split(strings.TrimSpace(hhmm), ":")
	if len(parts) != 2 {
		return time.Time{}, fmt.Errorf("expected HH:MM, got %q", hhmm)
	}
	h, e1 := strconv.Atoi(strings.TrimSpace(parts[0]))
	m, e2 := strconv.Atoi(strings.TrimSpace(parts[1]))
	if e1 != nil || e2 != nil || h < 0 || h > 23 || m < 0 || m > 59 {
		return time.Time{}, fmt.Errorf("invalid time value %q", hhmm)
	}
	return time.Date(
		recordDate.Year(), recordDate.Month(), recordDate.Day(),
		h, m, 0, 0, loc,
	), nil
}

// ── GET /api/admin/attendance/reports ────────────────────────────────────────

func (h *Handler) GetPendingReports(c *gin.Context) {

	// Simpler — pending reports always have an actual attendance row,
	// so the original query is fine here.
	var simpleRows []attendanceRaw
	h.DB.Raw(`
		SELECT
			a.id,
			a.user_id,
			COALESCE(NULLIF(TRIM(CONCAT(u.first_name, ' ', u.last_name)), ''), 'Unknown') AS intern_name,
			COALESCE(u.avatar_url, '') AS avatar_url,
			TO_CHAR(a.date::date, 'YYYY-MM-DD') AS date,
			TO_CHAR(a.time_in::timestamptz  AT TIME ZONE 'Asia/Manila', 'HH12:MI AM') AS time_in,
			TO_CHAR(a.time_out::timestamptz AT TIME ZONE 'Asia/Manila', 'HH12:MI AM') AS time_out,
			NULL AS hours_rendered,
			a.status,       
			COALESCE(a.is_reported, false) AS is_reported,
			COALESCE(a.report_reason, '') AS report_reason,
			COALESCE(a.report_type, '') AS report_type,
			TO_CHAR(a.reported_at AT TIME ZONE 'Asia/Manila', 'YYYY-MM-DD HH12:MI AM') AS reported_at,
			a.admin_note
		FROM attendance a
		LEFT JOIN users u ON u.id = a.user_id
		WHERE a.is_reported = true AND a.resolution IS NULL
		ORDER BY a.date DESC
	`).Scan(&simpleRows)

	response := toResponseRows(simpleRows)

	c.JSON(http.StatusOK, gin.H{
		"ok":      true,
		"records": response,
		"total":   len(response),
	})
}

// ── PATCH /api/admin/attendance/:id/remark ────────────────────────────────────

func (h *Handler) UpdateAttendanceRemark(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "Invalid ID"})
		return
	}

	var body struct {
		Remark string `json:"remark"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "Invalid body"})
		return
	}

	if err := h.DB.Model(&models.Attendance{}).
		Where("id = ?", id).
		Update("admin_note", strings.TrimSpace(body.Remark)).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"ok": false, "error": "Failed to save remark"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"ok": true})
}
