import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/user_home_screen.dart';
import 'screens/user_my_profile_screen.dart';   // view-only
import 'screens/user_account_settings_screen.dart';       // Account Settings
import 'screens/admin_my_profile_screen.dart';
import 'screens/admin_account_settings_screen.dart';
import 'screens/admin_users_screen.dart';
import 'screens/admin_add_user_screen.dart';
import 'screens/admin_config_screen.dart';        // departments & positions
import 'screens/admin_dashboard_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),

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
          seedColor: const Color(0xFF7B0D1E),
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
          // View-only profile
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => MaterialPage<void>(
              key: state.pageKey,
              child: const MyProfileScreen(),
            ),
          ),
          // Edit profile
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
          // Departments & positions config page
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
            path: '/admin/profile',
            pageBuilder: (context, state) => MaterialPage<void>(
              key: state.pageKey,
              child: const AdminMyProfileScreen(),
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
        ],
      ),
    );
  }
}
