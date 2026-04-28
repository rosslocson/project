package handlers

import (
	"bytes"
	"fmt"
	"image"
	"image/jpeg"
	"io"
	"net/http"
	"net/url"
	"os"
	"strconv"
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
func validateProfileURL(raw string) (string, error) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return "", nil
	}

	u, err := url.Parse(raw)
	if err != nil {
		return "", fmt.Errorf("invalid URL")
	}
	if u.Scheme == "" || u.Host == "" {
		return "", fmt.Errorf("invalid URL")
	}
	if u.Scheme != "http" && u.Scheme != "https" {
		return "", fmt.Errorf("URL must start with http:// or https://")
	}
	return u.String(), nil
}

func parseProfileDate(dateStr, fieldName string) (time.Time, error) {
	if strings.TrimSpace(dateStr) == "" {
		return time.Time{}, nil
	}
	parsed, err := time.Parse("2006-01-02", dateStr)
	if err != nil {
		return time.Time{}, fmt.Errorf("invalid %s format", fieldName)
	}
	return parsed, nil
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

// Password reset moved to auth_handlers.go

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
	role := c.GetString("role")
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

	// Validate URLs before applying them
	if req.LinkedIn != "" {
		cleaned, err := validateProfileURL(req.LinkedIn)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid LinkedIn URL: " + err.Error()})
			return
		}
		req.LinkedIn = cleaned
	}
	if req.GitHub != "" {
		cleaned, err := validateProfileURL(req.GitHub)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid GitHub URL: " + err.Error()})
			return
		}
		req.GitHub = cleaned
	}

	// Validate chronological dates. Use existing values when only one side is updated.
	startDateValue := user.StartDate
	endDateValue := user.EndDate
	if req.StartDate != "" {
		if _, err := parseProfileDate(req.StartDate, "start_date"); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
		startDateValue = req.StartDate
	}
	if req.EndDate != "" {
		if _, err := parseProfileDate(req.EndDate, "end_date"); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
		endDateValue = req.EndDate
	}
	if startDateValue != "" && endDateValue != "" {
		parsedStart, err := parseProfileDate(startDateValue, "start_date")
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
		parsedEnd, err := parseProfileDate(endDateValue, "end_date")
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
		if parsedEnd.Before(parsedStart) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "End date cannot be before start date"})
			return
		}
	}

	updates := map[string]interface{}{}
	if req.FirstName != "" {
		updates["first_name"] = req.FirstName
	}
	if req.LastName != "" {
		updates["last_name"] = req.LastName
	}
	if req.Phone != "" {
		updates["phone"] = req.Phone
	}

	if role == string(models.RoleAdmin) {
		if req.Department != "" {
			updates["department"] = req.Department
		}
		if req.Position != "" {
			updates["position"] = req.Position
		}
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

// ── Helper function: Compress and resize image ────────────────────────────────

// compressImage resizes and compresses an image to reduce file size
// Max dimensions: 512x512, JPEG quality: 85%
// Reduces file size by approximately 70-80%
func compressImage(imageBytes []byte) ([]byte, error) {
	// Decode image
	img, _, err := image.Decode(bytes.NewReader(imageBytes))
	if err != nil {
		return nil, fmt.Errorf("failed to decode image: %w", err)
	}

	// Resize if needed (max 512x512)
	bounds := img.Bounds()
	width := bounds.Dx()
	height := bounds.Dy()

	if width > 512 || height > 512 {
		// Calculate new dimensions maintaining aspect ratio
		var newWidth, newHeight int
		if width > height {
			newWidth = 512
			newHeight = (512 * height) / width
		} else {
			newHeight = 512
			newWidth = (512 * width) / height
		}

		// Simple box filter resize
		img = resizeImage(img, newWidth, newHeight)
	}

	// Encode as JPEG with 85% quality
	var buf bytes.Buffer
	opts := &jpeg.Options{Quality: 85}
	if err := jpeg.Encode(&buf, img, opts); err != nil {
		return nil, fmt.Errorf("failed to encode image: %w", err)
	}

	return buf.Bytes(), nil
}

// resizeImage performs a simple box filter resize
func resizeImage(src image.Image, newWidth, newHeight int) image.Image {
	srcBounds := src.Bounds()
	srcWidth := srcBounds.Dx()
	srcHeight := srcBounds.Dy()

	// Create a new image
	dst := image.NewRGBA(image.Rect(0, 0, newWidth, newHeight))

	// Simple nearest-neighbor resize for speed
	for y := 0; y < newHeight; y++ {
		for x := 0; x < newWidth; x++ {
			srcX := (x * srcWidth) / newWidth
			srcY := (y * srcHeight) / newHeight
			dst.Set(x, y, src.At(srcBounds.Min.X+srcX, srcBounds.Min.Y+srcY))
		}
	}

	return dst
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

	// Read entire file into memory for compression
	fileData, err := io.ReadAll(file)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to read file"})
		return
	}

	// Compress and resize image for faster storage and delivery
	compressedData, err := compressImage(fileData)
	if err != nil {
		// If compression fails, use original file
		fmt.Printf("⚠️ Image compression failed: %v, using original\n", err)
		compressedData = fileData
	} else {
		fmt.Printf("🗜️ Avatar compressed: %d → %d bytes (%.1f%% reduction)\n",
			len(fileData), len(compressedData),
			float64(len(fileData)-len(compressedData))/float64(len(fileData))*100)
	}

	// Create uploads directory if it doesn't exist
	uploadsDir := "./uploads"
	if err := os.MkdirAll(uploadsDir, 0755); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create uploads directory"})
		return
	}

	// Generate unique filename (use .jpg extension for compressed images)
	filename := fmt.Sprintf("%d_%d_%s.jpg", userID, time.Now().Unix(), strings.TrimSuffix(header.Filename, ".png"))
	filepath := fmt.Sprintf("%s/%s", uploadsDir, filename)

	// Save the compressed file
	if err := os.WriteFile(filepath, compressedData, 0644); err != nil {
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

	// Search filter
	if search := c.Query("search"); search != "" {
		query = query.Where("first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ?",
			"%"+search+"%", "%"+search+"%", "%"+search+"%")
	}

	// Status filter for tabs: 'all', 'active', 'archived', 'inactive'
	statusFilter := c.Query("status")
	if statusFilter != "" {
		switch statusFilter {
		case "active":
			query = query.Where("is_active = ? AND is_archived = ?", true, false)
		case "archived":
			query = query.Where("is_archived = ?", true)
		case "inactive":
			query = query.Where("is_active = ?", false)
			// 'all' or empty returns all users
		}
	}

	query.Order("created_at desc").Find(&users)

	// Calculate counts for all statuses
	var allCount, activeCount, inactiveCount, archivedCount int64
	h.DB.Model(&models.User{}).Count(&allCount)
	h.DB.Model(&models.User{}).Where("is_active = ? AND is_archived = ?", true, false).Count(&activeCount)
	h.DB.Model(&models.User{}).Where("is_active = ?", false).Count(&inactiveCount)
	h.DB.Model(&models.User{}).Where("is_archived = ?", true).Count(&archivedCount)

	c.JSON(http.StatusOK, gin.H{
		"users": users,
		"total": len(users),
		"counts": gin.H{
			"all":      allCount,
			"active":   activeCount,
			"inactive": inactiveCount,
			"archived": archivedCount,
		},
	})
}

