# Fix Admin Sidebar Auto-Closing
- [x] Plan confirmed with user
- [x] Step 1: Refactor admin_dashboard_screen.dart to use AdminLayout + SidebarProvider (remove local _isSidebarOpen, manual Row/AnimatedContainer/AdminSidebar)
- [x] Step 2: Refactor admin_user_management.dart to use AdminLayout + SidebarProvider (same changes)
- [x] Step 3: Check other admin screens for similar issues (search for _isSidebarOpen)
- [ ] Step 4: Test navigation: sidebar open → click Dashboard → confirm stays open
- [ ] Complete: attempt_completion

