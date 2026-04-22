import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/user_sidebar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UserEditProfileScreen — dedicated Edit Profile page
// Two sections:
//   1. Academic Info  (dept, position, school, program, specialization,
//                      year level, intern number, start/end dates)
//   2. Skills         (bio, technical skills, soft skills, LinkedIn, GitHub)
// ─────────────────────────────────────────────────────────────────────────────
class UserEditProfileScreen extends StatefulWidget {
  const UserEditProfileScreen({super.key});
  @override
  State<UserEditProfileScreen> createState() => _UserEditProfileScreenState();
}

class _UserEditProfileScreenState extends State<UserEditProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabs;

  // ── Academic Info ──────────────────────────────────────────────────────────
  final _academicKey = GlobalKey<FormState>();
  List<String> _departments = [];
  List<String> _positions = [];
  bool _configLoading = true;
  String? _selectedDept;
  String? _selectedPos;
  late TextEditingController _schoolCtrl;
  late TextEditingController _programCtrl;
  late TextEditingController _specCtrl;
  late TextEditingController _yearCtrl;
  late TextEditingController _internNumCtrl;
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;

  // ── Skills ─────────────────────────────────────────────────────────────────
  final _skillsKey = GlobalKey<FormState>();
  late TextEditingController _bioCtrl;
  late TextEditingController _techSkillsCtrl;
  late TextEditingController _softSkillsCtrl;
  late TextEditingController _linkedinCtrl;
  late TextEditingController _githubCtrl;

  // UI state
  bool _saving = false;
  String? _successMsg;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);

    final user = context.read<AuthProvider>().user;

    _schoolCtrl = TextEditingController(text: user?['school'] ?? '');
    _programCtrl = TextEditingController(text: user?['program'] ?? '');
    _specCtrl = TextEditingController(text: user?['specialization'] ?? '');
    _yearCtrl = TextEditingController(text: user?['year_level'] ?? '');
    _internNumCtrl = TextEditingController(text: user?['intern_number'] ?? '');
    _startCtrl = TextEditingController(text: user?['start_date'] ?? '');
    _endCtrl = TextEditingController(text: user?['end_date'] ?? '');

    _bioCtrl = TextEditingController(text: user?['bio'] ?? '');
    _techSkillsCtrl =
        TextEditingController(text: user?['technical_skills'] ?? '');
    _softSkillsCtrl = TextEditingController(text: user?['soft_skills'] ?? '');
    _linkedinCtrl = TextEditingController(text: user?['linked_in'] ?? '');
    _githubCtrl = TextEditingController(text: user?['git_hub'] ?? '');

    final dept = user?['department'] as String? ?? '';
    final pos = user?['position'] as String? ?? '';
    _selectedDept = dept.isNotEmpty ? dept : null;
    _selectedPos = pos.isNotEmpty ? pos : null;

    _loadConfig();
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final c in [
      _schoolCtrl,
      _programCtrl,
      _specCtrl,
      _yearCtrl,
      _internNumCtrl,
      _startCtrl,
      _endCtrl,
      _bioCtrl,
      _techSkillsCtrl,
      _softSkillsCtrl,
      _linkedinCtrl,
      _githubCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final d = await ApiService.getConfig(type: 'department');
    final p = await ApiService.getConfig(type: 'position');
    if (!mounted) return;
    setState(() {
      _departments =
          (d['items'] as List? ?? []).map((e) => e['name'] as String).toList();
      _positions =
          (p['items'] as List? ?? []).map((e) => e['name'] as String).toList();
      if (_selectedDept != null && !_departments.contains(_selectedDept)) {
        _departments.add(_selectedDept!);
      }
      if (_selectedPos != null && !_positions.contains(_selectedPos)) {
        _positions.add(_selectedPos!);
      }
      _configLoading = false;
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _successMsg = null;
      _errorMsg = null;
    });

    final res = await ApiService.updateProfile({
      'department': _selectedDept ?? '',
      'position': _selectedPos ?? '',
      'school': _schoolCtrl.text.trim(),
      'program': _programCtrl.text.trim(),
      'specialization': _specCtrl.text.trim(),
      'year_level': _yearCtrl.text.trim(),
      'intern_number': _internNumCtrl.text.trim(),
      'start_date': _startCtrl.text.trim(),
      'end_date': _endCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),
      'technical_skills': _techSkillsCtrl.text.trim(),
      'soft_skills': _softSkillsCtrl.text.trim(),
      'linked_in': _linkedinCtrl.text.trim(),
      'git_hub': _githubCtrl.text.trim(),
    });

    if (!mounted) return;
    setState(() => _saving = false);

    if (res['ok'] == true) {
      context
          .read<AuthProvider>()
          .updateUserData(Map<String, dynamic>.from(res['user'] ?? {}));

      // ✅ Always re-fetch to guarantee MyProfileScreen sees latest data
      final fresh = await ApiService.getProfile();
      if (mounted && (fresh['ok'] == true || fresh['id'] != null)) {
        context
            .read<AuthProvider>()
            .updateUserData(Map<String, dynamic>.from(fresh));
      }

      if (mounted)
        setState(() => _successMsg = 'Profile updated successfully!');
    } else {
      // ✅ Now actually surfaces errors
      if (mounted)
        setState(() => _errorMsg =
            res['error'] ?? res['details'] ?? 'Save failed. Please try again.');
    }
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    DateTime initial = DateTime.now();
    if (ctrl.text.isNotEmpty) {
      try {
        initial = DateTime.parse(ctrl.text);
      } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: kCrimsonDeep),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ctrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  // ── Shared field helpers ───────────────────────────────────────────────────
  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.75))),
      );

  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
  }) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: kCrimsonDeep.withOpacity(0.8), width: 1.5),
          ),
        ),
      );

  Widget _dropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required void Function(String?) onChanged,
  }) =>
      DropdownButtonFormField<String>(
        initialValue: value,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        dropdownColor: const Color(0xFF1A0A10),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: kCrimsonDeep.withOpacity(0.8), width: 1.5),
          ),
        ),
        hint: Text(hint,
            style:
                TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
        icon: Icon(Icons.keyboard_arrow_down,
            color: Colors.white.withOpacity(0.5)),
        items: items
            .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 13)),
                ))
            .toList(),
        onChanged: items.isEmpty ? null : onChanged,
      );

  Widget _sectionTitle(String title, String sub) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 4),
          Text(sub,
              style: TextStyle(
                  fontSize: 12, color: Colors.white.withOpacity(0.5))),
        ]),
      );

  // ── Tab 1: Academic Info ───────────────────────────────────────────────────
  Widget _buildAcademicTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _academicKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionTitle('Academic Information',
                'Your school, program, department, and internship details'),
            if (_configLoading)
              const Center(
                  child: CircularProgressIndicator(color: Colors.white))
            else ...[
              Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      _label('Department'),
                      _dropdown(
                        value: _selectedDept,
                        hint: _departments.isEmpty
                            ? 'No departments yet'
                            : 'Select Department',
                        items: _departments,
                        onChanged: (v) => setState(() {
                          _selectedDept = v;
                          _selectedPos = null;
                        }),
                      ),
                    ])),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      _label('Position'),
                      _dropdown(
                        value: _selectedPos,
                        hint: _positions.isEmpty
                            ? 'Select Dept First'
                            : 'Select Position',
                        items: _positions,
                        onChanged: (v) => setState(() => _selectedPos = v),
                      ),
                    ])),
              ]),
              const SizedBox(height: 16),
            ],
            _label('School / University'),
            _field(ctrl: _schoolCtrl, hint: 'e.g. University of Santo Tomas'),
            const SizedBox(height: 16),
            _label('Program / Course'),
            _field(ctrl: _programCtrl, hint: 'e.g. BS Computer Science'),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    _label('Specialization'),
                    _field(ctrl: _specCtrl, hint: 'e.g. Web Development'),
                  ])),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    _label('Year Level'),
                    _field(ctrl: _yearCtrl, hint: 'e.g. 4th Year'),
                  ])),
            ]),
            const SizedBox(height: 16),
            _label('Intern Number'),
            _field(ctrl: _internNumCtrl, hint: 'e.g. 12'),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    _label('Internship Start'),
                    _field(
                      ctrl: _startCtrl,
                      hint: 'YYYY-MM-DD',
                      suffix: IconButton(
                        icon: Icon(Icons.calendar_today,
                            size: 18, color: Colors.white.withOpacity(0.5)),
                        onPressed: () => _pickDate(_startCtrl),
                      ),
                    ),
                  ])),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    _label('Internship End'),
                    _field(
                      ctrl: _endCtrl,
                      hint: 'YYYY-MM-DD',
                      suffix: IconButton(
                        icon: Icon(Icons.calendar_today,
                            size: 18, color: Colors.white.withOpacity(0.5)),
                        onPressed: () => _pickDate(_endCtrl),
                      ),
                    ),
                  ])),
            ]),
          ]),
        ),
      );

  // ── Tab 2: Skills ──────────────────────────────────────────────────────────
  Widget _buildSkillsTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _skillsKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionTitle('Skills & Profile',
                'Bio, technical and soft skills, and social links'),
            _label('Bio'),
            _field(
                ctrl: _bioCtrl,
                hint: 'A short description about yourself…',
                maxLines: 4),
            const SizedBox(height: 16),
            _label('Technical Skills'),
            _field(
                ctrl: _techSkillsCtrl,
                hint: 'Flutter, Dart, Python, SQL  (comma-separated)',
                maxLines: 2),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 2),
              child: Text('Separate each skill with a comma',
                  style: TextStyle(
                      fontSize: 11, color: Colors.white.withOpacity(0.35))),
            ),
            const SizedBox(height: 16),
            _label('Soft Skills'),
            _field(
                ctrl: _softSkillsCtrl,
                hint: 'Teamwork, Leadership, Communication  (comma-separated)',
                maxLines: 2),
            const SizedBox(height: 16),
            _label('LinkedIn URL'),
            _field(
                ctrl: _linkedinCtrl,
                hint: 'https://linkedin.com/in/yourname',
                keyboardType: TextInputType.url),
            const SizedBox(height: 16),
            _label('GitHub URL'),
            _field(
                ctrl: _githubCtrl,
                hint: 'https://github.com/yourname',
                keyboardType: TextInputType.url),
          ]),
        ),
      );

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = user?['first_name'] as String? ?? 'User';
    final initials = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';

    return Scaffold(
      body: Row(children: [
        const UserSidebar(currentRoute: '/edit-profile'),
        Expanded(
            child: Stack(children: [
          Positioned.fill(
              child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF00022E), // kCosmicBlue
                  Color(0xFF1A1F5A), // kNavyDeep
                ],
              ),
            ),
          )),
          Positioned.fill(
            child: Column(children: [
              // ── Top bar ──────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF050505).withOpacity(0.95),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => context.go('/profile'),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text('Edit Profile',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const Spacer(),
                  Text(firstName,
                      style: TextStyle(
                          fontSize: 15, color: Colors.white.withOpacity(0.85))),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: kCrimsonDeep.withOpacity(0.6),
                    child: Text(initials,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ]),
              ),

              // ── Card ─────────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.12), width: 1),
                    ),
                    child: Column(children: [
                      // Feedback banners
                      if (_successMsg != null)
                        _banner(_successMsg!, success: true),
                      if (_errorMsg != null)
                        _banner(_errorMsg!, success: false),

                      // Tabs
                      TabBar(
                        controller: _tabs,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withOpacity(0.4),
                        indicatorColor: kCrimsonDeep,
                        indicatorWeight: 3,
                        dividerColor: Colors.white.withOpacity(0.08),
                        tabs: const [
                          Tab(
                              icon: Icon(Icons.school_outlined, size: 18),
                              text: 'Academic Info'),
                          Tab(
                              icon: Icon(Icons.stars_outlined, size: 18),
                              text: 'Skills'),
                        ],
                      ),

                      // Tab views
                      Expanded(
                        child: TabBarView(
                          controller: _tabs,
                          children: [
                            _buildAcademicTab(),
                            _buildSkillsTab(),
                          ],
                        ),
                      ),

                      // Save button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kCrimsonDeep,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: _saving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text('SAVE CHANGES',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8)),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ])),
      ]),
    );
  }

  Widget _banner(String msg, {required bool success}) => Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: success
              ? Colors.green.withOpacity(0.15)
              : Colors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: success
                  ? Colors.green.withOpacity(0.4)
                  : Colors.red.withOpacity(0.4)),
        ),
        child: Row(children: [
          Icon(success ? Icons.check_circle_outline : Icons.error_outline,
              color: success ? Colors.green.shade300 : Colors.red.shade300,
              size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(msg,
                  style: TextStyle(
                      color:
                          success ? Colors.green.shade200 : Colors.red.shade200,
                      fontSize: 13))),
          GestureDetector(
            onTap: () =>
                setState(() => success ? _successMsg = null : _errorMsg = null),
            child: Icon(Icons.close,
                size: 16, color: Colors.white.withOpacity(0.4)),
          ),
        ]),
      );
}
