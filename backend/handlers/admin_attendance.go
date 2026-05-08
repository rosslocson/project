// backend/handlers/admin_attendance.go
//
// Admin endpoint – returns all interns' attendance records,
// joined with user profile data, with optional date/period filtering,
// search by name, status filtering, and pagination.
//
// Routes (register in your router):
//   GET /api/admin/attendance
//   GET /api/admin/attendance/export   (CSV download)

package handlers

import (
	"encoding/csv"
	"fmt"
	"net/http"
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
	Date          string   `json:"date"`           // "YYYY-MM-DD"
	TimeIn        *string  `json:"time_in"`        // nullable "HH:MI AM"
	TimeOut       *string  `json:"time_out"`       // nullable "HH:MI AM"
	HoursRendered *float64 `json:"hours_rendered"` // nullable
	Status        string   `json:"status"`         // Present | Late | Absent | On Shift | Missed Clock Out
	IsReported    bool     `json:"is_reported"`
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

	// Try both padded and unpadded formats
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
	// If either time is missing, we can't compute anything.
	if timeIn == nil || timeOut == nil {
		return nil
	}

	loc := manilaLoc()

	// Postgres TO_CHAR with HH12 can produce "8:30 AM" (no leading zero) or
	// lowercase "am"/"pm" depending on locale. Normalize before parsing.
	normalize := func(t string) string {
		return strings.ToUpper(strings.TrimSpace(t))
	}

	// Try padded (03) then unpadded (3) 12-hour format.
	tryParse := func(dateStr, timeStr string) (time.Time, error) {
		timeStr = normalize(timeStr)
		for _, layout := range []string{
			"2006-01-02 03:04 PM", // e.g. "2025-05-06 08:30 AM"
			"2006-01-02 3:04 PM",  // e.g. "2025-05-06 8:30 AM"
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
		// Log so you can see the exact raw string coming from Postgres.
		fmt.Printf("[computeHours] parse error — timeIn=%q err=%v | timeOut=%q err=%v\n",
			*timeIn, err1, *timeOut, err2)
		return nil
	}

	// ── Step 1: Cap clock-out at 5:00 PM ─────────────────────────────────────
	// We don't count any time worked past 5 PM.
	cutoff := time.Date(tIn.Year(), tIn.Month(), tIn.Day(), 17, 0, 0, 0, loc)
	if tOut.After(cutoff) {
		tOut = cutoff
	}

	// ── Step 2: Guard — clock-out must be after clock-in ─────────────────────
	if !tOut.After(tIn) {
		zero := 0.0
		return &zero
	}

	// ── Step 3: Raw elapsed hours (before lunch deduction) ───────────────────
	// Example: 8:00 AM → 5:00 PM = 9.0 hours raw
	elapsed := tOut.Sub(tIn).Hours()

	// ── Step 4: Deduct lunch break (12:00 PM – 1:00 PM) ─────────────────────
	// We only deduct the portion of the lunch window the intern was actually
	// clocked in for. This handles edge cases like:
	//   - Clocked in after lunch (1:30 PM) → no deduction
	//   - Clocked out before lunch (11:00 AM) → no deduction
	//   - Clocked in during lunch (12:30 PM) → deduct only 30 min
	lunchStart := time.Date(tIn.Year(), tIn.Month(), tIn.Day(), 12, 0, 0, 0, loc)
	lunchEnd := time.Date(tIn.Year(), tIn.Month(), tIn.Day(), 13, 0, 0, 0, loc)

	// Overlap start = latest of (clock-in, lunch start)
	overlapStart := tIn
	if lunchStart.After(overlapStart) {
		overlapStart = lunchStart
	}

	// Overlap end = earliest of (effective clock-out, lunch end)
	overlapEnd := tOut
	if lunchEnd.Before(overlapEnd) {
		overlapEnd = lunchEnd
	}

	// Only deduct if there's a real overlap (overlap end is after overlap start).
	// Example: 8 AM–5 PM → overlap is 12:00–13:00 → deduct 1.0 hour
	// Example: 8 AM–11 AM → overlapEnd (11AM) is NOT after overlapStart (12PM) → no deduction
	if overlapEnd.After(overlapStart) {
		elapsed -= overlapEnd.Sub(overlapStart).Hours()
	}

	// ── Step 5: Clamp to zero (should never go negative, but just in case) ───
	if elapsed < 0 {
		elapsed = 0
	}

	// ── Examples ──────────────────────────────────────────────────────────────
	// 8:00 AM → 5:00 PM  = 9h raw − 1h lunch = 8.0h
	// 8:00 AM → 12:00 PM = 4h raw − 0h lunch = 4.0h  (left before lunch)
	// 1:00 PM → 5:00 PM  = 4h raw − 0h lunch = 4.0h  (arrived after lunch)
	// 8:00 AM → 6:00 PM  = 9h raw − 1h lunch = 8.0h  (capped at 5 PM first)
	// 12:30 PM → 5:00 PM = 4.5h raw − 0.5h lunch overlap = 4.0h

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
	IsReported    bool     `gorm:"column:is_reported"`
}

func toResponseRows(rows []attendanceRaw) []AdminAttendanceRow {
	out := make([]AdminAttendanceRow, 0, len(rows))
	for _, r := range rows {
		out = append(out, AdminAttendanceRow{
			ID:            r.ID,
			UserID:        r.UserID,
			InternName:    r.InternName,
			AvatarURL:     r.AvatarURL,
			Date:          r.Date,
			TimeIn:        r.TimeIn,
			TimeOut:       r.TimeOut,
			HoursRendered: computeHours(r.TimeIn, r.TimeOut, r.Date),
			Status:        deriveStatus(r.TimeIn, r.TimeOut, r.Date),
			IsReported:    r.IsReported,
		})
	}
	return out
}

// ── SQL select fragments ──────────────────────────────────────────────────────

const internSelectSingleDate = `
	COALESCE(a.id, 0)                                                                            AS id,
	u.id                                                                                         AS user_id,
	COALESCE(NULLIF(TRIM(CONCAT(u.first_name, ' ', u.last_name)), ''), 'Unknown')               AS intern_name,
	COALESCE(u.avatar_url, '')                                                                   AS avatar_url,
	CAST(? AS TEXT)                                                                              AS date,
	TO_CHAR(a.time_in::timestamptz  AT TIME ZONE 'Asia/Manila', 'HH12:MI AM')                  AS time_in,
	TO_CHAR(a.time_out::timestamptz AT TIME ZONE 'Asia/Manila', 'HH12:MI AM')                  AS time_out,
	` + adminAttendanceHoursExpr + `                                                             AS hours_rendered,
	COALESCE(a.is_reported, false)                                                               AS is_reported
`

const internSelectAllDates = `
	a.id                                                                                         AS id,
	a.user_id                                                                                    AS user_id,
	COALESCE(NULLIF(TRIM(CONCAT(u.first_name, ' ', u.last_name)), ''), 'Unknown')               AS intern_name,
	COALESCE(u.avatar_url, '')                                                                   AS avatar_url,
	TO_CHAR(a.date::date, 'YYYY-MM-DD')                                                         AS date,
	TO_CHAR(a.time_in::timestamptz  AT TIME ZONE 'Asia/Manila', 'HH12:MI AM')                  AS time_in,
	TO_CHAR(a.time_out::timestamptz AT TIME ZONE 'Asia/Manila', 'HH12:MI AM')                  AS time_out,
	` + adminAttendanceHoursExpr + `                                                             AS hours_rendered,
	COALESCE(a.is_reported, false)                                                               AS is_reported
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

// isValidDate returns true if s is a parseable YYYY-MM-DD string.
func isValidDate(s string) bool {
	_, err := time.Parse("2006-01-02", s)
	return err == nil
}

// ── GET /api/admin/attendance ─────────────────────────────────────────────────
//
// Query params:
//   date        – YYYY-MM-DD; used for a single-day query (shows all interns)
//   date_from   – YYYY-MM-DD; start of a custom range (use with date_to)
//   date_to     – YYYY-MM-DD; end of a custom range (use with date_from)
//   period      – today | week | month | year  (overrides date/date_from/date_to)
//   all_dates   – "true" to return every date on record (overrides everything)
//   search      – partial case-insensitive intern name match
//   status      – Present | Late | On Shift | Missed Clock Out | Absent
//   page        – 1-based; default = 1
//   limit       – rows per page 1-100; default = 20
//   user_id     – (optional) filter to one intern

func (h *Handler) AdminGetAttendance(c *gin.Context) {
	now := time.Now().In(manilaLoc())

	// ── parse params ──────────────────────────────────────────────────────────
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

	// ── build query ───────────────────────────────────────────────────────────
	var allRows []attendanceRaw

	// Helper: apply optional name search + user_id filter to any query.
	applyCommon := func(q *gorm.DB) *gorm.DB {
		if filterUID != "" {
			q = q.Where("a.user_id = ?", filterUID)
		}
		if search != "" {
			q = q.Where(
				"LOWER(TRIM(CONCAT(u.first_name, ' ', u.last_name))) LIKE ?",
				"%"+strings.ToLower(search)+"%",
			)
		}
		return q
	}

	switch {

	// ── (1) all_dates ─────────────────────────────────────────────────────────
	case allDates:
		q := h.DB.Table("attendance a").
			Select(internSelectAllDates).
			Joins("LEFT JOIN users u ON u.id = a.user_id")
		q = applyCommon(q)
		q.Order("a.date DESC, intern_name ASC").Scan(&allRows)

	// ── (2) named period ──────────────────────────────────────────────────────
	case period != "" && period != "today":
		start, end := periodDateRange(period, now)
		if start == "" {
			c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "invalid period"})
			return
		}
		q := h.DB.Table("attendance a").
			Select(internSelectAllDates).
			Joins("LEFT JOIN users u ON u.id = a.user_id").
			Where("a.date BETWEEN ? AND ?", start, end)
		q = applyCommon(q)
		q.Order("a.date DESC, intern_name ASC").Scan(&allRows)

	// ── (3) custom date range (date_from + date_to) ───────────────────────────
	//
	// Unlike single-date mode, we query attendance rows directly (not joined
	// to the users table as the "spine") so that only days with actual records
	// are returned — matching the multi-date behaviour of periods and all_dates.
	case dateFrom != "" && dateTo != "":
		if !isValidDate(dateFrom) || !isValidDate(dateTo) {
			c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "invalid date_from or date_to"})
			return
		}
		// Swap if caller passed them backwards.
		if dateFrom > dateTo {
			dateFrom, dateTo = dateTo, dateFrom
		}
		q := h.DB.Table("attendance a").
			Select(internSelectAllDates).
			Joins("LEFT JOIN users u ON u.id = a.user_id").
			Where("a.date BETWEEN ? AND ?", dateFrom, dateTo)
		q = applyCommon(q)
		q.Order("a.date DESC, intern_name ASC").Scan(&allRows)

	// ── (4) single date (today shorthand or explicit date param) ──────────────
	//
	// Queries from the users table as the spine so that every intern appears
	// even if they have no attendance record for that day (shown as Absent).
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
//
// Accepts the same filter params as AdminGetAttendance (except page/limit).
// Streams a CSV file directly to the response.

func (h *Handler) AdminExportAttendance(c *gin.Context) {
	now := time.Now().In(manilaLoc())

	allDates := c.DefaultQuery("all_dates", "false") == "true"
	period := strings.TrimSpace(c.DefaultQuery("period", ""))
	dateStr := strings.TrimSpace(c.DefaultQuery("date", now.Format("2006-01-02")))
	dateFrom := strings.TrimSpace(c.DefaultQuery("date_from", ""))
	dateTo := strings.TrimSpace(c.DefaultQuery("date_to", ""))
	search := strings.TrimSpace(c.DefaultQuery("search", ""))
	statusFilter := strings.TrimSpace(c.DefaultQuery("status", ""))

	applySearchFilter := func(q *gorm.DB) *gorm.DB {
		if search != "" {
			q = q.Where(
				"LOWER(TRIM(CONCAT(u.first_name, ' ', u.last_name))) LIKE ?",
				"%"+strings.ToLower(search)+"%",
			)
		}
		return q
	}

	var allRows []attendanceRaw

	switch {
	case allDates:
		q := h.DB.Table("attendance a").
			Select(internSelectAllDates).
			Joins("LEFT JOIN users u ON u.id = a.user_id")
		q = applySearchFilter(q)
		q.Order("a.date DESC, intern_name ASC").Scan(&allRows)

	case period != "" && period != "today":
		start, end := periodDateRange(period, now)
		if start == "" {
			c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "invalid period"})
			return
		}
		q := h.DB.Table("attendance a").
			Select(internSelectAllDates).
			Joins("LEFT JOIN users u ON u.id = a.user_id").
			Where("a.date BETWEEN ? AND ?", start, end)
		q = applySearchFilter(q)
		q.Order("a.date DESC, intern_name ASC").Scan(&allRows)

	// ── custom date range ─────────────────────────────────────────────────────
	case dateFrom != "" && dateTo != "":
		if !isValidDate(dateFrom) || !isValidDate(dateTo) {
			c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "invalid date_from or date_to"})
			return
		}
		if dateFrom > dateTo {
			dateFrom, dateTo = dateTo, dateFrom
		}
		q := h.DB.Table("attendance a").
			Select(internSelectAllDates).
			Joins("LEFT JOIN users u ON u.id = a.user_id").
			Where("a.date BETWEEN ? AND ?", dateFrom, dateTo)
		q = applySearchFilter(q)
		q.Order("a.date DESC, intern_name ASC").Scan(&allRows)

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
		q = applySearchFilter(q)
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

	// Use a descriptive filename for the range export.
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
