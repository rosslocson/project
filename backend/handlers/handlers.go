package handlers

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"
	"unicode"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"

	"project/backend/models"
)

// ── Constants ────────────────────────────────────────────────────────────────

const (
	maxLoginAttempts = 3
	lockDuration     = 1 * time.Minute
	resetTokenTTL    = 15 * time.Minute
)

// ── Handler struct ───────────────────────────────────────────────────────────

type Handler struct {
	DB *gorm.DB
}

func NewHandler(db *gorm.DB) *Handler {
	return &Handler{DB: db}
}

// ── Request/Response types ───────────────────────────────────────────────────

type RegisterRequest struct {
	FirstName       string `json:"first_name" binding:"required,min=2"`
	LastName        string `json:"last_name" binding:"required,min=2"`
	Email           string `json:"email" binding:"required,email"`
	Password        string `json:"password" binding:"required,min=8"`
	ConfirmPassword string `json:"confirm_password" binding:"required"`
	Phone           string `json:"phone"`
	Department      string `json:"department"`
	Position        string `json:"position"`
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

type ChangePasswordRequest struct {
	CurrentPassword string `json:"current_password" binding:"required"`
	NewPassword     string `json:"new_password" binding:"required,min=8"`
	ConfirmPassword string `json:"confirm_password" binding:"required"`
}

type UpdateProfileRequest struct {
	FirstName  string `json:"first_name"`
	LastName   string `json:"last_name"`
	Phone      string `json:"phone"`
	Department string `json:"department"`
	Position   string `json:"position"`
	Bio        string `json:"bio"`
}

type CreateUserRequest struct {
	FirstName  string      `json:"first_name" binding:"required"`
	LastName   string      `json:"last_name" binding:"required"`
	Email      string      `json:"email" binding:"required,email"`
	Password   string      `json:"password" binding:"required,min=8"`
	Phone      string      `json:"phone"`
	Department string      `json:"department"`
	Position   string      `json:"position"`
	Role       models.Role `json:"role"`
}

// ── Password validation ──────────────────────────────────────────────────────

func validatePassword(password string) []string {
	var errs []string
	if len(password) < 8 {
		errs = append(errs, "at least 8 characters")
	}
	var hasUpper, hasLower, hasDigit, hasSpecial bool
	for _, c := range password {
		switch {
		case unicode.IsUpper(c):
			hasUpper = true
		case unicode.IsLower(c):
			hasLower = true
		case unicode.IsDigit(c):
			hasDigit = true
		case unicode.IsPunct(c) || unicode.IsSymbol(c):
			hasSpecial = true
		}
	}
	if !hasUpper {
		errs = append(errs, "one uppercase letter")
	}
	if !hasLower {
		errs = append(errs, "one lowercase letter")
	}
	if !hasDigit {
		errs = append(errs, "one digit")
	}
	if !hasSpecial {
		errs = append(errs, "one special character")
	}
	return errs
}

// ── JWT helpers ──────────────────────────────────────────────────────────────

func generateToken(userID uint, role models.Role) (string, error) {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		secret = "your-super-secret-key-change-in-production"
	}
	claims := jwt.MapClaims{
		"user_id": userID,
		"role":    role,
		"exp":     time.Now().Add(24 * time.Hour).Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

// ── Random token generator ───────────────────────────────────────────────────

func generateResetToken() (string, error) {
	b := make([]byte, 16)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}

// ── Auth Handlers ────────────────────────────────────────────────────────────

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
	if errs := validatePassword(req.Password); len(errs) > 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Password too weak",
			"details": "Password must contain: " + strings.Join(errs, ", "),
		})
		return
	}

	var existing models.User
	if h.DB.Where("email = ?", req.Email).First(&existing).Error == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Email already registered"})
		return
	}

	hashed, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to process password"})
		return
	}

	user := models.User{
		FirstName:  req.FirstName,
		LastName:   req.LastName,
		Email:      strings.ToLower(req.Email),
		Password:   string(hashed),
		Phone:      req.Phone,
		Department: req.Department,
		Position:   req.Position,
		Role:       models.RoleUser,
		IsActive:   true,
	}
	if h.DB.Create(&user).Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
		return
	}

	h.logActivity(user.ID, "REGISTER", "New user registered", c.ClientIP())
	token, _ := generateToken(user.ID, user.Role)
	c.JSON(http.StatusCreated, gin.H{"message": "Registration successful", "token": token, "user": user})
}

