import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'user_account_status_banner.dart';

const _kBlue = Color(0xFF00022E);

class UserProfileTab extends StatefulWidget {
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

  @override
  State<UserProfileTab> createState() => _UserProfileTabState();
}

class _UserProfileTabState extends State<UserProfileTab> {
  // We store the initial states to compare against current inputs
  late String _initFirst;
  late String _initLast;
  late String _initOjt;
  String? _initDept;

  @override
  void initState() {
    super.initState();
    _captureInitialState();
  }

  void _captureInitialState() {
    _initFirst = widget.firstCtrl.text;
    _initLast = widget.lastCtrl.text;
    _initOjt = widget.ojtHoursCtrl.text;
    _initDept = widget.selectedDept;
  }

  @override
  void didUpdateWidget(covariant UserProfileTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the department finishes loading later, update the baseline
    if (oldWidget.loadingDepts && !widget.loadingDepts) {
      _initDept = widget.selectedDept;
    }
    // If the user successfully saves, update the baseline to the newly saved values
    if (widget.profileSuccess && !oldWidget.profileSuccess) {
      _captureInitialState();
    }
  }

  bool get _hasUnsavedChanges {
    return widget.firstCtrl.text != _initFirst ||
        widget.lastCtrl.text != _initLast ||
        widget.ojtHoursCtrl.text != _initOjt ||
        widget.selectedDept != _initDept;
  }

  void _cancelChanges() {
    widget.firstCtrl.text = _initFirst;
    widget.lastCtrl.text = _initLast;
    widget.ojtHoursCtrl.text = _initOjt;
    widget.onDeptChanged(_initDept);
    widget.formKey.currentState?.reset();
  }

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
          borderSide: BorderSide(
              color:
                  context.isDarkInternTheme ? const Color(0xFF7367F0) : _kBlue,
              width: 1.5)),
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
          SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color:
                      context.isDarkInternTheme ? const Color(0xFF7367F0) : _kBlue)),
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

  Widget _buildActionButtons(BuildContext context) {
    // We use AnimatedBuilder to evaluate button visibility instantly as the user types
    return AnimatedBuilder(
      animation: Listenable.merge(
          [widget.firstCtrl, widget.lastCtrl, widget.ojtHoursCtrl]),
      builder: (context, child) {
        if (!_hasUnsavedChanges) {
          // Empty space maintains your UI layout spacing when hidden
          return const SizedBox(height: 28);
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 28),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: widget.savingProfile ? null : _cancelChanges,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.internTheme.surfaceText,
                      side: BorderSide(color: context.internTheme.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: widget.savingProfile ? null : widget.onSave,
                    style: ElevatedButton.styleFrom(
                      // AFTER
backgroundColor: context.isDarkInternTheme
    ? const Color(0xFF7367F0)
    : _kBlue,
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
                        : const Text('SAVE',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                letterSpacing: 0.5)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
              key: widget.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.profileMsg != null) ...[
                    UserAccountStatusBanner(
                        msg: widget.profileMsg!,
                        success: widget.profileSuccess),
                    const SizedBox(height: 16),
                  ],
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: widget.firstCtrl,
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
                        controller: widget.lastCtrl,
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
                  widget.loadingDepts
                      ? _loadingDropdown(context, 'Department')
                      : _dropdownField(
                          context,
                          label: 'Department',
                          value: widget.selectedDept,
                          hint: widget.departments.isEmpty
                              ? 'None available'
                              : 'Select Department',
                          items: widget.departments,
                          onChanged: widget.onDeptChanged,
                        ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: widget.ojtHoursCtrl,
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
        _buildActionButtons(context),
      ],
    );
  }
}