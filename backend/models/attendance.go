// backend/models/attendance.go

package models

import "time"

type Attendance struct {
	ID            uint       `gorm:"primaryKey;autoIncrement" json:"id"`
	UserID        uint       `gorm:"not null;index"           json:"user_id"`
	Date          time.Time  `gorm:"type:date;not null"       json:"date"`
	TimeIn        *time.Time `gorm:"type:timestamptz"         json:"time_in"`
	TimeOut       *time.Time `gorm:"type:timestamptz"         json:"time_out"`
	HoursRendered *float64   `gorm:"->"                       json:"hours_rendered"` // read-only, computed by DB
	IsReported    bool       `gorm:"default:false"            json:"is_reported"`    // ← NEW
	ReportedAt    *time.Time `gorm:"type:timestamptz"         json:"reported_at"`
	CreatedAt     time.Time  `                                json:"created_at"`
	UpdatedAt     time.Time  `                                json:"updated_at"`

	// Preload association when needed
	User *User `gorm:"foreignKey:UserID" json:"-"`
}

// TableName overrides the table name
func (Attendance) TableName() string {
	return "attendance"
}
