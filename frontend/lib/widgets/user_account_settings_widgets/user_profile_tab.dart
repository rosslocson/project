import 'package:flutter/material.dart';
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

  InputDecoration _getFormDecoration(String label, {IconData? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey.shade500, size: 18) : null,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200, width: 1)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBlue, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade300, width: 1)),
    );
  }

  Widget _loadingDropdown(String label) => Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.black38, fontWeight: FontWeight.w500)),
            const Spacer(),
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _kBlue)),
          ],
        ),
      );

  Widget _dropdownField({required String label, required String? value, required String hint, required List<String> items, required void Function(String?)? onChanged}) => Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w600)),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isDense: true,
                  hint: Text(hint, style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w500)),
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[500], size: 18),
                  style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
                  items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
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
                    UserAccountStatusBanner(msg: profileMsg!, success: profileSuccess),
                    const SizedBox(height: 16),
                  ],
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: firstCtrl,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        decoration: _getFormDecoration('First Name'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: lastCtrl,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        decoration: _getFormDecoration('Last Name'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailCtrl,
                    enabled: false,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                    decoration: _getFormDecoration('Email (cannot change)', prefixIcon: Icons.email_outlined),
                  ),
                  const SizedBox(height: 16),
                  loadingDepts
                      ? _loadingDropdown('Department')
                      : _dropdownField(
                          label: 'Department',
                          value: selectedDept,
                          hint: departments.isEmpty ? 'None available' : 'Select Department',
                          items: departments,
                          onChanged: onDeptChanged,
                        ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: ojtHoursCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    decoration: _getFormDecoration('Required OJT Hours', prefixIcon: Icons.access_time_outlined),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final parsed = int.tryParse(v.trim());
                      if (parsed == null || parsed <= 0) return 'Enter a valid number of hours';
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: savingProfile
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5)),
            ),
          ),
        ),
      ],
    );
  }
}