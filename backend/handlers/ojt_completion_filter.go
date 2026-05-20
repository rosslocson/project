// backend/handlers/ojt_completion_filter.go
//
// applyOjtCompletionFilter takes the flat list of attendanceRaw rows that
// come from multiDateQuery (or the single-date query) and:
//
//  1. Groups rows by intern.
//  2. For each intern, walks dates in chronological order, accumulates hours,
//     and determines the OJT completion date.
//  3. Drops every absent row that falls AFTER the completion date.
//  4. Tags the completion-date row's status as "OJT Completed".
//
// This mirrors exactly what GetAttendanceHistory / GetAdminAttendance (the
// walk-based path in attendance.go) already do — we just centralise it here
// so the cross-join path in admin_attendance.go gets the same behaviour.

package handlers

import (
	"sort"
	"time"
)

// internOjtMeta is fetched once per call so we know each intern's required hours.
type internOjtMeta struct {
	UserID           int
	RequiredOjtHours int
}

// applyOjtCompletionFilter rewrites rows in-place:
//   - rows after the completion date (that are absent) are removed
//   - the completion row gets status = "OJT Completed"
//
// `metaByUser` maps user_id → required hours (0 → use default 400).
func applyOjtCompletionFilter(
	rows []attendanceRaw,
	metaByUser map[int]int,
) []attendanceRaw {

	loc := manilaLoc()

	// ── 1. Group rows by user, keep original order info via index ────────────
	type indexedRow struct {
		idx int
		row attendanceRaw
	}
	byUser := make(map[int][]indexedRow)
	for i, r := range rows {
		byUser[int(r.UserID)] = append(byUser[int(r.UserID)], indexedRow{i, r})
	}

	// We'll build a set of indices to DROP and a map of indices whose status
	// should be overridden to "OJT Completed".
	dropIdx := make(map[int]bool)
	completeIdx := make(map[int]string) // idx → "OJT Completed"

	for userID, userRows := range byUser {
		requiredHours := 400.0
		if h, ok := metaByUser[userID]; ok && h > 0 {
			requiredHours = float64(h)
		}

		// Sort chronologically for the forward walk.
		sort.Slice(userRows, func(a, b int) bool {
			return userRows[a].row.Date < userRows[b].row.Date
		})

		// ── Pass 1: find completion date ──────────────────────────────────────
		var completionDate string
		var cumulative float64

		for _, ir := range userRows {
			r := ir.row
			if r.TimeIn == nil {
				continue // absent — contributes 0 hours
			}
			if hrs := computeHours(r.TimeIn, r.TimeOut, r.Date); hrs != nil {
				cumulative += *hrs
				if cumulative >= requiredHours && completionDate == "" {
					completionDate = r.Date
				}
			}
		}

		if completionDate == "" {
			continue // intern hasn't completed OJT yet — nothing to rewrite
		}

		// ── Pass 2: tag completion row, drop absents after it ─────────────────
		// Parse the completion date once for string comparison.
		completionTime, err := time.ParseInLocation("2006-01-02", completionDate, loc)
		if err != nil {
			continue
		}
		_ = completionTime

		for _, ir := range userRows {
			r := ir.row

			// Tag the exact completion-date row.
			if r.Date == completionDate && r.TimeIn != nil {
				completeIdx[ir.idx] = "OJT Completed"
				continue
			}

			// Drop absent rows that come after the completion date.
			if r.Date > completionDate && r.TimeIn == nil {
				dropIdx[ir.idx] = true
			}
		}
	}

	// ── 3. Rebuild the slice, applying overrides and drops ───────────────────
	result := make([]attendanceRaw, 0, len(rows))
	for i, r := range rows {
		if dropIdx[i] {
			continue
		}
		if newStatus, ok := completeIdx[i]; ok {
			r.Status = &newStatus
		}
		result = append(result, r)
	}

	return result
}
