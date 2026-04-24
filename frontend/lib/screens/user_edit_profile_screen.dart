import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/user_sidebar.dart';

class HamburgerIcon extends StatelessWidget {
  const HamburgerIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 22,
            height: 2.5,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 14,
            height: 2.5,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 22,
            height: 2.5,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class UserEditProfileScreen extends StatefulWidget {
  const UserEditProfileScreen({super.key});
  @override
  State<UserEditProfileScreen> createState() => _UserEditProfileScreenState();
}

class _UserEditProfileScreenState extends State<UserEditProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabs;
  bool _sidebarVisible = true;

  final _academicKey = GlobalKey<FormState>();
  List<String> _departments = [];
  List<String> _positions = [];

  // FIX: Single loading flag for the entire init sequence
  bool _initialLoading = true;

  String? _selectedDept;
  String? _selectedPos;

  late TextEditingController _schoolCtrl;
  late TextEditingController _programCtrl;
  late TextEditingController _specCtrl;
  late TextEditingController _yearCtrl;
  late TextEditingController _internNumCtrl;
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;

  final _skillsKey = GlobalKey<FormState>();
  late TextEditingController _bioCtrl;
  late TextEditingController _techSkillsCtrl;
  late TextEditingController _softSkillsCtrl;
  late TextEditingController _linkedinCtrl;
  late TextEditingController _githubCtrl;

