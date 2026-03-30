import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/auth_layout.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _firstCtrl    = TextEditingController();
  final _lastCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool  _obscurePass    = true;
  bool  _obscureConfirm = true;

  // Config dropdowns — both declared AND used in _buildDropdown calls
  List<String> _departments = [];
  List<String> _positions   = [];
  String? _selectedDept;
  String? _selectedPos;

  // Validation state
  String? _passError;
  String? _confirmError;
  String  _passStrength = '';
  Color   _passColor    = Colors.grey;
  double  _passValue    = 0;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    for (final c in [
      _firstCtrl, _lastCtrl, _emailCtrl,
      _phoneCtrl, _passCtrl, _confirmCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final d = await ApiService.getConfig(type: 'department');
    final p = await ApiService.getConfig(type: 'position');
    if (mounted) {
      setState(() {
        _departments = (d['items'] as List? ?? [])
            .map((e) => e['name'] as String)
            .toList();
        _positions = (p['items'] as List? ?? [])
            .map((e) => e['name'] as String)
            .toList();
      });
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
        _passColor = kCrimson;
        _passValue = 0.25;
      } else if (score == 3) {
        _passStrength = 'Fair';
        _passColor = Colors.orange;
        _passValue = 0.50;
      } else if (score == 4) {
        _passStrength = 'Good';
        _passColor = Colors.blue;
        _passValue = 0.75;
      } else {
        _passStrength = 'Strong';
        _passColor = Colors.green;
        _passValue = 1.00;
      }
      _passError = (pass.isNotEmpty && pass.length < 8)
          ? 'Must be at least 8 characters'
          : null;
      if (_confirmCtrl.text.isNotEmpty) {
        _confirmError =
            _confirmCtrl.text != pass ? 'Passwords do not match' : null;
      }
    });
  }

  void _checkConfirm(String value) {
    setState(() {
      _confirmError =
          value != _passCtrl.text ? 'Passwords do not match' : null;
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
      'first_name':       _firstCtrl.text.trim(),
      'last_name':        _lastCtrl.text.trim(),
      'email':            _emailCtrl.text.trim(),
      'password':         _passCtrl.text,
      'confirm_password': _confirmCtrl.text,
      'phone':            _phoneCtrl.text.trim(),
      'department':       _selectedDept ?? '',
      'position':         _selectedPos  ?? '',
    });
    if (mounted && ok) context.go('/dashboard');
  }

  // ── Dropdown builder (used for dept, pos) ──────────────────────────────────
  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2F5),
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint,
              style: TextStyle(color: Colors.grey[400], fontSize: 15)),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[500]),
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          items: items
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: items.isEmpty ? null : onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return buildAuthLayout(
      context: context,
      headline: 'HI, WELCOME!',
      subheadline: 'Intern Data & Profile Overview',
      rightPanel: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Title ──────────────────────────────────────────────────
            const Text(
              'CREATE ACCOUNT',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: kCrimson,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 20),

            // ── Error banner ───────────────────────────────────────────
            if (auth.error != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kCrimson.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: kCrimson.withValues(alpha: 0.4)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline,
                      color: kCrimson, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(auth.error!,
                          style: const TextStyle(
                              color: kCrimson, fontSize: 13))),
                  GestureDetector(
                    onTap: () =>
                        context.read<AuthProvider>().clearError(),
                    child: const Icon(Icons.close,
                        size: 15, color: kCrimson),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
            ],

            // ── First Name & Last Name ─────────────────────────────────
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    fieldLabel('First Name'),
                    const SizedBox(height: 6),
                    plainTextField(
                      controller: _firstCtrl,
                      hint: 'First Name',
                      validator: (v) =>
                          v!.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    fieldLabel('Last Name'),
                    const SizedBox(height: 6),
                    plainTextField(
                      controller: _lastCtrl,
                      hint: 'Last Name',
                      validator: (v) =>
                          v!.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 14),

            // ── Email ──────────────────────────────────────────────────
            fieldLabel('Email'),
            const SizedBox(height: 6),
            plainTextField(
              controller: _emailCtrl,
              hint: 'Enter Email Address',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v!.isEmpty) { return 'Email is required'; }
                if (!v.contains('@')) { return 'Enter a valid email'; }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // ── Phone ──────────────────────────────────────────────────
            fieldLabel('Phone (optional)'),
            const SizedBox(height: 6),
            plainTextField(
              controller: _phoneCtrl,
              hint: 'Enter Phone Number',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),

            // ── Department & Position dropdowns ────────────────────────
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    fieldLabel('Department'),
                    const SizedBox(height: 6),
                    _buildDropdown(
                      value: _selectedDept,
                      hint: _departments.isEmpty ? 'N/A' : 'Select',
                      items: _departments,
                      onChanged: (v) =>
                          setState(() => _selectedDept = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    fieldLabel('Position'),
                    const SizedBox(height: 6),
                    _buildDropdown(
                      value: _selectedPos,
                      hint: _positions.isEmpty ? 'N/A' : 'Select',
                      items: _positions,
                      onChanged: (v) =>
                          setState(() => _selectedPos = v),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 14),

            // ── Password + strength meter ──────────────────────────────
            fieldLabel('Password'),
            const SizedBox(height: 6),
            passwordTextField(
              controller: _passCtrl,
              hint: 'Enter Password',
              obscure: _obscurePass,
              onToggle: () =>
                  setState(() => _obscurePass = !_obscurePass),
              onChanged: _checkStrength,
              hasError: _passError != null,
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
                  return 'Need one special character (!@#...)';
                }
                return null;
              },
            ),
            const SizedBox(height: 5),
            if (_passCtrl.text.isNotEmpty) ...[
              Row(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _passValue,
                      color: _passColor,
                      backgroundColor: Colors.grey.shade200,
                      minHeight: 5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _passStrength,
                  style: TextStyle(
                    color: _passColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ]),
              const SizedBox(height: 3),
            ],
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                _passError ?? 'Must be at least 8 characters',
                style: TextStyle(
                  fontSize: 11,
                  color: _passError != null
                      ? kCrimson
                      : Colors.grey[500],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Confirm password ───────────────────────────────────────
            fieldLabel('Confirm Password'),
            const SizedBox(height: 6),
            passwordTextField(
              controller: _confirmCtrl,
              hint: 'Confirm Password',
              obscure: _obscureConfirm,
              onToggle: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              onChanged: _checkConfirm,
              hasError: _confirmError != null,
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Please confirm your password';
                }
                if (v != _passCtrl.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            if (_confirmError != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  _confirmError!,
                  style:
                      const TextStyle(fontSize: 11, color: kCrimson),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // ── Sign up button ─────────────────────────────────────────
            crimsonButton(
              label: 'SIGN UP',
              onPressed: auth.isLoading ? null : _register,
              loading: auth.isLoading,
            ),
            const SizedBox(height: 16),

            // ── Login link ─────────────────────────────────────────────
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                const Text(
                  'Already have an account? ',
                  style: TextStyle(
                      fontSize: 13, color: Color(0xFF777777)),
                ),
                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: const Text(
                    'Login Now',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF2979FF),
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFF2979FF),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}