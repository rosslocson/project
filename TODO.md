# TODO

- [ ] Fix PostgreSQL safe migration for start_date/end_date (remove unsafe cast; idempotent; log invalid rows)
- [ ] Improve models.Date scanning to never error on empty-string/invalid values (treat as NULL) while preserving strict JSON parsing
- [ ] Ensure OTP/forgot-password flows cannot be blocked by date field scan failures (defensive selects to avoid selecting start_date/end_date when not needed)
- [ ] Ensure admin seeding respects uniqueness and does not repeatedly update/insert incorrectly
- [ ] Add defensive logging for rows with invalid date values during startup cleanup
- [ ] Verify compilation (no tests) and run quick `go vet`/`go test` if available