  bool _saving = false;
  String? _successMsg;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);

    // FIX: Initialize controllers with empty strings first.
    // They will be populated after we fetch fresh data from the server.
    _schoolCtrl = TextEditingController();
    _programCtrl = TextEditingController();
    _specCtrl = TextEditingController();
    _yearCtrl = TextEditingController();
    _internNumCtrl = TextEditingController();
    _startCtrl = TextEditingController();
    _endCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
    _techSkillsCtrl = TextEditingController();
    _softSkillsCtrl = TextEditingController();
    _linkedinCtrl = TextEditingController();
    _githubCtrl = TextEditingController();

    // FIX: Always fetch fresh data from the server on screen load
    _initScreenData();
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

  // FIX: Fetch fresh profile from server FIRST, then load dropdown configs,
  // then populate all controllers from the fresh data.
  Future<void> _initScreenData() async {
    try {
      // Step 1: Pull fresh profile from the server and update AuthProvider
      final profileRes = await ApiService.getProfile();
      if (!mounted) return;

      Map<String, dynamic> freshUser = {};
      if (profileRes['ok'] == true || profileRes['id'] != null) {
        freshUser = Map<String, dynamic>.from(profileRes);
        // Update the provider so the rest of the app also stays in sync
        await context.read<AuthProvider>().updateUserData(freshUser);
      } else {
        // Fall back to whatever is cached in the provider
        freshUser =
            Map<String, dynamic>.from(context.read<AuthProvider>().user ?? {});
      }

      // Step 2: Fetch dropdown options in parallel
      final results = await Future.wait([
        ApiService.getConfig(type: 'department'),
        ApiService.getConfig(type: 'position'),
      ]);
      if (!mounted) return;

      final deptRes = results[0];
      final posRes = results[1];

      final depts = (deptRes['items'] as List? ?? [])
          .map((e) => e['name'] as String)
          .toList();
      final positions = (posRes['items'] as List? ?? [])
          .map((e) => e['name'] as String)
          .toList();

      final dept = freshUser['department'] as String? ?? '';
      final pos = freshUser['position'] as String? ?? '';
      final savedDept = dept.isNotEmpty ? dept : null;
      final savedPos = pos.isNotEmpty ? pos : null;

      // Preserve saved values even if they aren't in the dropdown list yet
      if (savedDept != null && !depts.contains(savedDept)) {
        depts.add(savedDept);
      }
      if (savedPos != null && !positions.contains(savedPos)) {
        positions.add(savedPos);
      }

      // Step 3: Populate all controllers with the fresh server data
      setState(() {
        _departments = depts;
        _positions = positions;
        _selectedDept = savedDept;
        _selectedPos = savedPos;

        _schoolCtrl.text = freshUser['school'] as String? ?? '';
        _programCtrl.text = freshUser['program'] as String? ?? '';
        _specCtrl.text = freshUser['specialization'] as String? ?? '';
        _yearCtrl.text = freshUser['year_level'] as String? ?? '';
        _internNumCtrl.text = freshUser['intern_number'] as String? ?? '';
        _startCtrl.text = freshUser['start_date'] as String? ?? '';
        _endCtrl.text = freshUser['end_date'] as String? ?? '';
        _bioCtrl.text = freshUser['bio'] as String? ?? '';
        _techSkillsCtrl.text = freshUser['technical_skills'] as String? ?? '';
        _softSkillsCtrl.text = freshUser['soft_skills'] as String? ?? '';
        _linkedinCtrl.text = freshUser['linked_in'] as String? ?? '';
        _githubCtrl.text = freshUser['git_hub'] as String? ?? '';

        _initialLoading = false;
      });
    } catch (e) {
      debugPrint('EditProfile init error: $e');
      if (mounted) {
        // Fall back to cached provider data so the screen still renders
        final user = context.read<AuthProvider>().user ?? {};
        final dept = user['department'] as String? ?? '';
        final pos = user['position'] as String? ?? '';

        setState(() {
          _selectedDept = dept.isNotEmpty ? dept : null;
          _selectedPos = pos.isNotEmpty ? pos : null;
          _schoolCtrl.text = user['school'] as String? ?? '';
          _programCtrl.text = user['program'] as String? ?? '';
          _specCtrl.text = user['specialization'] as String? ?? '';
          _yearCtrl.text = user['year_level'] as String? ?? '';
          _internNumCtrl.text = user['intern_number'] as String? ?? '';
          _startCtrl.text = user['start_date'] as String? ?? '';
          _endCtrl.text = user['end_date'] as String? ?? '';
          _bioCtrl.text = user['bio'] as String? ?? '';
          _techSkillsCtrl.text = user['technical_skills'] as String? ?? '';
          _softSkillsCtrl.text = user['soft_skills'] as String? ?? '';
          _linkedinCtrl.text = user['linked_in'] as String? ?? '';
          _githubCtrl.text = user['git_hub'] as String? ?? '';
          _initialLoading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _successMsg = null;
      _errorMsg = null;
    });

    final payload = {
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
    };

    final res = await ApiService.updateProfile(payload);

    if (!mounted) return;

    if (res['ok'] == true) {
      final auth = context.read<AuthProvider>();

      // FIX: Merge the payload we just saved optimistically
      await auth.updateUserData(payload);

      // FIX: Then pull the canonical server copy so My Profile is fully in sync
      await auth.refreshProfile();

      if (mounted) {
        setState(() {
          _saving = false;
          _successMsg = 'Profile updated successfully!';
          _errorMsg = null;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _saving = false;
          _errorMsg = res['error'] ??
              res['details'] ??
              'Save failed. Please try again.';
          _successMsg = null;
        });
      }
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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
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
        style: const TextStyle(color: Colors.black, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          suffixIcon: suffix,
          filled: true,
          fillColor: const Color(0xFFF3F4F6),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
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
        value: value,
        style: const TextStyle(color: Colors.black, fontSize: 14),
        dropdownColor: Colors.white,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF3F4F6),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: kCrimsonDeep.withOpacity(0.8), width: 1.5),
          ),
        ),
        hint: Text(hint,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
        items: items
            .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.black, fontSize: 13)),
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
                  color: Colors.black)),
          const SizedBox(height: 4),
          Text(sub,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ]),
      );

  Widget _buildAcademicTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _academicKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionTitle('Academic Information',
                'Your school, program, department, and internship details'),
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
                            size: 18, color: Colors.grey.shade600),
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
                            size: 18, color: Colors.grey.shade600),
                        onPressed: () => _pickDate(_endCtrl),
                      ),
                    ),
                  ])),
            ]),
          ]),
        ),
      );

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
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Row(children: [
            if (_sidebarVisible)
              UserSidebar(
                currentRoute: '/edit-profile',
                onClose: () => setState(() => _sidebarVisible = false),
              ),
            Expanded(
                child: Stack(children: [
              Positioned.fill(
                  child: Image.asset(
                'assets/images/space_background.png',
                fit: BoxFit.cover,
              )),
              Positioned.fill(
                child: Column(children: [
                  // Top bar
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
                    child: const Row(children: [
                      Text('Edit Profile',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ]),
                  ),

                  // Card
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        // FIX: Show a loader while fetching fresh data from server
                        child: _initialLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: kCrimsonDeep))
                            : Column(children: [
                                if (_successMsg != null)
                                  _banner(_successMsg!, success: true),
                                if (_errorMsg != null)
                                  _banner(_errorMsg!, success: false),
                                SizedBox(
                                  height: 55,
                                  child: TabBar(
                                    controller: _tabs,
                                    labelColor: Colors.black,
                                    unselectedLabelColor: Colors.grey.shade500,
                                    indicatorColor: kCrimsonDeep,
                                    indicatorWeight: 3,
                                    dividerColor: Colors.grey.shade200,
                                    tabs: const [
                                      Tab(
                                          iconMargin:
                                              EdgeInsets.only(bottom: 4),
                                          icon: Icon(Icons.school_outlined,
                                              size: 18),
                                          text: 'Academic Info'),
                                      Tab(
                                          iconMargin:
                                              EdgeInsets.only(bottom: 4),
                                          icon: Icon(Icons.stars_outlined,
                                              size: 18),
                                          text: 'Skills'),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: TabBarView(
                                    controller: _tabs,
                                    children: [
                                      _buildAcademicTab(),
                                      _buildSkillsTab(),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(28, 0, 28, 24),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _saving ? null : _save,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kCrimsonDeep,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        elevation: 0,
                                      ),
                                      child: _saving
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2))
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
          if (!_sidebarVisible)
            Positioned(
              top: 24,
              left: 24,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  padding: const EdgeInsets.all(12),
                  onPressed: () => setState(() => _sidebarVisible = true),
                  icon: const HamburgerIcon(),
                  tooltip: 'Open Sidebar',
                  splashColor: Colors.white.withOpacity(0.1),
                  highlightColor: Colors.transparent,
                ),
              ),
            ),
        ],
      ),
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
              color: success ? Colors.green.shade600 : Colors.red.shade600,
              size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(msg,
                  style: TextStyle(
                      color:
                          success ? Colors.green.shade800 : Colors.red.shade800,
                      fontSize: 13))),
          GestureDetector(
            onTap: () =>
                setState(() => success ? _successMsg = null : _errorMsg = null),
            child: const Icon(Icons.close, size: 16, color: Colors.black54),
          ),
        ]),
      );
}