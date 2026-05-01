import 'package:flutter/material.dart';
import '../../widgets/app_theme.dart';
import 'edit_profile_form_components.dart';

class AcademicInfoTab extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final List<String> departments;
  final String? selectedDept;
  final String defaultPosition;
  final TextEditingController schoolCtrl;
  final TextEditingController programCtrl;
  final TextEditingController specCtrl;
  final TextEditingController yearCtrl;
  final TextEditingController internNumCtrl;
  final TextEditingController startCtrl;
  final TextEditingController endCtrl;
  final void Function(String?) onDeptChanged;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final int? requiredHours;

  const AcademicInfoTab({
    super.key,
    required this.formKey,
    required this.departments,
    required this.selectedDept,
    required this.defaultPosition,
    required this.schoolCtrl,
    required this.programCtrl,
    required this.specCtrl,
    required this.yearCtrl,
    required this.internNumCtrl,
    required this.startCtrl,
    required this.endCtrl,
    required this.onDeptChanged,
    required this.onPickStart,
    required this.onPickEnd,
    this.requiredHours,
  });

  @override
  State<AcademicInfoTab> createState() => _AcademicInfoTabState();
}

class _AcademicInfoTabState extends State<AcademicInfoTab> {
  String? _computedEnd;
  String? _localDept;

  @override
  void initState() {
    super.initState();
    _localDept = widget.selectedDept;
    // Listen directly to the start controller — fires even inside TabBarView
    widget.startCtrl.addListener(_onStartChanged);
    // Compute immediately in case start date is already populated
    _recalculate();
  }

  @override
  void dispose() {
    widget.startCtrl.removeListener(_onStartChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(AcademicInfoTab old) {
    super.didUpdateWidget(old);
    if (old.selectedDept != widget.selectedDept) {
      setState(() => _localDept = widget.selectedDept);
    }
    // If the controller instance ever changes, re-wire the listener
    if (old.startCtrl != widget.startCtrl) {
      old.startCtrl.removeListener(_onStartChanged);
      widget.startCtrl.addListener(_onStartChanged);
    }
    // Also recalculate if requiredHours changed
    if (old.requiredHours != widget.requiredHours) {
      _recalculate();
    }
  }

  void _onStartChanged() => _recalculate();

  void _recalculate() {
    final startVal = widget.startCtrl.text.trim();
    final hours = widget.requiredHours;

    if (hours == null || hours <= 0 || startVal.isEmpty) {
      if (_computedEnd != null) setState(() => _computedEnd = null);
      return;
    }

    final result = _computeEndDate(startVal, hours);
    if (result != _computedEnd) {
      setState(() => _computedEnd = result);
      // Also write into the end controller so it saves correctly
      if (result != null && widget.endCtrl.text != result) {
        widget.endCtrl.text = result;
      }
    }
  }

  /// Counts ceil(requiredHours / 8) weekdays (Mon–Fri) forward from startDateStr.
  String? _computeEndDate(String startDateStr, int hours) {
    DateTime start;
    try {
      start = DateTime.parse(startDateStr);
    } catch (_) {
      return null;
    }

    final int daysNeeded = (hours / 8).ceil();
    DateTime current = start;
    int worked = 0;

    while (worked < daysNeeded) {
      if (current.weekday != DateTime.saturday &&
          current.weekday != DateTime.sunday) {
        worked++;
      }
      if (worked < daysNeeded) {
        current = current.add(const Duration(days: 1));
      }
    }

    return '${current.year}-'
        '${current.month.toString().padLeft(2, '0')}-'
        '${current.day.toString().padLeft(2, '0')}';
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FormSectionTitle(
              title: 'Academic Information',
              sub: 'Your school, program, department, and internship details',
            ),

            // ── Department + Position ──────────────────────────────
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FormLabel(text: 'Department'),
                    CustomDropdown(
                      // Key forces a full rebuild when value changes
                      key: ValueKey(_localDept),
                      value: _localDept,
                      hint: widget.departments.isEmpty
                          ? 'No departments yet'
                          : 'Select Department',
                      items: widget.departments,
                      onChanged: (v) {
                        setState(() => _localDept = v); // ← update local state
                        widget.onDeptChanged(v); // ← notify parent
                      },
                      validator: _requiredValidator,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FormLabel(text: 'Position'),
                    IgnorePointer(
                      child: DropdownButtonFormField<String>(
                        initialValue: widget.defaultPosition,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        icon: Icon(Icons.keyboard_arrow_down,
                            color: Colors.grey.shade300),
                        items: [
                          DropdownMenuItem(
                            value: widget.defaultPosition,
                            child: Text(
                              widget.defaultPosition,
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 13),
                            ),
                          ),
                        ],
                        onChanged: null,
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // ── School ────────────────────────────────────────────
            const FormLabel(text: 'School / University'),
            CustomTextField(
              ctrl: widget.schoolCtrl,
              hint: 'e.g. Laguna State Polytechnic University',
              validator: _requiredValidator,
            ),
            const SizedBox(height: 16),

            // ── Program ───────────────────────────────────────────
            const FormLabel(text: 'Program / Course'),
            CustomTextField(
              ctrl: widget.programCtrl,
              hint: 'e.g. BS Computer Science',
              validator: _requiredValidator,
            ),
            const SizedBox(height: 16),

            // ── Specialization + Year ─────────────────────────────
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FormLabel(text: 'Specialization'),
                    CustomTextField(
                      ctrl: widget.specCtrl,
                      hint: 'e.g. Web Development',
                      validator: _requiredValidator,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FormLabel(text: 'Year Level'),
                    CustomTextField(
                      ctrl: widget.yearCtrl,
                      hint: 'e.g. 4th Year',
                      validator: _requiredValidator,
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // ── Intern Number ─────────────────────────────────────
            const FormLabel(text: 'Intern Number'),
            CustomTextField(
              ctrl: widget.internNumCtrl,
              hint: 'e.g. 12',
              validator: _requiredValidator,
            ),
            const SizedBox(height: 16),

            // ── Start + End dates ─────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Start date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FormLabel(text: 'Internship Start'),
                      CustomTextField(
                        ctrl: widget.startCtrl,
                        hint: 'YYYY-MM-DD',
                        validator: _requiredValidator,
                        suffix: IconButton(
                          icon: Icon(Icons.calendar_today,
                              size: 18, color: Colors.grey.shade600),
                          onPressed: widget.onPickStart,
                        ),
                      ),
                      if (widget.requiredHours != null &&
                          widget.requiredHours! > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 11, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'End date auto-fills from ${widget.requiredHours} required OJT hrs',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // End date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FormLabel(text: 'Internship End'),
                      CustomTextField(
                        ctrl: widget.endCtrl,
                        hint: 'YYYY-MM-DD',
                        validator: _requiredValidator,
                        suffix: IconButton(
                          icon: Icon(Icons.calendar_today,
                              size: 18, color: Colors.grey.shade600),
                          onPressed: widget.onPickEnd,
                        ),
                      ),
                      // Auto-computed badge — only shown when computed
                      if (_computedEnd != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: kCrimsonDeep.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: kCrimsonDeep.withValues(alpha: 0.22)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.auto_awesome_rounded,
                                  size: 11,
                                  color: kCrimsonDeep.withValues(alpha: 0.75)),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  'Est. $_computedEnd · ${widget.requiredHours} hrs, 8 hrs/day Mon–Fri',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: kCrimsonDeep.withValues(alpha: 0.80),
                                    fontStyle: FontStyle.italic,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
