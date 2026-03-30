import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../widgets/auth_layout.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});
  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  String? _selectedDept;
  String? _selectedPos;
  String  _role    = 'user';
  bool    _loading = false;
  bool    _configLoading = true;
  String? _error;

  List<String> _departments = [];
  List<String> _positions   = [];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    for (final c in [_firstCtrl, _lastCtrl, _emailCtrl, _phoneCtrl, _passCtrl]) {
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
        _configLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final res = await ApiService.createUser({
      'first_name': _firstCtrl.text.trim(),
      'last_name':  _lastCtrl.text.trim(),
      'email':      _emailCtrl.text.trim(),
      'password':   _passCtrl.text,
      'phone':      _phoneCtrl.text.trim(),
      'department': _selectedDept ?? '',
      'position':   _selectedPos ?? '',
      'role':       _role,
    });

    if (res['ok'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('User created successfully!'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      context.pop();
    } else {
      setState(() {
        _error = res['error'] ?? 'Failed to create user';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FF),
      appBar: AppBar(
        title: const Text('Add New User'),
        backgroundColor: Colors.white,
        foregroundColor: kCrimson,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: _configLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: kCrimson.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.person_add,
                                    color: kCrimson),
                              ),
                              const SizedBox(width: 12),
                              const Text('Create User Account',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                            ]),
                            const SizedBox(height: 24),

                            if (_error != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.red.shade200),
                                ),
                                child: Text(_error!,
                                    style: TextStyle(
                                        color: Colors.red.shade700)),
                              ),
                              const SizedBox(height: 14),
                            ],

                            Row(children: [
                              Expanded(child: Column(
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
                              )),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
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
                              )),
                            ]),
                            const SizedBox(height: 12),

                            fieldLabel('Email'),
                            const SizedBox(height: 6),
                            plainTextField(
                              controller: _emailCtrl,
                              hint: 'Email address',
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v!.isEmpty) return 'Required';
                                if (!v.contains('@')) return 'Invalid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            fieldLabel('Password'),
                            const SizedBox(height: 6),
                            passwordTextField(
                              controller: _passCtrl,
                              hint: 'Min 8 chars, uppercase, number, symbol',
                              obscure: true,
                              onToggle: () {},
                              validator: (v) {
                                if (v == null || v.length < 8)
                                  return 'Min 8 characters';
                                if (!v.contains(RegExp(r'[A-Z]')))
                                  return 'Need one uppercase letter';
                                if (!v.contains(RegExp(r'[0-9]')))
                                  return 'Need one number';
                                if (!v.contains(RegExp(r'[!@#$%^&*()]')))
                                  return 'Need one special character';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            fieldLabel('Phone (optional)'),
                            const SizedBox(height: 6),
                            plainTextField(
                              controller: _phoneCtrl,
                              hint: 'Phone number',
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 12),

                            // Department dropdown
                            fieldLabel('Department'),
                            const SizedBox(height: 6),
                            _buildDropdown(
                              value: _selectedDept,
                              hint: _departments.isEmpty
                                  ? 'No departments yet — add via Settings'
                                  : 'Select Department',
                              items: _departments,
                              onChanged: (v) =>
                                  setState(() => _selectedDept = v),
                            ),
                            const SizedBox(height: 12),

                            // Position dropdown
                            fieldLabel('Position'),
                            const SizedBox(height: 6),
                            _buildDropdown(
                              value: _selectedPos,
                              hint: _positions.isEmpty
                                  ? 'No positions yet — add via Settings'
                                  : 'Select Position',
                              items: _positions,
                              onChanged: (v) =>
                                  setState(() => _selectedPos = v),
                            ),
                            const SizedBox(height: 12),

                            // Role dropdown
                            fieldLabel('Role'),
                            const SizedBox(height: 6),
                            _buildDropdown(
                              value: _role,
                              hint: 'Select Role',
                              items: const ['user', 'admin'],
                              onChanged: (v) =>
                                  setState(() => _role = v ?? 'user'),
                            ),
                            const SizedBox(height: 28),

                            crimsonButton(
                              label: 'CREATE USER',
                              onPressed: _loading ? null : _submit,
                              loading: _loading,
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required void Function(String?) onChanged,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2F5),
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            hint: Text(hint,
                style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[500]),
            style: const TextStyle(color: Colors.black87, fontSize: 14),
            items: items
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: items.isEmpty ? null : onChanged,
          ),
        ),
      );
}