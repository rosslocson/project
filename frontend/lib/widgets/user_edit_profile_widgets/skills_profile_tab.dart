import 'package:flutter/material.dart';
import 'edit_profile_form_components.dart';

class SkillsProfileTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController bioCtrl;
  final TextEditingController techSkillsCtrl;
  final TextEditingController softSkillsCtrl;
  final TextEditingController linkedinCtrl;
  final TextEditingController githubCtrl;

  const SkillsProfileTab({
    super.key,
    required this.formKey,
    required this.bioCtrl,
    required this.techSkillsCtrl,
    required this.softSkillsCtrl,
    required this.linkedinCtrl,
    required this.githubCtrl,
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
            const FormSectionTitle(title: 'Skills & Profile', sub: 'Bio, technical and soft skills, and social links'),
            
            const FormLabel(text: 'Bio'),
            CustomTextField(ctrl: bioCtrl, hint: 'A short description about yourself…', maxLines: 4),
            const SizedBox(height: 16),
            
            const FormLabel(text: 'Technical Skills'),
            CustomTextField(ctrl: techSkillsCtrl, hint: 'Flutter, Dart, Python, SQL  (comma-separated)', maxLines: 2),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 2),
              child: Text('Separate each skill with a comma', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ),
            const SizedBox(height: 16),
            
            const FormLabel(text: 'Soft Skills'),
            CustomTextField(ctrl: softSkillsCtrl, hint: 'Teamwork, Leadership, Communication  (comma-separated)', maxLines: 2),
            const SizedBox(height: 16),
            
            const FormLabel(text: 'LinkedIn URL'),
            CustomTextField(ctrl: linkedinCtrl, hint: 'https://linkedin.com/in/yourname', keyboardType: TextInputType.url),
            const SizedBox(height: 16),
            
            const FormLabel(text: 'GitHub URL'),
            CustomTextField(ctrl: githubCtrl, hint: 'https://github.com/yourname', keyboardType: TextInputType.url),
          ],
        ),
      ),
    );
  }
}