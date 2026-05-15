import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'status_message_banner.dart';

class PasswordFormTab extends StatefulWidget {
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

  @override
  State<PasswordFormTab> createState() => _PasswordFormTabState();
}

class _PasswordFormTabState extends State<PasswordFormTab> {
  bool _isEditing = false;

  @override
  void didUpdateWidget(covariant PasswordFormTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Automatically hide the save button again if a save just completed successfully
    if (oldWidget.savingPass && !widget.savingPass && widget.passSuccess) {
      setState(() {
        _isEditing = false;
      });
    }
  }

  void _markAsEdited() {
    if (!_isEditing) {
      setState(() {
        _isEditing = true;
      });
    }
  }

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

  Widget _passField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
    VoidCallback? onTap,
    void Function(String)? onChanged,
  }) =>
      TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        onTap: onTap,
        onChanged: onChanged,
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
              key: widget.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.passMsg != null) ...[
                    StatusMessageBanner(msg: widget.passMsg!, success: widget.passSuccess),
                    const SizedBox(height: 16),
                  ],
                  _passField(
                    context,
                    controller: widget.curPassCtrl,
                    label: 'Current Password',
                    obscure: widget.obscureCur,
                    onToggle: widget.onToggleCur,
                    onTap: _markAsEdited,
                    onChanged: (_) => _markAsEdited(),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  _passField(
                    context,
                    controller: widget.newPassCtrl,
                    label: 'New Password',
                    obscure: widget.obscureNew,
                    onToggle: widget.onToggleNew,
                    onTap: _markAsEdited,
                    onChanged: (_) => _markAsEdited(),
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
                    controller: widget.confirmPassCtrl,
                    label: 'Confirm New Password',
                    obscure: widget.obscureConf,
                    onToggle: widget.onToggleConf,
                    onTap: _markAsEdited,
                    onChanged: (_) => _markAsEdited(),
                    validator: (v) {
                      if (v!.isEmpty) return 'Required';
                      if (v != widget.newPassCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Use AnimatedSwitcher to smoothly reveal the button when interacted with
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1.0,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          // Show the button if they are editing OR if it is actively saving
          child: (_isEditing || widget.savingPass)
              ? Padding(
                  key: const ValueKey('save_button'),
                  padding: const EdgeInsets.fromLTRB(40, 0, 40, 28),
                  child: SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.savingPass ? null : widget.onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: widget.savingPass
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5)),
                    ),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('empty_space')),
        ),
      ],
    );
  }
}