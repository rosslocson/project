package handlers

import (
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"

	"project/backend/email"
	"project/backend/models"
	"project/backend/repositories"
	"project/backend/services"
)

type RegisterRequest struct {
	FirstName        string `json:"first_name"`
	LastName         string `json:"last_name"`
	Email            string `json:"email"`
	Password         string `json:"password"`
	ConfirmPassword  string `json:"confirm_password"`
	Phone            string `json:"phone"`
	Department       string `json:"department"`
	Position         string `json:"position"`
	RequiredOjtHours int    `json:"required_ojt_hours"`
}

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type ForgotPasswordRequest struct {
	Email string `json:"email"`
}

type VerifyResetOTPRequest struct {
	OTP string `json:"otp"`
}

type ResetPasswordRequest struct {
	OTP             string `json:"otp"`
	NewPassword     string `json:"new_password"`
	ConfirmPassword string `json:"confirm_password"`
}

func (h *Handler) Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": err.Error()})
		return
	}

	if req.Password != req.ConfirmPassword {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "Passwords do not match"})
		return
	}

	if err := services.ValidateEmailFormat(strings.TrimSpace(req.Email)); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": err.Error()})
		return
	}

	if err := services.ValidatePasswordStrength(req.Password); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": err.Error()})
		return
	}

	enforcedPosition := "Intern"
	userRepo := repositories.NewUserRepository(h.DB)
	authService := services.NewAuthService(userRepo)

	ojtHours := req.RequiredOjtHours
	if ojtHours <= 0 {
		ojtHours = 400
	}

	user, token, err := authService.Register(
		req.FirstName, req.LastName, strings.TrimSpace(req.Email), req.Password,
		req.Phone, req.Department, enforcedPosition, models.RoleUser, ojtHours,
	)
	if err != nil {
		if strings.Contains(err.Error(), "admin role") {
			c.JSON(http.StatusForbidden, gin.H{"ok": false, "error": err.Error()})
		} else if strings.Contains(err.Error(), "email already") {
			c.JSON(http.StatusConflict, gin.H{"ok": false, "error": err.Error()})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"ok": false, "error": err.Error()})
		}
		return
	}

	h.logActivity(user.ID, "REGISTER", "New user registered", c.ClientIP())
	c.JSON(http.StatusCreated, gin.H{"ok": true, "message": "Registration successful", "token": token, "user": user})
}

func (h *Handler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": err.Error()})
		return
	}

	userRepo := repositories.NewUserRepository(h.DB)
	authService := services.NewAuthService(userRepo)

	// Fetch IP Address to securely track attempts over the network layer
	ip := c.ClientIP()
	result, err := authService.Login(strings.TrimSpace(req.Email), req.Password, ip)

	if err != nil {
		if result != nil && result.IsLocked {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"ok":               false,
				"error":            "Account temporarily locked",
				"locked":           true,
				"retry_after_secs": result.RetryAfterSecs,
				"attempts_left":    0,
			})
			return
		}

		attemptsLeft := 0
		if result != nil {
			attemptsLeft = result.AttemptsLeft
		}

		c.JSON(http.StatusUnauthorized, gin.H{
			"ok":            false,
			"error":         err.Error(),
			"attempts_left": attemptsLeft,
		})
		return
	}

	fullUser, err := userRepo.GetByID(result.User.ID)
	if err != nil {
		fullUser = result.User
	}

	h.logActivity(result.User.ID, "LOGIN", "User logged in", c.ClientIP())
	c.JSON(http.StatusOK, gin.H{
		"ok":      true,
		"message": "Login successful",
		"token":   result.Token,
		"user":    fullUser,
	})
}

func (h *Handler) ForgotPassword(c *gin.Context) {
	var req ForgotPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": err.Error()})
		return
	}

	recipientEmail := strings.ToLower(strings.TrimSpace(req.Email))

	var user models.User
	// Select only OTP columns to avoid scanning legacy start_date/end_date.
	if err := h.DB.Select("id", "email", "reset_token", "reset_token_expiry").
		Where("email = ?", recipientEmail).
		First(&user).Error; err != nil {
		c.JSON(http.StatusOK, gin.H{"ok": true, "message": "If the email exists, an OTP was sent."})
		return
	}

	otp, err := services.GenerateOTP()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"ok": false, "error": "Could not generate OTP"})
		return
	}

	expiry := time.Now().Add(2 * time.Minute)
	user.ResetOTP = otp
	user.ResetOTPExpiry = &expiry

	// Persist only the reset token columns to avoid any field/column mapping surprises.
	if err := h.DB.Model(&user).Select("reset_token", "reset_token_expiry").Updates(map[string]interface{}{
		"reset_token":        user.ResetOTP,
		"reset_token_expiry": user.ResetOTPExpiry,
	}).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"ok": false, "error": "Could not save OTP"})
		return
	}

	if err := email.SendPasswordResetEmail(user.Email, otp); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"ok": false, "error": "Could not send OTP email"})
		return
	}

	expiresInSecs := int(time.Until(expiry).Seconds())
	if expiresInSecs < 0 {
		expiresInSecs = 0
	}

	c.JSON(http.StatusOK, gin.H{
		"ok":              true,
		"message":         "Step 2 of 2 — Verify OTP & set password",
		"expires_in_secs": expiresInSecs,
	})
}

func (h *Handler) VerifyResetOTP(c *gin.Context) {
	var req VerifyResetOTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": err.Error()})
		return
	}

	var user models.User
	// Select only reset-token columns to avoid scanning legacy start_date/end_date.
	if err := h.DB.Select("id", "reset_token", "reset_token_expiry").
		Where("reset_token = ?", strings.TrimSpace(req.OTP)).
		First(&user).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "Invalid or expired OTP"})
		return
	}

	if user.ResetOTPExpiry == nil || user.ResetOTPExpiry.Before(time.Now()) {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "OTP has expired"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"ok": true, "message": "OTP verified"})
}

func (h *Handler) ResetPassword(c *gin.Context) {
	var req ResetPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": err.Error()})
		return
	}

	if req.NewPassword != req.ConfirmPassword {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "Passwords do not match"})
		return
	}

	if err := services.ValidatePasswordStrength(req.NewPassword); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": err.Error()})
		return
	}

	var user models.User
	// Select only reset-token columns to avoid scanning legacy start_date/end_date.
	if err := h.DB.Select("id", "reset_token", "reset_token_expiry").
		Where("reset_token = ?", strings.TrimSpace(req.OTP)).
		First(&user).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "Invalid or expired OTP"})
		return
	}

	if user.ResetOTPExpiry == nil || user.ResetOTPExpiry.Before(time.Now()) {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "OTP has expired"})
		return
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"ok": false, "error": "Failed to encrypt password"})
		return
	}
	user.Password = string(hashedPassword)

	user.ResetOTP = ""
	user.ResetOTPExpiry = nil
	user.FailedAttempts = 0
	user.LockedUntil = nil

	h.DB.Save(&user)

	c.JSON(http.StatusOK, gin.H{"ok": true, "message": "Password reset successful"})
}
