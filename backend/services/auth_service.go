package services

import (
	"crypto/rand"
	"errors"
	"fmt"
	"log"
	"math/big"
	"os"
	"regexp"
	"strings"
	"sync"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"

	"project/backend/email"
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

// PendingRegistration stores temporary registration data during OTP verification
type PendingRegistration struct {
	FirstName        string
	LastName         string
	Email            string
	HashedPassword   string
	Phone            string
	Department       string
	Position         string
	Role             models.Role
	IsActive         bool
	RequiredOjtHours int
	OTP              string
	OTPExpiry        time.Time
	CreatedAt        time.Time
}

var (
	pendingRegMu      sync.RWMutex
	pendingReg        = make(map[string]*PendingRegistration) // keyed by email
	lastResendAttempt = make(map[string]time.Time)            // rate limiting for resend
	lastResendMu      sync.RWMutex                            // mutex for lastResendAttempt
)

const resendCooldownSeconds = 60

type AuthService struct {
	userRepo *repositories.UserRepository
}

func NewAuthService(userRepo *repositories.UserRepository) *AuthService {
	return &AuthService{userRepo: userRepo}
}

func (s *AuthService) Register(firstName, lastName, rawEmail, password, phone, department, position string, role models.Role, requiredOjtHours int) (*models.User, string, error) {
	if role == models.RoleAdmin {
		return nil, "", errors.New("admin role cannot be registered. Contact administrator.")
	}

	// Normalize email for consistent uniqueness checks.
	normalizedEmail := strings.ToLower(strings.TrimSpace(rawEmail))

	// Block any already-registered email from re-registering.
	_, err := s.userRepo.GetByEmail(normalizedEmail)
	if err == nil {
		return nil, "", errors.New("email already in use")
	}
	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, "", err
	}

	// Hash password
	hashed, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		log.Printf("❌ Password hashing failed: %v", err)
		return nil, "", err
	}
	log.Printf("✅ Password hashed successfully for registration")

	// Generate OTP
	otp, err := GenerateOTP()
	if err != nil {
		log.Printf("❌ Failed to generate OTP: %v", err)
		return nil, "", err
	}

	// Store pending registration (overwrite if re-registering)
	pendingRegMu.Lock()
	pendingReg[normalizedEmail] = &PendingRegistration{
		FirstName:        firstName,
		LastName:         lastName,
		Email:            normalizedEmail,
		HashedPassword:   string(hashed),
		Phone:            phone,
		Department:       department,
		Position:         position,
		Role:             role,
		IsActive:         true,
		RequiredOjtHours: requiredOjtHours,
		OTP:              otp,
		OTPExpiry:        time.Now().Add(5 * time.Minute),
		CreatedAt:        time.Now(),
	}
	pendingRegMu.Unlock()

	log.Printf("📝 Pending registration stored for %s, OTP: %s (5 min expiry)", normalizedEmail, otp)

	// Send OTP email
	if err := email.SendRegistrationEmail(normalizedEmail, otp); err != nil {
		log.Printf("⚠️ Failed to send registration email to %s: %v", normalizedEmail, err)
		// Don't fail the request - let user try to resend
		return nil, "", errors.New("could not send OTP email. Please try again or contact support")
	}

	log.Printf("✅ Registration OTP email sent to %s", normalizedEmail)

	// Return success WITHOUT user or token - verification is required first
	return nil, "", nil
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

	// 4b. Enforce email verification for modern accounts only.
	if !user.IsVerified && !user.LegacyAccount {
		loginErr := errors.New("Please verify your email first")
		return &LoginResult{
			Error:        loginErr,
			AttemptsLeft: maxLoginAttempts,
		}, loginErr
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

// VerifyRegistrationOTP verifies the OTP and creates the user account
func (s *AuthService) VerifyRegistrationOTP(otp string) (*models.User, string, error) {
	otp = strings.TrimSpace(otp)

	pendingRegMu.RLock()
	var email string
	var pending *PendingRegistration
	for e, p := range pendingReg {
		if p.OTP == otp {
			email = e
			pending = p
			break
		}
	}
	pendingRegMu.RUnlock()

	if pending == nil {
		log.Printf("❌ Invalid OTP verification attempt: %s", otp)
		return nil, "", errors.New("Invalid or expired OTP")
	}

	// Check if OTP has expired
	if time.Now().After(pending.OTPExpiry) {
		log.Printf("⚠️ OTP expired for %s", email)
		pendingRegMu.Lock()
		delete(pendingReg, email)
		pendingRegMu.Unlock()
		return nil, "", errors.New("OTP has expired. Please register again")
	}

	// Create the user account now
	verifiedAt := time.Now()
	user := &models.User{
		FirstName:        pending.FirstName,
		LastName:         pending.LastName,
		Email:            email,
		Password:         pending.HashedPassword,
		Phone:            pending.Phone,
		Department:       pending.Department,
		Position:         pending.Position,
		Role:             models.RoleUser,
		IsActive:         pending.IsActive,
		IsVerified:       true, // Mark as verified since OTP was verified
		LegacyAccount:    false,
		EmailVerifiedAt:  &verifiedAt,
		RequiredOjtHours: pending.RequiredOjtHours,
	}

	if err := s.userRepo.Create(user); err != nil {
		// If duplicate constraint, user might have registered in parallel
		if strings.Contains(err.Error(), "duplicate") || strings.Contains(err.Error(), "23505") {
			log.Printf("⚠️ Email already registered during verification: %s", email)
			return nil, "", errors.New("This email has already been registered")
		}
		log.Printf("❌ Failed to create user: %v", err)
		return nil, "", errors.New("Failed to create account. Please try again")
	}

	log.Printf("✅ User account created and verified for %s", email)

	// Clear pending registration
	pendingRegMu.Lock()
	delete(pendingReg, email)
	pendingRegMu.Unlock()

	// Generate token
	token, err := s.generateToken(user.ID, user.Role)
	if err != nil {
		log.Printf("❌ Failed to generate token: %v", err)
		return nil, "", err
	}

	return user, token, nil
}

// ResendRegistrationOTP generates and sends a new OTP for registration
func (s *AuthService) ResendRegistrationOTP(emailAddr string) error {
	emailAddr = strings.ToLower(strings.TrimSpace(emailAddr))

	// Check rate limit
	lastResendMu.RLock()
	lastAttempt, exists := lastResendAttempt[emailAddr]
	lastResendMu.RUnlock()

	if exists && time.Since(lastAttempt) < time.Duration(resendCooldownSeconds)*time.Second {
		elapsed := time.Since(lastAttempt).Seconds()
		retryAfter := resendCooldownSeconds - int(elapsed)
		log.Printf("⚠️ Rate limited resend for %s. Retry after %d seconds", emailAddr, retryAfter)
		return fmt.Errorf("Please wait %d seconds before requesting a new code", retryAfter)
	}

	// Check if there's a pending registration
	pendingRegMu.RLock()
	pending, exists := pendingReg[emailAddr]
	pendingRegMu.RUnlock()

	if !exists {
		// Generic response to prevent email enumeration
		log.Printf("⚠️ Resend OTP attempt for non-existent pending email: %s", emailAddr)
		return nil // Return success to prevent enumeration
	}

	// Generate new OTP
	otp, err := GenerateOTP()
	if err != nil {
		log.Printf("❌ Failed to generate OTP: %v", err)
		return errors.New("Could not generate OTP. Please try again")
	}

	// Update pending registration with new OTP
	pendingRegMu.Lock()
	pending.OTP = otp
	pending.OTPExpiry = time.Now().Add(5 * time.Minute)
	pendingReg[emailAddr] = pending
	pendingRegMu.Unlock()

	// Send OTP email using email package SendRegistrationEmail function
	if err := email.SendRegistrationEmail(emailAddr, otp); err != nil {
		log.Printf("⚠️ Failed to send resend OTP email to %s: %v", emailAddr, err)
		return errors.New("Could not send OTP email. Please try again")
	}

	// Update last resend attempt
	lastResendMu.Lock()
	lastResendAttempt[emailAddr] = time.Now()
	lastResendMu.Unlock()

	log.Printf("✅ Resent registration OTP to %s", emailAddr)
	return nil
}
