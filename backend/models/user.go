package models

import (
	"time"

	"gorm.io/gorm"
)

type Role string

const (
	RoleAdmin Role = "admin"
	RoleUser  Role = "user"
)

type User struct {
	ID        uint           `json:"id"         gorm:"primarykey;autoIncrement"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `json:"-"          gorm:"index"`

	FirstName   string     `json:"first_name"         gorm:"not null"`
	LastName    string     `json:"last_name"          gorm:"not null"`
	Email       string     `json:"email"              gorm:"uniqueIndex;not null"`
	Password    string     `json:"-"                  gorm:"not null"`
	Phone       string     `json:"phone"`
	Department  string     `json:"department"`
	Position    string     `json:"position"`
	AvatarURL   string     `json:"avatar_url"`
	Role        Role       `json:"role"               gorm:"default:'user'"`
	IsActive    bool       `json:"is_active"          gorm:"default:true"`
	IsArchived  bool       `json:"is_archived"        gorm:"default:false"`
	LastLoginAt *time.Time `json:"last_login_at"`
	Bio         string     `json:"bio"`

	// --- NEW SECURITY FIELDS ---
	FailedAttempts int        `json:"failed_attempts"    gorm:"default:0"`
	LockedUntil    *time.Time `json:"locked_until"`
	ResetOTP       string     `json:"-"`
	ResetOTPExpiry *time.Time `json:"-"`

	RequiredOjtHours int    `gorm:"default:400"        json:"required_ojt_hours"`
	School           string `json:"school"`
	Program          string `json:"program"`
	Specialization   string `json:"specialization"`
	YearLevel        string `json:"year_level"`
	InternNumber     string `json:"intern_number"`
	StartDate        string `json:"start_date"`
	EndDate          string `json:"end_date"`
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
