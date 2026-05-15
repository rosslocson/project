package handlers

import (
	"net/http"
	"strconv"
	"time"

	"project/backend/models"

	"github.com/gin-gonic/gin"
)

func (h *Handler) AdminDashboard(c *gin.Context) {
	pageStr := c.DefaultQuery("page", "1")
	limitStr := c.DefaultQuery("limit", "5")

	page, _ := strconv.Atoi(pageStr)
	limit, _ := strconv.Atoi(limitStr)
	if page < 1 {
		page = 1
	}
	offset := (page - 1) * limit

	// ── Intern counts ─────────────────────────────────────────────────────
	var totalInterns int64
	h.DB.Model(&models.User{}).
		Where("role = ? AND is_archived = ?", models.RoleUser, false).
		Count(&totalInterns)

	// ── Today's attendance stats ──────────────────────────────────────────
	today := time.Now().Format("2006-01-02")

	// Present: clocked in at or before 8:15 AM today
	var presentCount int64
	h.DB.Model(&models.Attendance{}).
		Where("date = ? AND time_in IS NOT NULL AND EXTRACT(HOUR FROM time_in AT TIME ZONE 'Asia/Manila') * 60 + EXTRACT(MINUTE FROM time_in AT TIME ZONE 'Asia/Manila') <= 495", today).
		Count(&presentCount)

	// Late: clocked in after 8:15 AM today (8:16 AM onwards)
	var lateCount int64
	h.DB.Model(&models.Attendance{}).
		Where("date = ? AND time_in IS NOT NULL AND EXTRACT(HOUR FROM time_in AT TIME ZONE 'Asia/Manila') * 60 + EXTRACT(MINUTE FROM time_in AT TIME ZONE 'Asia/Manila') > 495", today).
		Count(&lateCount)

	// Absent: total interns minus those who clocked in at all today
	var clockedInToday int64
	h.DB.Model(&models.Attendance{}).
		Where("date = ? AND time_in IS NOT NULL", today).
		Count(&clockedInToday)
	absentCount := totalInterns - clockedInToday

	// ── Paginated recent users ────────────────────────────────────────────
	var recentUsers []models.User
	h.DB.Order("created_at desc").Limit(limit).Offset(offset).Find(&recentUsers)

	totalPages := (totalInterns + int64(limit) - 1) / int64(limit)

	c.JSON(http.StatusOK, gin.H{
		"ok":            true,
		"total_interns": totalInterns,
		"present_count": presentCount,
		"absent_count":  absentCount,
		"late_count":    lateCount,
		"recent_users":  recentUsers,
		"total_pages":   totalPages,
		"current_page":  page,
	})
}