func (h *Handler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var user models.User
	if h.DB.Where("email = ?", strings.ToLower(req.Email)).First(&user).Error != nil {
		// Don't reveal whether email exists
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid email or password"})
		return
	}

	if !user.IsActive {
		c.JSON(http.StatusForbidden, gin.H{"error": "Account is deactivated. Contact support."})
		return
	}

	// ── Check if account is currently locked ────────────────────────────────
	if user.LockedUntil != nil && time.Now().Before(*user.LockedUntil) {
		remaining := time.Until(*user.LockedUntil).Seconds()
		c.JSON(http.StatusTooManyRequests, gin.H{
			"error":            "Account temporarily locked due to too many failed attempts.",
			"locked":           true,
			"retry_after_secs": int(remaining) + 1,
		})
		return
	}

	// ── Wrong password ───────────────────────────────────────────────────────
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		newCount := user.FailedLoginCount + 1
		updates := map[string]interface{}{"failed_login_count": newCount}

		remaining := maxLoginAttempts - newCount

		if newCount >= maxLoginAttempts {
			lockedUntil := time.Now().Add(lockDuration)
			updates["locked_until"] = lockedUntil
			updates["failed_login_count"] = newCount
			h.DB.Model(&user).Updates(updates)
			h.logActivity(user.ID, "ACCOUNT_LOCKED", fmt.Sprintf("Account locked after %d failed attempts", newCount), c.ClientIP())
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error":            "Too many failed attempts. Account locked for 1 minute.",
				"locked":           true,
				"retry_after_secs": int(lockDuration.Seconds()),
			})
			return
		}

		h.DB.Model(&user).Updates(updates)
		h.logActivity(user.ID, "LOGIN_FAILED", fmt.Sprintf("Failed login attempt %d/%d", newCount, maxLoginAttempts), c.ClientIP())

		msg := fmt.Sprintf("Invalid email or password. %d attempt(s) remaining.", remaining)
		c.JSON(http.StatusUnauthorized, gin.H{
			"error":         msg,
			"attempts_left": remaining,
			"locked":        false,
		})
		return
	}

	// ── Successful login — reset counters ────────────────────────────────────
	now := time.Now()
	h.DB.Model(&user).Updates(map[string]interface{}{
		"failed_login_count": 0,
		"locked_until":       nil,
		"last_login_at":      now,
	})

	h.logActivity(user.ID, "LOGIN", "User logged in", c.ClientIP())
	token, _ := generateToken(user.ID, user.Role)
	c.JSON(http.StatusOK, gin.H{"message": "Login successful", "token": token, "user": user})
}

// ── Password Reset ───────────────────────────────────────────────────────────

