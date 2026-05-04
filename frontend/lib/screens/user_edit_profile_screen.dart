import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/user_sidebar.dart';
import '../widgets/app_background.dart';

import '../../widgets/user_edit_profile_widgets/edit_profile_hamburger_icon.dart';
import '../../widgets/user_edit_profile_widgets/edit_profile_status_banner.dart';
import '../../widgets/user_edit_profile_widgets/academic_info_tab.dart';
import '../../widgets/user_edit_profile_widgets/skills_profile_tab.dart';

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
  final String _defaultPosition = 'Intern';

  bool _initialLoading = true;
  String? _selectedDept;
  int? _requiredHours; // ← stored in state, not read from context in build()

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
  bool _academicTabInvalid = false;
  bool _skillsTabInvalid = false;

  bool get _isAcademicComplete {
    return _selectedDept?.isNotEmpty == true &&
        _schoolCtrl.text.trim().isNotEmpty &&
        _programCtrl.text.trim().isNotEmpty &&
        _specCtrl.text.trim().isNotEmpty &&
        _yearCtrl.text.trim().isNotEmpty &&
        _internNumCtrl.text.trim().isNotEmpty &&
        _startCtrl.text.trim().isNotEmpty &&
        _endCtrl.text.trim().isNotEmpty;
  }

  bool get _isSkillsComplete {
    return _techSkillsCtrl.text.trim().isNotEmpty &&
        _softSkillsCtrl.text.trim().isNotEmpty;
  }

  void _handleProfileFieldChanged() {
    // Only attempt to clear badges if error exists (after user tried to save)
    if (_errorMsg == null) return;

    if (!mounted) return;

    // Clear Academic badge and reset form if all academic fields are filled
    if (_isAcademicComplete && _academicTabInvalid) {
      _academicKey.currentState?.reset();
      // Re-validate with the filled values
      _academicKey.currentState?.validate();
      setState(() {
        _academicTabInvalid = false;
      });
    }

    // Clear Skills badge and reset form if only Tech and Soft Skills are filled
    if (_isSkillsComplete && _skillsTabInvalid) {
      _skillsKey.currentState?.reset();
      // Re-validate with the filled values
      _skillsKey.currentState?.validate();
      setState(() {
        _skillsTabInvalid = false;
      });
    }

    // Only clear main error when both tabs are completely valid
    if (_isAcademicComplete && _isSkillsComplete) {
      setState(() {
        _errorMsg = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);

    final user = context.read<AuthProvider>().user ?? {};

    _schoolCtrl = TextEditingController(text: user['school'] ?? '');
    _programCtrl = TextEditingController(text: user['program'] ?? '');
    _specCtrl = TextEditingController(text: user['specialization'] ?? '');
    _yearCtrl = TextEditingController(text: user['year_level'] ?? '');
    _internNumCtrl = TextEditingController(text: user['intern_number'] ?? '');
    _startCtrl = TextEditingController(text: user['start_date'] ?? '');
    _endCtrl = TextEditingController(text: user['end_date'] ?? '');
    _bioCtrl = TextEditingController(text: user['bio'] ?? '');
    _techSkillsCtrl =
        TextEditingController(text: user['technical_skills'] ?? '');
    _softSkillsCtrl = TextEditingController(text: user['soft_skills'] ?? '');
    _linkedinCtrl = TextEditingController(text: user['linked_in'] ?? '');
    _githubCtrl = TextEditingController(text: user['git_hub'] ?? '');

    final dept = user['department'] as String? ?? '';
    _selectedDept = dept.isNotEmpty ? dept : null;

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
    final result = await ApiService.getConfig(type: 'department');
    if (!mounted) return;

    final depts = (result['items'] as List? ?? [])
        .map((e) => e['name'] as String)
        .toList();

    if (_selectedDept != null && !depts.contains(_selectedDept!)) {
      depts.add(_selectedDept!);
    }

    // ── Read required_hours from the user profile ──
    final raw = context.read<AuthProvider>().user?['required_ojt_hours'];
    final hours = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
    debugPrint(
        '✅ _requiredHours loaded: $hours (raw: $raw, type: ${raw?.runtimeType})');

    setState(() {
      _departments = depts;
      _requiredHours = hours;
      _initialLoading = false;
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _successMsg = null;
      _errorMsg = null;
    });

    final academicValid = _isAcademicComplete;
    final skillsValid = _isSkillsComplete;

    _academicKey.currentState?.validate();
    _skillsKey.currentState?.validate();

    setState(() {
      _academicTabInvalid = !academicValid;
      _skillsTabInvalid = !skillsValid;
    });

    if (!academicValid || !skillsValid) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMsg = 'Please complete all required fields before saving.';
      });
      return;
    }

    final payload = {
      'department': _selectedDept ?? '',
      'position': _defaultPosition,
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

      // Optimistically merge the saved payload into local cache first
      final currentUser = Map<String, dynamic>.from(auth.user ?? {});
      currentUser.addAll(payload);
      await auth.updateUserData(currentUser);

      // Then let the server response confirm/correct it
      await auth.refreshProfile();

      if (mounted) {
        setState(() {
          _saving = false;
          _successMsg = 'Profile updated successfully!';
          _errorMsg = null;
          _academicTabInvalid = false;
          _skillsTabInvalid = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _saving = false;
          _errorMsg = res['error'] ?? 'Update failed. Please try again.';
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
      // The AcademicInfoTab listener handles end-date computation automatically.
      _handleProfileFieldChanged();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _sidebarVisible ? 250 : 0,
            child: _sidebarVisible
                ? UserSidebar(
                    currentRoute: '/edit-profile',
                    onClose: () => setState(() => _sidebarVisible = false),
                  )
                : null,
          ),
          Expanded(
            child: AppBackground(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 72,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 100, right: 100, top: 28),
                          child: Text(
                            'Edit Profile',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                          ),
                        ),
                        if (!_sidebarVisible)
                          Positioned(
                            left: 20,
                            top: 28,
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    const Color.fromRGBO(255, 255, 255, 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color.fromRGBO(
                                        255, 255, 255, 0.15)),
                              ),
                              child: IconButton(
                                padding: const EdgeInsets.all(12),
                                onPressed: () =>
                                    setState(() => _sidebarVisible = true),
                                icon: const EditProfileHamburgerIcon(),
                                tooltip: 'Open Sidebar',
                                splashColor:
                                    const Color.fromRGBO(255, 255, 255, 0.1),
                                highlightColor: Colors.transparent,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 100, right: 100, bottom: 28),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(255, 255, 255, 0.95),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: _initialLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                      color: kCrimsonDeep))
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (_successMsg != null)
                                      EditProfileStatusBanner(
                                        msg: _successMsg!,
                                        success: true,
                                        onClose: () =>
                                            setState(() => _successMsg = null),
                                      ),
                                    if (_errorMsg != null)
                                      EditProfileStatusBanner(
                                        msg: _errorMsg!,
                                        success: false,
                                        onClose: () =>
                                            setState(() => _errorMsg = null),
                                      ),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                            bottom: BorderSide(
                                                color: Colors.grey.shade200)),
                                      ),
                                      child: TabBar(
                                        controller: _tabs,
                                        labelColor: Colors.black,
                                        unselectedLabelColor:
                                            Colors.grey.shade500,
                                        indicatorColor: kCrimsonDeep,
                                        indicatorWeight: 3,
                                        dividerColor: Colors.transparent,
                                        tabs: [
                                          Tab(
                                            iconMargin: const EdgeInsets.only(
                                                bottom: 4),
                                            icon: const Icon(
                                                Icons.school_outlined,
                                                size: 18),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text('Academic Info'),
                                                if (_academicTabInvalid) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    width: 18,
                                                    height: 18,
                                                    decoration: const BoxDecoration(
                                                      color: Colors.redAccent,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: const Text(
                                                      '!',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          height: 1.1,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ]
                                              ],
                                            ),
                                          ),
                                          Tab(
                                            iconMargin: const EdgeInsets.only(
                                                bottom: 4),
                                            icon: const Icon(
                                                Icons.stars_outlined,
                                                size: 18),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text('Skills'),
                                                if (_skillsTabInvalid) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    width: 18,
                                                    height: 18,
                                                    decoration: const BoxDecoration(
                                                      color: Colors.redAccent,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: const Text(
                                                      '!',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          height: 1.1,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ]
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: TabBarView(
                                        controller: _tabs,
                                        children: [
                                          AcademicInfoTab(
                                            formKey: _academicKey,
                                            departments: _departments,
                                            selectedDept: _selectedDept,
                                            defaultPosition: _defaultPosition,
                                            schoolCtrl: _schoolCtrl,
                                            programCtrl: _programCtrl,
                                            specCtrl: _specCtrl,
                                            yearCtrl: _yearCtrl,
                                            internNumCtrl: _internNumCtrl,
                                            startCtrl: _startCtrl,
                                            endCtrl: _endCtrl,
                                            onDeptChanged: (v) => setState(
                                                () => _selectedDept = v),
                                            onPickStart: () =>
                                                _pickDate(_startCtrl),
                                            onPickEnd: () =>
                                                _pickDate(_endCtrl),
                                            onChanged:
                                                _handleProfileFieldChanged,
                                            requiredHours: _requiredHours,
                                          ),
                                          SkillsProfileTab(
                                            formKey: _skillsKey,
                                            bioCtrl: _bioCtrl,
                                            techSkillsCtrl: _techSkillsCtrl,
                                            softSkillsCtrl: _softSkillsCtrl,
                                            linkedinCtrl: _linkedinCtrl,
                                            githubCtrl: _githubCtrl,
                                            onChanged:
                                                _handleProfileFieldChanged,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          40, 0, 40, 28),
                                      child: SizedBox(
                                        height: 48,
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: _saving ? null : _save,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: kCrimsonDeep,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            elevation: 0,
                                          ),
                                          child: _saving
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 2),
                                                )
                                              : const Text(
                                                  'SAVE CHANGES',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 15,
                                                      letterSpacing: 0.8),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
