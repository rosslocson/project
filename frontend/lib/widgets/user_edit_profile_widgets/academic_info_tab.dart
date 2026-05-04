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
  final VoidCallback? onChanged;
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
    this.onChanged,
    this.requiredHours,
  });

  @override
  State<AcademicInfoTab> createState() => _AcademicInfoTabState();
}

class _AcademicInfoTabState extends State<AcademicInfoTab> {
  String? _computedEnd;
  String? _localDept;

  // Local state for Program and Year Level
  String? _selectedYearDropdown;
  final TextEditingController _localProgramCtrl = TextEditingController();
  final FocusNode _programFocus = FocusNode();

  final List<String> _yearOptions = [
    'SHS 12th Grade',
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
  ];

  @override
  void initState() {
    super.initState();
    _localDept = widget.selectedDept;

    widget.startCtrl.addListener(_onStartChanged);

    // --- Initialize Program ---
    if (widget.programCtrl.text.startsWith('Bachelor of Science in ')) {
      _localProgramCtrl.text =
          widget.programCtrl.text.replaceFirst('Bachelor of Science in ', '');
    } else {
      _localProgramCtrl.text = widget.programCtrl.text;
    }

    // --- Initialize Year Level ---
    if (_yearOptions.contains(widget.yearCtrl.text)) {
      _selectedYearDropdown = widget.yearCtrl.text;
    }

    // Listeners to format strings and update UI on focus change
    _programFocus.addListener(() {
      setState(() {});
    });

    _localProgramCtrl.addListener(() {
      if (_localProgramCtrl.text.isNotEmpty) {
        widget.programCtrl.text =
            'Bachelor of Science in ${_localProgramCtrl.text}';
      } else {
        widget.programCtrl.text = '';
      }
      widget.onChanged?.call();
    });

    _recalculate();
  }

  @override
  void dispose() {
    widget.startCtrl.removeListener(_onStartChanged);
    _localProgramCtrl.dispose();
    _programFocus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AcademicInfoTab old) {
    super.didUpdateWidget(old);
    if (old.selectedDept != widget.selectedDept) {
      setState(() => _localDept = widget.selectedDept);
    }
    if (old.startCtrl != widget.startCtrl) {
      old.startCtrl.removeListener(_onStartChanged);
      widget.startCtrl.addListener(_onStartChanged);
    }
    if (old.requiredHours != widget.requiredHours) {
      _recalculate();
    }
  }

  void _onStartChanged() {
    _recalculate();
    widget.onChanged?.call();
  }

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
      if (result != null && widget.endCtrl.text != result) {
        widget.endCtrl.text = result;
      }
    }
  }

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

  // A unified styling helper to guarantee all fields have the exact same box format
  InputDecoration _buildInputDecoration(BuildContext context,
      {required String hintText, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade700, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade700, width: 1.2),
      ),
      suffixIcon: suffixIcon,
      // Provide a slight margin below the error text to prevent crowding
      errorStyle: const TextStyle(height: 1.2),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool showProgramPrefix =
        _programFocus.hasFocus || _localProgramCtrl.text.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: widget.formKey,
        // THIS IS THE MAGIC LINE: It instantly checks rules as the user types or clears data
        autovalidateMode: AutovalidateMode.onUserInteraction,
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
                    DropdownButtonFormField<String>(
                      key: ValueKey(_localDept),
                      initialValue: _localDept,
                      icon: Icon(Icons.keyboard_arrow_down,
                          color: Colors.grey.shade600),
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black87),
                      decoration: _buildInputDecoration(context,
                          hintText: widget.departments.isEmpty
                              ? 'No departments yet'
                              : 'Select Department'),
                      items: widget.departments.map((dept) {
                        return DropdownMenuItem(value: dept, child: Text(dept));
                      }).toList(),
                      onChanged: (v) {
                        setState(() => _localDept = v);
                        widget.onDeptChanged(v);
                        widget.onChanged?.call();
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
                        icon: Icon(Icons.keyboard_arrow_down,
                            color: Colors.grey.shade300),
                        decoration:
                            _buildInputDecoration(context, hintText: ''),
                        items: [
                          DropdownMenuItem(
                            value: widget.defaultPosition,
                            child: Text(
                              widget.defaultPosition,
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 14),
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
            TextFormField(
              controller: widget.schoolCtrl,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              decoration: _buildInputDecoration(context,
                  hintText: 'e.g. Laguna State Polytechnic University'),
              validator: _requiredValidator,
              onChanged: (_) => widget.onChanged?.call(),
            ),
            const SizedBox(height: 16),

            // ── Program ───────────────────────────────────────────
            const FormLabel(text: 'Program'),
            TextFormField(
              controller: _localProgramCtrl,
              focusNode: _programFocus,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              decoration: _buildInputDecoration(context,
                      hintText: showProgramPrefix
                          ? 'Information Systems'
                          : 'e.g. Information Systems')
                  .copyWith(
                prefixText:
                    showProgramPrefix ? 'Bachelor of Science in ' : null,
                prefixStyle: TextStyle(
                  color: _programFocus.hasFocus
                      ? Colors.grey.shade500
                      : Colors.black87,
                  fontSize: 14,
                ),
              ),
              validator: _requiredValidator,
              onChanged: (_) => widget.onChanged?.call(),
            ),
            const SizedBox(height: 16),

            // ── Specialization + Year ─────────────────────────────
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FormLabel(text: 'Specialization'),
                    TextFormField(
                      controller: widget.specCtrl,
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black87),
                      decoration: _buildInputDecoration(context,
                          hintText: 'e.g. Web Development'),
                      validator: _requiredValidator,
                      onChanged: (_) => widget.onChanged?.call(),
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
                    DropdownButtonFormField<String>(
                      initialValue: _selectedYearDropdown,
                      icon: Icon(Icons.keyboard_arrow_down,
                          color: Colors.grey.shade600),
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black87),
                      decoration: _buildInputDecoration(context,
                          hintText: 'Select Year'),
                      items: _yearOptions.map((year) {
                        return DropdownMenuItem(value: year, child: Text(year));
                      }).toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedYearDropdown = v;
                          if (v != null) {
                            widget.yearCtrl.text = v;
                          }
                        });
                        widget.onChanged?.call();
                      },
                      validator: _requiredValidator,
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // ── Intern Number ─────────────────────────────────────
            const FormLabel(text: 'Intern Number'),
            TextFormField(
              controller: widget.internNumCtrl,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              decoration: _buildInputDecoration(context, hintText: 'e.g. 12'),
              validator: _requiredValidator,
              onChanged: (_) => widget.onChanged?.call(),
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
                      TextFormField(
                        controller: widget.startCtrl,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87),
                        decoration: _buildInputDecoration(
                          context,
                          hintText: 'YYYY-MM-DD',
                          suffixIcon: IconButton(
                            icon: Icon(Icons.calendar_today,
                                size: 18, color: Colors.grey.shade600),
                            onPressed: widget.onPickStart,
                          ),
                        ),
                        validator: _requiredValidator,
                        onChanged: (_) => widget.onChanged?.call(),
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
                      TextFormField(
                        controller: widget.endCtrl,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87),
                        decoration: _buildInputDecoration(
                          context,
                          hintText: 'YYYY-MM-DD',
                          suffixIcon: IconButton(
                            icon: Icon(Icons.calendar_today,
                                size: 18, color: Colors.grey.shade600),
                            onPressed: widget.onPickEnd,
                          ),
                        ),
                        validator: _requiredValidator,
                        onChanged: (_) => widget.onChanged?.call(),
                      ),
                      // Auto-computed badge
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
