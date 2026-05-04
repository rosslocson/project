import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_background.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  String? _selectedDept;
  String? _selectedPos;
  String _role = 'user';
  bool _loading = false;
  bool _configLoading = true;
  bool _obscurePass = true;
  String? _error;

  List<String> _departments = [];
  List<String> _positions = [];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    for (final c in [
      _firstCtrl,
      _lastCtrl,
      _emailCtrl,
      _phoneCtrl,
      _passCtrl
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
        _configLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await ApiService.createUser({
      'first_name': _firstCtrl.text.trim(),
      'last_name': _lastCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'password': _passCtrl.text,
      'phone': _phoneCtrl.text.trim(),
      'department': _selectedDept ?? '',
      'position': _selectedPos ?? '',
      'role': _role,
    });

    if (res['ok'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Account created successfully!'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      context.pop();
    } else {
      setState(() {
        _error = res['error'] ?? 'Failed to create account';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // WRAP IN CONTAINER: This correctly pushes the background image behind
    // the entire Scaffold, including the transparent AppBar.
    return AppBackground(
      child: Scaffold(
        backgroundColor:
            Colors.transparent, // Lets the container image show through
        appBar: AppBar(
          title: const Text('Create Account'),
          backgroundColor: Colors.transparent,
          foregroundColor: kCosmicBlue,
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
                  borderRadius: BorderRadius.circular(20),
                ),
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
                                    color: kCosmicBlue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.person_add,
                                      color: kCosmicBlue),
                                ),
                                const SizedBox(width: 12),
                                const Text('Create Account',
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
                                    border:
                                        Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Text(_error!,
                                      style: TextStyle(
                                          color: Colors.red.shade700)),
                                ),
                                const SizedBox(height: 14),
                              ],

                              // First & Last Name
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'First Name',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _firstCtrl,
                                          decoration: InputDecoration(
                                            labelText: 'First Name',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey.shade100,
                                          ),
                                          validator: (v) => v?.isEmpty ?? true
                                              ? 'Required'
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Last Name',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _lastCtrl,
                                          decoration: InputDecoration(
                                            labelText: 'Last Name',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey.shade100,
                                          ),
                                          validator: (v) => v?.isEmpty ?? true
                                              ? 'Required'
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Email
                              const Text('Email',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.black87)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: 'Email address',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                ),
                                validator: (v) {
                                  if (v!.isEmpty) return 'Required';
                                  if (!v.contains('@')) return 'Invalid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Password
                              const Text('Password',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.black87)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passCtrl,
                                obscureText: _obscurePass,
                                decoration: InputDecoration(
                                  hintText:
                                      'Min 8 chars, uppercase, number, symbol',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePass
                                        ? Icons.visibility_off
                                        : Icons.visibility),
                                    onPressed: () => setState(
                                        () => _obscurePass = !_obscurePass),
                                  ),
                                ),
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
                                  if (!v.contains(RegExp(r'[!@#$%^&*()]'))) {
                                    return 'Need one special character';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Phone
                              const Text('Phone (optional)',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.black87)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: 'Phone number',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Department
                              const Text('Department',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.black87)),
                              const SizedBox(height: 8),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedDept,
                                    decoration: InputDecoration.collapsed(
                                      hintText: _departments.isEmpty
                                          ? 'No departments yet — add via Settings'
                                          : 'Select Department',
                                      hintStyle: TextStyle(
                                          color: Colors
                                              .grey[400]), // Removed const here
                                    ),
                                    items: _departments
                                        .map((s) => DropdownMenuItem(
                                            value: s, child: Text(s)))
                                        .toList(),
                                    onChanged: _departments.isEmpty
                                        ? null
                                        : (v) =>
                                            setState(() => _selectedDept = v),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Position
                              const Text('Position',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.black87)),
                              const SizedBox(height: 8),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedPos,
                                    decoration: InputDecoration.collapsed(
                                      hintText: _positions.isEmpty
                                          ? 'No positions yet — add via Settings'
                                          : 'Select Position',
                                      hintStyle: TextStyle(
                                          color: Colors
                                              .grey[400]), // Removed const here
                                    ),
                                    items: _positions
                                        .map((s) => DropdownMenuItem(
                                            value: s, child: Text(s)))
                                        .toList(),
                                    onChanged: _positions.isEmpty
                                        ? null
                                        : (v) =>
                                            setState(() => _selectedPos = v),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Role
                              const Text('Role',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.black87)),
                              const SizedBox(height: 8),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _role,
                                    decoration: InputDecoration.collapsed(
                                      // Removed const here
                                      hintText: 'Select Role',
                                      hintStyle: TextStyle(
                                          color: Colors
                                              .grey[400]), // Removed const here
                                    ),
                                    items: const ['user', 'admin']
                                        .map((s) => DropdownMenuItem(
                                            value: s, child: Text(s)))
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _role = v ?? 'user'),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),

                              SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kCosmicBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'CREATE ACCOUNT',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
