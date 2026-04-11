package services

import (
	"errors"
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
		return nil, "", err
	}

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

func (s *AuthService) Login(email, password string) (*models.User, string, error) {
	user, err := s.userRepo.GetByEmail(email)
	if err != nil {
		return nil, "", errors.New("invalid email or password")
	}

	if !user.IsActive {
		return nil, "", errors.New("account deactivated")
	}

	// Lock check (simplified from handler)
	if user.LockedUntil != nil && time.Now().Before(*user.LockedUntil) {
		return nil, "", errors.New("account locked")
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password)); err != nil {
		// Increment failed count (simplified)
		return nil, "", errors.New("invalid email or password")
	}

	// Reset counters
	user.FailedLoginCount = 0
	user.LockedUntil = nil
	user.LastLoginAt = new(time.Time)
	s.userRepo.Update(user)

	token, err := s.generateToken(user.ID, user.Role)
	return user, token, err
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
