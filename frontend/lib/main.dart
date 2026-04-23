import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/sidebar_provider.dart';

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


 

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SidebarProvider()),
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
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'UserApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00022E),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      routerConfig: GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            pageBuilder: (context, state) => MaterialPage<void>(
              key: state.pageKey,
              child: const LoginScreen(),
            ),
          ),
          GoRoute(
            path: '/register',
            pageBuilder: (context, state) => MaterialPage<void>(
              key: state.pageKey,
              child: const RegisterScreen(),
            ),
          ),
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => MaterialPage<void>(
              key: state.pageKey,
              child: const UserHomeScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => MaterialPage<void>(
              key: state.pageKey,
              child: const MyProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/edit-profile',
            pageBuilder: (context, state) => MaterialPage<void>(
              key: state.pageKey,
              child: const UserEditProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/account-settings',
            pageBuilder: (context, state) => MaterialPage<void>(
              key: state.pageKey,
              child: const AccountSettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/users',
            pageBuilder: (context, state) => MaterialPage<void>(
              key: state.pageKey,
              child: const UsersScreen(),
            ),
          ),
          GoRoute(
            path: '/users/add',
            pageBuilder: (context, state) => MaterialPage<void>(
              key: state.pageKey,
              child: const AddUserScreen(),
            ),
          ),
          GoRoute(
            path: '/config',
            pageBuilder: (context, state) => MaterialPage<void>(
              key: state.pageKey,
              child: const ConfigScreen(),
            ),
          ),
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => MaterialPage<void>(
              key: state.pageKey,
              child: const AdminDashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/account-settings',
            pageBuilder: (context, state) => MaterialPage<void>(
              key: state.pageKey,
              child: const AdminAccountSettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin-dashboard',
            pageBuilder: (context, state) => MaterialPage<void>(
              key: state.pageKey,
              child: const AdminDashboardScreen(),
            ),
          ),
          // Attendance page
          GoRoute(
            path: '/attendance',
            pageBuilder: (context, state) => MaterialPage<void>(
              key: state.pageKey,
              child: const AttendanceScreen(),
            ),
          ),
        ],
      ),
    );
  }
}

