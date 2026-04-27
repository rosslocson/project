package handlers

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
	"unicode"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"

	"project/backend/email"
	"project/backend/models"
)

// ── Constants ────────────────────────────────────────────────────────────────

const (
	maxLoginAttempts = 3
	lockDuration     = 1 * time.Minute
	otpExpiry        = 5 * time.Minute
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

// ── Replace your UpdateProfileRequest struct ──────────────────────────────────

type UpdateProfileRequest struct {
	// Account Settings fields
	FirstName  string `json:"first_name"`
	LastName   string `json:"last_name"`
	Phone      string `json:"phone"`
	Department string `json:"department"`
	Position   string `json:"position"`

	// Edit Profile fields
	School         string `json:"school"`
	Program        string `json:"program"`
	Specialization string `json:"specialization"`
	YearLevel      string `json:"year_level"`
	InternNumber   string `json:"intern_number"`
	StartDate      string `json:"start_date"`
	EndDate        string `json:"end_date"`

	// Skills fields
	Bio             string `json:"bio"`
	TechnicalSkills string `json:"technical_skills"`
	SoftSkills      string `json:"soft_skills"`
	LinkedIn        string `json:"linked_in"`
	GitHub          string `json:"git_hub"`
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

// ── Auth Handlers ────────────────────────────────────────────────────────────

// Register moved to auth_handlers.go with service layer

// Login moved to auth_handlers.go with service layer (simplified lockout)

// ── Password Reset ───────────────────────────────────────────────────────────

func (h *Handler) ForgotPassword(c *gin.Context) {
	var body struct {
		Email string `json:"email" binding:"required,email"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Valid email required"})
		return
	}

	cleanEmail := strings.ToLower(strings.TrimSpace(body.Email))
	var user models.User
	if h.DB.Where("email = ?", cleanEmail).First(&user).Error != nil {
		log.Printf("Debug: Email not found in DB: '%s'", cleanEmail)
		// Always return success to avoid email enumeration
		c.JSON(http.StatusOK, gin.H{"message": "If that email exists, a reset token has been sent."})
		return
	}

	otp, err := email.GenerateSecureOTP()
	if err != nil {
		log.Printf("OTP generation failed: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not generate OTP"})
		return
	}

	expiry := time.Now().Add(otpExpiry)
	if err := h.DB.Model(&user).Updates(map[string]interface{}{
		"reset_token":        otp,
		"reset_token_expiry": expiry,
	}).Error; err != nil {
		log.Printf("DB update failed: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to store OTP"})
		return
	}

	if err := email.SendPasswordResetEmail(cleanEmail, otp); err != nil {
		log.Printf("Email send failed for %s: %v", cleanEmail, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Unable to send OTP email right now. Please try again later."})
		return
	}

	h.logActivity(user.ID, "PASSWORD_RESET_OTP_SENT", "OTP sent to "+cleanEmail, c.ClientIP())

	c.JSON(http.StatusOK, gin.H{"message": "If that email is registered, check your inbox for the 6-digit OTP (expires in 5 minutes)."})
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
	c.JSON(http.StatusOK, gin.H{"message": "Password reset successfully. You can now log in."})
}

// ── Profile Handlers ─────────────────────────────────────────────────────────

func (h *Handler) GetProfile(c *gin.Context) {
	userID := c.GetUint("user_id")
	var user models.User
	h.DB.First(&user, userID)
	c.JSON(http.StatusOK, user)
}

// ── Replace your UpdateProfile handler ───────────────────────────────────────

func (h *Handler) UpdateProfile(c *gin.Context) {
	userID := c.GetUint("user_id")
	var req UpdateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Fetch current user first so we only overwrite fields that were sent
	var user models.User
	if err := h.DB.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// Only overwrite a field if the request actually sent a non-empty value.
	// This prevents AccountSettings from blanking out Edit Profile fields
	// and vice versa.
	// Replace the updates map section in UpdateProfile
	updates := map[string]interface{}{}

	// Only write fields that were explicitly sent (non-empty)
	// If you need to allow clearing a field, the Flutter side must send a
	// sentinel like " " or handle it separately
	if req.FirstName != "" {
		updates["first_name"] = req.FirstName
	}
	if req.LastName != "" {
		updates["last_name"] = req.LastName
	}
	if req.Phone != "" {
		updates["phone"] = req.Phone
	}

	// ✅ Department/Position: only write if the key was actually in the JSON.
	// Use pointers in the request struct instead so you can distinguish
	// "not sent" from "intentionally empty":
	if req.Department != "" {
		updates["department"] = req.Department
	}
	if req.Position != "" {
		updates["position"] = req.Position
	}

	if req.School != "" {
		updates["school"] = req.School
	}
	if req.Program != "" {
		updates["program"] = req.Program
	}
	if req.Specialization != "" {
		updates["specialization"] = req.Specialization
	}
	if req.YearLevel != "" {
		updates["year_level"] = req.YearLevel
	}
	if req.InternNumber != "" {
		updates["intern_number"] = req.InternNumber
	}
	if req.StartDate != "" {
		updates["start_date"] = req.StartDate
	}
	if req.EndDate != "" {
		updates["end_date"] = req.EndDate
	}
	if req.Bio != "" {
		updates["bio"] = req.Bio
	}
	if req.TechnicalSkills != "" {
		updates["technical_skills"] = req.TechnicalSkills
	}
	if req.SoftSkills != "" {
		updates["soft_skills"] = req.SoftSkills
	}
	if req.LinkedIn != "" {
		updates["linked_in"] = req.LinkedIn
	}
	if req.GitHub != "" {
		updates["git_hub"] = req.GitHub
	}

	if err := h.DB.Model(&models.User{}).Where("id = ?", userID).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update profile"})
		return
	}

	h.logActivity(userID, "UPDATE_PROFILE", "Profile updated", c.ClientIP())

	// Return the full fresh user so Flutter always has the complete picture
	var updated models.User
	h.DB.First(&updated, userID)
	c.JSON(http.StatusOK, gin.H{"ok": true, "message": "Profile updated", "user": updated})
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
	c.JSON(http.StatusOK, gin.H{"message": "Password changed successfully"})
}

func (h *Handler) UploadAvatar(c *gin.Context) {
	userID := c.GetUint("user_id")

	// Get the file from the multipart form (field name must be 'avatar')
	header, err := c.FormFile("avatar")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No avatar file provided"})
		return
	}

	// Validate file size (max 5MB)
	if header.Size > 5*1024*1024 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "File size exceeds 5MB limit"})
		return
	}

	file, err := header.Open()
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to open file"})
		return
	}
	defer file.Close()

	// Read first 512 bytes for content type detection
	buffer := make([]byte, 512)
	n, err := file.Read(buffer)
	if err != nil && err != io.EOF {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to read file"})
		return
	}
	if n == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Empty file"})
		return
	}

	// Detect content type
	contentType := http.DetectContentType(buffer[:n])
	if !strings.HasPrefix(contentType, "image/") {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid type"})
		return
	}

	// Reset file pointer for saving
	if _, err := file.Seek(0, 0); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to reset file pointer"})
		return
	}

	// Create uploads directory if it doesn't exist
	uploadsDir := "./uploads"
	if err := os.MkdirAll(uploadsDir, 0755); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create uploads directory"})
		return
	}

	// Generate unique filename
	filename := fmt.Sprintf("%d_%d_%s", userID, time.Now().Unix(), header.Filename)
	filepath := fmt.Sprintf("%s/%s", uploadsDir, filename)

	// Save the file
	if err := c.SaveUploadedFile(header, filepath); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save file: " + err.Error()})
		return
	}

	// Update user's avatar URL in database
	avatarURL := fmt.Sprintf("/uploads/%s", filename)
	if err := h.DB.Model(&models.User{}).Where("id = ?", userID).Update("avatar_url", avatarURL).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update avatar URL: " + err.Error()})
		return
	}

	// Fetch updated user
	var user models.User
	if err := h.DB.Where("id = ?", userID).First(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch updated user"})
		return
	}

	h.logActivity(userID, "AVATAR_UPLOAD", "Avatar uploaded: "+filename, c.ClientIP())

	c.JSON(http.StatusOK, gin.H{
		"message":    "Avatar uploaded successfully",
		"user":       user,
		"avatar_url": avatarURL,
	})
}

// ── Dashboard ─────────────────────────────────────────────────────────────────

func (h *Handler) GetDashboardStats(c *gin.Context) {
	var totalUsers, activeUsers, adminUsers int64
	h.DB.Model(&models.User{}).Count(&totalUsers)
	h.DB.Model(&models.User{}).Where("is_active = true").Count(&activeUsers)
	h.DB.Model(&models.User{}).Where("role = ?", models.RoleAdmin).Count(&adminUsers)

	// Parse pagination parameters for recent users
	pageStr := c.DefaultQuery("page", "1")
	limitStr := c.DefaultQuery("limit", "5")

	page, err := strconv.Atoi(pageStr)
	if err != nil || page < 1 {
		page = 1
	}

	limit, err := strconv.Atoi(limitStr)
	if err != nil || limit < 1 || limit > 100 {
		limit = 5
	}

	offset := (page - 1) * limit

	// Get total count of users for pagination
	var totalUserCount int64
	h.DB.Model(&models.User{}).Count(&totalUserCount)

	// Calculate total pages for users
	totalPages := int((totalUserCount + int64(limit) - 1) / int64(limit))
	if totalPages == 0 {
		totalPages = 1
	}

	// Get paginated recent users
	var recentUsers []models.User
	h.DB.Order("created_at desc").Limit(limit).Offset(offset).Find(&recentUsers)

	// Get recent logs (not paginated for dashboard, just recent 10)
	var recentLogs []models.ActivityLog
	h.DB.Preload("User").Order("created_at desc").Limit(10).Find(&recentLogs)

	// Get all activity logs - SIMPLIFIED: Get last 7 days (past week)
	var allWeeklyLogs []models.ActivityLog
	now := time.Now().Local() // Use local time, not UTC

	// Get activities from the last 7 days to ensure we capture everything from the past week
	sevenDaysAgo := now.AddDate(0, 0, -7)
	tomorrow := now.AddDate(0, 0, 1).Add(time.Hour) // Include remainder of today

	fmt.Printf("DEBUG: Dashboard Stats - Querying logs from %v to %v (past 7 days)\n", sevenDaysAgo, tomorrow)

	h.DB.Preload("User").
		Where("created_at >= ? AND created_at < ?", sevenDaysAgo, tomorrow).
		Order("created_at desc").
		Find(&allWeeklyLogs)

	fmt.Printf("DEBUG: Dashboard Stats - Found %d activity logs in the past 7 days\n", len(allWeeklyLogs))

	c.JSON(http.StatusOK, gin.H{
		"total_users":  totalUsers,
		"active_users": activeUsers,
		"admin_users":  adminUsers,
		"new_users":    totalUsers - activeUsers,
		"recent_users": recentUsers,
		"recent_logs":  recentLogs,
		"weekly_logs":  allWeeklyLogs,
		"total_pages":  totalPages,
		"current_page": page,
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
	var body struct {
		FirstName  *string      `json:"first_name"`
		LastName   *string      `json:"last_name"`
		Phone      *string      `json:"phone"`
		Department *string      `json:"department"`
		Position   *string      `json:"position"`
		Role       *models.Role `json:"role"`
		IsActive   *bool        `json:"is_active"`
		IsArchived *bool        `json:"is_archived"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	// Use Omit to allow false boolean updates (GORM skips zero values with Updates)
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
	if body.IsArchived != nil {
		user.IsArchived = *body.IsArchived
	}
	// Save updates ALL fields including booleans
	h.DB.Save(&user)
	adminID := c.GetUint("user_id")
	h.logActivity(adminID, "UPDATE_USER", fmt.Sprintf("Admin updated user %s (active=%v, archived=%v)", user.Email, user.IsActive, user.IsArchived), c.ClientIP())
	c.JSON(http.StatusOK, gin.H{"message": "User updated", "user": user})
}

func (h *Handler) DeleteUser(c *gin.Context) {
	userIDParam := c.Param("id")
	if userIDParam == "" || userIDParam == "0" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	var user models.User
	result := h.DB.Where("id = ?", userIDParam).First(&user)
	if result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found", "id": userIDParam})
		return
	}

	// Hard delete — bypass soft-delete scope entirely
	delResult := h.DB.Unscoped().Where("id = ?", user.ID).Delete(&models.User{})
	if delResult.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete user"})
		return
	}

	adminID := c.GetUint("user_id")
	h.logActivity(adminID, "DELETE_USER", fmt.Sprintf("Admin deleted user: %s (id=%d)", user.Email, user.ID), c.ClientIP())
	c.JSON(http.StatusOK, gin.H{"message": "User deleted", "deleted_id": user.ID})
}

// ── Activity Log ──────────────────────────────────────────────────────────────

func (h *Handler) GetActivityLogs(c *gin.Context) {
	userID := c.GetUint("user_id")
	role := c.GetString("role")

	// Parse pagination parameters
	pageStr := c.DefaultQuery("page", "1")
	limitStr := c.DefaultQuery("limit", "5")

	page, err := strconv.Atoi(pageStr)
	if err != nil || page < 1 {
		page = 1
	}

	limit, err := strconv.Atoi(limitStr)
	if err != nil || limit < 1 || limit > 100 {
		limit = 5
	}

	offset := (page - 1) * limit

	// Build base query
	query := h.DB.Model(&models.ActivityLog{}).Preload("User")
	if role != string(models.RoleAdmin) {
		query = query.Where("user_id = ?", userID)
	}

	// Get total count for pagination
	var totalCount int64
	query.Count(&totalCount)

	// Calculate total pages
	totalPages := int((totalCount + int64(limit) - 1) / int64(limit))
	if totalPages == 0 {
		totalPages = 1
	}

	// Get paginated logs
	var logs []models.ActivityLog
	query.Order("created_at desc").Limit(limit).Offset(offset).Find(&logs)

	c.JSON(http.StatusOK, gin.H{
		"logs":         logs,
		"total_pages":  totalPages,
		"current_page": page,
	})
}

// ── List Interns ─────────────────────────────────────────────────────────────

func (h *Handler) ListInterns(c *gin.Context) {
	var interns []models.User
	h.DB.Where("role = ? AND is_active = ?", models.RoleUser, true).
		Select(`id, first_name, last_name, email, department, position, 
                avatar_url, school, program, specialization, 
                technical_skills, soft_skills, created_at`).
		Order("first_name asc, last_name asc").
		Find(&interns)
	c.JSON(http.StatusOK, gin.H{"interns": interns})
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

// ── Departments ───────────────────────────────────────────────────────────────

func (h *Handler) ListDepartments(c *gin.Context) {
	var items []models.Department
	h.DB.Order("name asc").Find(&items)
	c.JSON(http.StatusOK, gin.H{"items": items})
}

func (h *Handler) CreateDepartment(c *gin.Context) {
	adminID := c.GetUint("user_id")

	var body struct {
		Name string `json:"name" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	item := models.Department{Name: strings.TrimSpace(body.Name), IsActive: true}
	if err := h.DB.Create(&item).Error; err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Department name already exists"})
		return
	}

	h.logActivity(adminID, "CREATE_DEPARTMENT", "Admin created department: "+item.Name, c.ClientIP())

	c.JSON(http.StatusCreated, gin.H{"message": "Department created", "item": item})
}

func (h *Handler) UpdateDepartment(c *gin.Context) {
	adminID := c.GetUint("user_id")

	var item models.Department
	if h.DB.First(&item, c.Param("id")).Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Department not found"})
		return
	}
	var body struct {
		Name string `json:"name" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	oldName := item.Name
	item.Name = strings.TrimSpace(body.Name)
	if err := h.DB.Save(&item).Error; err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Department name already exists"})
		return
	}

	h.logActivity(adminID, "UPDATE_DEPARTMENT", fmt.Sprintf("Admin updated department: %s -> %s", oldName, item.Name), c.ClientIP())

	c.JSON(http.StatusOK, gin.H{"message": "Department updated", "item": item})
}

func (h *Handler) DeleteDepartment(c *gin.Context) {
	adminID := c.GetUint("user_id")

	var item models.Department
	if h.DB.First(&item, c.Param("id")).Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Department not found"})
		return
	}

	h.logActivity(adminID, "DELETE_DEPARTMENT", fmt.Sprintf("Admin deleted department: %s (id=%d)", item.Name, item.ID), c.ClientIP())

	h.DB.Unscoped().Delete(&item)
	c.JSON(http.StatusOK, gin.H{"message": "Department deleted"})
}

// ── Positions ──────────────────────────────────────────────────────────────────

func (h *Handler) ListPositions(c *gin.Context) {
	var items []models.Position
	h.DB.Order("name asc").Find(&items)
	c.JSON(http.StatusOK, gin.H{"items": items})
}

func (h *Handler) CreatePosition(c *gin.Context) {
	adminID := c.GetUint("user_id")

	var body struct {
		Name string `json:"name" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	item := models.Position{Name: strings.TrimSpace(body.Name), IsActive: true}
	if err := h.DB.Create(&item).Error; err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Position name already exists"})
		return
	}

	h.logActivity(adminID, "CREATE_POSITION", "Admin created position: "+item.Name, c.ClientIP())

	c.JSON(http.StatusCreated, gin.H{"message": "Position created", "item": item})
}

func (h *Handler) UpdatePosition(c *gin.Context) {
	adminID := c.GetUint("user_id")

	var item models.Position
	if h.DB.First(&item, c.Param("id")).Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Position not found"})
		return
	}
	var body struct {
		Name string `json:"name" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	oldName := item.Name
	item.Name = strings.TrimSpace(body.Name)
	if err := h.DB.Save(&item).Error; err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Position name already exists"})
		return
	}

	h.logActivity(adminID, "UPDATE_POSITION", fmt.Sprintf("Admin updated position: %s -> %s", oldName, item.Name), c.ClientIP())

	c.JSON(http.StatusOK, gin.H{"message": "Position updated", "item": item})
}

func (h *Handler) DeletePosition(c *gin.Context) {
	adminID := c.GetUint("user_id")

	var item models.Position
	if h.DB.First(&item, c.Param("id")).Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Position not found"})
		return
	}

	h.logActivity(adminID, "DELETE_POSITION", fmt.Sprintf("Admin deleted position: %s (id=%d)", item.Name, item.ID), c.ClientIP())

	h.DB.Unscoped().Delete(&item)
	c.JSON(http.StatusOK, gin.H{"message": "Position deleted"})
}
