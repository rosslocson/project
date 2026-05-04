import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../providers/auth_provider.dart';
import '../providers/sidebar_provider.dart';
import '../widgets/app_background.dart';
import '../services/api_service.dart';
import '../widgets/user_layout.dart';
import 'avatar_crop_screen.dart';

// ── Imported Extracted Widgets ──
import '../widgets/user_account_settings_widgets/user_account_hamburger.dart';
import '../widgets/user_account_settings_widgets/user_profile_tab.dart';
import '../widgets/user_account_settings_widgets/user_password_tab.dart';

const _kBlue = Color(0xFF00022E);

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});
  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  List<String> _departments = [];
  bool _loadingDepts = true;
  String? _selectedDept;

  final _profileKey = GlobalKey<FormState>();
  final _passKey = GlobalKey<FormState>();

  late TextEditingController _firstCtrl;
  late TextEditingController _lastCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _ojtHoursCtrl;

  final _curPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _savingProfile = false;
  bool _savingPass = false;
  String? _profileMsg;
  String? _passMsg;
  bool _profileSuccess = false;
  bool _passSuccess = false;
  
  bool _obscureCur = true;
  bool _obscureNew = true;
  bool _obscureConf = true;

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
    _ojtHoursCtrl = TextEditingController(text: (user?['required_ojt_hours'] ?? '').toString());

    _selectedDept = (user?['department'] as String? ?? '').isEmpty ? null : user?['department'] as String?;

    _fetchDepartments();
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final c in [_firstCtrl, _lastCtrl, _emailCtrl, _phoneCtrl, _ojtHoursCtrl, _curPassCtrl, _newPassCtrl, _confirmPassCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchDepartments() async {
    try {
      final res = await ApiService.getDepartments();
      if (!mounted) return;
      if (res['ok'] == true) {
        final List items = res['items'] ?? [];
        final depts = items.map<String>((d) => d['name'] as String).toList();
        setState(() {
          _departments = depts;
          _loadingDepts = false;
          if (_selectedDept != null && !_departments.contains(_selectedDept)) {
            _departments.add(_selectedDept!);
          }
        });
      } else {
        setState(() => _loadingDepts = false);
      }
    } catch (e) {
      debugPrint('Failed to fetch departments: $e');
      if (mounted) setState(() => _loadingDepts = false);
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a valid image file (JPG, PNG, JPEG)'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

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

      final XFile uploadFile;
      if (kIsWeb) {
        uploadFile = XFile.fromData(
          croppedBytes,
          name: pickedFile.name.isNotEmpty ? pickedFile.name : 'avatar.jpg',
        );
      } else {
        final tempFile =
            File('${(await getTemporaryDirectory()).path}/cropped_avatar.jpg');
        await tempFile.writeAsBytes(croppedBytes);
        if (!mounted) return;

        setState(() {
          _avatarFile = tempFile;
          _localAvatarBytes = null;
        });
        uploadFile = XFile(tempFile.path);
      }

      final res = await ApiService.uploadAvatar(uploadFile);
      if (!mounted) return;
      setState(() => _isUploadingAvatar = false);

      if (res['ok'] == true) {
        context.read<AuthProvider>().updateUserData(res['user'] ?? {});
        setState(() {
          _avatarFile = null;
          _localAvatarBytes = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _avatarFile = null;
          _localAvatarBytes = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['error'] ?? 'Failed to upload avatar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _avatarFile = null;
          _localAvatarBytes = null;
          _isUploadingAvatar = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_profileKey.currentState!.validate()) return;
    final hoursValue = int.tryParse(_ojtHoursCtrl.text.trim());
    debugPrint('🕒 OJT Hours being sent: $hoursValue');

    setState(() {
      _savingProfile = true;
      _profileMsg = null;
    });

    final res = await ApiService.updateProfile({
      'first_name': _firstCtrl.text.trim(),
      'last_name': _lastCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'department': _selectedDept ?? '',
      'required_ojt_hours': int.tryParse(_ojtHoursCtrl.text.trim()) ?? 0,
    });

    if (!mounted) return;

    if (res['ok'] == true) {
      context.read<AuthProvider>().updateUserData(res['user'] ?? {});
      final fresh = await ApiService.getProfile();
      if (mounted && (fresh['ok'] == true || fresh['id'] != null)) {
        context.read<AuthProvider>().updateUserData(Map<String, dynamic>.from(fresh));
        _ojtHoursCtrl.text = (fresh['required_ojt_hours'] ?? res['user']?['required_ojt_hours'] ?? '').toString();
      }
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
    return UserLayout(
      currentRoute: '/account-settings',
      child: _buildSettingsContent(context),
    );
  }

  Widget _buildSettingsContent(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final sidebar = context.watch<SidebarProvider>();

    final rawAvatarUrl = user?['avatar_url'] as String? ?? '';
    final finalAvatarUrl = rawAvatarUrl.isEmpty
        ? ''
        : rawAvatarUrl.startsWith('http')
            ? rawAvatarUrl
            : '${ApiService.baseUrl.replaceAll('/api', '')}$rawAvatarUrl';

    ImageProvider? avatarImage;
    if (_avatarFile != null) {
      avatarImage = FileImage(_avatarFile!);
    } else if (_localAvatarBytes != null) {
      avatarImage = MemoryImage(_localAvatarBytes!);
    } else if (finalAvatarUrl.isNotEmpty) {
      avatarImage = NetworkImage(finalAvatarUrl);
    }

    return AppBackground(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top bar ──
          SizedBox(
            height: 72,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 100, right: 100, top: 28),
                  child: Text(
                    'Account Settings',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                  ),
                ),
                if (!sidebar.isUserSidebarOpen)
                  Positioned(
                    left: 20,
                    top: 28,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: IconButton(
                        padding: const EdgeInsets.all(12),
                        onPressed: () => sidebar.setUserSidebarOpen(true),
                        icon: const UserAccountHamburger(),
                        tooltip: 'Open Sidebar',
                        splashColor: Colors.white.withOpacity(0.1),
                        highlightColor: Colors.transparent,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          // ── Main container ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 100, right: 100, bottom: 28),
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
                      // Profile Header Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                        child: Row(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: _kBlue.withOpacity(0.1),
                                  backgroundImage: avatarImage,
                                  child: _isUploadingAvatar
                                      ? const CircularProgressIndicator(color: _kBlue, strokeWidth: 3)
                                      : avatarImage == null
                                          ? Text(
                                              '${(user?['first_name'] as String? ?? ' ')[0]}${(user?['last_name'] as String? ?? ' ')[0]}',
                                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _kBlue),
                                            )
                                          : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _isUploadingAvatar ? null : pickAndCropAvatar,
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: _kBlue,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${user?['first_name'] ?? ''} ${user?['last_name'] ?? ''}',
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87, letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user?['email'] ?? '',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                  if ((user?['department'] as String? ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '${user?['department']} · ${user?['position'] ?? ''}',
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _kBlue.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Text(
                                      'USER',
                                      style: TextStyle(color: _kBlue, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tabs Header
                      Container(
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                        child: TabBar(
                          controller: _tabs,
                          labelColor: _kBlue,
                          indicatorColor: _kBlue,
                          indicatorWeight: 3,
                          unselectedLabelColor: Colors.grey.shade500,
                          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(icon: Icon(Icons.manage_accounts_outlined, size: 20), text: 'Account Settings'),
                            Tab(icon: Icon(Icons.lock_outline, size: 20), text: 'Change Password'),
                          ],
                        ),
                      ),

                      // Tabs Content
                      Expanded(
                        child: TabBarView(
                          controller: _tabs,
                          children: [
                            UserProfileTab(
                              formKey: _profileKey,
                              firstCtrl: _firstCtrl,
                              lastCtrl: _lastCtrl,
                              emailCtrl: _emailCtrl,
                              ojtHoursCtrl: _ojtHoursCtrl,
                              selectedDept: _selectedDept,
                              departments: _departments,
                              loadingDepts: _loadingDepts,
                              profileMsg: _profileMsg,
                              profileSuccess: _profileSuccess,
                              savingProfile: _savingProfile,
                              onDeptChanged: (v) => setState(() => _selectedDept = v),
                              onSave: _saveProfile,
                            ),
                            UserPasswordTab(
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
                              onToggleCur: () => setState(() => _obscureCur = !_obscureCur),
                              onToggleNew: () => setState(() => _obscureNew = !_obscureNew),
                              onToggleConf: () => setState(() => _obscureConf = !_obscureConf),
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
    );
  }
}
