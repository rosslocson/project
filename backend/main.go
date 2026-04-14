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

// seedAdminAccount creates a default admin account if it doesn't exist, or updates password if it does
func seedAdminAccount(db *gorm.DB) {
	adminEmail := "admin@example.com"
	adminPassword := "admin123"

	// Hash the admin password using bcrypt
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(adminPassword), bcrypt.DefaultCost)
	if err != nil {
		log.Printf("❌ Failed to hash admin password: %v", err)
		return
	}

	// Check if admin already exists
	var existingAdmin models.User
	if err := db.Where("email = ?", adminEmail).First(&existingAdmin).Error; err == nil {
		// Admin exists - check if password is properly hashed
		if !strings.HasPrefix(existingAdmin.Password, "$2a$") && !strings.HasPrefix(existingAdmin.Password, "$2b$") {
			log.Printf("⚠️ Admin account found but password is NOT bcrypt hashed. Updating with proper hash...")
			if err := db.Model(&existingAdmin).Update("password", string(hashedPassword)).Error; err != nil {
				log.Printf("❌ Failed to update admin password: %v", err)
				return
			}
			log.Println("✅ Admin account password updated to bcrypt hash")
		} else {
			log.Println("✅ Admin account already exists with proper bcrypt password")
		}
		return
	}

	// Create admin user
	adminUser := models.User{
		FirstName: "Admin",
		LastName:  "User",
		Email:     adminEmail,
		Password:  string(hashedPassword),
		Role:      models.RoleAdmin,
		IsActive:  true,
	}

	if err := db.Create(&adminUser).Error; err != nil {
		log.Printf("⚠️ Failed to create admin account: %v", err)
		return
	}

	log.Println("✅ Admin account created successfully")
	log.Println("📧 Email: admin@example.com")
	log.Println("🔑 Password: admin123")
}

// fixPlaintextPasswords finds all users with plaintext passwords and hashes them
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
		// Skip if already bcrypt hashed
		if strings.HasPrefix(user.Password, "$2a$") || strings.HasPrefix(user.Password, "$2b$") {
			continue
		}

		// Skip if password is empty
		if strings.TrimSpace(user.Password) == "" {
			log.Printf("⚠️ User %s (%s) has empty password", user.FirstName, user.Email)
			continue
		}

		log.Printf("🔧 Hashing plaintext password for user %s (%s)...", user.FirstName, user.Email)

		// Hash the plaintext password
		hashedPassword, err := bcrypt.GenerateFromPassword([]byte(user.Password), bcrypt.DefaultCost)
		if err != nil {
			log.Printf("❌ Failed to hash password for user %s: %v", user.Email, err)
			continue
		}

		// Update the user with the hashed password
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
	// Load environment variables
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

	// Auto migrate models
	DB.AutoMigrate(&models.User{}, &models.ActivityLog{}, &models.Department{}, &models.Position{})

	log.Println("Database migrated successfully")

	// Seed database with admin account
	seedAdminAccount(DB)

	//  Fix any users with plaintext passwords
	fixPlaintextPasswords(DB)

	// Init handlers with DB
	h := handlers.NewHandler(DB)

	r := gin.Default()

	// Set max multipart memory (32MB)
	r.MaxMultipartMemory = 32 << 20

	// CORS config - allows Flutter web app to call the API
	// CORS: AllowAllOrigins must be used instead of AllowOrigins["*"]
	// when AllowCredentials is true — otherwise browsers block DELETE/PUT with Auth headers
	r.Use(cors.New(cors.Config{
		AllowAllOrigins:  true,
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Content-Length", "Accept-Encoding", "Authorization", "Accept"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: false,
		MaxAge:           12 * time.Hour,
	}))

	// Serve uploaded files statically
	r.Static("/uploads", "./uploads")

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok", "time": time.Now()})
	})

	// Simple data endpoint
	r.GET("/api/data", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "success", "message": "Connected to Go Backend!"})
	})

	// Public routes
	auth := r.Group("/api/auth")
	{
		auth.POST("/register", h.Register)
		auth.POST("/login", h.Login)

		// Admin dashboard example (RBAC demo)
		admin := r.Group("/api/admin")
		admin.Use(middleware.JWTAuth(), middleware.AdminOnly())
		{
			admin.GET("/dashboard", h.AdminDashboard)
		}
		auth.POST("/forgot-password", h.ForgotPassword)
		auth.POST("/reset-password", h.ResetPassword)
	}

	// Protected routes
	api := r.Group("/api")
	api.Use(middleware.JWTAuth())
	{
		// User profile
		api.GET("/profile", h.GetProfile)
		api.PUT("/profile", h.UpdateProfile)
		api.PUT("/profile/password", h.ChangePassword)
		api.POST("/profile/avatar", h.UploadAvatar)

		// Dashboard stats
		api.GET("/dashboard/stats", h.GetDashboardStats)

		// Departments — public read, admin write/edit/delete
		api.GET("/departments", h.ListDepartments)
		depts := api.Group("/departments")
		depts.Use(middleware.AdminOnly())
		{
			depts.POST("", h.CreateDepartment)
			depts.PUT("/:id", h.UpdateDepartment)
			depts.DELETE("/:id", h.DeleteDepartment)
		}

		// Positions — public read, admin write/edit/delete
		api.GET("/positions", h.ListPositions)
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

		// Activity logs
		api.GET("/activity", h.GetActivityLogs)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server running on port %s", port)
	r.Run(":" + port)
}
