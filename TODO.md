## TODO - Performance Optimizations (Go/Gin/GORM/Postgres)

- [ ] Add missing composite indexes in `backend/schema.sql`:
  - attendance(user_id, date)
  - (optional) attendance(user_id, date) WHERE time_out IS NULL
  - activity_logs(created_at DESC)
  - (optional) activity_logs(user_id, created_at DESC)
- [ ] Constrain `GetDashboardStats` weekly logs query (avoid loading all rows): add LIMIT and/or reduce Preload scope.
- [ ] Rewrite `GetWeeklyAttendance` SQL to order/filter by raw `date` (avoid TO_CHAR in ORDER BY).
- [ ] Constrain `GetAttendanceHistory` DB fetch: limit by computed `walkStart..yesterday`.
- [ ] Ensure `GetAttendanceHistory` still fills absences exactly as before (response shape unchanged).
- [ ] Update or add GORM index tags in `backend/models/attendance.go` if needed for consistency.
- [ ] Sanity-check compile (no tests run).

