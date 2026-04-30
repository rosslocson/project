// backend/handlers/attendance.go

package handlers

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"project/backend/models"
)

// ── helpers ──────────────────────────────────────────────────────────────────

// todayDate returns midnight UTC of today.
func todayDate() time.Time {
	now := time.Now()
	return time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
}

// getUserIDFromCtx reads the user_id injected by JWTAuth middleware.
func getUserIDFromCtx(c *gin.Context) (uint, bool) {
	raw, exists := c.Get("user_id")
	if !exists {
		return 0, false
	}
	switch v := raw.(type) {
	case uint:
		return v, true
	case float64:
		return uint(v), true
	case int:
		return uint(v), true
	case string:
		id, err := strconv.ParseUint(v, 10, 64)
		if err != nil {
			return 0, false
		}
		return uint(id), true
	}
	return 0, false
}

// refreshAttendance re-fetches the record so the computed hours_rendered column is included.
func (h *Handler) refreshAttendance(id uint) (*models.Attendance, error) {
	var rec models.Attendance
	err := h.DB.
		Select("id, user_id, date, time_in, time_out, hours_rendered, created_at, updated_at").
		First(&rec, id).Error
	return &rec, err
}

// ── POST /api/attendance/time-in ─────────────────────────────────────────────

func (h *Handler) TimeIn(c *gin.Context) {
	userID, ok := getUserIDFromCtx(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"ok": false, "error": "Unauthorized"})
		return
	}

	today := todayDate()
	now := time.Now().UTC()

	rec := models.Attendance{
		UserID: userID,
		Date:   today,
		TimeIn: &now,
	}

	result := h.DB.
		Where(models.Attendance{UserID: userID, Date: today}).
		Attrs(models.Attendance{TimeIn: &now}).
		FirstOrCreate(&rec)

	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"ok": false, "error": result.Error.Error()})
		return
	}

	if result.RowsAffected == 0 {
		c.JSON(http.StatusConflict, gin.H{"ok": false, "error": "Already timed in today"})
		return
	}

	fresh, err := h.refreshAttendance(rec.ID)
	if err != nil {
		c.JSON(http.StatusOK, gin.H{"ok": true, "record": rec})
		return
	}
	c.JSON(http.StatusOK, gin.H{"ok": true, "record": fresh})
}

// ── PATCH /api/attendance/time-out ───────────────────────────────────────────

func (h *Handler) TimeOut(c *gin.Context) {
	userID, ok := getUserIDFromCtx(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"ok": false, "error": "Unauthorized"})
		return
	}

	today := todayDate()
	now := time.Now().UTC()

	var rec models.Attendance
	err := h.DB.
		Where("user_id = ? AND date = ? AND time_in IS NOT NULL AND time_out IS NULL", userID, today).
		First(&rec).Error

	if err == gorm.ErrRecordNotFound {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "No active time-in found for today"})
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"ok": false, "error": err.Error()})
		return
	}

	if err := h.DB.Model(&rec).Update("time_out", now).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"ok": false, "error": err.Error()})
		return
	}

	fresh, err := h.refreshAttendance(rec.ID)
	if err != nil {
		c.JSON(http.StatusOK, gin.H{"ok": true, "record": rec})
		return
	}
	c.JSON(http.StatusOK, gin.H{"ok": true, "record": fresh})
}

// ── GET /api/attendance/summary ──────────────────────────────────────────────

func (h *Handler) GetAttendanceSummary(c *gin.Context) {
	userID, ok := getUserIDFromCtx(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"ok": false, "error": "Unauthorized"})
		return
	}

	var user models.User
	h.DB.Select("required_ojt_hours").First(&user, userID)
	requiredHours := 486.0
	if user.RequiredOjtHours > 0 {
		requiredHours = float64(user.RequiredOjtHours)
	}

	type Summary struct {
		TotalHours float64 `gorm:"column:total_hours"`
		TotalDays  int     `gorm:"column:total_days"`
	}
	var summary Summary
	h.DB.Raw(`
		SELECT
			COALESCE(SUM(hours_rendered), 0)                              AS total_hours,
			COUNT(*) FILTER (WHERE hours_rendered IS NOT NULL)            AS total_days
		FROM attendance
		WHERE user_id = ?
	`, userID).Scan(&summary)

	today := todayDate()
	var todayRec *models.Attendance
	var t models.Attendance
	err := h.DB.
		Select("id, user_id, date, time_in, time_out, hours_rendered, created_at, updated_at").
		Where("user_id = ? AND date = ?", userID, today).
		First(&t).Error
	if err == nil {
		todayRec = &t
	}

	c.JSON(http.StatusOK, gin.H{
		"ok":                   true,
		"total_hours_rendered": summary.TotalHours,
		"required_hours":       requiredHours,
		"total_days":           summary.TotalDays,
		"today":                todayRec,
	})
}

