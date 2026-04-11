package handlers

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"

	"project/backend/models"
	"project/backend/repositories"
	"project/backend/services"
)

func (h *Handler) Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Password != req.ConfirmPassword {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Passwords do not match"})
		return
	}

	userRepo := repositories.NewUserRepository(h.DB)
	authService := services.NewAuthService(userRepo)

	user, token, err := authService.Register(
		req.FirstName, req.LastName, req.Email, req.Password,
		req.Phone, req.Department, req.Position, models.RoleUser,
	)
	if err != nil {
		// Service returns specific errors
		if strings.Contains(err.Error(), "admin role") {
			c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
		} else if strings.Contains(err.Error(), "email already") {
			c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		}
		return
	}

	h.logActivity(user.ID, "REGISTER", "New user registered", c.ClientIP())
	c.JSON(http.StatusCreated, gin.H{"message": "Registration successful", "token": token, "user": user})
}

func (h *Handler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userRepo := repositories.NewUserRepository(h.DB)
	authService := services.NewAuthService(userRepo)

	user, token, err := authService.Login(req.Email, req.Password)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	h.logActivity(user.ID, "LOGIN", "User logged in", c.ClientIP())
	c.JSON(http.StatusOK, gin.H{"message": "Login successful", "token": token, "user": user})
}