func (h *Handler) ForgotPassword(c *gin.Context) {
	var body struct {
		Email string `json:"email" binding:"required,email"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Valid email required"})
		return
	}

	var user models.User
	if h.DB.Where("email = ?", strings.ToLower(body.Email)).First(&user).Error != nil {
		c.JSON(http.StatusOK, gin.H{"message": "If that email exists, a reset token has been sent."})
		return
	}

	token, err := generateResetToken()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not generate token"})
		return
	}

	expiry := time.Now().Add(resetTokenTTL)
	h.DB.Model(&user).Updates(map[string]interface{}{
		"reset_token":        token,
		"reset_token_expiry": expiry,
	})
	h.logActivity(user.ID, "PASSWORD_RESET_REQUEST", "Reset token generated", c.ClientIP())

	c.JSON(http.StatusOK, gin.H{
		"message":     "Reset token generated. In production this would be emailed.",
		"reset_token": token, // ← Remove this line in production
		"expires_in":  "15 minutes",
	})
}

func (h *Handler) ResetPassword(c *gin.Context) {
	var body struct {
		Token           string `json:"token" binding:"required"`
		NewPassword     string `json:"new_password" binding:"required,min=8"`
		ConfirmPassword string `json:"confirm_password" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if body.NewPassword != body.ConfirmPassword {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Passwords do not match"})
		return
	}
	if errs := validatePassword(body.NewPassword); len(errs) > 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Password too weak",
			"details": strings.Join(errs, ", "),
		})
		return
	}

	var user models.User
	if h.DB.Where("reset_token = ?", body.Token).First(&user).Error != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid or expired reset token"})
		return
	}
	if user.ResetTokenExpiry == nil || time.Now().After(*user.ResetTokenExpiry) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Reset token has expired. Please request a new one."})
		return
	}

	hashed, _ := bcrypt.GenerateFromPassword([]byte(body.NewPassword), bcrypt.DefaultCost)
	h.DB.Model(&user).Updates(map[string]interface{}{
		"password":           string(hashed),
		"reset_token":        "",
		"reset_token_expiry": nil,
		"failed_login_count": 0,
		"locked_until":       nil,
	})
	h.logActivity(user.ID, "PASSWORD_RESET", "Password reset successfully", c.ClientIP())
	c.JSON(http.StatusOK, gin.H{"message": "Password reset successfully. You can now log in.", "ok": true})
}

// ── Profile Handlers ─────────────────────────────────────────────────────────

func (h *Handler) GetProfile(c *gin.Context) {
	userID := c.GetUint("user_id")
	var user models.User
	h.DB.First(&user, userID)
	c.JSON(http.StatusOK, user)
}

func (h *Handler) UpdateProfile(c *gin.Context) {
	userID := c.GetUint("user_id")
	var req UpdateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	h.DB.Model(&models.User{}).Where("id = ?", userID).Updates(map[string]interface{}{
		"first_name": req.FirstName,
		"last_name":  req.LastName,
		"phone":      req.Phone,
		"department": req.Department,
		"position":   req.Position,
		"bio":        req.Bio,
	})
	h.logActivity(userID, "UPDATE_PROFILE", "Profile updated", c.ClientIP())
	var user models.User
	h.DB.First(&user, userID)
	c.JSON(http.StatusOK, gin.H{"message": "Profile updated", "user": user, "ok": true})
}

func (h *Handler) ChangePassword(c *gin.Context) {
	userID := c.GetUint("user_id")
	var req ChangePasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if req.NewPassword != req.ConfirmPassword {
		c.JSON(http.StatusBadRequest, gin.H{"error": "New passwords do not match"})
		return
	}
	if errs := validatePassword(req.NewPassword); len(errs) > 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Password too weak: " + strings.Join(errs, ", ")})
		return
	}
	var user models.User
	h.DB.First(&user, userID)
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.CurrentPassword)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Current password is incorrect"})
		return
	}
	hashed, _ := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	h.DB.Model(&user).Update("password", string(hashed))
	h.logActivity(userID, "CHANGE_PASSWORD", "Password changed", c.ClientIP())
	c.JSON(http.StatusOK, gin.H{"message": "Password changed successfully", "ok": true})
}

func (h *Handler) UploadAvatar(c *gin.Context) {
	userID := c.GetUint("user_id")
	var body struct {
		AvatarURL string `json:"avatar_url"`
	}
	c.ShouldBindJSON(&body)
	h.DB.Model(&models.User{}).Where("id = ?", userID).Update("avatar_url", body.AvatarURL)
	c.JSON(http.StatusOK, gin.H{"message": "Avatar updated", "avatar_url": body.AvatarURL, "ok": true})
}

// ── Dashboard ─────────────────────────────────────────────────────────────────

