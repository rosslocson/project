import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/app_background.dart';

// ── Imported Extracted Widgets ──
import '../widgets/login_screen_widgets/login_form.dart';
import '../widgets/login_screen_widgets/forgot_password_sheet.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
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
    final result = await auth.loginWithDetails(_emailCtrl.text.trim(), _passCtrl.text.trim());
    
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
      setState(() => _attemptsLeft = result['attempts_left'] as int? ?? _attemptsLeft - 1);
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

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // The abstracted form widget
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

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            // Desktop layout
            return Row(
              children: [
                Expanded(
                  child: AppBackground(backgroundAsset: 'assets/images/star_background.png', 
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/logo_login.png',
                                height: 280,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.public, size: 120, color: Colors.white),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                "BACK IN THE COSMOS.",
                                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                              ),
                              const SizedBox(height: 16),
                              Container(width: 40, height: 2, color: Colors.white54),
                              const SizedBox(height: 16),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 64.0),
                                child: Text(
                                  'Securely access your dashboard and monitor your workspace\nwithin the InternSpace galaxy.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                                ),
                              ),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: formWidget,
                  ),
                ),
              ],
            );
          } else {
            // Mobile layout
            return AppBackground(backgroundAsset: 'assets/images/star_background.png', 
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 5),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: formWidget,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}