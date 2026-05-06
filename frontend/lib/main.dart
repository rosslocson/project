import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/sidebar_provider.dart';
import 'providers/theme_provider.dart';
import 'widgets/app_theme.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/user_homescreen.dart';
import 'screens/user_my_profile_screen.dart';
import 'screens/user_account_settings_screen.dart';
import 'screens/user_edit_profile_screen.dart';
import 'screens/admin_account_settings_screen.dart';
import 'screens/admin_user_management.dart';
import 'screens/admin_add_user.dart';
import 'screens/admin_departments_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/user_attendance_screen.dart';
import 'screens/admin_attendance_screen.dart';
import 'screens/user_about_contact_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SidebarProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const UserHomeScreen(),
        ),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const MyProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/edit-profile',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const UserEditProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/account-settings',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const AccountSettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/users',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const UsersScreen(),
        ),
      ),
      GoRoute(
        path: '/users/add',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const AddUserScreen(),
        ),
      ),
      GoRoute(
        path: '/config',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const ConfigScreen(),
        ),
      ),
      GoRoute(
        path: '/dashboard',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const AdminDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/account-settings',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const AdminAccountSettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/admin-dashboard',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const AdminDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/attendance',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const AttendanceScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/attendance',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const AdminAttendanceScreen(),
        ),
      ),
      GoRoute(
        path: '/about',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const UserAboutScreen(),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      title: 'InternSpace',
      debugShowCheckedModeBanner: false,
      theme: internSpaceTheme(brightness: Brightness.light),
      darkTheme: internSpaceTheme(brightness: Brightness.dark),
      themeMode: themeProvider.themeMode,
      routerConfig: _router,
    );
  }
}
