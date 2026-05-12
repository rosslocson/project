import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_background.dart';

// ── Imported Extracted Widgets ──
import '../widgets/login_screen_widgets/login_form.dart';
import '../widgets/login_screen_widgets/forgot_password_sheet.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  // Lockout State
  bool _isLocked = false;
  int _lockSecsLeft = 0;
  int _attemptsLeft = 3;
  Timer? _lockTimer;

  @override
  void dispose() {
    _lockTimer?.cancel();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Lock countdown ──
  void _startLockCountdown(int seconds) {
    setState(() {
      _isLocked = true;
      _lockSecsLeft = seconds;
    });

    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }

      setState(() => _lockSecsLeft--);

      if (_lockSecsLeft <= 0) {
        t.cancel();
        setState(() {
          _isLocked = false;
          _attemptsLeft = 3;
        });
        context.read<AuthProvider>().clearError();
      }
    });
  }

  // ── Login ──
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final result = await auth.loginWithDetails(
      _emailCtrl.text.trim(),
      _passCtrl.text.trim(),
    );

    if (!mounted) return;

    if (result['ok'] == true) {
      if (auth.isAdmin) {
        context.go('/dashboard');
      } else {
        context.go('/home');
      }
    } else if (result['locked'] == true) {
      _startLockCountdown(result['retry_after_secs'] as int? ?? 60);
    } else {
      setState(() => _attemptsLeft =
          result['attempts_left'] as int? ?? _attemptsLeft - 1);
    }
  }

  // ── Forgot password sheet ──
  void _showForgotPassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ForgotPasswordSheet(
        initialEmail: _emailCtrl.text.trim(),
        onResetSuccess: () {
          setState(() {
            _isLocked = false;
            _attemptsLeft = 3;
          });

          _lockTimer?.cancel();
          context.read<AuthProvider>().clearError();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final formWidget = LoginForm(
      formKey: _formKey,
      emailCtrl: _emailCtrl,
      passCtrl: _passCtrl,
      obscure: _obscure,
      isLocked: _isLocked,
      lockSecsLeft: _lockSecsLeft,
      attemptsLeft: _attemptsLeft,
      auth: auth,
      onToggleObscure: () => setState(() => _obscure = !_obscure),
      onLogin: _login,
      onForgotPassword: _showForgotPassword,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Extracted the left-side visual content into a variable to avoid repeating code
    final leftSideContent = Stack(
      children: [
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo_login.png',
                height: 280,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.public,
                        size: 120, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                "BACK IN THE COSMOS.",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 2,
                color: Colors.white54,
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 64.0),
                child: Text(
                  'Securely access your dashboard and monitor your workspace\nwithin the InternSpace galaxy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF050510) : Colors.white,
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final themeToggle = Positioned(
            top: 24,
            right: 24,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints.tightFor(width: 36, height: 36),
              splashRadius: 18,
              icon: Icon(
                isDark
                    ? Icons.wb_sunny_outlined
                    : Icons.nightlight_round_outlined,
                color: isDark ? Colors.white : const Color(0xFF00022E),
                size: 20,
              ),
              onPressed: () => context.read<ThemeProvider>().toggleTheme(),
            ),
          );

          if (constraints.maxWidth > 900) {
            // Desktop layout
            return Stack(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: isDark
                          // DARK MODE: Untouched, uses your original AppBackground
                          ? AppBackground(
                              backgroundAsset: 'assets/images/star_background.png',
                              child: leftSideContent,
                            )
                          // LIGHT MODE: Bypasses AppBackground, forces the image explicitly
                          : Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF050510), // Base dark color in case of transparent PNG
                                image: DecorationImage(
                                  image: AssetImage('assets/images/star_background.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: leftSideContent,
                            ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? null : Colors.white,
                          gradient: isDark
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF010205),
                                    Color(0xFF080E26),
                                  ],
                                )
                              : null,
                        ),
                        child: formWidget,
                      ),
                    ),
                  ],
                ),
                themeToggle,
              ],
            );
          }

          // Mobile layout content
          final mobileContent = Center(
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0B0B13) : Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: formWidget,
            ),
          );

          // Mobile layout return
          return Stack(
            children: [
              isDark
                  // DARK MODE: Untouched
                  ? AppBackground(
                      backgroundAsset: 'assets/images/star_background.png',
                      child: mobileContent,
                    )
                  // LIGHT MODE: Bypasses AppBackground, applies star image directly
                  : Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF050510),
                        image: DecorationImage(
                          image: AssetImage('assets/images/star_background.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: mobileContent,
                    ),
              themeToggle,
            ],
          );
        },
      ),
    );
  }
}