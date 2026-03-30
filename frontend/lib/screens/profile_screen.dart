import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/sidebar.dart';

const _kCrimson = Color(0xFF7B0D1E);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // Config dropdowns
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
  late TextEditingController _bioCtrl;

  // Password controllers
  final _curPassCtrl     = TextEditingController();
  final _newPassCtrl     = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  // UI state
  bool    _savingProfile  = false;
  bool    _savingPass     = false;
  String? _profileMsg;
  String? _passMsg;
  bool    _profileSuccess = false;
  bool    _passSuccess    = false;
  bool    _obscureCur     = true;
  bool    _obscureNew     = true;
  bool    _obscureConf    = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    final user = context.read<AuthProvider>().user;
    _firstCtrl = TextEditingController(text: user?['first_name'] ?? '');
    _lastCtrl  = TextEditingController(text: user?['last_name']  ?? '');
    _emailCtrl = TextEditingController(text: user?['email']      ?? '');
    _phoneCtrl = TextEditingController(text: user?['phone']      ?? '');
    _bioCtrl   = TextEditingController(text: user?['bio']        ?? '');
    final dept = user?['department'] as String? ?? '';
    final pos  = user?['position']   as String? ?? '';
    _selectedDept = dept.isNotEmpty ? dept : null;
    _selectedPos  = pos.isNotEmpty  ? pos  : null;
    _loadConfig();
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final c in [
      _firstCtrl, _lastCtrl, _emailCtrl, _phoneCtrl, _bioCtrl,
      _curPassCtrl, _newPassCtrl, _confirmPassCtrl,
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
      _departments = (d['items'] as List? ?? [])
          .map((e) => e['name'] as String)
          .toList();
      _positions = (p['items'] as List? ?? [])
          .map((e) => e['name'] as String)
          .toList();
      // Re-validate selected values exist in list
      if (_selectedDept != null && !_departments.contains(_selectedDept)) {
        _departments.add(_selectedDept!);
      }
      if (_selectedPos != null && !_positions.contains(_selectedPos)) {
        _positions.add(_selectedPos!);
      }
    });
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
      'bio':        _bioCtrl.text.trim(),
    });
    if (!mounted) return;
    if (res['ok'] == true) {
      context.read<AuthProvider>().updateUserData(res['user'] ?? {});
      setState(() { _profileMsg = 'Profile updated successfully!'; _profileSuccess = true; });
    } else {
      setState(() { _profileMsg = res['error'] ?? 'Update failed'; _profileSuccess = false; });
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
      setState(() { _passMsg = res['error'] ?? res['details'] ?? 'Change failed'; _passSuccess = false; });
    }
    setState(() => _savingPass = false);
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user   = context.watch<AuthProvider>().user;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FF),
      body: Row(
        children: [
          const Sidebar(currentRoute: '/profile'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Profile',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),

                    // ── Avatar card ──────────────────────────────────────
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: _kCrimson.withValues(alpha: 0.1),
                            backgroundImage: (user?['avatar_url'] as String? ?? '')
                                    .isNotEmpty
                                ? NetworkImage(user!['avatar_url'])
                                : null,
                            child: (user?['avatar_url'] as String? ?? '').isEmpty
                                ? Text(
                                    '${(user?['first_name'] as String? ?? ' ')[0]}'
                                    '${(user?['last_name']  as String? ?? ' ')[0]}',
                                    style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: colors.primary),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${user?['first_name'] ?? ''} ${user?['last_name'] ?? ''}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(user?['email'] ?? '',
                                    style: TextStyle(
                                        color: Colors.grey.shade600)),
                                if ((user?['department'] as String? ?? '')
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '${user?['department']} · ${user?['position'] ?? ''}',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 13),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: user?['role'] == 'admin'
                                        ? Colors.red.shade50
                                        : _kCrimson.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    (user?['role'] ?? 'user').toUpperCase(),
                                    style: TextStyle(
                                      color: user?['role'] == 'admin'
                                          ? Colors.red.shade700
                                          : _kCrimson,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Tabs card ────────────────────────────────────────
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Column(children: [
                        TabBar(
                          controller: _tabs,
                          labelColor: _kCrimson,
                          indicatorColor: _kCrimson,
                          unselectedLabelColor: Colors.grey,
                          tabs: const [
                            Tab(text: 'Edit Profile'),
                            Tab(text: 'Change Password'),
                          ],
                        ),
                        SizedBox(
                          height: 520,
                          child: TabBarView(
                            controller: _tabs,
                            children: [
                              _buildProfileForm(),
                              _buildPasswordForm(),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Profile form ───────────────────────────────────────────────────────────
  Widget _buildProfileForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _profileKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_profileMsg != null) ...[
              _msgBanner(_profileMsg!, _profileSuccess),
              const SizedBox(height: 12),
            ],

            // Name row
            Row(children: [
              Expanded(child: TextFormField(
                controller: _firstCtrl,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              )),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(
                controller: _lastCtrl,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              )),
            ]),
            const SizedBox(height: 12),

            // Email (read-only)
            TextFormField(
              controller: _emailCtrl,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Email (cannot change)',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),

            // Phone
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),

            // Department dropdown
            _dropdownField(
              label: 'Department',
              value: _selectedDept,
              hint: _departments.isEmpty
                  ? 'No departments — admin must add via Settings'
                  : 'Select Department',
              items: _departments,
              onChanged: (v) => setState(() => _selectedDept = v),
            ),
            const SizedBox(height: 12),

            // Position dropdown
            _dropdownField(
              label: 'Position',
              value: _selectedPos,
              hint: _positions.isEmpty
                  ? 'No positions — admin must add via Settings'
                  : 'Select Position',
              items: _positions,
              onChanged: (v) => setState(() => _selectedPos = v),
            ),
            const SizedBox(height: 12),

            // Bio
            TextFormField(
              controller: _bioCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Bio',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savingProfile ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kCrimson,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _savingProfile
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes',
                        style: TextStyle(fontWeight: FontWeight.w700)),
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
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _passKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_passMsg != null) ...[
              _msgBanner(_passMsg!, _passSuccess),
              const SizedBox(height: 12),
            ],

            _passField(
              controller: _curPassCtrl,
              label: 'Current Password',
              obscure: _obscureCur,
              onToggle: () => setState(() => _obscureCur = !_obscureCur),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            _passField(
              controller: _newPassCtrl,
              label: 'New Password',
              obscure: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
              // FIX: wrapped bare if-body in curly braces
              validator: (v) {
                if (v == null || v.length < 8) { return 'Min 8 characters'; }
                if (!v.contains(RegExp(r'[A-Z]'))) { return 'Need one uppercase letter'; }
                if (!v.contains(RegExp(r'[0-9]'))) { return 'Need one number'; }
                if (!v.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                  return 'Need one special character';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _passField(
              controller: _confirmPassCtrl,
              label: 'Confirm New Password',
              obscure: _obscureConf,
              onToggle: () => setState(() => _obscureConf = !_obscureConf),
              validator: (v) {
                if (v!.isEmpty) return 'Required';
                if (v != _newPassCtrl.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savingPass ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kCrimson,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _savingPass
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Change Password',
                        style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────
  Widget _dropdownField({
    required String label,
    required String? value,
    required String hint,
    required List<String> items,
    required void Function(String?) onChanged,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                hint: Text(hint,
                    style: TextStyle(
                        color: Colors.grey[400], fontSize: 13)),
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down,
                    color: Colors.grey[500]),
                style: const TextStyle(
                    color: Colors.black87, fontSize: 14),
                items: items
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: items.isEmpty ? null : onChanged,
              ),
            ),
          ),
        ],
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
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                size: 20),
            onPressed: onToggle,
          ),
        ),
      );

  Widget _msgBanner(String msg, bool success) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: success ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color:
                  success ? Colors.green.shade200 : Colors.red.shade200),
        ),
        child: Row(children: [
          Icon(
              success ? Icons.check_circle : Icons.error_outline,
              color: success ? Colors.green : Colors.red,
              size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg,
                style: TextStyle(
                    color: success
                        ? Colors.green.shade800
                        : Colors.red.shade800)),
          ),
        ]),
      );
}