func (h *Handler) GetDashboardStats(c *gin.Context) {
	var totalUsers, activeUsers, adminUsers int64
	h.DB.Model(&models.User{}).Count(&totalUsers)
	h.DB.Model(&models.User{}).Where("is_active = true").Count(&activeUsers)
	h.DB.Model(&models.User{}).Where("role = ?", models.RoleAdmin).Count(&adminUsers)

	var recentUsers []models.User
	h.DB.Order("created_at desc").Limit(5).Find(&recentUsers)

	var recentLogs []models.ActivityLog
	h.DB.Preload("User").Order("created_at desc").Limit(10).Find(&recentLogs)

	c.JSON(http.StatusOK, gin.H{
		"total_users":  totalUsers,
		"active_users": activeUsers,
		"admin_users":  adminUsers,
		"new_users":    totalUsers - activeUsers,
		"recent_users": recentUsers,
		"recent_logs":  recentLogs,
		"ok":           true,
	})
}

// ── User Management (Admin) ───────────────────────────────────────────────────

func (h *Handler) ListUsers(c *gin.Context) {
	var users []models.User
	query := h.DB.Model(&models.User{})
	if search := c.Query("search"); search != "" {
		query = query.Where("first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ?",
			"%"+search+"%", "%"+search+"%", "%"+search+"%")
	}
	query.Order("created_at desc").Find(&users)
	c.JSON(http.StatusOK, gin.H{"users": users, "total": len(users), "ok": true})
}

func (h *Handler) CreateUser(c *gin.Context) {
	var req CreateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	var existing models.User
	if h.DB.Where("email = ?", req.Email).First(&existing).Error == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Email already exists"})
		return
	}
	hashed, _ := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	role := req.Role
	if role == "" {
		role = models.RoleUser
	}
	user := models.User{
		FirstName:  req.FirstName,
		LastName:   req.LastName,
		Email:      strings.ToLower(req.Email),
		Password:   string(hashed),
		Phone:      req.Phone,
		Department: req.Department,
		Position:   req.Position,
		Role:       role,
		IsActive:   true,
	}
	h.DB.Create(&user)
	adminID := c.GetUint("user_id")
	h.logActivity(adminID, "CREATE_USER", "Admin created user: "+user.Email, c.ClientIP())
	c.JSON(http.StatusCreated, gin.H{"message": "User created", "user": user, "ok": true})
}

func (h *Handler) GetUser(c *gin.Context) {
	var user models.User
	if h.DB.First(&user, c.Param("id")).Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"user": user, "ok": true})
}

