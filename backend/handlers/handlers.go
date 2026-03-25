package handlers

import (
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

type Handler struct {
	DB *gorm.DB
}

func NewHandler(db *gorm.DB) *Handler {
	return &Handler{DB: db}
}

// ── Request/Response types ──────────────────────────────────────────────────

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
	var errors []string
	if len(password) < 8 {
		errors = append(errors, "at least 8 characters")
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
		errors = append(errors, "at least one uppercase letter")
	}
	if !hasLower {
		errors = append(errors, "at least one lowercase letter")
	}
	if !hasDigit {
		errors = append(errors, "at least one digit")
	}
	if !hasSpecial {
		errors = append(errors, "at least one special character")
	}
	return errors
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

// ── Auth Handlers ────────────────────────────────────────────────────────────

func (h *Handler) Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Confirm password check
	if req.Password != req.ConfirmPassword {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Passwords do not match"})
		return
	}

	// Strong password validation
	if errs := validatePassword(req.Password); len(errs) > 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Password too weak",
			"details": "Password must contain: " + strings.Join(errs, ", "),
		})
		return
	}

	// Check duplicate email
	var existing models.User
	if result := h.DB.Where("email = ?", req.Email).First(&existing); result.Error == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Email already registered"})
		return
	}

	// Hash password
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

	if result := h.DB.Create(&user); result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
		return
	}

	// Log activity
	h.logActivity(user.ID, "REGISTER", "New user registered", c.ClientIP())

	token, _ := generateToken(user.ID, user.Role)
	c.JSON(http.StatusCreated, gin.H{
		"message": "Registration successful",
		"token":   token,
		"user":    user,
	})
}

func (h *Handler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var user models.User
	if result := h.DB.Where("email = ?", strings.ToLower(req.Email)).First(&user); result.Error != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid email or password"})
		return
	}

	if !user.IsActive {
		c.JSON(http.StatusForbidden, gin.H{"error": "Account is deactivated"})
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid email or password"})
		return
	}

	now := time.Now()
	h.DB.Model(&user).Update("last_login_at", now)
	h.logActivity(user.ID, "LOGIN", "User logged in", c.ClientIP())

	token, _ := generateToken(user.ID, user.Role)
	c.JSON(http.StatusOK, gin.H{
		"message": "Login successful",
		"token":   token,
		"user":    user,
	})
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
	updates := map[string]interface{}{
		"first_name": req.FirstName,
		"last_name":  req.LastName,
		"phone":      req.Phone,
		"department": req.Department,
		"position":   req.Position,
		"bio":        req.Bio,
	}
	h.DB.Model(&models.User{}).Where("id = ?", userID).Updates(updates)
	h.logActivity(userID, "UPDATE_PROFILE", "Profile updated", c.ClientIP())
	var user models.User
	h.DB.First(&user, userID)
	c.JSON(http.StatusOK, gin.H{"message": "Profile updated", "user": user})
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
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Password too weak",
			"details": "Password must contain: " + strings.Join(errs, ", "),
		})
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
	c.JSON(http.StatusOK, gin.H{"message": "Password changed successfully"})
}

func (h *Handler) UploadAvatar(c *gin.Context) {
	userID := c.GetUint("user_id")
	// In production, upload to S3/Cloudinary. Here we save the URL sent from client.
	var body struct {
		AvatarURL string `json:"avatar_url"`
	}
	c.ShouldBindJSON(&body)
	h.DB.Model(&models.User{}).Where("id = ?", userID).Update("avatar_url", body.AvatarURL)
	c.JSON(http.StatusOK, gin.H{"message": "Avatar updated", "avatar_url": body.AvatarURL})
}

// ── Dashboard Handlers ────────────────────────────────────────────────────────

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
	})
}

// ── User Management Handlers (Admin) ─────────────────────────────────────────

func (h *Handler) ListUsers(c *gin.Context) {
	var users []models.User
	query := h.DB.Model(&models.User{})

	// Optional search
	if search := c.Query("search"); search != "" {
		query = query.Where("first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ?",
			"%"+search+"%", "%"+search+"%", "%"+search+"%")
	}

	query.Order("created_at desc").Find(&users)
	c.JSON(http.StatusOK, gin.H{"users": users, "total": len(users)})
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
	c.JSON(http.StatusCreated, gin.H{"message": "User created", "user": user})
}

func (h *Handler) GetUser(c *gin.Context) {
	var user models.User
	if h.DB.First(&user, c.Param("id")).Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}
	c.JSON(http.StatusOK, user)
}

func (h *Handler) UpdateUser(c *gin.Context) {
	var user models.User
	if h.DB.First(&user, c.Param("id")).Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}
	var body map[string]interface{}
	c.ShouldBindJSON(&body)
	h.DB.Model(&user).Updates(body)
	c.JSON(http.StatusOK, gin.H{"message": "User updated", "user": user})
}

func (h *Handler) DeleteUser(c *gin.Context) {
	var user models.User
	if h.DB.First(&user, c.Param("id")).Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}
	// Soft delete via GORM
	h.DB.Delete(&user)
	adminID := c.GetUint("user_id")
	h.logActivity(adminID, "DELETE_USER", "Admin deleted user: "+user.Email, c.ClientIP())
	c.JSON(http.StatusOK, gin.H{"message": "User deleted"})
}

// ── Activity Log ─────────────────────────────────────────────────────────────

func (h *Handler) GetActivityLogs(c *gin.Context) {
	userID := c.GetUint("user_id")
	role := c.GetString("role")

	var logs []models.ActivityLog
	query := h.DB.Preload("User").Order("created_at desc").Limit(50)

	// Admins see all logs, users see only their own
	if role != string(models.RoleAdmin) {
		query = query.Where("user_id = ?", userID)
	}
	query.Find(&logs)
	c.JSON(http.StatusOK, gin.H{"logs": logs})
}

func (h *Handler) logActivity(userID uint, action, details, ip string) {
	log := models.ActivityLog{
		UserID:    userID,
		Action:    action,
		Details:   details,
		IPAddress: ip,
	}
	h.DB.Create(&log)
}
