# Flutter App Error Fixes - Screens Cleanup
## Status: [IN PROGRESS]

### 1. [ ] main.dart - Fix imports & routes
   - Rename profile_screen import → account_settings_screen  
   - Add /account-settings route for AccountSettingsScreen

### 2. [ ] Add missing imports to ALL screens
   - go_router, provider, api_service.dart
   - app_theme.dart (kCrimson, fieldLabel, CrimsonButton)
   - auth_layout.dart (plainTextField, passwordTextField)
   - star_background.dart (GalaxyBackground, StarfieldPainter)

### 3. [ ] add_user_screen.dart
   - Add imports above
   - Fix AppBar navigation (use context.pop())

### 4. [ ] dashboard_screen.dart & my_profile_screen.dart  
   - Remove duplicate Star/StarfieldPainter classes
   - Import/use star_background.dart components
   - Add stat_card.dart import

### 5. [ ] login_screen.dart & register_screen.dart
   - Add missing imports
   - Verify GalaxyBackground usage

### 6. [ ] users_screen.dart
   - Remove duplicate _isSidebarVisible + header code
   - Use AppScaffold consistently

### 7. [ ] Verify all screens compile
   - flutter analyze
   - No undefined imports/widgets

### 8. [ ] Test
   - flutter pub get
   - cd frontend && flutter run
   - Test navigation/backend

**Completed by BLACKBOXAI**

