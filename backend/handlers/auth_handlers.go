package handlers

import (
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"

	"project/backend/models"
	"project/backend/repositories"
	"project/backend/services"
)

// ── Request Structs ────────────────────────────────────────────────────────

type RegisterRequest struct {
	FirstName       string `json:"first_name"`
	LastName        string `json:"last_name"`
	Email           string `json:"email"`
	Password        string `json:"password"`
	ConfirmPassword string `json:"confirm_password"`
	Phone           string `json:"phone"`
	Department      string `json:"department"`
	Position        string `json:"position"`
}

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type ForgotPasswordRequest struct {
	Email string `json:"email"`
}

type ResetPasswordRequest struct {
	OTP             string `json:"otp"`
	NewPassword     string `json:"new_password"`
	ConfirmPassword string `json:"confirm_password"`
}

// ── Registration & Login Endpoints ─────────────────────────────────────────

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

	userRepo := repositories.NewUserRepository(h.DB)
	authService := services.NewAuthService(userRepo)

	user, token, err := authService.Register(
		req.FirstName, req.LastName, strings.TrimSpace(req.Email), req.Password,
		req.Phone, req.Department, req.Position, models.RoleUser,
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

	// The service handles all the lockout logic, attempts counting, and hashing checks
	result, err := authService.Login(strings.TrimSpace(req.Email), req.Password)
	if err != nil {
		if result.IsLocked {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"ok":               false,
				"error":            "Account temporarily locked",
				"locked":           true,
				"retry_after_secs": result.RetryAfterSecs,
				"attempts_left":    0,
			})
			return
		}
		c.JSON(http.StatusUnauthorized, gin.H{
			"ok":            false,
			"error":         result.Error.Error(),
			"attempts_left": result.AttemptsLeft,
		})
		return
	}

	// Re-fetch full user from DB — result.User only has auth fields,
	// not school/program/skills etc. This is why data was stale after re-login.
	fullUser, err := userRepo.GetByID(result.User.ID)
	if err != nil {
		fullUser = result.User // non-fatal fallback
	}

	h.logActivity(result.User.ID, "LOGIN", "User logged in", c.ClientIP())
	c.JSON(http.StatusOK, gin.H{
		"ok":      true,
		"message": "Login successful",
		"token":   result.Token,
		"user":    fullUser, // complete profile
	})
}

// ── 6-Digit OTP Endpoints ──────────────────────────────────────────────────

func (h *Handler) ForgotPassword(c *gin.Context) {
	var req ForgotPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": err.Error()})
		return
	}

	var user models.User
	if err := h.DB.Where("email = ?", strings.TrimSpace(req.Email)).First(&user).Error; err != nil {
		// Prevent email enumeration by returning a success message regardless
		c.JSON(http.StatusOK, gin.H{"ok": true, "message": "If the email exists, an OTP was sent."})
		return
	}

	otp, err := services.GenerateOTP()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"ok": false, "error": "Could not generate OTP"})
		return
	}

	expiry := time.Now().Add(15 * time.Minute)
	user.ResetOTP = otp
	user.ResetOTPExpiry = &expiry
	h.DB.Save(&user)

	// TODO: Call your email package here! e.g., email.SendResetOTP(user.Email, otp)

	c.JSON(http.StatusOK, gin.H{
		"ok":      true,
		"message": "Step 2 of 2 — Verify OTP & set password",
	})
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

	// 1. Enforce secure password
	if err := services.ValidatePasswordStrength(req.NewPassword); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": err.Error()})
		return
	}

	// 2. Find user by OTP
	var user models.User
	if err := h.DB.Where("reset_otp = ?", strings.TrimSpace(req.OTP)).First(&user).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "Invalid or expired OTP"})
		return
	}

	// 3. Check if OTP is expired
	if user.ResetOTPExpiry == nil || user.ResetOTPExpiry.Before(time.Now()) {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "OTP has expired"})
		return
	}

	// 4. Hash the new password securely
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"ok": false, "error": "Failed to encrypt password"})
		return
	}
	user.Password = string(hashedPassword)

	// 5. Clear the OTP fields and unlock the account
	user.ResetOTP = ""
	user.ResetOTPExpiry = nil
	user.FailedAttempts = 0
	user.LockedUntil = nil

	h.DB.Save(&user)

	c.JSON(http.StatusOK, gin.H{"ok": true, "message": "Password reset successful"})
}