import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/sidebar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _profileKey = GlobalKey<FormState>();
  final _passKey = GlobalKey<FormState>();

  late TextEditingController _firstCtrl, _lastCtrl, _emailCtrl,
      _phoneCtrl, _deptCtrl, _posCtrl, _bioCtrl;
  final _curPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _savingProfile = false;
  bool _savingPass = false;
  String? _profileMsg;
  String? _passMsg;
  bool _profileSuccess = false;
  bool _passSuccess = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    final user = context.read<AuthProvider>().user;
    _firstCtrl = TextEditingController(text: user?['first_name'] ?? '');
    _lastCtrl = TextEditingController(text: user?['last_name'] ?? '');
    _emailCtrl = TextEditingController(text: user?['email'] ?? '');
    _phoneCtrl = TextEditingController(text: user?['phone'] ?? '');
    _deptCtrl = TextEditingController(text: user?['department'] ?? '');
    _posCtrl = TextEditingController(text: user?['position'] ?? '');
    _bioCtrl = TextEditingController(text: user?['bio'] ?? '');
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final c in [_firstCtrl, _lastCtrl, _emailCtrl, _phoneCtrl, _deptCtrl, _posCtrl, _bioCtrl, _curPassCtrl, _newPassCtrl, _confirmPassCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_profileKey.currentState!.validate()) return;
    setState(() { _savingProfile = true; _profileMsg = null; });
    final res = await ApiService.updateProfile({
      'first_name': _firstCtrl.text,
      'last_name': _lastCtrl.text,
      'phone': _phoneCtrl.text,
      'department': _deptCtrl.text,
      'position': _posCtrl.text,
      'bio': _bioCtrl.text,
    });
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
      'new_password': _newPassCtrl.text,
      'confirm_password': _confirmPassCtrl.text,
    });
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
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
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),

                    // Avatar card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: colors.primary.withOpacity(0.1),
                              backgroundImage: user?['avatar_url'] != null &&
                                      (user!['avatar_url'] as String).isNotEmpty
                                  ? NetworkImage(user['avatar_url'])
                                  : null,
                              child: user?['avatar_url'] == null || (user!['avatar_url'] as String).isEmpty
                                  ? Text(
                                      '${user?['first_name']?[0] ?? ''}${user?['last_name']?[0] ?? ''}',
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
                                      style: TextStyle(color: Colors.grey.shade600)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: user?['role'] == 'admin'
                                          ? Colors.red.shade50
                                          : colors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      (user?['role'] ?? 'user').toUpperCase(),
                                      style: TextStyle(
                                        color: user?['role'] == 'admin'
                                            ? Colors.red.shade700
                                            : colors.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
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
                    const SizedBox(height: 24),

                    // Tabs
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        children: [
                          TabBar(
                            controller: _tabs,
                            tabs: const [
                              Tab(text: 'Edit Profile'),
                              Tab(text: 'Change Password'),
                            ],
                          ),
                          SizedBox(
                            height: 480,
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _profileKey,
        child: Column(
          children: [
            if (_profileMsg != null) ...[
              _msgBanner(_profileMsg!, _profileSuccess),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
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
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Email (cannot change)',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextFormField(
                  controller: _deptCtrl,
                  decoration: const InputDecoration(labelText: 'Department'),
                )),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  controller: _posCtrl,
                  decoration: const InputDecoration(labelText: 'Position'),
                )),
              ],
            ),
            const SizedBox(height: 12),
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
                child: _savingProfile
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordForm() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _passKey,
        child: Column(
          children: [
            if (_passMsg != null) ...[
              _msgBanner(_passMsg!, _passSuccess),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _curPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock_reset),
              ),
              validator: (v) {
                if (v == null || v.length < 8) return 'Min 8 characters';
                if (!v.contains(RegExp(r'[A-Z]'))) return 'Need one uppercase letter';
                if (!v.contains(RegExp(r'[0-9]'))) return 'Need one number';
                if (!v.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return 'Need one special character';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
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
                child: _savingPass
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Change Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _msgBanner(String msg, bool success) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: success ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: success ? Colors.green.shade200 : Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(success ? Icons.check_circle : Icons.error_outline,
              color: success ? Colors.green : Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: TextStyle(color: success ? Colors.green.shade800 : Colors.red.shade800))),
        ],
      ),
    );
  }
}