func (h *Handler) CreateUser(c *gin.Context) {
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

	// Get current user ID from JWT
	currentUserID := c.GetUint("user_id")

	// Parse target user ID
	targetUserIDStr := c.Param("id")
	targetUserID, err := strconv.ParseUint(targetUserIDStr, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Security Check 1: Cannot archive yourself
	if body.IsArchived != nil && *body.IsArchived && uint(targetUserID) == currentUserID {
		c.JSON(http.StatusBadRequest, gin.H{"error": "You cannot archive your own account"})
		return
	}

	// Security Check 2: Last Admin Protection
	if user.Role == models.RoleAdmin {
		// Check if trying to deactivate or archive an admin
		isTryingToDeactivate := (body.IsActive != nil && !*body.IsActive) || (body.IsArchived != nil && *body.IsArchived)

		if isTryingToDeactivate {
			// Count active admins (excluding archived and inactive)
			var activeAdminCount int64
			h.DB.Model(&models.User{}).Where("role = ? AND is_active = ? AND is_archived = ?", models.RoleAdmin, true, false).Count(&activeAdminCount)

			if activeAdminCount <= 1 {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Action denied: At least one active admin must remain"})
				return
			}
		}
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

func (h *Handler) GetUser(c *gin.Context) {
	var user models.User
	if h.DB.First(&user, c.Param("id")).Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}
	c.JSON(http.StatusOK, user)
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
                technical_skills, soft_skills, intern_number, created_at`).
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
	h.DB.Preload("Positions").Order("name asc").Find(&items)
	c.JSON(http.StatusOK, gin.H{"items": items})
}

func (h *Handler) GetDepartmentsWithPositions(c *gin.Context) {
	var departments []models.Department
	h.DB.Preload("Positions").Order("name asc").Find(&departments)

	// Transform to the format expected by frontend
	result := make(map[string][]string)
	for _, dept := range departments {
		var positions []string
		for _, pos := range dept.Positions {
			positions = append(positions, pos.Name)
		}
		result[dept.Name] = positions
	}

	c.JSON(http.StatusOK, gin.H{"departments": result})
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
	item := models.Department{Name: strings.TrimSpace(body.Name)}
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
		DepartmentID uint   `json:"department_id" binding:"required"`
		Name         string `json:"name" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Verify department exists
	var dept models.Department
	if err := h.DB.First(&dept, body.DepartmentID).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid department ID"})
		return
	}

	item := models.Position{
		DepartmentID: body.DepartmentID,
		Name:         strings.TrimSpace(body.Name),
	}
	if err := h.DB.Create(&item).Error; err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Position name already exists in this department"})
		return
	}

	h.logActivity(adminID, "CREATE_POSITION", fmt.Sprintf("Admin created position: %s in %s", item.Name, dept.Name), c.ClientIP())

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
		DepartmentID *uint  `json:"department_id"`
		Name         string `json:"name" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if body.DepartmentID != nil {
		// Verify department exists
		var dept models.Department
		if err := h.DB.First(&dept, *body.DepartmentID).Error; err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid department ID"})
			return
		}
		item.DepartmentID = *body.DepartmentID
	}

	oldName := item.Name
	item.Name = strings.TrimSpace(body.Name)
	if err := h.DB.Save(&item).Error; err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Position name already exists in this department"})
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
