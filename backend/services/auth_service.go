package services

import (
	"errors"
	"log"
	"os"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"

	"project/backend/models"
	"project/backend/repositories"
)

const (
	maxLoginAttempts = 3
	lockDuration     = 1 * time.Minute
)

type AuthService struct {
	userRepo *repositories.UserRepository
}

func NewAuthService(userRepo *repositories.UserRepository) *AuthService {
	return &AuthService{userRepo: userRepo}
}

func (s *AuthService) Register(firstName, lastName, email, password, phone, department, position string, role models.Role) (*models.User, string, error) {
	// Reject admin registration
	if role == models.RoleAdmin {
		return nil, "", errors.New("admin role cannot be registered. Contact administrator.")
	}

	// Check existing email
	if _, err := s.userRepo.GetByEmail(email); err == nil {
		return nil, "", errors.New("email already registered")
	}

	// Hash password
	hashed, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		log.Printf("❌ Password hashing failed: %v", err)
		return nil, "", err
	}
	log.Printf("✅ Password hashed successfully for registration - Hash: %.20s...", string(hashed))

	user := &models.User{
		FirstName:  firstName,
		LastName:   lastName,
		Email:      strings.ToLower(email),
		Password:   string(hashed),
		Phone:      phone,
		Department: department,
		Position:   position,
		Role:       models.RoleUser, // Force user role
		IsActive:   true,
	}
	if err := s.userRepo.Create(user); err != nil {
		return nil, "", err
	}

	token, err := s.generateToken(user.ID, user.Role)
	return user, token, err
}

// LoginResult contains the outcome of a login attempt
type LoginResult struct {
	User           *models.User
	Token          string
	Error          error
	IsLocked       bool
	RetryAfterSecs int
	AttemptsLeft   int
}

func (s *AuthService) Login(email, password string) (*LoginResult, error) {
	result := &LoginResult{
		AttemptsLeft: maxLoginAttempts,
	}

	user, err := s.userRepo.GetByEmail(email)
	if err != nil {
		log.Printf("🔍 Login: Email '%s' not found in database", email)
		result.Error = errors.New("invalid email or password")
		return result, result.Error
	}

	log.Printf("🔍 Login: User found - Email: %s, Role: %s, Active: %v", user.Email, user.Role, user.IsActive)
	log.Printf("🔍 Failed login count: %d", user.FailedLoginCount)

	if !user.IsActive {
		log.Printf("⚠️ Login failed: Account is deactivated for %s", email)
		result.Error = errors.New("account deactivated")
		return result, result.Error
	}

	// Check if account is locked
	if user.LockedUntil != nil && time.Now().Before(*user.LockedUntil) {
		retryAfter := int(user.LockedUntil.Sub(time.Now()).Seconds())
		log.Printf("🔒 Account locked for %s. Retry after %d seconds", email, retryAfter)
		result.IsLocked = true
		result.RetryAfterSecs = retryAfter
		result.Error = errors.New("account temporarily locked due to failed login attempts")
		return result, result.Error
	}

	// Clear lock if expired
	if user.LockedUntil != nil && time.Now().After(*user.LockedUntil) {
		log.Printf("🔓 Lock expired for %s, resetting counters", email)
		user.FailedLoginCount = 0
		user.LockedUntil = nil
		s.userRepo.Update(user)
	}

	// Check if password is bcrypt hash (starts with $2a$ or $2b$)
	passwordTrimmed := strings.TrimSpace(password)
	if !strings.HasPrefix(user.Password, "$2a$") && !strings.HasPrefix(user.Password, "$2b$") {
		hashPreview := user.Password
		if len(hashPreview) > 20 {
			hashPreview = hashPreview[:20]
		}
		log.Printf("❌ CRITICAL: Password in DB for %s is NOT bcrypt hashed! First 20 chars: %s", user.Email, hashPreview)
		result.Error = errors.New("invalid email or password")
		return result, result.Error
	}

	// Verify password
	err = bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(passwordTrimmed))
	if err != nil {
		log.Printf("❌ Password mismatch for %s", user.Email)

		// Increment failed login count
		user.FailedLoginCount++
		result.AttemptsLeft = maxLoginAttempts - user.FailedLoginCount
		log.Printf("⚠️ Failed login attempt %d/%d for %s", user.FailedLoginCount, maxLoginAttempts, user.Email)

		// Lock account if max attempts reached
		if user.FailedLoginCount >= maxLoginAttempts {
			lockUntil := time.Now().Add(lockDuration)
			user.LockedUntil = &lockUntil
			log.Printf("🔒 Account locked for %s until %v (max attempts reached)", email, lockUntil)
			result.IsLocked = true
			result.RetryAfterSecs = int(lockDuration.Seconds())
		}

		// Update user with new failed count
		s.userRepo.Update(user)

		result.Error = errors.New("invalid email or password")
		return result, result.Error
	}

	log.Printf("✅ Password verified successfully for %s", user.Email)

	// Reset counters on successful login
	user.FailedLoginCount = 0
	user.LockedUntil = nil
	now := time.Now()
	user.LastLoginAt = &now
	s.userRepo.Update(user)

	token, err := s.generateToken(user.ID, user.Role)
	if err != nil {
		result.Error = err
		return result, err
	}

	result.User = user
	result.Token = token
	result.Error = nil
	return result, nil
}

func (s *AuthService) generateToken(userID uint, role models.Role) (string, error) {
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
