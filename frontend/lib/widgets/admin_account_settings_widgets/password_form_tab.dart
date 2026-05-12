import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'status_message_banner.dart';

class PasswordFormTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController curPassCtrl;
  final TextEditingController newPassCtrl;
  final TextEditingController confirmPassCtrl;
  final bool obscureCur;
  final bool obscureNew;
  final bool obscureConf;
  final String? passMsg;
  final bool passSuccess;
  final bool savingPass;
  final VoidCallback onToggleCur;
  final VoidCallback onToggleNew;
  final VoidCallback onToggleConf;
  final VoidCallback onSave;

  const PasswordFormTab({
    super.key,
    required this.formKey,
    required this.curPassCtrl,
    required this.newPassCtrl,
    required this.confirmPassCtrl,
    required this.obscureCur,
    required this.obscureNew,
    required this.obscureConf,
    required this.passMsg,
    required this.passSuccess,
    required this.savingPass,
    required this.onToggleCur,
    required this.onToggleNew,
    required this.onToggleConf,
    required this.onSave,
  });

  InputDecoration _getFormDecoration(
    BuildContext context,
    String label, {
    IconData? prefixIcon,
  }) {
    final theme = context.internTheme;
    final isDark = context.isDarkInternTheme;
    final primaryColor = isDark ? const Color(0xFF7367F0) : const Color(0xFF00022E);
    final errorColor = isDark ? const Color(0xFF7367F0).withOpacity(0.6) : const Color(0xFF00022E).withOpacity(0.6);

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 13, color: theme.mutedText, fontWeight: FontWeight.w500),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: theme.mutedText, size: 18) : null,
      filled: true,
      fillColor: theme.formFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.border, width: 1)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: errorColor, width: 1)),
    );
  }

  Widget _passField(BuildContext context, {required TextEditingController controller, required String label, required bool obscure, required VoidCallback onToggle, required String? Function(String?) validator}) =>
      TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.internTheme.surfaceText),
        decoration: _getFormDecoration(context, label, prefixIcon: Icons.lock_outline).copyWith(
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 18, color: context.internTheme.mutedText),
            onPressed: onToggle,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkInternTheme;
    final primaryColor = isDark ? const Color(0xFF7367F0) : const Color(0xFF00022E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (passMsg != null) ...[
                    StatusMessageBanner(msg: passMsg!, success: passSuccess),
                    const SizedBox(height: 16),
                  ],
                  _passField(
                    context,
                    controller: curPassCtrl,
                    label: 'Current Password',
                    obscure: obscureCur,
                    onToggle: onToggleCur,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  _passField(
                    context,
                    controller: newPassCtrl,
                    label: 'New Password',
                    obscure: obscureNew,
                    onToggle: onToggleNew,
                    validator: (v) {
                      if (v == null || v.length < 8) return 'Min 8 characters';
                      if (!v.contains(RegExp(r'[A-Z]'))) return 'Need one uppercase letter';
                      if (!v.contains(RegExp(r'[0-9]'))) return 'Need one number';
                      if (!v.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return 'Need one special character';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _passField(
                    context,
                    controller: confirmPassCtrl,
                    label: 'Confirm New Password',
                    obscure: obscureConf,
                    onToggle: onToggleConf,
                    validator: (v) {
                      if (v!.isEmpty) return 'Required';
                      if (v != newPassCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 28),
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: savingPass ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: savingPass
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5)),
            ),
          ),
        ),
      ],
    );
  }
}