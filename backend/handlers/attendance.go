// backend/handlers/attendance.go

package handlers

import (
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"project/backend/models"
)

const attendanceHoursExpr = `
	CASE
		WHEN time_in IS NOT NULL AND time_out IS NOT NULL
			THEN EXTRACT(EPOCH FROM (time_out - time_in)) / 3600.0
		ELSE NULL
	END
`

const attendanceSelectWithHours = `
	id,
	user_id,
	date,
	time_in,
	time_out,
	is_reported,
	reported_at,
	report_reason,
	report_type,
	resolution,
	admin_note,
	status,
	is_absent,
	` + attendanceHoursExpr + ` AS hours_rendered,
	created_at,
	updated_at
`

// ── helpers ──────────────────────────────────────────────────────────────────

func todayDate() time.Time {
	now := time.Now()
	return time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
}

func getUserIDFromCtx(c *gin.Context) (uint, bool) {
	raw, exists := c.Get("user_id")
	if !exists {
		return 0, false
	}
	switch v := raw.(type) {
	case uint:
		return v, true
	case float64:
		return uint(v), true
	case int:
		return uint(v), true
	case string:
		id, err := strconv.ParseUint(v, 10, 64)
		if err != nil {
			return 0, false
		}
		return uint(id), true
	}
	return 0, false
}

func (h *Handler) refreshAttendance(id uint) (*models.Attendance, error) {
	var rec models.Attendance
	err := h.DB.
		Select(attendanceSelectWithHours).
		First(&rec, id).Error
	return &rec, err
}

// ── POST /api/attendance/time-in ─────────────────────────────────────────────

func (h *Handler) TimeIn(c *gin.Context) {
	userID, ok := getUserIDFromCtx(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"ok": false, "error": "Unauthorized"})
		return
	}

	today := todayDate()
	now := time.Now().UTC()

	rec := models.Attendance{
		UserID: userID,
		Date:   today,
		TimeIn: &now,
	}

	result := h.DB.
		Where(models.Attendance{UserID: userID, Date: today}).
		Attrs(models.Attendance{TimeIn: &now}).
		FirstOrCreate(&rec)

	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"ok": false, "error": result.Error.Error()})
		return
	}

	if result.RowsAffected == 0 {
		c.JSON(http.StatusConflict, gin.H{"ok": false, "error": "Already timed in today"})
		return
	}

	fresh, err := h.refreshAttendance(rec.ID)
	if err != nil {
		c.JSON(http.StatusOK, gin.H{"ok": true, "record": rec})
		return
	}
	c.JSON(http.StatusOK, gin.H{"ok": true, "record": fresh})
}

// ── PATCH /api/attendance/time-out ───────────────────────────────────────────

func (h *Handler) TimeOut(c *gin.Context) {
	userID, ok := getUserIDFromCtx(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"ok": false, "error": "Unauthorized"})
		return
	}

	today := todayDate()
	now := time.Now().UTC()

	var rec models.Attendance
	err := h.DB.
		Where("user_id = ? AND date = ? AND time_in IS NOT NULL AND time_out IS NULL", userID, today).
		First(&rec).Error

	if err == gorm.ErrRecordNotFound {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "No active time-in found for today"})
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"ok": false, "error": err.Error()})
		return
	}

	if err := h.DB.Model(&rec).Update("time_out", now).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"ok": false, "error": err.Error()})
		return
	}

	fresh, err := h.refreshAttendance(rec.ID)
	if err != nil {
		c.JSON(http.StatusOK, gin.H{"ok": true, "record": rec})
		return
	}
	c.JSON(http.StatusOK, gin.H{"ok": true, "record": fresh})
}

// ── GET /api/attendance/summary ──────────────────────────────────────────────

