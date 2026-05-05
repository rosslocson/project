import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../app_theme.dart'; // Adjust path if needed
import 'locked_banner.dart';
import 'error_banner.dart';

class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final bool isLocked;
  final int lockSecsLeft;
  final int attemptsLeft;
  final AuthProvider auth;
  final VoidCallback onToggleObscure;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.isLocked,
    required this.lockSecsLeft,
    required this.attemptsLeft,
    required this.auth,
    required this.onToggleObscure,
    required this.onLogin,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    final dec =
        pillInputDecoration(); // Assuming this comes from app_theme.dart

    return Container(
      alignment: Alignment.center,
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'LOG IN',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: kCrimsonDeep,
                    letterSpacing: 1.2),
              ),
              const SizedBox(height: 40),
              if (isLocked) ...[
                LockedBanner(
                    lockSecsLeft: lockSecsLeft,
                    onForgotPassword: onForgotPassword),
                const SizedBox(height: 20),
              ] else if (auth.error != null) ...[
                ErrorBanner(
                    auth: auth,
                    attemptsLeft: attemptsLeft,
                    onForgotPassword: onForgotPassword),
                const SizedBox(height: 20),
              ],
              fieldLabel('Email Address'),
              const SizedBox(height: 6),
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                enabled: !isLocked,
                decoration: dec.copyWith(hintText: 'Enter your email'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              fieldLabel('Password'),
              const SizedBox(height: 6),
              TextFormField(
                controller: passCtrl,
                obscureText: obscure,
                enabled: !isLocked,
                decoration: dec.copyWith(
                  hintText: 'Enter your password',
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: Icon(
                        obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF9CA3AF),
                        size: 22,
                      ),
                      onPressed: onToggleObscure,
                    ),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Password is required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Spacer(),
                  GestureDetector(
                    onTap: onForgotPassword,
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                          fontSize: 13,
                          color: kCrimsonDeep,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              BlueButton(
                label: isLocked ? 'LOCKED — WAIT ${lockSecsLeft}s' : 'LOG IN',
                onPressed: (auth.isLoading || isLocked) ? null : onLogin,
                loading: auth.isLoading,
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ",
                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  GestureDetector(
                    onTap: () => context.go('/register'),
                    child: const Text('CREATE ACCOUNT',
                        style: TextStyle(
                            fontSize: 13,
                            color: kCrimsonDeep,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
