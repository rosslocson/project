# Project TODO

## Profile merge + normalization (Flutter)
- [x] Refactor `AuthProvider.refreshProfile()` merge logic: server-first only when value is valid (non-null, non-empty), otherwise keep cached.

- [ ] Harden `_loadFromStorage()` restoration: validate decoded cache, normalize corrupted values (empty strings -> null, invalid date placeholders -> null).
- [ ] Improve logging: only log meaningful overwritten fields and summary counts.
- [ ] Remove noisy debug logging in `user_homescreen.dart` intern fetch flow.
- [x] Fix `InternProfile.fromJson()` date parsing to treat `0001-01-01...` placeholders as null.


## Backend
- [ ] (No changes expected unless client normalization requires it)