func (h *Handler) UpdateUser(c *gin.Context) {
	var user models.User
	if h.DB.First(&user, c.Param("id")).Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}
	var body struct {
		FirstName  *string      `json:"first_name"`
		LastName   *string      `json:"last_name"`
		Phone      *string      `json:"phone"`
		Department *string      `json:"department"`
		Position   *string      `json:"position"`
		Role       *models.Role `json:"role"`
		IsActive   *bool        `json:"is_active"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if body.FirstName != nil {
		user.FirstName = *body.FirstName
	}
	if body.LastName != nil {
		user.LastName = *body.LastName
	}
	if body.Phone != nil {
		user.Phone = *body.Phone
	}
	if body.Department != nil {
		user.Department = *body.Department
	}
	if body.Position != nil {
		user.Position = *body.Position
	}
	if body.Role != nil {
		user.Role = *body.Role
	}
	if body.IsActive != nil {
		user.IsActive = *body.IsActive
	}
	// Save updates ALL fields including booleans
	h.DB.Save(&user)
	adminID := c.GetUint("user_id")
	h.logActivity(adminID, "UPDATE_USER", fmt.Sprintf("Admin updated user %s (active=%v)", user.Email, user.IsActive), c.ClientIP())
	c.JSON(http.StatusOK, gin.H{"message": "User updated", "user": user, "ok": true})
}

// ── FIXED: DeleteUser ─────────────────────────────────────────────────────────
// Root cause of "failed to delete":
//
//	ActivityLog has a FK → users.id with no ON DELETE CASCADE.
//	Any user with login/activity history causes a constraint violation.
//	Fix: hard-delete the user's activity logs first, then delete the user.
func (h *Handler) DeleteUser(c *gin.Context) {
	userIDParam := c.Param("id")
	if userIDParam == "" || userIDParam == "0" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// 1. Find the user (Unscoped so soft-deleted users can also be purged)
	var user models.User
	if err := h.DB.Unscoped().Where("id = ?", userIDParam).First(&user).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found", "id": userIDParam})
		return
	}

	// 2. Hard-delete activity logs that reference this user FIRST.
	//    Without this, the FK constraint on activity_logs.user_id → users.id
	//    causes the user delete to fail with a constraint violation.
	if err := h.DB.Unscoped().Where("user_id = ?", user.ID).Delete(&models.ActivityLog{}).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to remove user activity logs",
			"details": err.Error(),
		})
		return
	}

	// 3. Hard-delete the user — FK is now satisfied.
	if err := h.DB.Unscoped().Delete(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to delete user",
			"details": err.Error(),
		})
		return
	}

	adminID := c.GetUint("user_id")
	h.logActivity(adminID, "DELETE_USER",
		fmt.Sprintf("Admin deleted user: %s (id=%d)", user.Email, user.ID),
		c.ClientIP())

	c.JSON(http.StatusOK, gin.H{"message": "User deleted", "deleted_id": user.ID, "ok": true})
}

// ── Activity Log ──────────────────────────────────────────────────────────────

func (h *Handler) GetActivityLogs(c *gin.Context) {
	userID := c.GetUint("user_id")
	role := c.GetString("role")
	var logs []models.ActivityLog
	query := h.DB.Preload("User").Order("created_at desc").Limit(50)
	if role != string(models.RoleAdmin) {
		query = query.Where("user_id = ?", userID)
	}
	query.Find(&logs)
	c.JSON(http.StatusOK, gin.H{"logs": logs, "ok": true})
}

func (h *Handler) logActivity(userID uint, action, details, ip string) {
	entry := models.ActivityLog{
		UserID:    userID,
		Action:    action,
		Details:   details,
		IPAddress: ip,
	}
	h.DB.Create(&entry)
}

// ── Department / Position Config (Admin) ─────────────────────────────────────

func (h *Handler) ListConfig(c *gin.Context) {
	configType := c.Query("type") // "department" or "position"
	var items []models.DepartmentConfig
	query := h.DB.Where("is_active = true")
	if configType != "" {
		query = query.Where("type = ?", configType)
	}
	query.Order("name asc").Find(&items)
	c.JSON(http.StatusOK, gin.H{"items": items, "ok": true})
}

func (h *Handler) CreateConfig(c *gin.Context) {
	var body struct {
		Name string `json:"name" binding:"required"`
		Type string `json:"type" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if body.Type != "department" && body.Type != "position" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "type must be 'department' or 'position'"})
		return
	}
	item := models.DepartmentConfig{Name: body.Name, Type: body.Type, IsActive: true}
	if err := h.DB.Create(&item).Error; err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Name already exists"})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"message": "Created", "item": item, "ok": true})
}

func (h *Handler) DeleteConfig(c *gin.Context) {
	var item models.DepartmentConfig
	if h.DB.First(&item, c.Param("id")).Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Not found"})
		return
	}
	h.DB.Delete(&item)
	c.JSON(http.StatusOK, gin.H{"message": "Deleted", "ok": true})
}

// ════════════════════════════════════════════════════════════════════
// 2. ADD THIS HANDLER to handlers.go
//    Place it right after DeleteConfig()
// ════════════════════════════════════════════════════════════════════

func (h *Handler) UpdateConfig(c *gin.Context) {
	var item models.DepartmentConfig
	if h.DB.First(&item, c.Param("id")).Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Not found"})
		return
	}
	var body struct {
		Name string `json:"name" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.DB.Model(&item).Update("name", body.Name).Error; err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Name already exists"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Updated", "item": item, "ok": true})
}