func (h *Handler) GetAttendanceSummary(c *gin.Context) {
	userID, ok := getUserIDFromCtx(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"ok": false, "error": "Unauthorized"})
		return
	}

	var user models.User
	h.DB.Select("start_date, required_ojt_hours").First(&user, userID)
	requiredHours := 400.0
	if user.RequiredOjtHours > 0 {
		requiredHours = float64(user.RequiredOjtHours)
	}

	type SummaryRaw struct {
		Date    string  `gorm:"column:date"`
		TimeIn  *string `gorm:"column:time_in"`
		TimeOut *string `gorm:"column:time_out"`
	}
	var summaryRaws []SummaryRaw
	h.DB.Raw(`
		SELECT
			TO_CHAR(date, 'YYYY-MM-DD') AS date,
			TO_CHAR(time_in  AT TIME ZONE 'Asia/Manila', 'HH12:MI AM') AS time_in,
			TO_CHAR(time_out AT TIME ZONE 'Asia/Manila', 'HH12:MI AM') AS time_out
		FROM attendance
		WHERE user_id = ?
	`, userID).Scan(&summaryRaws)

	var totalHours float64
	var totalDays int
	for _, r := range summaryRaws {
		if hrs := computeHours(r.TimeIn, r.TimeOut, r.Date); hrs != nil {
			totalHours += *hrs
			totalDays++
		}
	}

	today := todayDate()
	var todayRec *models.Attendance
	var t models.Attendance
	err := h.DB.
		Select(attendanceSelectWithHours).
		Where("user_id = ? AND date = ?", userID, today).
		First(&t).Error
	if err == nil {
		todayRec = &t
	}

	// Expose OJT completion flag so the dashboard can react immediately.
	isCompleted := totalHours >= requiredHours

	c.JSON(http.StatusOK, gin.H{
		"ok":                   true,
		"total_hours_rendered": totalHours,
		"required_hours":       requiredHours,
		"total_days":           totalDays,
		"today":                todayRec,
		"is_ojt_completed":     isCompleted,
	})
}

// ── GET /api/attendance/history ───────────────────────────────────────────────

