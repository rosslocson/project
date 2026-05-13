package services

import (
	"crypto/rand"
	"errors"
	"log"
	"math/big"
	"os"
	"regexp"
	"strings"
	"sync"
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

// IPLock tracks failed login attempts by IP address to prevent brute-force via random emails
type IPLock struct {
	Attempts    int
	LockedUntil *time.Time
}

var (
	ipTrackerMu sync.Mutex
	ipTracker   = make(map[string]*IPLock)
)

type AuthService struct {
	userRepo *repositories.UserRepository
}

func NewAuthService(userRepo *repositories.UserRepository) *AuthService {
	return &AuthService{userRepo: userRepo}
}

func (s *AuthService) Register(firstName, lastName, email, password, phone, department, position string, role models.Role, requiredOjtHours int) (*models.User, string, error) {
	if role == models.RoleAdmin {
		return nil, "", errors.New("admin role cannot be registered. Contact administrator.")
	}

	if _, err := s.userRepo.GetByEmail(email); err == nil {
		return nil, "", errors.New("email already registered")
	}

	hashed, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		log.Printf("❌ Password hashing failed: %v", err)
		return nil, "", err
	}
	log.Printf("✅ Password hashed successfully for registration - Hash: %.20s...", string(hashed))

	user := &models.User{
		FirstName:        firstName,
		LastName:         lastName,
		Email:            strings.ToLower(email),
		Password:         string(hashed),
		Phone:            phone,
		Department:       department,
		Position:         position,
		Role:             models.RoleUser,
		IsActive:         true,
		RequiredOjtHours: requiredOjtHours,
	}
	if err := s.userRepo.Create(user); err != nil {
		return nil, "", err
	}

	token, err := s.generateToken(user.ID, user.Role)
	return user, token, err
}

type LoginResult struct {
	User           *models.User
	Token          string
	Error          error
	IsLocked       bool
	RetryAfterSecs int
	AttemptsLeft   int
}

func (s *AuthService) Login(email, password, ip string) (*LoginResult, error) {
	result := &LoginResult{
		AttemptsLeft: maxLoginAttempts,
	}

	// SECURE: Generic error message for all failures
	genericErr := errors.New("The email or password you entered is incorrect.")
	// SECURE: Dummy hash to simulate processing time for non-existent users
	dummyHash := []byte("$2a$10$vI8aWBnW3fID.ZQ4/zo1G.q1lRps.9cGLcZEiGDMVr5yUP1KUOYTa")

	// 1. Check IP lock first (prevents bypassing lockout by guessing different/fake emails)
	ipTrackerMu.Lock()
	ipLock, exists := ipTracker[ip]
	if !exists {
		ipLock = &IPLock{}
		ipTracker[ip] = ipLock
	}

	if ipLock.LockedUntil != nil {
		if time.Now().Before(*ipLock.LockedUntil) {
			retryAfter := int(ipLock.LockedUntil.Sub(time.Now()).Seconds())
			ipTrackerMu.Unlock()

			result.IsLocked = true
			result.RetryAfterSecs = retryAfter
			result.AttemptsLeft = 0
			result.Error = errors.New("account temporarily locked")
			return result, result.Error
		} else {
			// Lock expired
			ipLock.Attempts = 0
			ipLock.LockedUntil = nil
		}
	}
	ipTrackerMu.Unlock()

	// 2. Fetch User
	user, err := s.userRepo.GetByEmail(email)
	if err != nil {
		log.Printf("🔍 Login: Email not found, simulating check to prevent timing analysis")
		bcrypt.CompareHashAndPassword(dummyHash, []byte(password))
		return s.handleFailedAttempt(ip, genericErr)
	}

	// 3. User locked check
	if user.LockedUntil != nil && time.Now().Before(*user.LockedUntil) {
		retryAfter := int(user.LockedUntil.Sub(time.Now()).Seconds())
		result.IsLocked = true
		result.RetryAfterSecs = retryAfter
		result.AttemptsLeft = 0
		result.Error = errors.New("account temporarily locked")
		return result, result.Error
	}

	// 4. Validate Account Activity
	if !user.IsActive || user.IsArchived {
		bcrypt.CompareHashAndPassword(dummyHash, []byte(password))
		return s.handleFailedAttempt(ip, genericErr)
	}

	// 5. Verify Password
	passwordTrimmed := strings.TrimSpace(password)
	if !strings.HasPrefix(user.Password, "$2a$") && !strings.HasPrefix(user.Password, "$2b$") {
		bcrypt.CompareHashAndPassword(dummyHash, []byte(passwordTrimmed))
		return s.handleFailedAttempt(ip, genericErr)
	}

	err = bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(passwordTrimmed))
	if err != nil {
		log.Printf("❌ Password mismatch for %s", user.Email)

		// Update database user failed attempts limit alongside IP limit
		user.FailedAttempts++
		if user.FailedAttempts >= maxLoginAttempts {
			lockUntil := time.Now().Add(lockDuration)
			user.LockedUntil = &lockUntil
		}
		s.userRepo.Update(user)

		return s.handleFailedAttempt(ip, genericErr)
	}

	log.Printf("✅ Password verified successfully for %s", user.Email)

	// Clear IP tracker on success
	ipTrackerMu.Lock()
	delete(ipTracker, ip)
	ipTrackerMu.Unlock()

	user.FailedAttempts = 0
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

// handleFailedAttempt centrally processes fail counts and lockouts per IP
func (s *AuthService) handleFailedAttempt(ip string, err error) (*LoginResult, error) {
	ipTrackerMu.Lock()
	defer ipTrackerMu.Unlock()

	lock, exists := ipTracker[ip]
	if !exists {
		lock = &IPLock{}
		ipTracker[ip] = lock
	}

	lock.Attempts++
	attemptsLeft := maxLoginAttempts - lock.Attempts
	if attemptsLeft < 0 {
		attemptsLeft = 0
	}

	result := &LoginResult{
		Error:        err,
		AttemptsLeft: attemptsLeft,
	}

	if lock.Attempts >= maxLoginAttempts {
		t := time.Now().Add(lockDuration)
		lock.LockedUntil = &t
		result.IsLocked = true
		result.RetryAfterSecs = int(lockDuration.Seconds())
		result.Error = errors.New("account temporarily locked")
	}

	return result, result.Error
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

func ValidatePasswordStrength(password string) error {
	if len(password) < 8 {
		return errors.New("password must be at least 8 characters long")
	}
	if !regexp.MustCompile(`[A-Z]`).MatchString(password) {
		return errors.New("password must contain at least one uppercase letter")
	}
	if !regexp.MustCompile(`[0-9]`).MatchString(password) {
		return errors.New("password must contain at least one number")
	}
	if !regexp.MustCompile(`[!@#$%^&*(),.?":{}|<>]`).MatchString(password) {
		return errors.New("password must contain at least one special character")
	}
	return nil
}

func ValidateEmailFormat(email string) error {
	re := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
	if !re.MatchString(email) {
		return errors.New("Invalid email format")
	}
	return nil
}

func GenerateOTP() (string, error) {
	const otpChars = "1234567890"
	otpLength := 6
	otp := make([]byte, otpLength)
	for i := range otp {
		num, err := rand.Int(rand.Reader, big.NewInt(int64(len(otpChars))))
		if err != nil {
			return "", err
		}
		otp[i] = otpChars[num.Int64()]
	}
	return string(otp), nil
}