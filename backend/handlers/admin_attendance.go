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

// AdminAttendanceRow is the flattened row returned to the Flutter client.
type AdminAttendanceRow struct {
	ID            uint     `json:"id"`
	UserID        uint     `json:"user_id"`
	InternName    string   `json:"intern_name"`
	AvatarURL     string   `json:"avatar_url"`
	Date          string   `json:"date"`           // "YYYY-MM-DD"
	TimeIn        *string  `json:"time_in"`        // nullable RFC3339
	TimeOut       *string  `json:"time_out"`       // nullable RFC3339
	HoursRendered *float64 `json:"hours_rendered"` // nullable
	Status        string   `json:"status"`         // Present | Late | Absent | In Progress
}

// ── Status logic ──────────────────────────────────────────────────────────────

const lateThresholdHour = 8 // 08:00 local time is the cutoff
const lateThresholdMin = 0

func deriveStatus(timeIn *string, timeOut *string) string {
	if timeIn == nil {
		return "Absent"
	}
	if timeOut == nil {
		return "In Progress"
	}
	// Parse time-in to check lateness
	t, err := time.Parse(time.RFC3339Nano, *timeIn)
	if err != nil {
		// Fallback: assume present
		return "Present"
	}
	local := t.Local()
	if local.Hour() > lateThresholdHour ||
		(local.Hour() == lateThresholdHour && local.Minute() > lateThresholdMin) {
		return "Late"
	}
	return "Present"
}

// ── GET /api/admin/attendance ─────────────────────────────────────────────────
//
// Query params:
//   date        – filter by exact date (YYYY-MM-DD); default = today
//   page        – 1-based page number; default = 1
//   limit       – rows per page (1-100); default = 20
//   user_id     – (optional) filter to a single intern
//   all_dates   – "true" to skip the date filter entirely

func (h *Handler) AdminGetAttendance(c *gin.Context) {
	// ── Parse query params ────────────────────────────────────────────────────
	dateStr := c.DefaultQuery("date", time.Now().Format("2006-01-02"))
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

	// ── Build query ───────────────────────────────────────────────────────────
	//
	// We LEFT JOIN users so that rows whose user was deleted still appear.
	// Columns assumed in your schema:
	//   attendance: id, user_id, date, time_in, time_out, hours_rendered
	//   users:      id, name (or first_name+last_name), avatar_url
	//
	// Adjust the SELECT list to match your actual users table columns.

	type rawRow struct {
		ID            uint     `gorm:"column:id"`
		UserID        uint     `gorm:"column:user_id"`
		InternName    string   `gorm:"column:intern_name"`
		AvatarURL     string   `gorm:"column:avatar_url"`
		Date          string   `gorm:"column:date"`
		TimeIn        *string  `gorm:"column:time_in"`
		TimeOut       *string  `gorm:"column:time_out"`
		HoursRendered *float64 `gorm:"column:hours_rendered"`
	}

	q := h.DB.Table("attendance a").
		Select(`
			a.id,
			a.user_id,
			COALESCE(u.name, CONCAT(u.first_name, ' ', u.last_name), 'Unknown') AS intern_name,
			COALESCE(u.avatar_url, '')                                           AS avatar_url,
			TO_CHAR(a.date, 'YYYY-MM-DD')                                        AS date,
			TO_CHAR(a.time_in  AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Manila', 'HH12:MI AM') AS time_in,
			TO_CHAR(a.time_out AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Manila', 'HH12:MI AM') AS time_out,
			a.hours_rendered
		`).
		Joins("LEFT JOIN users u ON u.id = a.user_id")

	if !allDates {
		q = q.Where("a.date = ?", dateStr)
	}
	if filterUID != "" {
		q = q.Where("a.user_id = ?", filterUID)
	}

	var total int64
	q.Count(&total)

	var rows []rawRow
	q.Order("a.date DESC, a.time_in ASC").
		Limit(limit).
		Offset(offset).
		Scan(&rows)

	// ── Enrich with derived status ────────────────────────────────────────────
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
			Status:        deriveStatus(r.TimeIn, r.TimeOut),
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"ok":      true,
		"records": out,
		"total":   total,
		"page":    page,
		"limit":   limit,
	})
}

// ── GET /api/admin/attendance/export ─────────────────────────────────────────
//
// Same filters as above but streams a CSV response for download.

func (h *Handler) AdminExportAttendance(c *gin.Context) {
	dateStr := c.DefaultQuery("date", time.Now().Format("2006-01-02"))
	allDates := c.DefaultQuery("all_dates", "false") == "true"

	type rawRow struct {
		InternName    string   `gorm:"column:intern_name"`
		Date          string   `gorm:"column:date"`
		TimeIn        *string  `gorm:"column:time_in"`
		TimeOut       *string  `gorm:"column:time_out"`
		HoursRendered *float64 `gorm:"column:hours_rendered"`
	}

	q := h.DB.Table("attendance a").
		Select(`
			COALESCE(u.name, CONCAT(u.first_name, ' ', u.last_name), 'Unknown') AS intern_name,
			TO_CHAR(a.date, 'YYYY-MM-DD')                                        AS date,
			TO_CHAR(a.time_in  AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Manila', 'HH12:MI AM') AS time_in,
			TO_CHAR(a.time_out AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Manila', 'HH12:MI AM') AS time_out,
			a.hours_rendered
		`).
		Joins("LEFT JOIN users u ON u.id = a.user_id").
		Order("a.date DESC, intern_name ASC")

	if !allDates {
		q = q.Where("a.date = ?", dateStr)
	}

	var rows []rawRow
	q.Scan(&rows)

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
			deriveStatus(r.TimeIn, r.TimeOut),
		})
	}
	w.Flush()
}
