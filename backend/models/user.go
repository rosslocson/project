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
	gorm.Model
	FirstName   string     `json:"first_name" gorm:"not null"`
	LastName    string     `json:"last_name" gorm:"not null"`
	Email       string     `json:"email" gorm:"uniqueIndex;not null"`
	Password    string     `json:"-" gorm:"not null"`
	Phone       string     `json:"phone"`
	Department  string     `json:"department"`
	Position    string     `json:"position"`
	AvatarURL   string     `json:"avatar_url"`
	Role        Role       `json:"role" gorm:"default:'user'"`
	IsActive    bool       `json:"is_active" gorm:"default:true"`
	LastLoginAt *time.Time `json:"last_login_at"`
	Bio         string     `json:"bio"`
}

type ActivityLog struct {
	gorm.Model
	UserID    uint   `json:"user_id"`
	User      User   `json:"user" gorm:"foreignKey:UserID"`
	Action    string `json:"action"`
	Details   string `json:"details"`
	IPAddress string `json:"ip_address"`
}
