import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/my_profile_screen.dart';   // view-only
import 'screens/profile_screen.dart';       // edit profile
import 'screens/users_screen.dart';
import 'screens/add_user_screen.dart';
import 'screens/config_screen.dart';        // departments & positions

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

// No-animation page transition
CustomTransitionPage<void> _noTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      transitionsBuilder: (_, __, ___, child) => child,
    );

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _router = GoRouter(
      refreshListenable: auth,
      redirect: (context, state) {
        final loggedIn = auth.isLoggedIn;
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';
        if (!loggedIn && !isAuthRoute) return '/login';
        if (loggedIn && isAuthRoute) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          pageBuilder: (c, s) => _noTransition(
              context: c, state: s, child: const LoginScreen()),
        ),
        GoRoute(
          path: '/register',
          pageBuilder: (c, s) => _noTransition(
              context: c, state: s, child: const RegisterScreen()),
        ),
        GoRoute(
          path: '/dashboard',
          pageBuilder: (c, s) => _noTransition(
              context: c, state: s, child: const DashboardScreen()),
        ),
        // View-only profile
        GoRoute(
          path: '/profile',
          pageBuilder: (c, s) => _noTransition(
              context: c, state: s, child: const MyProfileScreen()),
        ),
        // Edit profile
        GoRoute(
          path: '/profile/edit',
          pageBuilder: (c, s) => _noTransition(
              context: c, state: s, child: const ProfileScreen()),
        ),
        GoRoute(
          path: '/users',
          pageBuilder: (c, s) => _noTransition(
              context: c, state: s, child: const UsersScreen()),
        ),
        GoRoute(
          path: '/users/add',
          pageBuilder: (c, s) => _noTransition(
              context: c, state: s, child: const AddUserScreen()),
        ),
        // Departments & positions config page
        GoRoute(
          path: '/config',
          pageBuilder: (c, s) => _noTransition(
              context: c, state: s, child: const ConfigScreen()),
        ),
        GoRoute(path: '/', redirect: (_, __) => '/dashboard'),
      ],
    );
  }

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
      routerConfig: _router,
    );
  }
}