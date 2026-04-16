import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/admin_sidebar.dart';
import 'avatar_crop_screen.dart';

const _kCrimson = Color(0xFF7B0D1E);

// ── Custom Hamburger Icon ────────────────────────────────────────────────────
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

// ── Star Data Class ─────────────────────────────────────────────────────────
class Star {
  final double x;
  final double y;
  final double size;
  final double baseOpacity;
  final double speed;
  final double twinklePhase;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.baseOpacity,
    required this.speed,
    required this.twinklePhase,
  });
}

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

  // Department → Position mapping
  static const Map<String, List<String>> _deptRoles = {
    'Business Relationship Management': [
      'Account Manager',
      'Business Analyst',
      'Client Relations',
      'Intern',
      'Others',
    ],
    'Project Management Office': [
      'Project Manager',
      'Project Coordinator',
      'Scrum Master',
      'Intern',
      'Others',
    ],
    'Quality Assurance': [
      'QA Engineer',
      'QA Automation Tester',
      'Manual Tester',
      'Intern',
      'Others',
    ],
    'Technical Support Department': [
      'IT Support Specialist',
      'System Administrator',
      'Helpdesk Technician',
      'Intern',
      'Others',
    ],
    'Development Department': [
      'Software Engineer',
      'Frontend Developer',
      'Backend Developer',
      'UI/UX Designer',
      'Intern',
      'Others',
    ],
  };

  List<String> _departments = [];
  List<String> _positions = [];
  String? _selectedDept;
  String? _selectedPos;

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
  final bool _isUploadingAvatar = false;
  final ImagePicker _picker = ImagePicker();
  Uint8List? _localAvatarBytes;
  File? _avatarFile;

  // Animation controller
  late AnimationController _bgAnimController;
  final List<Star> _stars = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _departments = _deptRoles.keys.toList();
    final user = context.read<AuthProvider>().user;
    _firstCtrl = TextEditingController(text: user?['first_name'] ?? '');
    _lastCtrl = TextEditingController(text: user?['last_name'] ?? '');
    _emailCtrl = TextEditingController(text: user?['email'] ?? '');
    _phoneCtrl = TextEditingController(text: user?['phone'] ?? '');

    // Initialize Department and Position state
    final dept = user?['department'] as String? ?? '';
    final pos = user?['position'] as String? ?? '';

    if (dept.isNotEmpty && _departments.contains(dept)) {
      _selectedDept = dept;
      _positions = _deptRoles[dept] ?? ['Intern', 'Others'];
    } else if (dept.isNotEmpty) {
      _selectedDept = dept;
      if (!_departments.contains(dept)) _departments.add(dept);
      _positions = [pos];
    }

    if (pos.isNotEmpty && _positions.contains(pos)) {
      _selectedPos = pos;
    } else if (pos.isNotEmpty) {
      _selectedPos = pos;
      if (!_positions.contains(pos)) _positions.add(pos);
    }

    _generateStars();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 150),
    )..repeat();
  }

  void _generateStars() {
    final random = math.Random();
    for (int i = 0; i < 200; i++) {
      _stars.add(Star(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 2.0 + 0.5,
        baseOpacity: random.nextDouble() * 0.7 + 0.3,
        speed: random.nextDouble() * 0.05 + 0.01,
        twinklePhase: random.nextDouble() * 2 * math.pi,
      ));
    }
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    _tabs.dispose();
    for (final c in [
      _firstCtrl,
      _lastCtrl,
      _emailCtrl,
      _phoneCtrl,
      _curPassCtrl,
      _newPassCtrl,
      _confirmPassCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Avatar Pick & Upload ───────────────────────────────────────────────────
  Future<void> pickAndCropAvatar() async {
    try {
      print("🔥 Edit Avatar clicked");
      print("📸 Function started");

      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // prevent corrupted compression
      );

      print("📂 Picker opened");

      if (pickedFile == null) {
        print("❌ User cancelled image selection");
        return;
      }

      print("✅ Image selected: ${pickedFile.path}");

      // Validate using MIME type on actual file bytes
      print("📂 Full path: ${pickedFile.path}");
      print("📂 Lowercase path: ${pickedFile.path.toLowerCase()}");

      final pickedFileBytes = await pickedFile.readAsBytes();
      final mimeType =
          lookupMimeType(pickedFile.name, headerBytes: pickedFileBytes);
      print("📄 MIME TYPE: $mimeType");

      if (mimeType == null || !mimeType.startsWith('image/')) {
        print("❌ Invalid file type detected (MIME: $mimeType)");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Please select a valid image file (JPG, PNG, JPEG)'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      print("✅ Valid image file detected");

      if (kIsWeb) {
        print("🌐 Web detected - opening crop screen");
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

        print(
            "🔙 Returned from crop screen: ${croppedBytes?.length ?? 0} bytes");

        if (croppedBytes == null) {
          print("❌ Cropping cancelled");
          return;
        }

        if (!mounted) return;

        setState(() {
          _localAvatarBytes = croppedBytes;
          _avatarFile = null;
        });

        final res = await ApiService.uploadAvatar(
          XFile.fromData(croppedBytes, name: pickedFile.name),
        );

        if (!mounted) return;
        if (res['ok'] == true) {
          print("✅ Web upload successful");
          await context.read<AuthProvider>().updateUserData(res['user'] ?? {});
          setState(() {
            _avatarFile = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avatar updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          print("❌ Web upload failed: ${res['error'] ?? 'Unknown error'}");
          setState(() {
            _avatarFile = null;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(res['error'] ?? 'Failed to upload avatar'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        return;
      }

      final file = File(pickedFile.path);

      if (!await file.exists()) {
        print("❌ File does not exist: ${pickedFile.path}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File does not exist'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final fileSize = await file.length();
      print("✅ File verified: size=${fileSize}bytes");

      print("🚀 Navigating to crop screen");
      final croppedBytes = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(
          builder: (_) => AvatarCropScreen(
            imageBytes: pickedFileBytes,
            fileName: pickedFile.name,
          ),
        ),
      );

      print("🔙 Returned from crop screen: ${croppedBytes?.length ?? 0} bytes");

      if (croppedBytes == null) {
        print("❌ Cropping cancelled");
        return;
      }

      if (!mounted) return;

      final tempFile =
          File('${(await getTemporaryDirectory()).path}/cropped_avatar.png');
      await tempFile.writeAsBytes(croppedBytes);
      setState(() {
        _avatarFile = tempFile;
      });
      print("✅ UI updated with cropped image");

      if (!mounted) return;
      print("📤 Uploading avatar...");

      final res = await ApiService.uploadAvatar(XFile(_avatarFile!.path));
      print("🔙 Upload response received");

      if (!mounted) return;

      if (res['ok'] == true) {
        print("✅ Upload successful");
        await context.read<AuthProvider>().updateUserData(res['user'] ?? {});

        setState(() {
          _avatarFile = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print("❌ Upload failed: ${res['error'] ?? 'Unknown error'}");
        setState(() {
          _avatarFile = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['error'] ?? 'Upload failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      print("❌ ERROR: $e");
      print("📋 Stack trace: $stackTrace");

      if (mounted) {
        setState(() {
          _avatarFile = null;
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
    setState(() {
      _savingProfile = true;
      _profileMsg = null;
    });
    final res = await ApiService.updateProfile({
      'first_name': _firstCtrl.text.trim(),
      'last_name': _lastCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'department': _selectedDept ?? '',
      'position': _selectedPos ?? '',
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

  // ── Animated Background ────────────────────────────────────────────────────
  Widget _buildAnimatedGalaxyBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.3, -0.2),
          radius: 1.5,
          colors: [
            Color(0xFF3A0812),
            Color(0xFF140306),
            Color(0xFF050505),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: AnimatedBuilder(
        animation: _bgAnimController,
        builder: (context, child) {
          return CustomPaint(
            painter: StarfieldPainter(
              animationValue: _bgAnimController.value,
              stars: _stars,
            ),
          );
        },
      ),
    );
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
        borderSide: const BorderSide(color: _kCrimson, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade300, width: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    String rawAvatarUrl = user?['avatar_url'] as String? ?? '';
    String finalAvatarUrl = '';
    if (rawAvatarUrl.isNotEmpty) {
      if (!rawAvatarUrl.startsWith('http')) {
        finalAvatarUrl =
            '${Uri.parse(ApiService.baseUrl).replace(queryParameters: null).toString().replaceAll('/api', '')}$rawAvatarUrl';
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
            child: Stack(
              children: [
                Positioned.fill(child: _buildAnimatedGalaxyBackground()),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 48),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                if (!_isSidebarOpen) ...[
                                  Container(
                                    margin: const EdgeInsets.only(right: 16),
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
                                      onPressed: () =>
                                          setState(() => _isSidebarOpen = true),
                                      icon: const HamburgerIcon(),
                                      tooltip: 'Open Sidebar',
                                      splashColor:
                                          Colors.white.withOpacity(0.1),
                                      highlightColor: Colors.transparent,
                                    ),
                                  ),
                                ],
                                Text(
                                  'Account Settings',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Card(
                              elevation: 0,
                              color: Colors.white.withOpacity(0.95),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 20),
                                child: Row(
                                  children: [
                                    Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        CircleAvatar(
                                          radius: 40,
                                          backgroundColor:
                                              _kCrimson.withOpacity(0.1),
                                          backgroundImage: _avatarFile != null
                                              ? FileImage(_avatarFile!)
                                              : (_localAvatarBytes != null
                                                  ? MemoryImage(
                                                      _localAvatarBytes!)
                                                  : (finalAvatarUrl.isNotEmpty
                                                      ? NetworkImage(
                                                          finalAvatarUrl)
                                                      : null)) as ImageProvider,
                                          child: _isUploadingAvatar
                                              ? const CircularProgressIndicator(
                                                  color: _kCrimson,
                                                  strokeWidth: 3)
                                              : (_avatarFile == null &&
                                                      _localAvatarBytes ==
                                                          null &&
                                                      finalAvatarUrl.isEmpty)
                                                  ? Text(
                                                      '${(user?['first_name'] as String? ?? ' ')[0]}'
                                                      '${(user?['last_name'] as String? ?? ' ')[0]}',
                                                      style: const TextStyle(
                                                        fontSize: 28,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: _kCrimson,
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
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: _kCrimson,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color: Colors.white,
                                                      width: 2),
                                                ),
                                                child: const Icon(
                                                  Icons.camera_alt,
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
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
                                          if ((user?['department'] as String? ??
                                                  '')
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
                                              color: user?['role'] == 'admin'
                                                  ? Colors.red.shade50
                                                  : _kCrimson.withOpacity(0.08),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              (user?['role'] ?? 'user')
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                color: user?['role'] == 'admin'
                                                    ? Colors.red.shade700
                                                    : _kCrimson,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: Card(
                                elevation: 0,
                                color: Colors.white.withOpacity(0.95),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24)),
                                child: Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                              color: Colors.grey.shade200),
                                        ),
                                      ),
                                      child: TabBar(
                                        controller: _tabs,
                                        labelColor: _kCrimson,
                                        indicatorColor: _kCrimson,
                                        indicatorWeight: 3,
                                        unselectedLabelColor:
                                            Colors.grey.shade500,
                                        labelStyle: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700),
                                        unselectedLabelStyle: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500),
                                        dividerColor: Colors.transparent,
                                        tabs: const [
                                          Tab(text: 'Account Settings'),
                                          Tab(text: 'Change Password'),
                                        ],
                                      ),
                                    ),
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
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return SingleChildScrollView(
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
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                decoration: _getFormDecoration('First Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              )),
              const SizedBox(width: 16),
              Expanded(
                  child: TextFormField(
                controller: _lastCtrl,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                decoration: _getFormDecoration('Last Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              )),
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
            Row(children: [
              Expanded(
                child: _dropdownField(
                  label: 'Department',
                  value: _selectedDept,
                  hint: _departments.isEmpty ? 'N/A' : 'Select Department',
                  items: _departments,
                  onChanged: (v) {
                    setState(() {
                      _selectedDept = v;
                      _positions = _deptRoles[v] ?? ['Intern', 'Others'];
                      if (_selectedPos != null &&
                          !_positions.contains(_selectedPos)) {
                        _selectedPos = null;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _dropdownField(
                  label: 'Position',
                  value: _selectedPos,
                  hint: _positions.isEmpty
                      ? 'Select Dept First'
                      : 'Select Position',
                  items: _positions,
                  onChanged: _positions.isEmpty
                      ? null
                      : (v) => setState(() => _selectedPos = v),
                ),
              ),
            ]),
            const SizedBox(height: 32),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savingProfile ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kCrimson,
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
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordForm() {
    return SingleChildScrollView(
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
                if (v == null || v.length < 8) {
                  return 'Min 8 characters';
                }
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
              onToggle: () => setState(() => _obscureConf = !_obscureConf),
              validator: (v) {
                if (v!.isEmpty) {
                  return 'Required';
                }
                if (v != _newPassCtrl.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savingPass ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kCrimson,
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
          ],
        ),
      ),
    );
  }

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
                          child: Text(
                            s,
                            overflow: TextOverflow.ellipsis,
                          )))
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

// ── Starfield Painter ───────────────────────────────────────────────────────
class StarfieldPainter extends CustomPainter {
  final double animationValue;
  final List<Star> stars;

  StarfieldPainter({required this.animationValue, required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var star in stars) {
      double twinkle =
          (math.sin((animationValue * 2 * math.pi * 1.5) + star.twinklePhase) +
                  1.0) /
              2.0;
      double currentOpacity = star.baseOpacity * (0.3 + (0.7 * twinkle));

      paint.color = Colors.white.withOpacity(currentOpacity.clamp(0.0, 1.0));

      double dx =
          (star.x * size.width + (animationValue * size.width * star.speed)) %
              size.width;
      double dy = star.y * size.height;

      if (star.size > 1.5) {
        final glowPaint = Paint()
          ..color = Colors.white.withOpacity(currentOpacity * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
        canvas.drawCircle(Offset(dx, dy), star.size * 2, glowPaint);
      }

      canvas.drawCircle(Offset(dx, dy), star.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StarfieldPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
