package models

import "time"

type Attendance struct {
	ID            uint       `gorm:"primaryKey;autoIncrement" json:"id"`
	UserID        uint       `gorm:"not null;index"           json:"user_id"`
	Date          time.Time  `gorm:"type:date;not null"       json:"date"`
	TimeIn        *time.Time `gorm:"type:timestamptz"         json:"time_in"`
	TimeOut       *time.Time `gorm:"type:timestamptz"         json:"time_out"`
	HoursRendered *float64   `gorm:"->"                       json:"hours_rendered"`
	IsReported    bool       `gorm:"default:false"            json:"is_reported"`
	ReportedAt    *time.Time `gorm:"type:timestamptz"         json:"reported_at"`
	ReportReason  string     `json:"report_reason"`
	Resolution    *string    `gorm:"type:text"                json:"resolution"` // ← ADD
	AdminNote     *string    `gorm:"type:text"                json:"admin_note"` // ← ADD
	CreatedAt     time.Time  `                                json:"created_at"`
	UpdatedAt     time.Time  `                                json:"updated_at"`

	User *User `gorm:"foreignKey:UserID" json:"-"`
}

func (Attendance) TableName() string {
	return "attendance"
}