// ── GET /api/attendance/history ───────────────────────────────────────────────

func (h *Handler) GetAttendanceHistory(c *gin.Context) {
	userID, ok := getUserIDFromCtx(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"ok": false, "error": "Unauthorized"})
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}
	offset := (page - 1) * limit

	var records []models.Attendance
	var total int64

	h.DB.Model(&models.Attendance{}).Where("user_id = ?", userID).Count(&total)

	h.DB.
		Select("id, user_id, date, time_in, time_out, hours_rendered, created_at, updated_at").
		Where("user_id = ?", userID).
		Order("date DESC").
		Limit(limit).
		Offset(offset).
		Find(&records)

	c.JSON(http.StatusOK, gin.H{
		"ok":      true,
		"records": records,
		"total":   total,
		"page":    page,
		"limit":   limit,
	})
}

// ── GET /api/admin/attendance ─────────────────────────────────────────────────
//
// Query params:
//   page        int     (default 1)
//   limit       int     (default 20, max 100)
//   date        string  "YYYY-MM-DD"   — exact date filter (ignored when period set)
//   all_dates   bool    "true"         — skip date filtering entirely
//   period      string  "today" | "week" | "month" | "year"
//   search      string  — partial match on intern full name (ILIKE)
//   status      string  "Present" | "Late" | "On Shift" | "Missed Clock Out" | "Absent"
//   user_id     int     — filter to a single intern

