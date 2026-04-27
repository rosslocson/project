package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"project/backend/models"
)

func (h *Handler) AdminDashboard(c *gin.Context) {
	// 1. Extract Pagination Parameters from Flutter request
	// Default to Page 1 and Limit 5 if not provided
	pageStr := c.DefaultQuery("page", "1")
	limitStr := c.DefaultQuery("limit", "5")

	page, _ := strconv.Atoi(pageStr)
	limit, _ := strconv.Atoi(limitStr)
	if page < 1 {
		page = 1
	}

	// Calculate offset for PostgreSQL (e.g., Page 2 starts after skipping the first 5)
	offset := (page - 1) * limit

	// 2. Fetch General Stats (Total Counts)
	var totalUsers, activeUsers, adminUsers, newUsers int64
	h.DB.Model(&models.User{}).Count(&totalUsers)
	h.DB.Model(&models.User{}).Where("status = ?", "active").Count(&activeUsers)
	h.DB.Model(&models.User{}).Where("role = ?", "admin").Count(&adminUsers)
	h.DB.Model(&models.User{}).Where("status = ?", "inactive").Count(&newUsers)

	// 3. Fetch Paginated Recent Users
	var recentUsers []models.User
	h.DB.Order("created_at desc").Limit(limit).Offset(offset).Find(&recentUsers)

	// 4. Calculate Total Pages for the frontend dots/buttons
	totalPages := (totalUsers + int64(limit) - 1) / int64(limit)

	// 5. Send Clean JSON to Flutter
	c.JSON(http.StatusOK, gin.H{
		"ok":           true,
		"total_users":  totalUsers,
		"active_users": activeUsers,
		"admin_users":  adminUsers,
		"new_users":    newUsers,
		"recent_users": recentUsers, // This only contains the 5 for this page
		"total_pages":  totalPages,
		"current_page": page,
	})
}