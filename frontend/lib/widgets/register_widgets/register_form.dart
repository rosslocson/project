import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../app_theme.dart'; // Adjust path if needed
import 'register_error_banner.dart';
import 'password_strength_indicator.dart';

const kCosmicBlue = Color(0xFF00022E);

class RegisterForm {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstCtrl;
  final TextEditingController lastCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final TextEditingController confirmCtrl;
  final TextEditingController ojtHoursCtrl;

  final bool obscurePass;
  final bool obscureConfirm;
  final List<String> departments;
  final bool loadingDepts;
  final String? selectedDept;
  final String defaultPosition;

  final String passStrength;
  final Color passColor;
  final double passValue;
  final String? confirmError;

  final AuthProvider auth;

  final VoidCallback onToggleObscurePass;
  final VoidCallback onToggleObscureConfirm;
  final Function(String) onPassChanged;
  final Function(String) onConfirmChanged;
  final Function(String?) onDeptChanged;
  final VoidCallback onRegister;

  RegisterForm({
    required this.formKey,
    required this.firstCtrl,
    required this.lastCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.confirmCtrl,
    required this.obscurePass,
    required this.obscureConfirm,
    required this.departments,
    required this.loadingDepts,
    required this.selectedDept,
    required this.defaultPosition,
    required this.ojtHoursCtrl,
    required this.passStrength,
    required this.passColor,
    required this.passValue,
    required this.confirmError,
    required this.auth,
    required this.onToggleObscurePass,
    required this.onToggleObscureConfirm,
    required this.onPassChanged,
    required this.onConfirmChanged,
    required this.onDeptChanged,
    required this.onRegister,
  });

  Widget _shimmerDropdown(InputDecoration dec) {
    return DropdownButtonFormField<String>(
      decoration: dec.copyWith(filled: true, fillColor: Colors.grey.shade100),
      hint: const Text('Loading...', style: TextStyle(fontSize: 13)),
      icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade300),
      items: const [],
      onChanged: null,
    );
  }

  Widget buildForm({required bool isMobile, required BuildContext context}) {
    final dec = pillInputDecoration();

    return Container(
      alignment: Alignment.center,
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 64, vertical: isMobile ? 24 : 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'CREATE ACCOUNT',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: kCosmicBlue,
                    letterSpacing: 1.2),
              ),
              const Spacer(flex: 3),

              if (auth.error != null) ...[
                RegisterErrorBanner(
                  error: auth.error!,
                  onClear: () => context.read<AuthProvider>().clearError(),
                ),
                const SizedBox(height: 8),
              ],

              // ── First Name / Last Name ──────────────────────────────────
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      fieldLabel('First Name'),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: firstCtrl,
                        decoration: dec.copyWith(hintText: 'First Name'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      fieldLabel('Last Name'),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: lastCtrl,
                        decoration: dec.copyWith(hintText: 'Last Name'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ]),
              const Spacer(flex: 1),

              // ── Email ───────────────────────────────────────────────────
              fieldLabel('Email Address'),
              const SizedBox(height: 4),
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: dec.copyWith(hintText: 'Enter Email Address'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  final emailRegex = RegExp(
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                  if (!emailRegex.hasMatch(v)) {
                    return 'Enter a valid email (e.g., name@example.com)';
                  }
                  return null;
                },
              ),
              const Spacer(flex: 1),

              // ── Department / Position ───────────────────────────────────
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      fieldLabel('Department'),
                      const SizedBox(height: 4),
                      loadingDepts
                          ? _shimmerDropdown(dec)
                          : DropdownButtonFormField<String>(
                              initialValue: selectedDept,
                              decoration: dec,
                              hint: Text(
                                  departments.isEmpty
                                      ? 'None available'
                                      : 'Select Department',
                                  style: const TextStyle(fontSize: 13)),
                              icon: Icon(Icons.keyboard_arrow_down,
                                  color: Colors.grey.shade500),
                              items: departments
                                  .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s,
                                          overflow: TextOverflow.ellipsis,
                                          style:
                                              const TextStyle(fontSize: 12))))
                                  .toList(),
                              onChanged: onDeptChanged,
                            ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      fieldLabel('Position'),
                      const SizedBox(height: 4),
                      IgnorePointer(
                        child: DropdownButtonFormField<String>(
                          initialValue: defaultPosition,
                          decoration: dec.copyWith(
                              filled: true, fillColor: Colors.grey.shade100),
                          icon: Icon(Icons.keyboard_arrow_down,
                              color: Colors.grey.shade300),
                          items: [
                            DropdownMenuItem(
                                value: defaultPosition,
                                child: Text(defaultPosition,
                                    style: const TextStyle(fontSize: 12))),
                          ],
                          onChanged: null,
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
              const Spacer(flex: 1),

              // ── Required OJT Hours ──────────────────────────────────────
              fieldLabel('Required OJT Hours'),
              const SizedBox(height: 4),
              TextFormField(
                controller: ojtHoursCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: dec.copyWith(
                  hintText: 'e.g. 400',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.timer_outlined,
                        color: Color(0xFF9CA3AF), size: 20),
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter your required OJT hours';
                  }
                  final n = int.tryParse(v.trim());
                  if (n == null || n <= 0) {
                    return 'Enter a valid number greater than 0';
                  }
                  if (n > 2000) {
                    return 'Value seems too high — please check';
                  }
                  return null;
                },
              ),
              const Spacer(flex: 1),

              // ── Password ────────────────────────────────────────────────
              fieldLabel('Password'),
              const SizedBox(height: 4),
              TextFormField(
                controller: passCtrl,
                obscureText: obscurePass,
                onChanged: onPassChanged,
                decoration: dec.copyWith(
                  hintText: 'Create a password',
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: Icon(
                          obscurePass
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF9CA3AF),
                          size: 20),
                      onPressed: onToggleObscurePass,
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.length < 8) return 'Min 8 characters';
                  if (!v.contains(RegExp(r'[A-Z]'))) {
                    return 'Need one uppercase letter';
                  }
                  if (!v.contains(RegExp(r'[0-9]'))) return 'Need one number';
                  if (!v.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                    return 'Need one special character';
                  }
                  return null;
                },
              ),

              if (passCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 6),
                PasswordStrengthIndicator(
                    passValue: passValue,
                    passColor: passColor,
                    passStrength: passStrength),
              ],
              const Spacer(flex: 1),

              // ── Confirm Password ────────────────────────────────────────
              fieldLabel('Confirm Password'),
              const SizedBox(height: 4),
              TextFormField(
                controller: confirmCtrl,
                obscureText: obscureConfirm,
                onChanged: onConfirmChanged,
                decoration: dec.copyWith(
                  hintText: 'Confirm your password',
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF9CA3AF),
                          size: 20),
                      onPressed: onToggleObscureConfirm,
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (v != passCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),

              if (confirmError != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(confirmError!,
                      style: const TextStyle(fontSize: 11, color: Colors.red)),
                ),
              ],
              const Spacer(flex: 3),

              // ── Submit ──────────────────────────────────────────────────
              BlueButton(
                label: 'Create Account',
                onPressed: auth.isLoading ? null : onRegister,
                loading: auth.isLoading,
              ),
              const Spacer(flex: 2),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? ',
                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text('Log In',
                        style: TextStyle(
                            fontSize: 13,
                            color: kCosmicBlue,
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
