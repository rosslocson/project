import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'status_message_banner.dart';

class ProfileFormTab extends StatefulWidget {
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

  @override
  State<ProfileFormTab> createState() => _ProfileFormTabState();
}

class _ProfileFormTabState extends State<ProfileFormTab> {
  bool _isEditing = false;

  @override
  void didUpdateWidget(covariant ProfileFormTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Automatically hide the save button again if a save just completed successfully
    if (oldWidget.savingProfile && !widget.savingProfile && widget.profileSuccess) {
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
    final primaryColor =
        isDark ? const Color(0xFF7367F0) : const Color(0xFF00022E);
    final errorColor = isDark
        ? const Color(0xFF7367F0).withOpacity(0.6)
        : const Color(0xFF00022E).withOpacity(0.6);

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
    VoidCallback? onTap,
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
                value: (value != null && items.contains(value)) ? value : null,
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
                onTap: onTap, // Triggers when the dropdown is clicked
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
    final primaryColor =
        isDark ? const Color(0xFF7367F0) : const Color(0xFF00022E);

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
                  if (widget.profileMsg != null) ...[
                    StatusMessageBanner(
                        msg: widget.profileMsg!,
                        success: widget.profileSuccess),
                    const SizedBox(height: 16),
                  ],
                  Row(children: [
                    Expanded(
                        child: TextFormField(
                      controller: widget.firstCtrl,
                      onTap: _markAsEdited,
                      onChanged: (_) => _markAsEdited(),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.surfaceText),
                      decoration: _getFormDecoration(context, 'First Name'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    )),
                    const SizedBox(width: 16),
                    Expanded(
                        child: TextFormField(
                      controller: widget.lastCtrl,
                      onTap: _markAsEdited,
                      onChanged: (_) => _markAsEdited(),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.surfaceText),
                      decoration: _getFormDecoration(context, 'Last Name'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    )),
                  ]),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: widget.emailCtrl,
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
                  _dropdownField(
                    context,
                    label: 'Department',
                    value: widget.selectedDept,
                    hint: widget.isLoadingDepartments
                        ? 'Loading departments...'
                        : (widget.departments.isEmpty
                            ? 'N/A'
                            : 'Select Department'),
                    items: widget.departments,
                    onTap: _markAsEdited,
                    onChanged: widget.isLoadingDepartments
                        ? null
                        : (val) {
                            _markAsEdited();
                            widget.onDeptChanged(val);
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
          // We show the button if they are editing OR if it is actively saving
          child: (_isEditing || widget.savingProfile)
              ? Padding(
                  key: const ValueKey('save_button'),
                  padding: const EdgeInsets.fromLTRB(40, 0, 40, 28),
                  child: SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.savingProfile ? null : widget.onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: widget.savingProfile
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('SAVE CHANGES',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  letterSpacing: 0.8)),
                    ),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('empty_space')),
        ),
      ],
    );
  }
}