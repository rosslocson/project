// backend/handlers/report_attendance.go
//
// POST /api/attendance/report
//
// Unified report endpoint for Late, Absent, and Missed Clock Out.
// Unlike the old ReportMissedClockOut (which required an existing row),
// this endpoint upserts the attendance row so an Absent day — which has
// no row at all — can also be reported.
//
// Body (JSON):
//   user_id     uint   – injected from JWT; ignored if also in body
//   date        string – "YYYY-MM-DD"
//   report_type string – "late" | "absent" | "missed_clock_out"
//   reason      string – free-text explanation (required)
//
// Response:
//   { "ok": true, "record_id": <uint> }

package handlers

import (
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"project/backend/models"
)

// validReportTypes is the allow-list for report_type values.
var validReportTypes = map[string]bool{
	"late":             true,
	"absent":           true,
	"missed_clock_out": true,
}

// POST /api/attendance/report
func (h *Handler) ReportAttendanceIssue(c *gin.Context) {
	userID, ok := getUserIDFromCtx(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"ok": false, "error": "Unauthorized"})
		return
	}

	var body struct {
		Date       string `json:"date"        binding:"required"`
		ReportType string `json:"report_type" binding:"required"`
		Reason     string `json:"reason"      binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "date, report_type and reason are required"})
		return
	}

	// ── Validate report_type ─────────────────────────────────────────────────
	body.ReportType = strings.ToLower(strings.TrimSpace(body.ReportType))
	if !validReportTypes[body.ReportType] {
		c.JSON(http.StatusBadRequest, gin.H{
			"ok":    false,
			"error": "report_type must be one of: late, absent, missed_clock_out",
		})
		return
	}

	// ── Validate & parse date ────────────────────────────────────────────────
	body.Date = strings.TrimSpace(body.Date)
	reportDate, err := time.ParseInLocation("2006-01-02", body.Date, manilaLoc())
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "date must be YYYY-MM-DD"})
		return
	}

	// Prevent reporting future dates.
	today := time.Now().In(manilaLoc())
	todayMidnight := time.Date(today.Year(), today.Month(), today.Day(), 0, 0, 0, 0, manilaLoc())
	if reportDate.After(todayMidnight) {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "Cannot report a future date"})
		return
	}

	// ── Validate reason ──────────────────────────────────────────────────────
	reason := strings.TrimSpace(body.Reason)
	if len(reason) < 5 {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "Please provide a reason (at least 5 characters)"})
		return
	}
	if len(reason) > 500 {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "Reason must be 500 characters or fewer"})
		return
	}

	// ── Look up or create the attendance row ─────────────────────────────────
	// Absent reports have no existing row, so we upsert.
	var rec models.Attendance

	// Try to find an existing row for this user + date.
	findErr := h.DB.
		Where("user_id = ? AND date = ?", userID, reportDate).
		First(&rec).Error

	now := time.Now().In(manilaLoc())

	if findErr != nil {
		// No row exists (typical for Absent). Create a bare skeleton row so the
		// report has something to attach to. The admin can later mark_present or
		// excuse it via ResolveAttendanceIssue.
		if body.ReportType != "absent" {
			// For Late / Missed-Clock-Out the row must already exist
			// (the intern had to clock in first).
			c.JSON(http.StatusNotFound, gin.H{
				"ok":    false,
				"error": "No attendance record found for that date. Did you clock in?",
			})
			return
		}

		rec = models.Attendance{
			UserID:      userID,
			Date:        reportDate,
			IsReported:  true,
			ReportedAt:  &now,
			ReportType:  body.ReportType,
			ReportReason: reason,
		}
		if err := h.DB.Create(&rec).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"ok": false, "error": "Failed to create report"})
			return
		}
	} else {
		// Row exists — guard against duplicate reports.
		if rec.IsReported {
			c.JSON(http.StatusConflict, gin.H{"ok": false, "error": "A report has already been submitted for this record"})
			return
		}

		// Guard: for "late" the record must have a time_in and time_out
		// (so the status really is Late, not On Shift).
		if body.ReportType == "late" && rec.TimeIn == nil {
			c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "Cannot report Late: no clock-in on record"})
			return
		}

		// Guard: for "missed_clock_out" the record must have time_in but no time_out.
		if body.ReportType == "missed_clock_out" && (rec.TimeIn == nil || rec.TimeOut != nil) {
			c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "Record is not in Missed Clock-Out status"})
			return
		}

		// Apply the report fields.
		updates := map[string]interface{}{
			"is_reported":   true,
			"reported_at":   now,
			"report_reason": reason,
			"report_type":   body.ReportType,
		}
		if err := h.DB.Model(&rec).Updates(updates).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"ok": false, "error": "Failed to save report"})
			return
		}
	}

	// ── Activity log ─────────────────────────────────────────────────────────
	h.logActivity(
		userID,
		"REPORT_ATTENDANCE",
		fmt.Sprintf("Intern reported %s for attendance record #%d (%s)", body.ReportType, rec.ID, body.Date),
		c.ClientIP(),
	)

	c.JSON(http.StatusOK, gin.H{
		"ok":        true,
		"record_id": rec.ID,
	})
}