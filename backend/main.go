package main

import (
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"

	"project/backend/handlers"
	"project/backend/middleware"
	"project/backend/models"
)

var DB *gorm.DB

func seedAdminAccount(db *gorm.DB) {
	adminEmail := "admin@example.com"
	adminPassword := "admin123"

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(adminPassword), bcrypt.DefaultCost)
	if err != nil {
		log.Printf("❌ Failed to hash admin password: %v", err)
		return
	}

	var existingAdmin models.User
	err = db.Unscoped().Where("email = ?", adminEmail).First(&existingAdmin).Error

	if err == nil {
		// Admin exists: restore if needed and update password only if required.
		if existingAdmin.DeletedAt.Valid {

			log.Println("⚠️ Admin account was soft-deleted. Restoring...")
			if err := db.Unscoped().Model(&existingAdmin).Updates(map[string]interface{}{
				"deleted_at":  nil,
				"password":    string(hashedPassword),
				"is_active":   true,
				"is_verified": true,
			}).Error; err != nil {
				log.Printf("❌ Failed to restore admin account: %v", err)
				return
			}
			log.Println("✅ Admin account restored and password updated")
			return
		}

		if !strings.HasPrefix(existingAdmin.Password, "$2a$") && !strings.HasPrefix(existingAdmin.Password, "$2b$") {
			log.Printf("⚠️ Admin password is not bcrypt hashed. Updating...")
			if err := db.Model(&existingAdmin).Updates(map[string]interface{}{
				"password":    string(hashedPassword),
				"is_verified": true,
			}).Error; err != nil {
				log.Printf("❌ Failed to update admin password: %v", err)
				return
			}
			log.Println("✅ Admin password updated to bcrypt hash")
		} else {
			log.Println("✅ Admin account already exists with proper bcrypt password")
		}
		return
	}

	adminUser := models.User{
		FirstName:  "Admin",
		LastName:   "User",
		Email:      adminEmail,
		Password:   string(hashedPassword),
		Role:       models.RoleAdmin,
		IsActive:   true,
		IsVerified: true,
	}

	if err := db.Create(&adminUser).Error; err != nil {
		log.Printf("⚠️ Failed to create admin account: %v", err)
		return
	}

	log.Println("✅ Admin account created successfully")
	log.Println("📧 Email: admin@example.com")
	log.Println("🔑 Password: admin123")
}

func ensureAdminAccountsVerified(db *gorm.DB) {
	if err := db.Model(&models.User{}).
		Where("role = ? AND is_verified = ?", models.RoleAdmin, false).
		Updates(map[string]interface{}{"is_verified": true}).Error; err != nil {
		log.Printf("⚠️ Failed to verify existing admin accounts: %v", err)
		return
	}
	log.Println("✅ Existing admin accounts verified if needed")
}

func fixPlaintextPasswords(db *gorm.DB) {
	var users []models.User
	if err := db.Find(&users).Error; err != nil {
		log.Printf("⚠️ Could not scan users for plaintext password fix: %v", err)
		return
	}

	if len(users) == 0 {
		log.Println("✅ No users to fix")
		return
	}

	fixed := 0
	for _, user := range users {
		if strings.HasPrefix(user.Password, "$2a$") || strings.HasPrefix(user.Password, "$2b$") {
			continue
		}
		if strings.TrimSpace(user.Password) == "" {
			log.Printf("⚠️ User %s (%s) has empty password", user.FirstName, user.Email)
			continue
		}

		log.Printf("🔧 Hashing plaintext password for user %s (%s)...", user.FirstName, user.Email)

		hashedPassword, err := bcrypt.GenerateFromPassword([]byte(user.Password), bcrypt.DefaultCost)
		if err != nil {
			log.Printf("❌ Failed to hash password for user %s: %v", user.Email, err)
			continue
		}

		if err := db.Model(&user).Update("password", string(hashedPassword)).Error; err != nil {
			log.Printf("❌ Failed to update password for user %s: %v", user.Email, err)
			continue
		}

		log.Printf("✅ Password hashed and updated for user %s", user.Email)
		fixed++
	}

	if fixed > 0 {
		log.Printf("✅ Fixed %d user(s) with plaintext passwords", fixed)
	} else {
		log.Println("✅ All users have properly hashed passwords")
	}
}

