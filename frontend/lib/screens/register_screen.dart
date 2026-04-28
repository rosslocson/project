import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../providers/auth_provider.dart';
import '../services/api_service.dart';

// ── Imported Extracted Widgets ──
import '../widgets/register_widgets/register_form.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  // Departments
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

  @override
  void dispose() {
    for (final c in [_firstCtrl, _lastCtrl, _emailCtrl, _passCtrl, _confirmCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchDepartments() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/departments'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List items = data['items'] ?? [];
        if (mounted) {
          setState(() {
            _departments = items.map<String>((d) => d['name'] as String).toList();
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
        _passColor = const Color(0xFF00022E); // kCosmicBlue
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
        _confirmError = _confirmCtrl.text != pass ? 'Passwords do not match' : null;
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
      'position': _defaultPosition,
    });
    
    if (mounted && ok) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Extracted Form Widget
    final formWidget = RegisterForm(
      formKey: _formKey,
      firstCtrl: _firstCtrl,
      lastCtrl: _lastCtrl,
      emailCtrl: _emailCtrl,
      passCtrl: _passCtrl,
      confirmCtrl: _confirmCtrl,
      obscurePass: _obscurePass,
      obscureConfirm: _obscureConfirm,
      departments: _departments,
      loadingDepts: _loadingDepts,
      selectedDept: _selectedDept,
      defaultPosition: _defaultPosition,
      passStrength: _passStrength,
      passColor: _passColor,
      passValue: _passValue,
      confirmError: _confirmError,
      auth: auth,
      onToggleObscurePass: () => setState(() => _obscurePass = !_obscurePass),
      onToggleObscureConfirm: () => setState(() => _obscureConfirm = !_obscureConfirm),
      onPassChanged: _checkStrength,
      onConfirmChanged: _checkConfirm,
      onDeptChanged: (v) => setState(() => _selectedDept = v),
      onRegister: _register,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            // Desktop Layout
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
                                    const Icon(Icons.public, size: 120, color: Colors.white),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'READY FOR LIFTOFF?',
                                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                              ),
                              const SizedBox(height: 16),
                              Container(width: 40, height: 2, color: Colors.white54),
                              const SizedBox(height: 16),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 64.0),
                                child: Text(
                                  'Launch your intern journey today.\nBuild your profile and explore the stars of our current cohort.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
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
                    child: formWidget.buildForm(isMobile: false, context: context),
                  ),
                ),
              ],
            );
          } else {
            // Mobile Layout
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
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 5),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: formWidget.buildForm(isMobile: true, context: context),
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