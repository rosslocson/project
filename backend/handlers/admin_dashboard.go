package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"project/backend/models"
)

func (h *Handler) AdminDashboard(c *gin.Context) {
	// Admin-only stats example
	var totalUsers, adminCount int64
	h.DB.Model(&models.User{}).Count(&totalUsers)
	h.DB.Model(&models.User{}).Where("role = ?", models.RoleAdmin).Count(&adminCount)

	c.JSON(http.StatusOK, gin.H{
		"message":     "Admin dashboard",
		"total_users": totalUsers,
		"admin_count": adminCount,
	})
}
