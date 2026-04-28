import 'package:flutter/material.dart';
import 'edit_profile_form_components.dart';

class AcademicInfoTab extends StatelessWidget {
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
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FormSectionTitle(title: 'Academic Information', sub: 'Your school, program, department, and internship details'),
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FormLabel(text: 'Department'),
                    CustomDropdown(
                      value: selectedDept,
                      hint: departments.isEmpty ? 'No departments yet' : 'Select Department',
                      items: departments,
                      onChanged: onDeptChanged,
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
                        initialValue: defaultPosition,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade300),
                        items: [
                          DropdownMenuItem(
                            value: defaultPosition,
                            child: Text(defaultPosition, style: const TextStyle(color: Colors.black54, fontSize: 13)),
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
            const FormLabel(text: 'School / University'),
            CustomTextField(ctrl: schoolCtrl, hint: 'e.g. University of Santo Tomas'),
            const SizedBox(height: 16),
            const FormLabel(text: 'Program / Course'),
            CustomTextField(ctrl: programCtrl, hint: 'e.g. BS Computer Science'),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FormLabel(text: 'Specialization'),
                    CustomTextField(ctrl: specCtrl, hint: 'e.g. Web Development'),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FormLabel(text: 'Year Level'),
                    CustomTextField(ctrl: yearCtrl, hint: 'e.g. 4th Year'),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),
            const FormLabel(text: 'Intern Number'),
            CustomTextField(ctrl: internNumCtrl, hint: 'e.g. 12'),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FormLabel(text: 'Internship Start'),
                    CustomTextField(
                      ctrl: startCtrl,
                      hint: 'YYYY-MM-DD',
                      suffix: IconButton(
                        icon: Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
                        onPressed: onPickStart,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FormLabel(text: 'Internship End'),
                    CustomTextField(
                      ctrl: endCtrl,
                      hint: 'YYYY-MM-DD',
                      suffix: IconButton(
                        icon: Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
                        onPressed: onPickEnd,
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}