func main() {
	godotenv.Load()

	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		dsn = "host=localhost user=postgres password=alex12345 dbname=userapp port=5432 sslmode=disable"
	}

	var err error
	DB, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	// IMPORTANT: do NOT auto-migrate into DATE columns when existing rows contain empty strings
	// or non-parseable values. Legacy systems sometimes store "" in DATE columns and
	// PostgreSQL will error during casts.
	//
	// Safe, idempotent two-phase cleanup:
	// 1) Convert only valid YYYY-MM-DD strings to DATE; everything else becomes NULL.
	// 2) Run AutoMigrate after cleanup.
	if err := DB.Exec(`
		-- Phase 1: sanitize start_date/end_date to either a valid date or NULL.
		-- Use regex to only cast strings that match YYYY-MM-DD.
		UPDATE users
		SET
			start_date = CASE
				WHEN start_date IS NULL THEN NULL
				WHEN (start_date::text) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN (start_date::text)::date
				ELSE NULL
			END,
			end_date = CASE
				WHEN end_date IS NULL THEN NULL
				WHEN (end_date::text) ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN (end_date::text)::date
				ELSE NULL
			END
		;
	`).Error; err != nil {
		log.Printf("⚠️ Safe date cleanup before migration failed (continuing): %v", err)
	}

	// Defensive observability: count invalid date-like rows (do not fail startup).
	type invalidDatesRow struct {
		InvalidStart int64
		InvalidEnd   int64
	}
	var row invalidDatesRow
	if err := DB.Raw(`
		SELECT
			COALESCE(SUM(CASE WHEN start_date IS NOT NULL AND (start_date::text) !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN 1 ELSE 0 END), 0) AS invalid_start,
			COALESCE(SUM(CASE WHEN end_date   IS NOT NULL AND (end_date::text)   !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN 1 ELSE 0 END), 0) AS invalid_end
		FROM users
	`).Scan(&row).Error; err != nil {
		log.Printf("⚠️ Could not compute invalid start/end_date counts: %v", err)
	} else if row.InvalidStart > 0 || row.InvalidEnd > 0 {
		log.Printf("⚠️ Detected legacy invalid dates: invalid_start=%d invalid_end=%d (these should have been nulled)", row.InvalidStart, row.InvalidEnd)
	}

	DB.AutoMigrate(

		&models.User{},
		&models.ActivityLog{},
		&models.Department{},
		&models.Position{},
		&models.Attendance{},
	)
	log.Println("Database migrated successfully")

	ensureAdminAccountsVerified(DB)
	seedAdminAccount(DB)
	fixPlaintextPasswords(DB)

	h := handlers.NewHandler(DB)

	// gin.Default() already includes Logger + Recovery.
	r := gin.New()
	r.Use(gin.Logger(), gin.Recovery())
	r.MaxMultipartMemory = 32 << 20

	r.Use(cors.New(cors.Config{
		AllowAllOrigins:  true,
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Content-Length", "Accept-Encoding", "Authorization", "Accept"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: false,
		MaxAge:           12 * time.Hour,
	}))

	r.Static("/uploads", "./uploads")

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok", "time": time.Now()})
	})

	r.GET("/api/data", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "success", "message": "Connected to Go Backend!"})
	})

	// ── Public routes ─────────────────────────────────────────────────────────
	auth := r.Group("/api/auth")
	{
		auth.POST("/register", h.Register)
		auth.POST("/login", h.Login)
		auth.POST("/forgot-password", h.ForgotPassword)
		auth.POST("/verify-reset-otp", h.VerifyResetOTP)
		auth.POST("/verify-otp", h.VerifyRegistrationOTP)
		auth.POST("/resend-otp", h.ResendRegistrationOTP)
		auth.POST("/reset-password", h.ResetPassword)

		r.GET("/api/departments", h.ListDepartments)
		r.GET("/api/departments-with-positions", h.GetDepartmentsWithPositions)
		r.GET("/api/positions", h.ListPositions)
	}

	// ── Admin-only routes (JWT + AdminOnly) ───────────────────────────────────
	admin := r.Group("/api/admin")
	admin.Use(middleware.JWTAuth(), middleware.AdminOnly())
	{
		admin.GET("/dashboard", h.AdminDashboard)

		// Attendance monitoring
		admin.GET("/attendance", h.AdminGetAttendance)
		admin.GET("/attendance/export", h.AdminExportAttendance)
		admin.GET("/attendance/reports", h.GetPendingReports)

		// Resolve a reported record (PATCH = quick dismiss, POST = full resolution)
		admin.PATCH("/attendance/:id/resolve", h.ResolveAttendanceReport)
		admin.POST("/attendance/:id/resolve", h.ResolveAttendanceIssue)

		// Inline remark editing from the attendance table
		admin.PATCH("/attendance/:id/remark", h.UpdateAttendanceRemark)
	}

	// ── Protected routes (JWT only) ───────────────────────────────────────────
	api := r.Group("/api")
	api.Use(middleware.JWTAuth())
	{
		// Profile
		api.GET("/profile", h.GetProfile)
		api.PUT("/profile", h.UpdateProfile)
		api.PUT("/profile/password", h.ChangePassword)
		api.POST("/profile/avatar", h.UploadAvatar)
		api.DELETE("/profile/avatar", h.RemoveAvatar)

		// Dashboard
		api.GET("/dashboard/stats", h.GetDashboardStats)

		// Departments (admin write)
		depts := api.Group("/departments")
		depts.Use(middleware.AdminOnly())
		{
			depts.POST("", h.CreateDepartment)
			depts.PUT("/:id", h.UpdateDepartment)
			depts.DELETE("/:id", h.DeleteDepartment)
		}

		// Positions (admin write)
		positions := api.Group("/positions")
		positions.Use(middleware.AdminOnly())
		{
			positions.POST("", h.CreatePosition)
			positions.PUT("/:id", h.UpdatePosition)
			positions.DELETE("/:id", h.DeletePosition)
		}

		// User management (admin only)
		users := api.Group("/users")
		users.Use(middleware.AdminOnly())
		{
			users.GET("", h.ListUsers)
			users.POST("", h.CreateUser)
			users.GET("/:id", h.GetUser)
			users.PUT("/:id", h.UpdateUser)
			users.DELETE("/:id", h.DeleteUser)
		}

		// Activity + interns
		api.GET("/activity", h.GetActivityLogs)
		api.GET("/interns", h.ListInterns)

		// Attendance (intern-facing)
		attendance := api.Group("/attendance")
		{
			attendance.POST("/time-in", h.TimeIn)
			attendance.PATCH("/time-out", h.TimeOut)
			attendance.GET("/summary", h.GetAttendanceSummary)
			attendance.GET("/history", h.GetAttendanceHistory)
			attendance.GET("/weekly", h.GetWeeklyAttendance)

			// Intern reports an issue (Late, Absent, or Missed Clock-Out)
			attendance.POST("/report", h.ReportAttendanceIssue)

			// Legacy missed clock-out endpoint (kept for older clients)
			attendance.POST("/:id/report-missed-clockout", h.ReportMissedClockOut)
		}
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server running on port %s", port)
	r.Run(":" + port)
}
