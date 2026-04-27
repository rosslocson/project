// backend/handlers/admin_attendance.go
//
// Admin endpoint – returns all interns' attendance records,
// joined with user profile data, with optional date filtering
// and pagination.
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
	"time"

	"github.com/gin-gonic/gin"
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
	Status        string   `json:"status"`         // Present | Late | Absent | In Progress | Missed Clock Out
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

func deriveStatus(timeIn *string, timeOut *string, recordDate string) string {
	if timeIn == nil {
		return "Absent"
	}
	if timeOut == nil {
		today := time.Now().In(manilaLoc()).Format("2006-01-02")
		if recordDate == today {
			return "In Progress"
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
			HoursRendered: r.HoursRendered,
			Status:        deriveStatus(r.TimeIn, r.TimeOut, r.Date),
		})
	}
	return out
}

// ── intern base query helpers ─────────────────────────────────────────────────

const internSelectSingleDate = `
	COALESCE(a.id, 0)                                                                            AS id,
	u.id                                                                                         AS user_id,
	COALESCE(NULLIF(TRIM(CONCAT(u.first_name, ' ', u.last_name)), ''), 'Unknown')               AS intern_name,
	COALESCE(u.avatar_url, '')                                                                   AS avatar_url,
	CAST(? AS TEXT)                                                                              AS date,
	TO_CHAR(a.time_in::timestamptz  AT TIME ZONE 'Asia/Manila', 'HH12:MI AM')                  AS time_in,
	TO_CHAR(a.time_out::timestamptz AT TIME ZONE 'Asia/Manila', 'HH12:MI AM')                  AS time_out,
	a.hours_rendered
`

const internSelectAllDates = `
	a.id                                                                                         AS id,
	a.user_id                                                                                    AS user_id,
	COALESCE(NULLIF(TRIM(CONCAT(u.first_name, ' ', u.last_name)), ''), 'Unknown')               AS intern_name,
	COALESCE(u.avatar_url, '')                                                                   AS avatar_url,
	TO_CHAR(a.date::date, 'YYYY-MM-DD')                                                         AS date,
	TO_CHAR(a.time_in::timestamptz  AT TIME ZONE 'Asia/Manila', 'HH12:MI AM')                  AS time_in,
	TO_CHAR(a.time_out::timestamptz AT TIME ZONE 'Asia/Manila', 'HH12:MI AM')                  AS time_out,
	a.hours_rendered
`

// ── GET /api/admin/attendance ─────────────────────────────────────────────────
//
// Query params:
//   date        – YYYY-MM-DD; default = today (Manila)
//   all_dates   – "true" to skip the date filter
//   page        – 1-based; default = 1
//   limit       – rows per page 1-100; default = 20
//   user_id     – (optional) filter to one intern

func (h *Handler) AdminGetAttendance(c *gin.Context) {
	dateStr := c.DefaultQuery("date", time.Now().In(manilaLoc()).Format("2006-01-02"))
	allDates := c.DefaultQuery("all_dates", "false") == "true"
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	filterUID := c.DefaultQuery("user_id", "")

	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}
	offset := (page - 1) * limit

	var rows []attendanceRaw
	var total int64

	if !allDates {
		q := h.DB.Table("users u").
			Select(internSelectSingleDate, dateStr).
			Joins(`LEFT JOIN attendance a ON a.user_id = u.id AND a.date = ?`, dateStr).
			Where("u.deleted_at IS NULL").
			Where("u.is_archived = ?", false).
			Where("u.role = ?", "user").
			Where("u.position = ?", "Intern")

		if filterUID != "" {
			q = q.Where("u.id = ?", filterUID)
		}

		q.Count(&total)
		q.Order("intern_name ASC").Limit(limit).Offset(offset).Scan(&rows)

	} else {
		q := h.DB.Table("attendance a").
			Select(internSelectAllDates).
			Joins(`LEFT JOIN users u ON u.id = a.user_id`)

		if filterUID != "" {
			q = q.Where("a.user_id = ?", filterUID)
		}

		q.Count(&total)
		q.Order("a.date DESC, intern_name ASC").Limit(limit).Offset(offset).Scan(&rows)
	}

	c.JSON(http.StatusOK, gin.H{
		"ok":      true,
		"records": toResponseRows(rows),
		"total":   total,
		"page":    page,
		"limit":   limit,
	})
}

// ── GET /api/admin/attendance/export ─────────────────────────────────────────

func (h *Handler) AdminExportAttendance(c *gin.Context) {
	dateStr := c.DefaultQuery("date", time.Now().In(manilaLoc()).Format("2006-01-02"))
	allDates := c.DefaultQuery("all_dates", "false") == "true"

	const exportSelectSingleDate = `
		COALESCE(NULLIF(TRIM(CONCAT(u.first_name, ' ', u.last_name)), ''), 'Unknown')               AS intern_name,
		CAST(? AS TEXT)                                                                              AS date,
		TO_CHAR(a.time_in::timestamptz  AT TIME ZONE 'Asia/Manila', 'HH12:MI AM')                  AS time_in,
		TO_CHAR(a.time_out::timestamptz AT TIME ZONE 'Asia/Manila', 'HH12:MI AM')                  AS time_out,
		a.hours_rendered
	`
	const exportSelectAllDates = `
		COALESCE(NULLIF(TRIM(CONCAT(u.first_name, ' ', u.last_name)), ''), 'Unknown')               AS intern_name,
		TO_CHAR(a.date::date, 'YYYY-MM-DD')                                                         AS date,
		TO_CHAR(a.time_in::timestamptz  AT TIME ZONE 'Asia/Manila', 'HH12:MI AM')                  AS time_in,
		TO_CHAR(a.time_out::timestamptz AT TIME ZONE 'Asia/Manila', 'HH12:MI AM')                  AS time_out,
		a.hours_rendered
	`

	var rows []attendanceRaw

	if !allDates {
		h.DB.Table("users u").
			Select(exportSelectSingleDate, dateStr).
			Joins(`LEFT JOIN attendance a ON a.user_id = u.id AND a.date = ?`, dateStr).
			Where("u.deleted_at IS NULL").
			Where("u.is_archived = ?", false).
			Where("u.role = ?", "user").
			Where("u.position = ?", "Intern").
			Order("intern_name ASC").
			Scan(&rows)
	} else {
		h.DB.Table("attendance a").
			Select(exportSelectAllDates).
			Joins(`LEFT JOIN users u ON u.id = a.user_id`).
			Order("a.date DESC, intern_name ASC").
			Scan(&rows)
	}

	filename := fmt.Sprintf("attendance_%s.csv", dateStr)
	c.Header("Content-Disposition", "attachment; filename="+filename)
	c.Header("Content-Type", "text/csv")

	w := csv.NewWriter(c.Writer)
	_ = w.Write([]string{"Intern", "Date", "Time In", "Time Out", "Hours Rendered", "Status"})

	for _, r := range rows {
		timeIn := "--:--"
		timeOut := "--:--"
		hours := "0h 0m"
		if r.TimeIn != nil {
			timeIn = *r.TimeIn
		}
		if r.TimeOut != nil {
			timeOut = *r.TimeOut
		}
		if r.HoursRendered != nil {
			h := int(*r.HoursRendered)
			m := int((*r.HoursRendered - float64(h)) * 60)
			hours = fmt.Sprintf("%dh %dm", h, m)
		}
		_ = w.Write([]string{
			r.InternName,
			r.Date,
			timeIn,
			timeOut,
			hours,
			deriveStatus(r.TimeIn, r.TimeOut, r.Date),
		})
	}
	w.Flush()
}
