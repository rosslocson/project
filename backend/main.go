package main

import (
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"

	"project/backend/handlers"
	"project/backend/middleware"
	"project/backend/models"
)

var DB *gorm.DB

func main() {
	// Load environment variables
	godotenv.Load()

	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		dsn = "host=localhost user=postgres password=postgres dbname=userapp port=5432 sslmode=disable"
	}

	var err error
	DB, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	// Auto migrate models
	DB.AutoMigrate(&models.User{}, &models.ActivityLog{}, &models.Department{}, &models.Position{})

	log.Println("Database migrated successfully")

	// Init handlers with DB
	h := handlers.NewHandler(DB)

	r := gin.Default()

	// CORS config - allows Flutter web app to call the API
	// CORS: AllowAllOrigins must be used instead of AllowOrigins["*"]
	// when AllowCredentials is true — otherwise browsers block DELETE/PUT with Auth headers
	r.Use(cors.New(cors.Config{
		AllowAllOrigins:  true,
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization", "Accept"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: false,
		MaxAge:           12 * time.Hour,
	}))

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok", "time": time.Now()})
	})

	// Public routes
	auth := r.Group("/api/auth")
	{
		auth.POST("/register", h.Register)
		auth.POST("/login", h.Login)
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