func (h *Handler) GetAttendanceHistory(c *gin.Context) {
	userID, ok := getUserIDFromCtx(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"ok": false, "error": "Unauthorized"})
		return
	}

	var user models.User
	if err := h.DB.Select("start_date, required_ojt_hours").First(&user, userID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"ok": false, "error": "Could not load user profile"})
		return
	}

	requiredHours := 400.0
	if user.RequiredOjtHours > 0 {
		requiredHours = float64(user.RequiredOjtHours)
	}

	loc := manilaLoc()
	now := time.Now().In(loc)
	yesterday := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, loc).AddDate(0, 0, -1)

	var walkStart time.Time
	if user.StartDate != nil {
		walkStart = time.Date(user.StartDate.Year(), user.StartDate.Month(), user.StartDate.Day(), 0, 0, 0, 0, loc)
	}

	start := time.Time{}
	if !walkStart.IsZero() {
		start = walkStart
	}

	var records []models.Attendance
	q := h.DB.
		Select(attendanceSelectWithHours).
		Where("user_id = ? AND date <= ?", userID, yesterday)
	if !start.IsZero() {
		q = q.Where("date >= ?", start)
	}
	q = q.Order("date DESC")
	q.Find(&records)

	type dateKey = string
	byDate := make(map[dateKey]*models.Attendance, len(records))
	for i := range records {
		key := records[i].Date.UTC().Format("2006-01-02")
		byDate[key] = &records[i]
	}

	if walkStart.IsZero() {
		if len(records) > 0 {
			earliest := records[len(records)-1].Date.In(loc)
			walkStart = time.Date(earliest.Year(), earliest.Month(), earliest.Day(), 0, 0, 0, 0, loc)
		} else {
			c.JSON(http.StatusOK, gin.H{"ok": true, "records": []interface{}{}})
			return
		}
	}

	// ── First pass: find the OJT completion date ──────────────────────────────
	// Walk forward and accumulate hours until requiredHours is reached.
	// The date on which the threshold is crossed is the completion date —
	// no absent rows are emitted after it.
	var completionDate string
	var cumulativeHours float64

	for cursor := walkStart; !cursor.After(yesterday); cursor = cursor.AddDate(0, 0, 1) {
		if cursor.Weekday() == time.Saturday || cursor.Weekday() == time.Sunday {
			continue
		}
		key := cursor.Format("2006-01-02")
		if rec, found := byDate[key]; found {
			var tIn, tOut *string
			if rec.TimeIn != nil {
				s := rec.TimeIn.In(loc).Format("3:04 PM")
				tIn = &s
			}
			if rec.TimeOut != nil {
				s := rec.TimeOut.In(loc).Format("3:04 PM")
				tOut = &s
			}
			if hrs := computeHours(tIn, tOut, key); hrs != nil {
				cumulativeHours += *hrs
				if cumulativeHours >= requiredHours && completionDate == "" {
					completionDate = key
				}
			}
		}
	}

	// ── Second pass: build the result rows ────────────────────────────────────
	type HistoryRow struct {
		ID            uint     `json:"id"`
		UserID        uint     `json:"user_id"`
		Date          string   `json:"date"`
		TimeIn        *string  `json:"time_in"`
		TimeOut       *string  `json:"time_out"`
		HoursRendered *float64 `json:"hours_rendered"`
		Status        string   `json:"status"`
		IsReported    bool     `json:"is_reported"`
		IsAbsent      bool     `json:"is_absent"`
	}

	var result []HistoryRow

	for cursor := walkStart; !cursor.After(yesterday); cursor = cursor.AddDate(0, 0, 1) {
		wd := cursor.Weekday()
		if wd == time.Saturday || wd == time.Sunday {
			continue
		}

		key := cursor.Format("2006-01-02")

		// Stop emitting rows past the OJT completion date.
		if completionDate != "" && key > completionDate {
			break
		}

		if rec, found := byDate[key]; found {
			var timeInStr, timeOutStr *string
			if rec.TimeIn != nil {
				s := rec.TimeIn.In(loc).Format("3:04 PM")
				timeInStr = &s
			}
			if rec.TimeOut != nil {
				s := rec.TimeOut.In(loc).Format("3:04 PM")
				timeOutStr = &s
			}
			hours := computeHours(timeInStr, timeOutStr, key)

			status := deriveStatus(timeInStr, timeOutStr, key)
			if rec.Status != nil && *rec.Status != "" {
				status = *rec.Status
			}

			// Tag the exact completion date row with "OJT Completed".
			if completionDate != "" && key == completionDate {
				status = "OJT Completed"
			}

			result = append(result, HistoryRow{
				ID:            rec.ID,
				UserID:        rec.UserID,
				Date:          key,
				TimeIn:        timeInStr,
				TimeOut:       timeOutStr,
				HoursRendered: hours,
				Status:        status,
				IsReported:    rec.IsReported,
				IsAbsent:      false,
			})
		} else {
			// Only emit absent rows before OJT is complete.
			result = append(result, HistoryRow{
				ID:       0,
				UserID:   userID,
				Date:     key,
				Status:   "Absent",
				IsAbsent: true,
			})
		}
	}

	// Reverse to newest-first.
	for i, j := 0, len(result)-1; i < j; i, j = i+1, j-1 {
		result[i], result[j] = result[j], result[i]
	}

	c.JSON(http.StatusOK, gin.H{
		"ok":      true,
		"records": result,
		"total":   len(result),
	})
}

