import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../app_theme.dart';
import 'locked_banner.dart';

const kCosmicBlue = Color(0xFF00022E);
const kAccentPurple = Color(0xFF7367F0);

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dec = pillInputDecoration();

    final labelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white : const Color(0xFF00022E),
    );

    final inputTextStyle = TextStyle(
      fontSize: 14,
      color: isDark ? Colors.white : Colors.black,
    );

    final defaultBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(
        color: isDark ? const Color(0xFF2A2A38) : Colors.grey.shade300,
        width: 1.5,
      ),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(
        color: isDark ? const Color(0xFF6366F1) : kCosmicBlue,
        width: 2,
      ),
    );

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
              Text(
                'LOG IN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : kCosmicBlue,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 40),

              if (isLocked) ...[
                LockedBanner(
                  lockSecsLeft: lockSecsLeft,
                  onForgotPassword: onForgotPassword,
                ),
                const SizedBox(height: 20),
              ] else if (auth.error != null) ...[
                // Custom banner matching image_71b702.png
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFB74D), width: 1),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                auth.error?.toLowerCase() == "invalid email or password"
                                    ? "invalid email or password"
                                    : (auth.error ?? "invalid email or password"),
                                style: const TextStyle(
                                  color: Color(0xFFE65100),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text(
                                "Attempts left: ",
                                style: TextStyle(color: Color(0xFFE65100), fontSize: 13),
                              ),
                              Row(
                                children: List.generate(
                                  attemptsLeft > 0 ? attemptsLeft : 0,
                                  (index) => const Padding(
                                    padding: EdgeInsets.only(right: 4.0),
                                    child: Icon(Icons.circle, size: 10, color: Color(0xFFFFA000)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: onForgotPassword,
                            child: const Text(
                              "Forgot password? Reset it →",
                              style: TextStyle(
                                color: Color(0xFFE65100),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close, color: Color(0xFFFFA000), size: 20),
                          onPressed: () => auth.clearError(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              Text('Email Address', style: labelStyle),
              const SizedBox(height: 6),
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                enabled: !isLocked,
                style: inputTextStyle,
                cursorColor: isDark ? kAccentPurple : kCosmicBlue,
                decoration: dec.copyWith(
                  hintText: 'Enter your email',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  fillColor: isDark ? const Color(0xFF14141D) : null,
                  enabledBorder: defaultBorder,
                  focusedBorder: focusedBorder,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              Text('Password', style: labelStyle),
              const SizedBox(height: 6),
              TextFormField(
                controller: passCtrl,
                obscureText: obscure,
                enabled: !isLocked,
                style: inputTextStyle,
                cursorColor: isDark ? kAccentPurple : kCosmicBlue,
                decoration: dec.copyWith(
                  hintText: 'Enter your password',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  fillColor: isDark ? const Color(0xFF14141D) : null,
                  enabledBorder: defaultBorder,
                  focusedBorder: focusedBorder,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
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
                  TextButton(
                    onPressed: onForgotPassword,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: isDark ? kAccentPurple : kCosmicBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              SizedBox(
                height: 50,
                child: isDark
                    ? ElevatedButton(
                        onPressed:
                            (auth.isLoading || isLocked) ? null : onLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAccentPurple,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: kAccentPurple.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
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
                                isLocked
                                    ? 'LOCKED — WAIT ${lockSecsLeft}s'
                                    : 'LOG IN',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      )
                    : BlueButton(
                        label: isLocked
                            ? 'LOCKED — WAIT ${lockSecsLeft}s'
                            : 'LOG IN',
                        onPressed: (auth.isLoading || isLocked) ? null : onLogin,
                        loading: auth.isLoading,
                      ),
              ),

              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: isDark ? kAccentPurple : kCosmicBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'CREATE ACCOUNT',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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