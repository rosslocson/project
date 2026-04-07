import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'admin_users_screen.dart' as admin;
import 'user_home_screen.dart' as user_home;

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return auth.isAdmin
        ? const admin.UsersScreen()
        : const user_home.DashboardScreen();
  }
}
