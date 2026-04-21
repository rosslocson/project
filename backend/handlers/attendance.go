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

// todayUTC returns midnight of today in the server's local date (date-only).
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

// refreshHours re-fetches the record so the computed hours_rendered column is included.
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

	// Try to insert a new record; if one already exists for today, do nothing.
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

	// RowsAffected == 0 means the record already existed (already timed in today)
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

	// Find today's record that has time_in but no time_out yet
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

	// Update time_out
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

	// Get required hours from users table (default 486 if column missing)
	var user models.User
	h.DB.Select("required_ojt_hours").First(&user, userID)
	requiredHours := 486.0
	if user.RequiredOjtHours > 0 {
		requiredHours = float64(user.RequiredOjtHours)
	}

	// Aggregate total hours and days
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

	// Today's record
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
		"today":                todayRec, // nil if no record today
	})
}

// ── GET /api/attendance/history ───────────────────────────────────────────────

func (h *Handler) GetAttendanceHistory(c *gin.Context) {
	userID, ok := getUserIDFromCtx(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"ok": false, "error": "Unauthorized"})
		return
	}

	// Pagination
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

// ── Suppress unused import warning for clause (used if you switch to upsert) ─
var _ = clause.OnConflict{}