// ── GET /api/admin/attendance ─────────────────────────────────────────────────
//
// Query params:
//
//	page        int     (default 1)
//	limit       int     (default 20, max 100)
//	date        string  "YYYY-MM-DD"   — exact date filter (ignored when period set)
//	all_dates   bool    "true"         — skip date filtering entirely
//	period      string  "today" | "week" | "month" | "year"
//	search      string  — partial match on intern full name (ILIKE)
//	status      string  "Present" | "Late" | "On Shift" | "Missed Clock Out" | "Absent"
//	user_id     int     — filter to a single intern
func (h *Handler) GetAdminAttendance(c *gin.Context) {

	// ── pagination ────────────────────────────────────────────────────────────
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}
	offset := (page - 1) * limit

	// ── date / period range ───────────────────────────────────────────────────
	allDates := c.Query("all_dates") == "true"
	period := c.Query("period")
	dateStr := c.Query("date")

	now := time.Now().UTC()
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)

	var rangeStart, rangeEnd time.Time
	useRange := false

	if !allDates {
		switch period {
		case "today":
			rangeStart = today
			rangeEnd = today.AddDate(0, 0, 1)
			useRange = true
		case "week":
			weekday := int(now.Weekday())
			if weekday == 0 {
				weekday = 7
			}
			rangeStart = today.AddDate(0, 0, -(weekday - 1))
			rangeEnd = rangeStart.AddDate(0, 0, 7)
			useRange = true
		case "month":
			rangeStart = time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.UTC)
			rangeEnd = rangeStart.AddDate(0, 1, 0)
			useRange = true
		case "year":
			rangeStart = time.Date(now.Year(), 1, 1, 0, 0, 0, 0, time.UTC)
			rangeEnd = rangeStart.AddDate(1, 0, 0)
			useRange = true
		default:
			if dateStr != "" {
				parsed, err := time.Parse("2006-01-02", dateStr)
				if err == nil {
					rangeStart = parsed
					rangeEnd = parsed.AddDate(0, 0, 1)
					useRange = true
				}
			}
		}

		if useRange {
			tomorrow := today.AddDate(0, 0, 1)
			if rangeEnd.After(tomorrow) {
				rangeEnd = tomorrow
			}
		}

		fmt.Printf("[DEBUG] allDates=%v useRange=%v rangeStart=%s rangeEnd=%s\n",
			allDates, useRange, rangeStart.Format("2006-01-02"), rangeEnd.Format("2006-01-02"))
	}

	// ── optional filters ──────────────────────────────────────────────────────
	search := c.Query("search")
	status := c.Query("status")
	userIDStr := c.Query("user_id")

	if allDates {
		loc := manilaLoc()
		nowLoc := time.Now().In(loc)
		todayLocal := time.Date(nowLoc.Year(), nowLoc.Month(), nowLoc.Day(), 0, 0, 0, 0, loc)

		type InternMeta struct {
			ID               int        `gorm:"column:id"`
			FirstName        string     `gorm:"column:first_name"`
			LastName         string     `gorm:"column:last_name"`
			AvatarURL        string     `gorm:"column:avatar_url"`
			StartDate        *time.Time `gorm:"column:start_date"`
			RequiredOjtHours int        `gorm:"column:required_ojt_hours"`
		}

		var interns []InternMeta
		q := h.DB.Table("users").
			Select("id, first_name, last_name, COALESCE(avatar_url, '') as avatar_url, start_date, required_ojt_hours").
			Where("role = 'user'")
		if userIDStr != "" {
			uid, err := strconv.Atoi(userIDStr)
			if err == nil {
				q = q.Where("id = ?", uid)
			}
		}
		if search != "" {
			q = q.Where("CONCAT(first_name, ' ', last_name) ILIKE ?", "%"+search+"%")
		}
		q.Find(&interns)

		fmt.Printf("[DEBUG allDates] found %d interns\n", len(interns))
		for _, intern := range interns {
			fmt.Printf("[DEBUG allDates] intern id=%d name=%s %s start_date=%v required_hours=%d\n",
				intern.ID, intern.FirstName, intern.LastName, intern.StartDate, intern.RequiredOjtHours)
		}

		if len(interns) == 0 {
			c.JSON(http.StatusOK, gin.H{"ok": true, "records": []interface{}{}, "total": 0, "page": 1, "limit": limit})
			return
		}

		internIDs := make([]int, len(interns))
		for i, intern := range interns {
			internIDs[i] = intern.ID
		}

		type RealRow struct {
			ID           int     `gorm:"column:id"`
			UserID       int     `gorm:"column:user_id"`
			Date         string  `gorm:"column:date"`
			TimeIn       *string `gorm:"column:time_in"`
			TimeOut      *string `gorm:"column:time_out"`
			Status       string  `gorm:"column:status"`
			IsReported   bool    `gorm:"column:is_reported"`
			ReportReason string  `gorm:"column:report_reason"`
			ReportType   string  `gorm:"column:report_type"`
			AdminNote    *string `gorm:"column:admin_note"`
		}

		var realRows []RealRow
		h.DB.Raw(`
			SELECT
				a.id,
				a.user_id,
				TO_CHAR(a.date, 'YYYY-MM-DD') AS date,
				TO_CHAR(a.time_in  AT TIME ZONE 'Asia/Manila', 'HH12:MI AM') AS time_in,
				TO_CHAR(a.time_out AT TIME ZONE 'Asia/Manila', 'HH12:MI AM') AS time_out,
				CASE
					WHEN a.time_in IS NOT NULL AND a.time_out IS NULL AND a.date = CURRENT_DATE THEN 'On Shift'
					WHEN a.time_in IS NOT NULL AND a.time_out IS NULL AND a.date < CURRENT_DATE THEN 'Missed Clock Out'
					WHEN a.time_out IS NOT NULL AND EXTRACT(HOUR FROM a.time_in AT TIME ZONE 'Asia/Manila') < 9  THEN 'Present'
					WHEN a.time_out IS NOT NULL AND EXTRACT(HOUR FROM a.time_in AT TIME ZONE 'Asia/Manila') >= 9 THEN 'Late'
					ELSE 'Absent'
				END AS status,
				a.is_reported,
				COALESCE(a.report_reason, '') AS report_reason,
				COALESCE(a.report_type,  '') AS report_type,
				a.admin_note
			FROM attendance a
			WHERE a.user_id = ANY(?)
			ORDER BY a.user_id, a.date ASC
		`, internIDs).Scan(&realRows)

		type rowKey struct {
			UserID int
			Date   string
		}
		byKey := make(map[rowKey]*RealRow, len(realRows))
		for i := range realRows {
			byKey[rowKey{realRows[i].UserID, realRows[i].Date}] = &realRows[i]
		}

		internMap := make(map[int]*InternMeta, len(interns))
		for i := range interns {
			internMap[interns[i].ID] = &interns[i]
		}

		type WalkRow struct {
			ID            int      `json:"id"`
			UserID        int      `json:"user_id"`
			InternName    string   `json:"intern_name"`
			AvatarURL     string   `json:"avatar_url"`
			Date          string   `json:"date"`
			TimeIn        *string  `json:"time_in"`
			TimeOut       *string  `json:"time_out"`
			HoursRendered *float64 `json:"hours_rendered"`
			Status        string   `json:"status"`
			IsReported    bool     `json:"is_reported"`
			ReportReason  string   `json:"report_reason"`
			ReportType    string   `json:"report_type"`
			AdminNote     *string  `json:"admin_note"`
		}

		var walked []WalkRow

		for _, intern := range interns {
			var internWalkStart time.Time
			if intern.StartDate != nil {
				internWalkStart = time.Date(intern.StartDate.Year(), intern.StartDate.Month(), intern.StartDate.Day(), 0, 0, 0, 0, loc)
			}
			if internWalkStart.IsZero() {
				continue
			}

			requiredHours := 400.0
			if intern.RequiredOjtHours > 0 {
				requiredHours = float64(intern.RequiredOjtHours)
			}

			internName := intern.FirstName + " " + intern.LastName

			// ── First pass: find this intern's OJT completion date ────────────
			var completionDate string
			var cumulativeHours float64

			for cursor := internWalkStart; !cursor.After(todayLocal); cursor = cursor.AddDate(0, 0, 1) {
				if cursor.Weekday() == time.Saturday || cursor.Weekday() == time.Sunday {
					continue
				}
				key := cursor.Format("2006-01-02")
				rk := rowKey{intern.ID, key}
				if rec, found := byKey[rk]; found {
					if hrs := computeHours(rec.TimeIn, rec.TimeOut, key); hrs != nil {
						cumulativeHours += *hrs
						if cumulativeHours >= requiredHours && completionDate == "" {
							completionDate = key
						}
					}
				}
			}

			// ── Second pass: emit walk rows up to completion date ─────────────
			for cursor := internWalkStart; !cursor.After(todayLocal); cursor = cursor.AddDate(0, 0, 1) {
				wd := cursor.Weekday()
				if wd == time.Saturday || wd == time.Sunday {
					continue
				}
				key := cursor.Format("2006-01-02")

				// Stop walking past the OJT completion date.
				if completionDate != "" && key > completionDate {
					break
				}

				rk := rowKey{intern.ID, key}

				if rec, found := byKey[rk]; found {
					// Determine the effective row status, tagging the completion date.
					rowStatus := rec.Status
					if completionDate != "" && key == completionDate {
						rowStatus = "OJT Completed"
					}

					// Apply status filter against the effective status.
					if status != "" && rowStatus != status {
						continue
					}

					hrs := computeHours(rec.TimeIn, rec.TimeOut, key)
					walked = append(walked, WalkRow{
						ID:            rec.ID,
						UserID:        intern.ID,
						InternName:    internName,
						AvatarURL:     intern.AvatarURL,
						Date:          key,
						TimeIn:        rec.TimeIn,
						TimeOut:       rec.TimeOut,
						HoursRendered: hrs,
						Status:        rowStatus,
						IsReported:    rec.IsReported,
						ReportReason:  rec.ReportReason,
						ReportType:    rec.ReportType,
						AdminNote:     rec.AdminNote,
					})
				} else {
					// Only emit absent rows before OJT is complete.
					if status != "" && status != "Absent" {
						continue
					}
					walked = append(walked, WalkRow{
						UserID:     intern.ID,
						InternName: internName,
						AvatarURL:  intern.AvatarURL,
						Date:       key,
						Status:     "Absent",
					})
				}
			}
		}

		// Newest-first.
		for i, j := 0, len(walked)-1; i < j; i, j = i+1, j-1 {
			walked[i], walked[j] = walked[j], walked[i]
		}

		total := len(walked)
		startIdx := (page - 1) * limit
		if startIdx > total {
			startIdx = total
		}
		endIdx := startIdx + limit
		if endIdx > total {
			endIdx = total
		}

		c.JSON(http.StatusOK, gin.H{
			"ok":      true,
			"records": walked[startIdx:endIdx],
			"total":   total,
			"page":    page,
			"limit":   limit,
		})
		return
	}

	// ── Non-allDates path (period / date range / single date) ─────────────────

	type AdminRow struct {
		ID            int      `gorm:"column:id"             json:"id"`
		UserID        int      `gorm:"column:user_id"        json:"user_id"`
		InternName    string   `gorm:"column:intern_name"    json:"intern_name"`
		AvatarURL     string   `gorm:"column:avatar_url"     json:"avatar_url"`
		Date          string   `gorm:"column:date"           json:"date"`
		TimeIn        *string  `gorm:"column:time_in"        json:"time_in"`
		TimeOut       *string  `gorm:"column:time_out"       json:"time_out"`
		HoursRendered *float64 `gorm:"column:hours_rendered" json:"hours_rendered"`
		Status        string   `gorm:"column:status"         json:"status"`
		IsReported    bool     `gorm:"column:is_reported"    json:"is_reported"`
		ReportedAt    *string  `gorm:"column:reported_at"    json:"reported_at"`
		ReportReason  string   `gorm:"column:report_reason"  json:"report_reason"`
		ReportType    string   `gorm:"column:report_type"    json:"report_type"`
		AdminNote     *string  `gorm:"column:admin_note"     json:"admin_note"`
	}

	baseSQL := `
		SELECT
			a.id,
			a.user_id,
			CONCAT(u.first_name, ' ', u.last_name)          AS intern_name,
			COALESCE(u.avatar_url, '')                       AS avatar_url,
			TO_CHAR(a.date, 'YYYY-MM-DD')                   AS date,
			TO_CHAR(a.time_in,  'HH12:MI AM')               AS time_in,
			TO_CHAR(a.time_out, 'HH12:MI AM')               AS time_out,
			CASE
				WHEN a.time_in IS NOT NULL AND a.time_out IS NOT NULL
					THEN EXTRACT(EPOCH FROM (a.time_out - a.time_in)) / 3600.0
				ELSE NULL
			END AS hours_rendered,
			CASE
				WHEN a.time_in IS NOT NULL AND a.time_out IS NULL AND a.date = CURRENT_DATE
					THEN 'On Shift'
				WHEN a.time_in IS NOT NULL AND a.time_out IS NULL AND a.date < CURRENT_DATE
					THEN 'Missed Clock Out'
				WHEN a.time_out IS NOT NULL AND EXTRACT(HOUR FROM a.time_in) < 9
					THEN 'Present'
				WHEN a.time_out IS NOT NULL AND EXTRACT(HOUR FROM a.time_in) >= 9
					THEN 'Late'
				ELSE 'Absent'
			END AS status,
			a.is_reported,
			TO_CHAR(a.reported_at, 'YYYY-MM-DD HH12:MI AM') AS reported_at,
			COALESCE(a.report_reason, '')                    AS report_reason,
			COALESCE(a.report_type, '')                      AS report_type,
			a.admin_note
		FROM attendance a
		LEFT JOIN users u ON u.id = a.user_id
		WHERE 1=1
	`

	args := []interface{}{}

	if useRange {
		baseSQL += " AND a.date >= ? AND a.date < ?"
		args = append(args, rangeStart, rangeEnd)
	}

	if search != "" {
		baseSQL += " AND CONCAT(u.first_name, ' ', u.last_name) ILIKE ?"
		args = append(args, "%"+search+"%")
	}

	statusClause := ""
	if status != "" {
		statusClause = " AND status = ?"
		args = append(args, status)
	}

	if userIDStr != "" {
		uid, err := strconv.Atoi(userIDStr)
		if err == nil {
			baseSQL += " AND a.user_id = ?"
			args = append(args, uid)
		}
	}

	wrappedSQL := "SELECT * FROM (" + baseSQL + ") sub WHERE 1=1" + statusClause

	countSQL := "SELECT COUNT(*) FROM (" + wrappedSQL + ") counted"
	var total int64
	h.DB.Raw(countSQL, args...).Scan(&total)

	finalSQL := wrappedSQL + " ORDER BY date DESC LIMIT ? OFFSET ?"
	pageArgs := append(args, limit, offset)

	var rows []AdminRow
	h.DB.Raw(finalSQL, pageArgs...).Scan(&rows)

	c.JSON(http.StatusOK, gin.H{
		"ok":      true,
		"records": rows,
		"total":   total,
		"page":    page,
		"limit":   limit,
	})
}

