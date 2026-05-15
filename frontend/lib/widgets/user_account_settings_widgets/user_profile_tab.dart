import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'user_account_status_banner.dart';

const _kBlue = Color(0xFF00022E);

class UserProfileTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstCtrl;
  final TextEditingController lastCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController ojtHoursCtrl;

  final String? selectedDept;
  final List<String> departments;
  final bool loadingDepts;

  final String? profileMsg;
  final bool profileSuccess;
  final bool savingProfile;

  final void Function(String?) onDeptChanged;
  final VoidCallback onSave;

  const UserProfileTab({
    super.key,
    required this.formKey,
    required this.firstCtrl,
    required this.lastCtrl,
    required this.emailCtrl,
    required this.ojtHoursCtrl,
    required this.selectedDept,
    required this.departments,
    required this.loadingDepts,
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
          borderSide: const BorderSide(color: _kBlue, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1)),
    );
  }

  Widget _loadingDropdown(BuildContext context, String label) {
    final theme = context.internTheme;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: theme.formFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: theme.mutedText,
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: _kBlue)),
        ],
      ),
    );
  }

  Widget _dropdownField(BuildContext context,
      {required String label,
      required String? value,
      required String hint,
      required List<String> items,
      required void Function(String?)? onChanged}) {
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
                value: value,
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
                    UserAccountStatusBanner(
                        msg: profileMsg!, success: profileSuccess),
                    const SizedBox(height: 16),
                  ],
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: firstCtrl,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: theme.surfaceText),
                        decoration: _getFormDecoration(context, 'First Name'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: lastCtrl,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: theme.surfaceText),
                        decoration: _getFormDecoration(context, 'Last Name'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailCtrl,
                    enabled: false,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.mutedText),
                    decoration: _getFormDecoration(
                        context, 'Email (cannot change)',
                        prefixIcon: Icons.email_outlined),
                  ),
                  const SizedBox(height: 16),
                  loadingDepts
                      ? _loadingDropdown(context, 'Department')
                      : _dropdownField(
                          context,
                          label: 'Department',
                          value: selectedDept,
                          hint: departments.isEmpty
                              ? 'None available'
                              : 'Select Department',
                          items: departments,
                          onChanged: onDeptChanged,
                        ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: ojtHoursCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.surfaceText),
                    decoration: _getFormDecoration(
                        context, 'Required OJT Hours',
                        prefixIcon: Icons.access_time_outlined),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final parsed = int.tryParse(v.trim());
                      if (parsed == null || parsed <= 0) {
                        return 'Enter a valid number of hours';
                      }
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
              onPressed: savingProfile ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
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
                  : const Text('SAVE CHANGES',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.8)),
            ),
          ),
        ),
      ],
    );
  }
}
