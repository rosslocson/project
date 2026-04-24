import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_theme.dart';
// Add your API service import:
import '../services/api_service.dart'; // adjust path as needed
import 'dart:convert';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  // ── Dynamic departments from DB ──────────────────────────────────────────
  List<String> _departments = [];
  bool _loadingDepts = true;
  String? _selectedDept;

  // Position is always fixed to "Intern" on registration
  final String _defaultPosition = 'Intern';

  // Password strength
  String _passStrength = '';
  Color _passColor = Colors.grey;
  double _passValue = 0;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/departments'),
        headers: {'Content-Type': 'application/json'}, // no auth token
      ).timeout(const Duration(seconds: 10));

      debugPrint('Departments status: ${res.statusCode}');
      debugPrint('Departments body: ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List items = data['items'] ?? [];
        if (mounted) {
          setState(() {
            _departments =
                items.map<String>((d) => d['name'] as String).toList();
            _loadingDepts = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingDepts = false);
      }
    } catch (e) {
      debugPrint('Failed to fetch departments: $e');
      if (mounted) setState(() => _loadingDepts = false);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _firstCtrl,
      _lastCtrl,
      _emailCtrl,
      _passCtrl,
      _confirmCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _checkStrength(String pass) {
    int score = 0;
    if (pass.length >= 8) score++;
    if (pass.contains(RegExp(r'[A-Z]'))) score++;
    if (pass.contains(RegExp(r'[a-z]'))) score++;
    if (pass.contains(RegExp(r'[0-9]'))) score++;
    if (pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    setState(() {
      if (score <= 2) {
        _passStrength = 'Weak';
        _passColor = kCosmicBlue;
        _passValue = 0.25;
      } else if (score == 3) {
        _passStrength = 'Fair';
        _passColor = Colors.orange;
        _passValue = 0.5;
      } else if (score == 4) {
        _passStrength = 'Good';
        _passColor = Colors.blue;
        _passValue = 0.75;
      } else {
        _passStrength = 'Strong';
        _passColor = Colors.green;
        _passValue = 1.0;
      }
      if (_confirmCtrl.text.isNotEmpty) {
        _confirmError =
            _confirmCtrl.text != pass ? 'Passwords do not match' : null;
      }
    });
  }

  void _checkConfirm(String v) {
    setState(() {
      _confirmError = v != _passCtrl.text ? 'Passwords do not match' : null;
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _confirmError = 'Passwords do not match');
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.register({
      'first_name': _firstCtrl.text.trim(),
      'last_name': _lastCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'password': _passCtrl.text,
      'confirm_password': _confirmCtrl.text,
      'department': _selectedDept ?? '',
      'position': _defaultPosition, // always "Intern"
    });
    if (mounted && ok) context.go('/home');
  }

  // ── Form ─────────────────────────────────────────────────────────────────
  Widget _buildForm(AuthProvider auth, {required bool isMobile}) {
    final dec = pillInputDecoration();

    return Container(
      alignment: Alignment.center,
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 64,
        vertical: isMobile ? 24 : 40,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'CREATE ACCOUNT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: kCosmicBlue,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(flex: 3),

              // Error banner
              if (auth.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kCosmicBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kCosmicBlue.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        color: kCosmicBlue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(auth.error!,
                            style: const TextStyle(
                                color: kCosmicBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.w600))),
                    GestureDetector(
                      onTap: () => context.read<AuthProvider>().clearError(),
                      child:
                          const Icon(Icons.close, size: 20, color: kCosmicBlue),
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
              ],

              // First + Last name
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      fieldLabel('First Name'),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _firstCtrl,
                        decoration: dec.copyWith(hintText: 'First Name'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      fieldLabel('Last Name'),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _lastCtrl,
                        decoration: dec.copyWith(hintText: 'Last Name'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ]),
              const Spacer(flex: 1),

              // Email
              fieldLabel('Email Address'),
              const SizedBox(height: 4),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: dec.copyWith(hintText: 'Enter Email Address'),
                validator: (v) {
                  if (v!.isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const Spacer(flex: 1),

              // Department (dynamic) + Position (fixed: Intern)
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      fieldLabel('Department'),
                      const SizedBox(height: 4),
                      _loadingDepts
                          ? _shimmerDropdown(dec)
                          : DropdownButtonFormField<String>(
                              initialValue: _selectedDept,
                              decoration: dec,
                              hint: Text(
                                _departments.isEmpty
                                    ? 'None available'
                                    : 'Select Department',
                                style: const TextStyle(fontSize: 13),
                              ),
                              icon: Icon(Icons.keyboard_arrow_down,
                                  color: Colors.grey.shade500),
                              items: _departments
                                  .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s,
                                          overflow: TextOverflow.ellipsis,
                                          style:
                                              const TextStyle(fontSize: 12))))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedDept = v),
                            ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Position — always "Intern", shown as a disabled field
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      fieldLabel('Position'),
                      const SizedBox(height: 4),
                      IgnorePointer(
                        child: DropdownButtonFormField<String>(
                          initialValue: _defaultPosition,
                          decoration: dec.copyWith(
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                          icon: Icon(Icons.keyboard_arrow_down,
                              color: Colors.grey.shade300),
                          items: [
                            DropdownMenuItem(
                              value: _defaultPosition,
                              child: Text(
                                _defaultPosition,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                          onChanged: null,
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
              const Spacer(flex: 1),

              // Password
              fieldLabel('Password'),
              const SizedBox(height: 4),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                onChanged: _checkStrength,
                decoration: dec.copyWith(
                  hintText: 'Create a password',
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF9CA3AF),
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.length < 8) return 'Min 8 characters';
                  if (!v.contains(RegExp(r'[A-Z]'))) {
                    return 'Need one uppercase letter';
                  }
                  if (!v.contains(RegExp(r'[0-9]'))) return 'Need one number';
                  if (!v.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                    return 'Need one special character';
                  }
                  return null;
                },
              ),
              if (_passCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _passValue,
                        color: _passColor,
                        backgroundColor: Colors.grey.shade200,
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 48,
                    child: Text(_passStrength,
                        style: TextStyle(
                            color: _passColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800)),
                  ),
                ]),
              ],
              const Spacer(flex: 1),

              // Confirm password
              fieldLabel('Confirm Password'),
              const SizedBox(height: 4),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscureConfirm,
                onChanged: _checkConfirm,
                decoration: dec.copyWith(
                  hintText: 'Confirm your password',
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF9CA3AF),
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (v != _passCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),
              if (_confirmError != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(_confirmError!,
                      style: const TextStyle(fontSize: 11, color: Colors.red)),
                ),
              ],
              const Spacer(flex: 3),

              BlueButton(
                label: 'SIGN UP',
                onPressed: auth.isLoading ? null : _register,
                loading: auth.isLoading,
              ),
              const Spacer(flex: 2),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? ',
                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text('Login Now',
                        style: TextStyle(
                          fontSize: 13,
                          color: kCosmicBlue,
                          fontWeight: FontWeight.bold,
                        )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Placeholder shimmer-style widget while departments load
  Widget _shimmerDropdown(InputDecoration dec) {
    return DropdownButtonFormField<String>(
      decoration: dec.copyWith(
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      hint: const Text('Loading...', style: TextStyle(fontSize: 13)),
      icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade300),
      items: const [],
      onChanged: null,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/star_background.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/logo_login.png',
                                height: 280,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.public,
                                        size: 120, color: Colors.white),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'READY FOR LIFTOFF?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                  width: 40, height: 2, color: Colors.white54),
                              const SizedBox(height: 16),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 64.0),
                                child: Text(
                                  'Launch your intern journey today.\nBuild your profile and explore the stars of our current cohort.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: _buildForm(auth, isMobile: false),
                  ),
                ),
              ],
            );
          } else {
            return Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/star_background.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _buildForm(auth, isMobile: true),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
