import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Note: You must add 'image_picker: ^1.0.7' (or latest) to your pubspec.yaml
import 'package:image_picker/image_picker.dart'; 
import '../providers/auth_provider.dart';

import '../services/api_service.dart';
import '../widgets/user_layout.dart';


const _kCrimson = Color(0xFF7B0D1E);

// ── Custom Hamburger Icon (Redesigned) ──────────────────────────────────────
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
            width: 14, // Shorter middle line for a modern, dynamic feel
            height: 2.5,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
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

// ── Star Data Class for Galaxy Theme ─────────────────────────────────────────
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

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});
  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabs;

  // Department → Position mapping (from register_screen)
  static const Map<String, List<String>> _deptRoles = {
    'Business Relationship Management': [
      'Account Manager', 'Business Analyst', 'Client Relations',
      'Intern', 'Others',
    ],
    'Project Management Office': [
      'Project Manager', 'Project Coordinator', 'Scrum Master',
      'Intern', 'Others',
    ],
    'Quality Assurance': [
      'QA Engineer', 'QA Automation Tester', 'Manual Tester',
      'Intern', 'Others',
    ],
    'Technical Support Department': [
      'IT Support Specialist', 'System Administrator',
      'Helpdesk Technician', 'Intern', 'Others',
    ],
    'Development Department': [
      'Software Engineer', 'Frontend Developer', 'Backend Developer',
      'UI/UX Designer', 'Intern', 'Others',
    ],
  };

  List<String> _departments = [];
  List<String> _positions   = [];
  String? _selectedDept;
  String? _selectedPos;

  // Form keys
  final _profileKey = GlobalKey<FormState>();
  final _passKey    = GlobalKey<FormState>();

  // Profile controllers
  late TextEditingController _firstCtrl;
  late TextEditingController _lastCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  // Password controllers
  final _curPassCtrl     = TextEditingController();
  final _newPassCtrl     = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  // UI state
  bool    _savingProfile = false;
  bool    _savingPass    = false;
  String? _profileMsg;
  String? _passMsg;
  bool    _profileSuccess = false;
  bool    _passSuccess    = false;
  bool    _obscureCur     = true;
  bool    _obscureNew     = true;
  bool    _obscureConf    = true;

  // Avatar Upload State
  bool _isUploadingAvatar = false;
  final ImagePicker _picker = ImagePicker();

  // Animation controller for galaxy background
  late AnimationController _bgAnimController;
  final List<Star> _stars = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _departments = _deptRoles.keys.toList();
    final user = context.read<AuthProvider>().user;
    _firstCtrl = TextEditingController(text: user?['first_name'] ?? '');
    _lastCtrl  = TextEditingController(text: user?['last_name']  ?? '');
    _emailCtrl = TextEditingController(text: user?['email']      ?? '');
    _phoneCtrl = TextEditingController(text: user?['phone']      ?? '');
    
    // Initialize Department and Position state
    final dept = user?['department'] as String? ?? '';
    final pos  = user?['position']   as String? ?? '';
    
    if (dept.isNotEmpty && _departments.contains(dept)) {
      _selectedDept = dept;
      _positions = _deptRoles[dept] ?? ['Intern', 'Others'];
    } else if (dept.isNotEmpty) {
      // Fallback in case their current dept isn't in the static list
      _selectedDept = dept;
      if (!_departments.contains(dept)) _departments.add(dept);
      _positions = [pos];
    }

    if (pos.isNotEmpty && _positions.contains(pos)) {
      _selectedPos = pos;
    } else if (pos.isNotEmpty) {
       // Fallback in case their current pos isn't in the static list
      _selectedPos = pos;
      if (!_positions.contains(pos)) _positions.add(pos);
    }

    // Initialize Starfield
    _generateStars();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 150), // Very slow, ambient drift
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
      _firstCtrl, _lastCtrl, _emailCtrl, _phoneCtrl,
      _curPassCtrl, _newPassCtrl, _confirmPassCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Avatar Pick & Upload Logic ─────────────────────────────────────────────
  Future<void> _pickAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return; // User canceled the picker

      setState(() => _isUploadingAvatar = true);

      // Call your actual ApiService here
      final res = await ApiService.uploadAvatar(image); 
      
      if (!mounted) return;
      
      if (res['ok'] == true) {
        // Update the user provider with the new avatar URL so the UI updates
        context.read<AuthProvider>().updateUserData(res['user'] ?? {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['error'] ?? 'Upload failed'), 
            backgroundColor: Colors.red,
          ),
        );
      }

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_profileKey.currentState!.validate()) return;
    setState(() { _savingProfile = true; _profileMsg = null; });
    final res = await ApiService.updateProfile({
      'first_name': _firstCtrl.text.trim(),
      'last_name':  _lastCtrl.text.trim(),
      'phone':      _phoneCtrl.text.trim(),
      'department': _selectedDept ?? '',
      'position':   _selectedPos  ?? '',
    });
    if (!mounted) return;
    if (res['ok'] == true) {
      context.read<AuthProvider>().updateUserData(res['user'] ?? {});
      setState(() {
        _profileMsg    = 'Profile updated successfully!';
        _profileSuccess = true;
      });
    } else {
      setState(() {
        _profileMsg    = res['error'] ?? 'Update failed';
        _profileSuccess = false;
      });
    }
    setState(() => _savingProfile = false);
  }

  Future<void> _changePassword() async {
    if (!_passKey.currentState!.validate()) return;
    setState(() { _savingPass = true; _passMsg = null; });
    final res = await ApiService.changePassword({
      'current_password': _curPassCtrl.text,
      'new_password':     _newPassCtrl.text,
      'confirm_password': _confirmPassCtrl.text,
    });
    if (!mounted) return;
    if (res['ok'] == true) {
      _curPassCtrl.clear();
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();
      setState(() { _passMsg = 'Password changed successfully!'; _passSuccess = true; });
    } else {
      setState(() {
        _passMsg    = res['error'] ?? res['details'] ?? 'Change failed';
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
            Color(0xFF3A0812), // Deep glowing nebula red
            Color(0xFF140306), // Very dark crimson
            Color(0xFF050505), // Pure deep space black
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

  // ── Reusable Input Decoration ──────────────────────────────────────────────
  InputDecoration _getFormDecoration(String label, {IconData? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey.shade500, size: 18) : null,
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

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return UserLayout(
      currentRoute: '/account-settings',
      child: _buildSettingsContent(context),
    );
  }

  Widget _buildSettingsContent(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    // Avatar URL helper logic
    String rawAvatarUrl = user?['avatar_url'] as String? ?? '';
    String finalAvatarUrl = '';
    if (rawAvatarUrl.isNotEmpty) {
      // If the backend returned a relative path, attach the backend server address
      if (!rawAvatarUrl.startsWith('http')) {
        finalAvatarUrl = 'http://127.0.0.1:8080$rawAvatarUrl'; // Adjust to match your Go port
      } else {
        finalAvatarUrl = rawAvatarUrl;
      }
    }

    return Stack(
      children: [
        // Galaxy Background
        Positioned.fill(child: _buildAnimatedGalaxyBackground()),
        
        // Form Content
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 48),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // ── Page header (no hamburger - handled by layout) ──
                    Row(
                      children: [
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

                    // ── Avatar card ──────────────────────────────────────
                    Card(
                      elevation: 0,
                      color: Colors.white.withOpacity(0.95),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        child: Row(
                          children: [
                            // Stack used here to place the edit button over the avatar
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor:
                                      _kCrimson.withOpacity(0.1),
                                  backgroundImage: finalAvatarUrl.isNotEmpty 
                                      ? NetworkImage(finalAvatarUrl) 
                                      : null,
                                  child: _isUploadingAvatar
                                      ? const CircularProgressIndicator(color: _kCrimson, strokeWidth: 3)
                                      : finalAvatarUrl.isEmpty
                                          ? Text(
                                              '${(user?['first_name'] as String? ?? ' ')[0]}'
                                              '${(user?['last_name'] as String? ?? ' ')[0]}',
                                              style: const TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                color: _kCrimson,
                                              ),
                                            )
                                          : null,
                                ),
                                // Edit Button Over Avatar
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _isUploadingAvatar ? null : _pickAvatar,
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: _kCrimson,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
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
                                      color: _kCrimson.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Text(
                                      'USER',
                                      style: TextStyle(
                                        color: _kCrimson,
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

                    // ── Tabs card ────────────────────────────────────────
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
                                  bottom: BorderSide(color: Colors.grey.shade200),
                                ),
                              ),
                              child: TabBar(
                                controller: _tabs,
                                labelColor: _kCrimson,
                                indicatorColor: _kCrimson,
                                indicatorWeight: 3,
                                unselectedLabelColor: Colors.grey.shade500,
                                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
    );
  }


  // ── Profile form ───────────────────────────────────────────────────────────
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
              Expanded(child: TextFormField(
                controller: _firstCtrl,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                decoration: _getFormDecoration('First Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              )),
              const SizedBox(width: 16),
              Expanded(child: TextFormField(
                controller: _lastCtrl,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                decoration: _getFormDecoration('Last Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              )),
            ]),
            
            const SizedBox(height: 16),

            // Email takes up the full width now
            TextFormField(
              controller: _emailCtrl,
              enabled: false,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
              decoration: _getFormDecoration('Email (cannot change)', prefixIcon: Icons.email_outlined),
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
                      // Update positions when a new department is selected
                      _positions = _deptRoles[v] ?? ['Intern', 'Others'];
                      // Clear selected position if it isn't part of the newly loaded list
                      if (_selectedPos != null && !_positions.contains(_selectedPos)) {
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
                  hint: _positions.isEmpty ? 'Select Dept First' : 'Select Position',
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
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Password form ──────────────────────────────────────────────────────────
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
                if (v == null || v.length < 8) { return 'Min 8 characters'; }
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
                if (v!.isEmpty) { return 'Required'; }
                if (v != _newPassCtrl.text) { return 'Passwords do not match'; }
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
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
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
                          color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w500)),
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down,
                      color: Colors.grey[500], size: 18),
                  style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
                  items: items
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis,)))
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
        decoration: _getFormDecoration(label, prefixIcon: Icons.lock_outline).copyWith(
          suffixIcon: IconButton(
            icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
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
              color: success
                  ? Colors.green.shade200
                  : Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(
                success ? Icons.check_circle : Icons.error_outline,
                color: success ? Colors.green : Colors.red,
                size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg,
                  style: TextStyle(
                      fontSize: 13,
                      color: success
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

// ── Custom Painter for Starfield ─────────────────────────────────────────────
class StarfieldPainter extends CustomPainter {
  final double animationValue;
  final List<Star> stars;

  StarfieldPainter({required this.animationValue, required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var star in stars) {
      double twinkle = (math.sin((animationValue * 2 * math.pi * 1.5) + star.twinklePhase) + 1.0) / 2.0;
      double currentOpacity = star.baseOpacity * (0.3 + (0.7 * twinkle));
      
      paint.color = Colors.white.withValues(alpha: currentOpacity.clamp(0.0, 1.0));

      double dx = (star.x * size.width + (animationValue * size.width * star.speed)) % size.width;
      double dy = star.y * size.height;

      if (star.size > 1.5) {
        final glowPaint = Paint()
          ..color = Colors.white.withValues(alpha: currentOpacity * 0.3)
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