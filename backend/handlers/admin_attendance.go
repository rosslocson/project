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

// adminAttendanceHoursExpr is kept as NULL — hours are computed in Go via
// computeHours() so we can apply the lunch deduction and 5 PM cap correctly.
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
	t, err := time.Parse("03:04 PM", *timeIn)
	if err != nil {
		return "Present"
	}
	if t.Hour() > lateThresholdHour ||
		(t.Hour() == lateThresholdHour && t.Minute() > lateThresholdMin) {
		return "Late"
	}
	return "Present"
}

// ── Hours computation ─────────────────────────────────────────────────────────
//
// Rules:
//   - Returns nil if either time_in or time_out is missing.
//   - Caps time_out at 17:00 (5 PM) — no overtime counted.
//   - Deducts the 12:00–13:00 lunch hour if the shift overlaps that window.

func computeHours(timeIn *string, timeOut *string, recordDate string) *float64 {
	if timeIn == nil || timeOut == nil {
		return nil
	}

	loc := manilaLoc()
	const layout = "2006-01-02 03:04 PM"

	tIn, err1 := time.ParseInLocation(layout, recordDate+" "+*timeIn, loc)
	tOut, err2 := time.ParseInLocation(layout, recordDate+" "+*timeOut, loc)
	if err1 != nil || err2 != nil {
		return nil
	}

	// Cap time_out at 5:00 PM.
	cutoff := time.Date(tIn.Year(), tIn.Month(), tIn.Day(), 17, 0, 0, 0, loc)
	if tOut.After(cutoff) {
		tOut = cutoff
	}

	// Guard: if capping pushed tOut to before tIn, return zero.
	if !tOut.After(tIn) {
		zero := 0.0
		return &zero
	}

	elapsed := tOut.Sub(tIn).Hours()

	// Deduct lunch (12:00–13:00) proportional to how much of it the shift covers.
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
	HoursRendered *float64 `gorm:"column:hours_rendered"` // always NULL from DB; computed below
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
			HoursRendered: computeHours(r.TimeIn, r.TimeOut, r.Date), // ← Go-computed
			Status:        deriveStatus(r.TimeIn, r.TimeOut, r.Date),
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
	` + adminAttendanceHoursExpr + `                                                             AS hours_rendered
`

const internSelectAllDates = `
	a.id                                                                                         AS id,
	a.user_id                                                                                    AS user_id,
	COALESCE(NULLIF(TRIM(CONCAT(u.first_name, ' ', u.last_name)), ''), 'Unknown')               AS intern_name,
	COALESCE(u.avatar_url, '')                                                                   AS avatar_url,
	TO_CHAR(a.date::date, 'YYYY-MM-DD')                                                         AS date,
	TO_CHAR(a.time_in::timestamptz  AT TIME ZONE 'Asia/Manila', 'HH12:MI AM')                  AS time_in,
	TO_CHAR(a.time_out::timestamptz AT TIME ZONE 'Asia/Manila', 'HH12:MI AM')                  AS time_out,
	` + adminAttendanceHoursExpr + `                                                             AS hours_rendered
`

// ── date range helper ─────────────────────────────────────────────────────────

// periodDateRange returns the inclusive [start, end] date strings for a named
// period relative to now (Manila time). Returns ("", "") for unknown periods.
func periodDateRange(period string, now time.Time) (start, end string) {
	const layout = "2006-01-02"
	switch period {
	case "today":
		d := now.Format(layout)
		return d, d
	case "week":
		// Sunday → Saturday of the current calendar week
		weekday := int(now.Weekday()) // 0 = Sunday
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

// ── GET /api/admin/attendance ─────────────────────────────────────────────────
//
// Query params:
//   date        – YYYY-MM-DD; used when period is absent and all_dates is false
//   period      – today | week | month | year  (overrides date)
//   all_dates   – "true" to return every date on record (overrides both)
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

	switch {

	// ── (1) all_dates: every row in the attendance table ─────────────────────
	case allDates:
		q := h.DB.Table("attendance a").
			Select(internSelectAllDates).
			Joins("LEFT JOIN users u ON u.id = a.user_id")

		if filterUID != "" {
			q = q.Where("a.user_id = ?", filterUID)
		}
		if search != "" {
			q = q.Where(
				"LOWER(TRIM(CONCAT(u.first_name, ' ', u.last_name))) LIKE ?",
				"%"+strings.ToLower(search)+"%",
			)
		}
		q.Order("a.date DESC, intern_name ASC").Scan(&allRows)

	// ── (2) named period (today / week / month / year) ────────────────────────
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

		if filterUID != "" {
			q = q.Where("a.user_id = ?", filterUID)
		}
		if search != "" {
			q = q.Where(
				"LOWER(TRIM(CONCAT(u.first_name, ' ', u.last_name))) LIKE ?",
				"%"+strings.ToLower(search)+"%",
			)
		}
		q.Order("a.date DESC, intern_name ASC").Scan(&allRows)

	// ── (3) single date (today shorthand or explicit date) ────────────────────
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

	// ── derive status + compute hours for every row ───────────────────────────
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

	// Derive status + compute hours, then apply optional status filter.
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

	// Stream CSV
	filename := fmt.Sprintf("attendance_%s.csv", dateStr)
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
