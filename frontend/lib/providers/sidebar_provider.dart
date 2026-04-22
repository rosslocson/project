import 'package:flutter/material.dart';

/// Global provider to manage sidebar state across all screens.
/// This ensures the sidebar remains in the same state when navigating between screens.
class SidebarProvider extends ChangeNotifier {
  bool _isAdminSidebarOpen = true;
  bool _isUserSidebarOpen = true;

  bool get isAdminSidebarOpen => _isAdminSidebarOpen;
  bool get isUserSidebarOpen => _isUserSidebarOpen;

  void toggleAdminSidebar() {
    _isAdminSidebarOpen = !_isAdminSidebarOpen;
    notifyListeners();
  }

  void setAdminSidebarOpen(bool value) {
    if (_isAdminSidebarOpen != value) {
      _isAdminSidebarOpen = value;
      notifyListeners();
    }
  }

  void toggleUserSidebar() {
    _isUserSidebarOpen = !_isUserSidebarOpen;
    notifyListeners();
  }

  void setUserSidebarOpen(bool value) {
    if (_isUserSidebarOpen != value) {
      _isUserSidebarOpen = value;
      notifyListeners();
    }
  }

  /// Close both sidebars (useful on logout)
  void closeAll() {
    _isAdminSidebarOpen = true;
    _isUserSidebarOpen = true;
    notifyListeners();
  }
}