// ── Suppress unused import warning for clause ─────────────────────────────────
var _ = clause.OnConflict{}

// ── POST /api/attendance/:id/report-missed-clockout ───────────────────────────

func (h *Handler) ReportMissedClockOut(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "Invalid ID"})
		return
	}

	var body struct {
		Reason string `json:"reason"`
	}
	_ = c.ShouldBindJSON(&body)

	var rec models.Attendance
	if err := h.DB.First(&rec, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"ok": false, "error": "Record not found"})
		return
	}

	updates := map[string]interface{}{
		"is_reported": true,
		"reported_at": time.Now().In(manilaLoc()),
	}
	if strings.TrimSpace(body.Reason) != "" {
		updates["report_reason"] = strings.TrimSpace(body.Reason)
	}

	if err := h.DB.Model(&rec).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"ok": false, "error": "Failed to report"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"ok": true})
}

// ── PATCH /api/admin/attendance/:id/set-timeout ───────────────────────────────

func (h *Handler) AdminSetTimeOut(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "Invalid record ID"})
		return
	}

	var body struct {
		TimeOut string `json:"time_out" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "time_out is required"})
		return
	}

	var timeOut time.Time
	for _, layout := range []string{time.RFC3339, "2006-01-02T15:04:05"} {
		if t, err := time.Parse(layout, body.TimeOut); err == nil {
			timeOut = t.UTC()
			break
		}
	}
	if timeOut.IsZero() {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "Invalid time_out format — use RFC3339 or YYYY-MM-DDTHH:MM:SS"})
		return
	}

	var rec models.Attendance
	if err := h.DB.First(&rec, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"ok": false, "error": "Record not found"})
		return
	}

	if rec.TimeIn != nil && !timeOut.After(*rec.TimeIn) {
		c.JSON(http.StatusBadRequest, gin.H{"ok": false, "error": "time_out must be after time_in"})
		return
	}

	adminID, _ := getUserIDFromCtx(c)
	if err := h.DB.Model(&rec).Updates(map[string]interface{}{
		"time_out":    timeOut,
		"is_reported": false,
		"reported_at": nil,
	}).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"ok": false, "error": "Failed to update record"})
		return
	}

	h.logActivity(
		adminID,
		"SET_TIMEOUT",
		fmt.Sprintf("Admin set time-out for attendance record %d to %s", id, timeOut.Format(time.RFC3339)),
		c.ClientIP(),
	)

	c.JSON(http.StatusOK, gin.H{"ok": true})
}

// ── GET /api/attendance/weekly ────────────────────────────────────────────────

func (h *Handler) GetWeeklyAttendance(c *gin.Context) {
	userID, ok := getUserIDFromCtx(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"ok": false, "error": "Unauthorized"})
		return
	}

	loc := manilaLoc()
	now := time.Now().In(loc)

	weekday := int(now.Weekday())
	if weekday == 0 {
		weekday = 7
	}

	weekStart := time.Date(now.Year(), now.Month(), now.Day()-(weekday-1), 0, 0, 0, 0, loc)
	weekEnd := weekStart.AddDate(0, 0, 7)

	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, loc)
	if weekEnd.After(today) {
		weekEnd = today
	}

	type weekRaw struct {
		Date    string  `gorm:"column:date"`
		TimeIn  *string `gorm:"column:time_in"`
		TimeOut *string `gorm:"column:time_out"`
	}
	var weekRaws []weekRaw
	err := h.DB.Raw(`
		SELECT
			TO_CHAR(a.date, 'YYYY-MM-DD') AS date,
			TO_CHAR(a.time_in  AT TIME ZONE 'Asia/Manila', 'HH12:MI AM') AS time_in,
			TO_CHAR(a.time_out AT TIME ZONE 'Asia/Manila', 'HH12:MI AM') AS time_out
		FROM attendance a
		WHERE a.user_id = ?
		  AND a.date >= ?
		  AND a.date < ?
		ORDER BY a.date ASC
	`, userID, weekStart, weekEnd).Scan(&weekRaws).Error

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"ok": false, "error": err.Error()})
		return
	}

	type WeeklyRow struct {
		Date  string   `json:"date"`
		Hours *float64 `json:"hours"`
	}

	rows := make([]WeeklyRow, 0, len(weekRaws))
	for _, r := range weekRaws {
		hrs := computeHours(r.TimeIn, r.TimeOut, r.Date)
		var h float64
		if hrs != nil {
			h = *hrs
		}
		rows = append(rows, WeeklyRow{Date: r.Date, Hours: &h})
	}

	c.JSON(http.StatusOK, gin.H{
		"ok":      true,
		"records": rows,
	})
}
