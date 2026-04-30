import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../providers/auth_provider.dart';
import '../widgets/app_background.dart';
import '../../services/api_service.dart';
import '../../widgets/admin_sidebar.dart';
import 'avatar_crop_screen.dart';

// ── Imported Extracted Widgets ──
import '../widgets/admin_account_settings_widgets/hamburger_icon.dart';
import '../widgets/admin_account_settings_widgets/profile_form_tab.dart';
import '../widgets/admin_account_settings_widgets/password_form_tab.dart';

const _kBlue = Color(0xFF00022E);

class AdminAccountSettingsScreen extends StatefulWidget {
  const AdminAccountSettingsScreen({super.key});

  @override
  State<AdminAccountSettingsScreen> createState() =>
      _AdminAccountSettingsScreenState();
}

class _AdminAccountSettingsScreenState extends State<AdminAccountSettingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabs;
  bool _isSidebarOpen = true;

  // Department state
  Map<String, List<String>> _deptRoles = {};
  bool _isLoadingDepartments = true;
  List<String> _departments = [];
  String? _selectedDept;

  // Form keys
  final _profileKey = GlobalKey<FormState>();
  final _passKey = GlobalKey<FormState>();

  // Profile controllers
  late TextEditingController _firstCtrl;
  late TextEditingController _lastCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;

  // Password controllers
  final _curPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  // UI state
  bool _savingProfile = false;
  bool _savingPass = false;
  String? _profileMsg;
  String? _passMsg;
  bool _profileSuccess = false;
  bool _passSuccess = false;
  bool _obscureCur = true;
  bool _obscureNew = true;
  bool _obscureConf = true;

  // Avatar Upload State
  bool _isUploadingAvatar = false;
  final ImagePicker _picker = ImagePicker();
  Uint8List? _localAvatarBytes;
  File? _avatarFile;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);

    final user = context.read<AuthProvider>().user;
    _firstCtrl = TextEditingController(text: user?['first_name'] ?? '');
    _lastCtrl = TextEditingController(text: user?['last_name'] ?? '');
    _emailCtrl = TextEditingController(text: user?['email'] ?? '');
    _phoneCtrl = TextEditingController(text: user?['phone'] ?? '');

    _loadDepartments();
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final c in [
      _firstCtrl,
      _lastCtrl,
      _emailCtrl,
      _phoneCtrl,
      _curPassCtrl,
      _newPassCtrl,
      _confirmPassCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    try {
      final res = await ApiService.getDepartments();
      if (!mounted) return;
      if (res['ok'] == true) {
        final List items = res['items'] ?? [];
        final depts = items.map<String>((d) => d['name'] as String).toList();
        final userDept =
            context.read<AuthProvider>().user?['department'] as String? ?? '';
        setState(() {
          _deptRoles = {};
          _departments = depts;
          _isLoadingDepartments = false;
          if (userDept.isNotEmpty && !_departments.contains(userDept)) {
            _departments.add(userDept);
          }
          if (userDept.isNotEmpty) _selectedDept = userDept;
        });
      } else {
        setState(() => _isLoadingDepartments = false);
      }
    } catch (e) {
      debugPrint('Failed to fetch departments: $e');
      if (mounted) setState(() => _isLoadingDepartments = false);
    }
  }

  Future<void> pickAndCropAvatar() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile == null) return;

      final pickedFileBytes = await pickedFile.readAsBytes();
      final mimeType =
          lookupMimeType(pickedFile.name, headerBytes: pickedFileBytes);

      if (mimeType == null || !mimeType.startsWith('image/')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please select a valid image file (JPG, PNG, JPEG)'),
            backgroundColor: Colors.red,
          ));
        }
        return;
      }

      if (kIsWeb) {
        if (!mounted) return;
        final croppedBytes = await Navigator.push<Uint8List>(
          context,
          MaterialPageRoute(
            builder: (_) => AvatarCropScreen(
              imageBytes: pickedFileBytes,
              fileName: pickedFile.name,
            ),
          ),
        );
        if (croppedBytes == null || !mounted) return;

        setState(() {
          _localAvatarBytes = croppedBytes;
          _avatarFile = null;
          _isUploadingAvatar = true;
        });

        final res = await ApiService.uploadAvatar(
            XFile.fromData(croppedBytes, name: pickedFile.name));
        if (!mounted) return;
        setState(() => _isUploadingAvatar = false);

        if (res['ok'] == true) {
          await context.read<AuthProvider>().updateUserData(res['user'] ?? {});
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Avatar updated successfully!'),
            backgroundColor: Colors.green,
          ));
        } else {
          setState(() => _localAvatarBytes = null);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res['error'] ?? 'Failed to upload avatar'),
            backgroundColor: Colors.red,
          ));
        }
        return;
      }

      final file = File(pickedFile.path);
      if (!await file.exists()) return;

      final croppedBytes = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(
          builder: (_) => AvatarCropScreen(
            imageBytes: pickedFileBytes,
            fileName: pickedFile.name,
          ),
        ),
      );
      if (croppedBytes == null || !mounted) return;

      final tempFile =
          File('${(await getTemporaryDirectory()).path}/cropped_avatar.png');
      await tempFile.writeAsBytes(croppedBytes);

      setState(() {
        _avatarFile = tempFile;
        _isUploadingAvatar = true;
      });

      final res = await ApiService.uploadAvatar(XFile(_avatarFile!.path));
      if (!mounted) return;
      setState(() => _isUploadingAvatar = false);

      if (res['ok'] == true) {
        await context.read<AuthProvider>().updateUserData(res['user'] ?? {});
        setState(() => _avatarFile = null);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Avatar updated successfully!'),
          backgroundColor: Colors.green,
        ));
      } else {
        setState(() => _avatarFile = null);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['error'] ?? 'Upload failed'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _avatarFile = null;
          _isUploadingAvatar = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_profileKey.currentState!.validate()) return;
    setState(() {
      _savingProfile = true;
      _profileMsg = null;
    });

    final res = await ApiService.updateProfile({
      'first_name': _firstCtrl.text.trim(),
      'last_name': _lastCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'department': _selectedDept ?? '',
    });

    if (!mounted) return;

    if (res['ok'] == true) {
      context.read<AuthProvider>().updateUserData(res['user'] ?? {});
      setState(() {
        _profileMsg = 'Profile updated successfully!';
        _profileSuccess = true;
      });
    } else {
      setState(() {
        _profileMsg = res['error'] ?? 'Update failed';
        _profileSuccess = false;
      });
    }
    setState(() => _savingProfile = false);
  }

  Future<void> _changePassword() async {
    if (!_passKey.currentState!.validate()) return;
    setState(() {
      _savingPass = true;
      _passMsg = null;
    });

    final res = await ApiService.changePassword({
      'current_password': _curPassCtrl.text,
      'new_password': _newPassCtrl.text,
      'confirm_password': _confirmPassCtrl.text,
    });

    if (!mounted) return;

    if (res['ok'] == true) {
      _curPassCtrl.clear();
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();
      setState(() {
        _passMsg = 'Password changed successfully!';
        _passSuccess = true;
      });
    } else {
      setState(() {
        _passMsg = res['error'] ?? res['details'] ?? 'Change failed';
        _passSuccess = false;
      });
    }
    setState(() => _savingPass = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    String rawAvatarUrl = user?['avatar_url'] as String? ?? '';
    String finalAvatarUrl = '';

    if (rawAvatarUrl.isNotEmpty) {
      if (!rawAvatarUrl.startsWith('http')) {
        // Fixed: Use an empty map instead of null to properly clear queries
        finalAvatarUrl =
            '${Uri.parse(ApiService.baseUrl).replace(queryParameters: const {}).toString().replaceAll('/api', '')}$rawAvatarUrl';
      } else {
        finalAvatarUrl = rawAvatarUrl;
      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isSidebarOpen ? 250 : 0,
            child: _isSidebarOpen
                ? AdminSidebar(
                    currentRoute: '/admin/account-settings',
                    onClose: () => setState(() => _isSidebarOpen = false),
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
                            'Account Settings',
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
                        if (!_isSidebarOpen)
                          Positioned(
                            left: 20,
                            top: 28,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.15)),
                              ),
                              child: IconButton(
                                padding: const EdgeInsets.all(12),
                                onPressed: () =>
                                    setState(() => _isSidebarOpen = true),
                                icon: const HamburgerIcon(),
                                tooltip: 'Open Sidebar',
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
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 20),
                                decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                          color: Colors.grey.shade200)),
                                ),
                                child: Row(
                                  children: [
                                    Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        CircleAvatar(
                                          radius: 40,
                                          backgroundColor:
                                              _kBlue.withOpacity(0.1),
                                          backgroundImage: _avatarFile != null
                                              ? FileImage(_avatarFile!)
                                              : (_localAvatarBytes != null
                                                  ? MemoryImage(
                                                      _localAvatarBytes!)
                                                  : (finalAvatarUrl.isNotEmpty
                                                      ? NetworkImage(
                                                          finalAvatarUrl)
                                                      : null)) as ImageProvider?,
                                          child: _isUploadingAvatar
                                              ? const CircularProgressIndicator(
                                                  color: _kBlue, strokeWidth: 3)
                                              : (_avatarFile == null &&
                                                      _localAvatarBytes ==
                                                          null &&
                                                      finalAvatarUrl.isEmpty)
                                                  ? Text(
                                                      '${(user?['first_name'] as String? ?? ' ')[0]}${(user?['last_name'] as String? ?? ' ')[0]}',
                                                      style: const TextStyle(
                                                          fontSize: 28,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: _kBlue),
                                                    )
                                                  : null,
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: _isUploadingAvatar
                                                  ? null
                                                  : pickAndCropAvatar,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: _kBlue,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color: Colors.white,
                                                      width: 2),
                                                ),
                                                child: const Icon(
                                                    Icons.camera_alt,
                                                    color: Colors.white,
                                                    size: 14),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              '${user?['first_name'] ?? ''} ${user?['last_name'] ?? ''}',
                                              style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.black87)),
                                          const SizedBox(height: 2),
                                          Text(user?['email'] ?? '',
                                              style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500)),
                                          if ((user?['department']
                                                      as String? ??
                                                  '')
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text('${user?['department']}',
                                                style: TextStyle(
                                                    color: Colors.grey.shade500,
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w500)),
                                          ],
                                          const SizedBox(height: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _kBlue.withOpacity(0.08),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                                (user?['role'] ?? 'user')
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                    color: _kBlue
                                                        .withOpacity(0.9),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 1.0)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Tabs
                              Container(
                                decoration: BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(
                                            color: Colors.grey.shade200))),
                                child: TabBar(
                                  controller: _tabs,
                                  labelColor: _kBlue,
                                  indicatorColor: _kBlue,
                                  indicatorWeight: 3,
                                  unselectedLabelColor: Colors.grey.shade500,
                                  labelStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700),
                                  unselectedLabelStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                  dividerColor: Colors.transparent,
                                  tabs: const [
                                    Tab(
                                        icon: Icon(
                                            Icons.manage_accounts_outlined,
                                            size: 20),
                                        text: 'Account Settings'),
                                    Tab(
                                        icon: Icon(Icons.lock_outline,
                                            size: 20),
                                        text: 'Change Password'),
                                  ],
                                ),
                              ),

                              // Tab Content Modules
                              Expanded(
                                child: TabBarView(
                                  controller: _tabs,
                                  children: [
                                    ProfileFormTab(
                                      formKey: _profileKey,
                                      firstCtrl: _firstCtrl,
                                      lastCtrl: _lastCtrl,
                                      emailCtrl: _emailCtrl,
                                      selectedDept: _selectedDept,
                                      departments: _departments,
                                      isLoadingDepartments:
                                          _isLoadingDepartments,
                                      profileMsg: _profileMsg,
                                      profileSuccess: _profileSuccess,
                                      savingProfile: _savingProfile,
                                      onDeptChanged: (v) =>
                                          setState(() => _selectedDept = v),
                                      onSave: _saveProfile,
                                    ),
                                    PasswordFormTab(
                                      formKey: _passKey,
                                      curPassCtrl: _curPassCtrl,
                                      newPassCtrl: _newPassCtrl,
                                      confirmPassCtrl: _confirmPassCtrl,
                                      obscureCur: _obscureCur,
                                      obscureNew: _obscureNew,
                                      obscureConf: _obscureConf,
                                      passMsg: _passMsg,
                                      passSuccess: _passSuccess,
                                      savingPass: _savingPass,
                                      onToggleCur: () => setState(
                                          () => _obscureCur = !_obscureCur),
                                      onToggleNew: () => setState(
                                          () => _obscureNew = !_obscureNew),
                                      onToggleConf: () => setState(
                                          () => _obscureConf = !_obscureConf),
                                      onSave: _changePassword,
                                    ),
                                  ],
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
    ); // <-- The missing semicolon was added right here
  }
}