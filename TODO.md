# TODO

- [x] Inspect `user_homescreen.dart` and `user_glass_topbar.dart` hamburger/menu implementation.
- [x] Inspect each target user screen to confirm whether their hamburger/menu matches `user_homescreen.dart`.
- [x] Identify mismatch risk: `user_my_profile_screen.dart` used local sidebar state instead of `SidebarProvider`.
- [x] Update `frontend/lib/screens/user_my_profile_screen.dart` to use `SidebarProvider.isUserSidebarOpen` for sidebar + `GlassTopBar` hamburger behavior.
- [x] Update `frontend/lib/screens/user_edit_profile_screen.dart` to use `SidebarProvider.isUserSidebarOpen` for sidebar + `GlassTopBar` hamburger behavior.


- [ ] Verify other target pages (About & Contact, Account Settings, Attendance) already match `user_homescreen.dart` hamburger behavior.
- [ ] Run a quick Flutter build/analyze to ensure compilation succeeds (no tests run).