func (h *Handler) GetAdminAttendance(c *gin.Context) {
	// ── pagination ──────────────────────────────────────────────────────────
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}
	offset := (page - 1) * limit

	// ── date / period range ─────────────────────────────────────────────────
	allDates := c.Query("all_dates") == "true"
	period := c.Query("period") // "today" | "week" | "month" | "year"
	dateStr := c.Query("date")  // "YYYY-MM-DD"

	now := time.Now().UTC()
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)

	var rangeStart, rangeEnd time.Time
	useRange := false

	if !allDates {
		switch period {
		case "today":
			rangeStart = today
			rangeEnd = today.AddDate(0, 0, 1)
			useRange = true
		case "week":
			// Monday of current ISO week
			weekday := int(now.Weekday())
			if weekday == 0 {
				weekday = 7 // Sunday → 7
			}
			rangeStart = today.AddDate(0, 0, -(weekday - 1))
			rangeEnd = rangeStart.AddDate(0, 0, 7)
			useRange = true
		case "month":
			rangeStart = time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.UTC)
			rangeEnd = rangeStart.AddDate(0, 1, 0)
			useRange = true
		case "year":
			rangeStart = time.Date(now.Year(), 1, 1, 0, 0, 0, 0, time.UTC)
			rangeEnd = rangeStart.AddDate(1, 0, 0)
			useRange = true
		default:
			// Fall back to exact date if provided
			if dateStr != "" {
				parsed, err := time.Parse("2006-01-02", dateStr)
				if err == nil {
					rangeStart = parsed
					rangeEnd = parsed.AddDate(0, 0, 1)
					useRange = true
				}
			}
		}
	}

	// ── optional filters ────────────────────────────────────────────────────
	search := c.Query("search") // intern name partial match
	status := c.Query("status") // exact status value
	userIDStr := c.Query("user_id")

	// ── base query joining users for intern name & avatar ───────────────────
	//
	// Assumes the admin attendance view / query returns intern_name, avatar_url,
	// and status (computed or stored). Adjust the JOIN / column names to your
	// actual schema.  The query below uses a LEFT JOIN on users and derives
	// status from the attendance columns — adapt as needed.
	//
	// status derivation (PostgreSQL):
	//   'On Shift'    — time_in set, time_out NULL, date = today
	//   'Missed Clock Out' — time_in set, time_out NULL, date < today
	//   'Present'        — time_out set, time_in before 09:00
	//   'Late'           — time_out set, time_in at/after 09:00
	//   'Absent'         — no record (handled at application level or via generated series)

	type AdminRow struct {
		ID            int      `gorm:"column:id"             json:"id"`
		UserID        int      `gorm:"column:user_id"        json:"user_id"`
		InternName    string   `gorm:"column:intern_name"    json:"intern_name"`
		AvatarURL     string   `gorm:"column:avatar_url"     json:"avatar_url"`
		Date          string   `gorm:"column:date"           json:"date"`
		TimeIn        *string  `gorm:"column:time_in"        json:"time_in"`
		TimeOut       *string  `gorm:"column:time_out"       json:"time_out"`
		HoursRendered *float64 `gorm:"column:hours_rendered" json:"hours_rendered"`
		Status        string   `gorm:"column:status"         json:"status"`
	}

	baseSQL := `
		SELECT
			a.id,
			a.user_id,
			CONCAT(u.first_name, ' ', u.last_name)   AS intern_name,
			COALESCE(u.avatar_url, '')                AS avatar_url,
			TO_CHAR(a.date, 'YYYY-MM-DD')            AS date,
			TO_CHAR(a.time_in,  'HH12:MI AM')        AS time_in,
			TO_CHAR(a.time_out, 'HH12:MI AM')        AS time_out,
			a.hours_rendered,
			CASE
				WHEN a.time_in IS NOT NULL AND a.time_out IS NULL AND a.date = CURRENT_DATE
					THEN 'On Shift'
				WHEN a.time_in IS NOT NULL AND a.time_out IS NULL AND a.date < CURRENT_DATE
					THEN 'Missed Clock Out'
				WHEN a.time_out IS NOT NULL AND EXTRACT(HOUR FROM a.time_in) < 9
					THEN 'Present'
				WHEN a.time_out IS NOT NULL AND EXTRACT(HOUR FROM a.time_in) >= 9
					THEN 'Late'
				ELSE 'Absent'
			END AS status
		FROM attendance a
		LEFT JOIN users u ON u.id = a.user_id
		WHERE 1=1
	`

	args := []interface{}{}

	// Date/period range
	if useRange {
		baseSQL += " AND a.date >= ? AND a.date < ?"
		args = append(args, rangeStart, rangeEnd)
	}

	// Name search
	if search != "" {
		baseSQL += " AND CONCAT(u.first_name, ' ', u.last_name) ILIKE ?"
		args = append(args, "%"+search+"%")
	}

	// Status filter (applied as a subquery wrapper so the CASE alias is visible)
	statusClause := ""
	if status != "" {
		statusClause = " AND status = ?"
		args = append(args, status)
	}

	// Single user filter
	if userIDStr != "" {
		uid, err := strconv.Atoi(userIDStr)
		if err == nil {
			baseSQL += " AND a.user_id = ?"
			args = append(args, uid)
		}
	}

	// Wrap in a subquery so we can filter on the computed "status" alias
	wrappedSQL := "SELECT * FROM (" + baseSQL + ") sub WHERE 1=1" + statusClause

	// Count
	countSQL := "SELECT COUNT(*) FROM (" + wrappedSQL + ") counted"
	var total int64
	h.DB.Raw(countSQL, args...).Scan(&total)

	// Paginated fetch
	finalSQL := wrappedSQL + " ORDER BY date DESC LIMIT ? OFFSET ?"
	pageArgs := append(args, limit, offset)

	var rows []AdminRow
	h.DB.Raw(finalSQL, pageArgs...).Scan(&rows)

	c.JSON(http.StatusOK, gin.H{
		"ok":      true,
		"records": rows,
		"total":   total,
		"page":    page,
		"limit":   limit,
	})
}

// ── GET /api/admin/attendance/export ─────────────────────────────────────────
// Same filters as GetAdminAttendance; returns CSV.
// (Implementation left to your CSV helper — just reuse the same query above.)

// ── Suppress unused import warning for clause ─────────────────────────────────
var _ = clause.OnConflict{}
