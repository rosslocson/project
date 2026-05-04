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

const _kBlue = Color(0xFF00022E);

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
              color: Colors.white.withOpacity(0.8), // Fixed
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

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});
  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen>
    with SingleTickerProviderStateMixin {
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
    _ojtHoursCtrl = TextEditingController(
      text: (user?['required_ojt_hours'] ?? '').toString(),
    );

    _selectedDept = (user?['department'] as String? ?? '').isEmpty
        ? null
        : user?['department'] as String?;

    _fetchDepartments();
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final c in [
      _firstCtrl,
      _lastCtrl,
      _emailCtrl,
      _phoneCtrl,
      _ojtHoursCtrl,
      _curPassCtrl,
      _newPassCtrl,
      _confirmPassCtrl,
    ]) {
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
    final hoursValue = int.tryParse(_ojtHoursCtrl.text.trim());
  debugPrint('🕒 OJT Hours being sent: $hoursValue'); // Add this

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
        context
            .read<AuthProvider>()
            .updateUserData(Map<String, dynamic>.from(fresh));
        _ojtHoursCtrl.text = (fresh['required_ojt_hours'] ??
                res['user']?['required_ojt_hours'] ??
                '')
            .toString();
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

  InputDecoration _getFormDecoration(String label, {IconData? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
          fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: Colors.grey.shade500, size: 18)
          : null,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade300, width: 1),
      ),
    );
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

    // Debug prints
    //debugPrint('🖼️ User Avatar Debug: rawAvatarUrl="$rawAvatarUrl", finalAvatarUrl="$finalAvatarUrl"');

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
          // ── Top bar ───────────────────────────────────────────
          SizedBox(
            height: 72,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.only(left: 100, right: 100, top: 28),
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
                        color: Colors.white.withOpacity(0.05), // Fixed
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15), // Fixed
                        ),
                      ),
                      child: IconButton(
                        padding: const EdgeInsets.all(12),
                        onPressed: () => sidebar.setUserSidebarOpen(true),
                        icon: const HamburgerIcon(),
                        tooltip: 'Open Sidebar',
                        splashColor: Colors.white.withOpacity(0.1), // Fixed
                        highlightColor: Colors.transparent,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          // ── Main container ────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 100, right: 100, bottom: 28),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95), // Fixed
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Profile card ──────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 20),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Row(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor:
                                      _kBlue.withOpacity(0.1), // Fixed
                                  backgroundImage: avatarImage,
                                  child: _isUploadingAvatar
                                      ? const CircularProgressIndicator(
                                          color: _kBlue, strokeWidth: 3)
                                      : avatarImage == null
                                          ? Text(
                                              '${(user?['first_name'] as String? ?? ' ')[0]}'
                                              '${(user?['last_name'] as String? ?? ' ')[0]}',
                                              style: const TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                color: _kBlue,
                                              ),
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
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: _kBlue,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 2),
                                        ),
                                        child: const Icon(Icons.camera_alt,
                                            color: Colors.white, size: 14),
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
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black87,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user?['email'] ?? '',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  if ((user?['department'] as String? ?? '')
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '${user?['department']} · ${user?['position'] ?? ''}',
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _kBlue.withOpacity(0.08), // Fixed
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Text('USER',
                                        style: TextStyle(
                                          color: _kBlue,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.0,
                                        )),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Tabs ──────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: TabBar(
                          controller: _tabs,
                          labelColor: _kBlue,
                          indicatorColor: _kBlue,
                          indicatorWeight: 3,
                          unselectedLabelColor: Colors.grey.shade500,
                          labelStyle: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                          unselectedLabelStyle: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(
                              icon: Icon(Icons.manage_accounts_outlined,
                                  size: 20),
                              text: 'Account Settings',
                            ),
                            Tab(
                              icon: Icon(Icons.lock_outline, size: 20),
                              text: 'Change Password',
                            ),
                          ],
                        ),
                      ),

                      // ── Tab content ───────────────────────────
                      Expanded(
                        child: TabBarView(
                          controller: _tabs,
                          children: [
                            _buildProfileForm(),
                            _buildPasswordForm(),
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
    ); // Fixed: Added missing semicolon
  }

  Widget _buildProfileForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: Form(
              key: _profileKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_profileMsg != null) ...[
                    _msgBanner(_profileMsg!, _profileSuccess),
                    const SizedBox(height: 16),
                  ],
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstCtrl,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                        decoration: _getFormDecoration('First Name'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _lastCtrl,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                        decoration: _getFormDecoration('Last Name'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailCtrl,
                    enabled: false,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600),
                    decoration: _getFormDecoration('Email (cannot change)',
                        prefixIcon: Icons.email_outlined),
                  ),
                  const SizedBox(height: 16),
                  _loadingDepts
                      ? _loadingDropdown('Department')
                      : _dropdownField(
                          label: 'Department',
                          value: _selectedDept,
                          hint: _departments.isEmpty
                              ? 'None available'
                              : 'Select Department',
                          items: _departments,
                          onChanged: (v) => setState(() => _selectedDept = v),
                        ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ojtHoursCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                    decoration: _getFormDecoration(
                      'Required OJT Hours',
                      prefixIcon: Icons.access_time_outlined,
                    ),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 28),
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _savingProfile ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _savingProfile
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Save Changes',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 0.5)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: Form(
              key: _passKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_passMsg != null) ...[
                    _msgBanner(_passMsg!, _passSuccess),
                    const SizedBox(height: 16),
                  ],
                  _passField(
                    controller: _curPassCtrl,
                    label: 'Current Password',
                    obscure: _obscureCur,
                    onToggle: () => setState(() => _obscureCur = !_obscureCur),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  _passField(
                    controller: _newPassCtrl,
                    label: 'New Password',
                    obscure: _obscureNew,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                    validator: (v) {
                      if (v == null || v.length < 8) return 'Min 8 characters';
                      if (!v.contains(RegExp(r'[A-Z]'))) {
                        return 'Need one uppercase letter';
                      }
                      if (!v.contains(RegExp(r'[0-9]'))) {
                        return 'Need one number';
                      }
                      if (!v.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                        return 'Need one special character';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _passField(
                    controller: _confirmPassCtrl,
                    label: 'Confirm New Password',
                    obscure: _obscureConf,
                    onToggle: () =>
                        setState(() => _obscureConf = !_obscureConf),
                    validator: (v) {
                      if (v!.isEmpty) return 'Required';
                      if (v != _newPassCtrl.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 28),
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _savingPass ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _savingPass
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Change Password',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 0.5)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _loadingDropdown(String label) => Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black38,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: _kBlue),
            ),
          ],
        ),
      );

  Widget _dropdownField({
    required String label,
    required String? value,
    required String hint,
    required List<String> items,
    required void Function(String?)? onChanged,
  }) =>
      Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600)),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isDense: true,
                  hint: Text(hint,
                      style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down,
                      color: Colors.grey[500], size: 18),
                  style: const TextStyle(
                      color: Colors.black87,
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

  Widget _passField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) =>
      TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        decoration:
            _getFormDecoration(label, prefixIcon: Icons.lock_outline).copyWith(
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                size: 18, color: Colors.grey.shade500),
            onPressed: onToggle,
          ),
        ),
      );

  Widget _msgBanner(String msg, bool success) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: success ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: success ? Colors.green.shade200 : Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(success ? Icons.check_circle : Icons.error_outline,
                color: success ? Colors.green : Colors.red, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg,
                  style: TextStyle(
                      fontSize: 13,
                      color:
                          success ? Colors.green.shade800 : Colors.red.shade800,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}
