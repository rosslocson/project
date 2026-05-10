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

  // The accent color matching the "Save Changes" button
  static const Color kAccentPurple = Color(0xFF7367F0);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dec =
        pillInputDecoration(); // Assuming this comes from app_theme.dart and handles dark borders

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
                    color: Colors.white, // Changed to white for dark mode
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
              
              // If fieldLabel is hardcoded to black in app_theme, you may need to 
              // update it there to return white text, or replace it with a Text widget here.
              const Text(
                'Email Address',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                enabled: !isLocked,
                style: const TextStyle(color: Colors.white), // Added white text for input
                decoration: dec.copyWith(
                  hintText: 'Enter your email',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFF2A2A38), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Password',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: passCtrl,
                obscureText: obscure,
                enabled: !isLocked,
                style: const TextStyle(color: Colors.white), // Added white text for input
                decoration: dec.copyWith(
                  hintText: 'Enter your password',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFF2A2A38), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                  ),
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
                          color: kAccentPurple, // Changed to match Save Changes button
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              
              // Replaced BlueButton with a custom styled ElevatedButton to match the screenshot
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: (auth.isLoading || isLocked) ? null : onLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentPurple,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: kAccentPurple.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isLocked ? 'LOCKED — WAIT ${lockSecsLeft}s' : 'LOG IN',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ",
                      style: TextStyle(
                          fontSize: 13, 
                          color: Colors.white70)), // Lightened for dark mode
                  GestureDetector(
                    onTap: () => context.go('/register'),
                    child: const Text('CREATE ACCOUNT',
                        style: TextStyle(
                            fontSize: 13,
                            color: kAccentPurple, // Changed to match Save Changes button
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