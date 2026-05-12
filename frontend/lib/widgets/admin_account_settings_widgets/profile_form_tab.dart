import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'status_message_banner.dart';

class ProfileFormTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstCtrl;
  final TextEditingController lastCtrl;
  final TextEditingController emailCtrl;
  final String? selectedDept;
  final List<String> departments;
  final bool isLoadingDepartments;
  final String? profileMsg;
  final bool profileSuccess;
  final bool savingProfile;
  final void Function(String?) onDeptChanged;
  final VoidCallback onSave;

  const ProfileFormTab({
    super.key,
    required this.formKey,
    required this.firstCtrl,
    required this.lastCtrl,
    required this.emailCtrl,
    required this.selectedDept,
    required this.departments,
    required this.isLoadingDepartments,
    required this.profileMsg,
    required this.profileSuccess,
    required this.savingProfile,
    required this.onDeptChanged,
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
      labelStyle: TextStyle(
          fontSize: 13, color: theme.mutedText, fontWeight: FontWeight.w500),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: theme.mutedText, size: 18)
          : null,
      filled: true,
      fillColor: theme.formFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.border, width: 1)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor, width: 1)),
    );
  }

  Widget _dropdownField(
    BuildContext context, {
    required String label,
    required String? value,
    required String hint,
    required List<String> items,
    required void Function(String?)? onChanged,
  }) {
    final theme = context.internTheme;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: theme.formFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: theme.mutedText,
                    fontWeight: FontWeight.w600)),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: (value != null && items.contains(value))
                      ? value
                      : null, // ← fix here
                  isDense: true,
                  hint: Text(hint,
                      style: TextStyle(
                          color: theme.mutedText,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down,
                      color: theme.mutedText, size: 18),
                  style: TextStyle(
                      color: theme.surfaceText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                  items: items
                      .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ],
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;
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
                  if (profileMsg != null) ...[
                    StatusMessageBanner(
                        msg: profileMsg!, success: profileSuccess),
                    const SizedBox(height: 16),
                  ],
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                      controller: firstCtrl,
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500, color: theme.surfaceText),
                      decoration: _getFormDecoration(context, 'First Name'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    )),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                      controller: lastCtrl,
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500, color: theme.surfaceText),
                      decoration: _getFormDecoration(context, 'Last Name'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    )),
                  ]),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailCtrl,
                    enabled: false,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.mutedText),
                    decoration: _getFormDecoration(context, 'Email (cannot change)',
                        prefixIcon: Icons.email_outlined),
                  ),
                  const SizedBox(height: 16),
                  _dropdownField(
                    context,
                    label: 'Department',
                    value: selectedDept,
                    hint: isLoadingDepartments
                        ? 'Loading departments...'
                        : (departments.isEmpty ? 'N/A' : 'Select Department'),
                    items: departments,
                    onChanged: isLoadingDepartments ? null : onDeptChanged,
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
              onPressed: savingProfile ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: savingProfile
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Save Changes',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 0.5)),
            ),
          ),
        ),
      ],
    );
  }
}