package models

import (
	"database/sql/driver"
	"encoding/json"
	"strings"
	"time"

	"gorm.io/gorm"
)

type Role string

const dateLayout = "2006-01-02"

type Date struct {
	time.Time
}

func (d *Date) UnmarshalJSON(b []byte) error {
	s := strings.Trim(string(b), `"`)
	if s == "" || strings.EqualFold(s, "null") {
		d.Time = time.Time{}
		return nil
	}
	parsed, err := time.Parse(dateLayout, s)
	if err != nil {
		return err
	}
	d.Time = parsed
	return nil
}

func (d Date) MarshalJSON() ([]byte, error) {
	if d.Time.IsZero() {
		return []byte("null"), nil
	}
	return json.Marshal(d.Time.Format(dateLayout))
}

func (d *Date) Value() (driver.Value, error) {
	if d == nil || d.Time.IsZero() {
		return nil, nil
	}
	return d.Time, nil
}

func (d *Date) Scan(value interface{}) error {
	// Never fail scans due to legacy/dirty data. Any invalid/empty date becomes NULL.
	if value == nil {
		d.Time = time.Time{}
		return nil
	}

	switch v := value.(type) {
	case time.Time:
		if v.IsZero() {
			d.Time = time.Time{}
			return nil
		}
		d.Time = v
		return nil
	case []byte:
		s := strings.TrimSpace(string(v))
		if s == "" {
			d.Time = time.Time{}
			return nil
		}
		parsed, err := time.Parse(dateLayout, s)
		if err != nil {
			// Dirty/legacy value: treat as NULL.
			d.Time = time.Time{}
			return nil
		}
		d.Time = parsed
		return nil
	case string:
		s := strings.TrimSpace(v)
		if s == "" {
			d.Time = time.Time{}
			return nil
		}
		parsed, err := time.Parse(dateLayout, s)
		if err != nil {
			// Dirty/legacy value: treat as NULL.
			d.Time = time.Time{}
			return nil
		}
		d.Time = parsed
		return nil
	default:
		// Unknown type: treat as NULL.
		d.Time = time.Time{}
		return nil
	}
}

func (d Date) String() string {
	if d.Time.IsZero() {
		return ""
	}
	return d.Time.Format(dateLayout)
}

const (
	RoleAdmin Role = "admin"
	RoleUser  Role = "user"
)

type User struct {
	ID uint `json:"id"         gorm:"primarykey;autoIncrement"`

	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `json:"-"          gorm:"index"`

	FirstName       string     `json:"first_name"         gorm:"not null"`
	LastName        string     `json:"last_name"          gorm:"not null"`
	Email           string     `json:"email"              gorm:"uniqueIndex;not null"`
	Password        string     `json:"-"                  gorm:"not null"`
	Phone           string     `json:"phone"`
	Department      string     `json:"department"`
	Position        string     `json:"position"`
	AvatarURL       string     `json:"avatar_url"`
	Role            Role       `json:"role"               gorm:"default:'user'"`
	IsActive        bool       `json:"is_active"          gorm:"default:true"`
	IsArchived      bool       `json:"is_archived"        gorm:"default:false"`
	IsVerified      bool       `json:"is_verified"        gorm:"default:false"`
	EmailVerifiedAt *time.Time `json:"email_verified_at"  gorm:"column:email_verified_at"`
	LegacyAccount   bool       `json:"legacy_account"     gorm:"default:false"`
	LastLoginAt     *time.Time `json:"last_login_at"`
	Bio             string     `json:"bio"`

	// --- NEW SECURITY FIELDS ---
	FailedAttempts int        `json:"failed_attempts"    gorm:"default:0"`
	LockedUntil    *time.Time `json:"locked_until"`

	// Password reset (OTP)
	// NOTE: schema.sql uses reset_token/reset_token_expiry
	ResetOTP       string     `json:"-" gorm:"column:reset_token"`
	ResetOTPExpiry *time.Time `json:"-" gorm:"column:reset_token_expiry"`

	// Registration email verification (OTP)
	VerificationOTP       string     `json:"-" gorm:"column:verification_token"`
	VerificationOTPExpiry *time.Time `json:"-" gorm:"column:verification_token_expiry"`

	RequiredOjtHours int `gorm:"default:400"        json:"required_ojt_hours"`

	School           string `json:"school"`
	Program          string `json:"program"`
	Specialization   string `json:"specialization"`
	YearLevel        string `json:"year_level"`
	InternNumber     string `json:"intern_number"`
	StartDate        *Date  `json:"start_date" gorm:"type:date"`
	EndDate          *Date  `json:"end_date" gorm:"type:date"`
	EstimatedEndDate string `json:"estimated_end_date" gorm:"-"`
	TechnicalSkills  string `json:"technical_skills"`
	SoftSkills       string `json:"soft_skills"`
	LinkedIn         string `json:"linked_in"`
	GitHub           string `json:"git_hub"`
}

type ActivityLog struct {
	ID        uint           `json:"id"         gorm:"primarykey;autoIncrement"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `json:"-"          gorm:"index"`

	UserID    uint   `json:"user_id"`
	User      User   `json:"user"       gorm:"foreignKey:UserID"`
	Action    string `json:"action"`
	Details   string `json:"details"`
	IPAddress string `json:"ip_address"`
}

// Department — stored in its own table
type Department struct {
	ID        uint           `json:"id"         gorm:"primarykey;autoIncrement"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `json:"-"          gorm:"index"`

	Name      string     `json:"name"       gorm:"unique;not null"`
	Positions []Position `json:"positions"  gorm:"foreignKey:DepartmentID"`
}

// Position — stored in its own table
type Position struct {
	ID        uint           `json:"id"           gorm:"primarykey;autoIncrement"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `json:"-"            gorm:"index"`

	DepartmentID uint        `json:"department_id" gorm:"not null"`
	Name         string      `json:"name"          gorm:"not null"`
	Department   *Department `json:"department,omitempty" gorm:"foreignKey:DepartmentID"`
}
