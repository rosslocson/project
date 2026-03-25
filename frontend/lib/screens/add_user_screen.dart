import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});
  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _posCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _role = 'user';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_firstCtrl, _lastCtrl, _emailCtrl, _phoneCtrl, _deptCtrl, _posCtrl, _passCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final res = await ApiService.createUser({
      'first_name': _firstCtrl.text.trim(),
      'last_name': _lastCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'password': _passCtrl.text,
      'phone': _phoneCtrl.text.trim(),
      'department': _deptCtrl.text.trim(),
      'position': _posCtrl.text.trim(),
      'role': _role,
    });

    if (res['ok'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User created successfully!'), backgroundColor: Colors.green),
      );
      context.pop();
    } else {
      setState(() { _error = res['error'] ?? 'Failed to create user'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New User'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      backgroundColor: const Color(0xFFF5F5FF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Create User Account',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Fill in the details for the new user.',
                          style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 24),

                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                        ),
                        const SizedBox(height: 12),
                      ],

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
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                        validator: (v) {
                          if (v!.isEmpty) return 'Required';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                        validator: (v) {
                          if (v == null || v.length < 8) return 'Min 8 characters';
                          if (!v.contains(RegExp(r'[A-Z]'))) return 'Need uppercase';
                          if (!v.contains(RegExp(r'[0-9]'))) return 'Need number';
                          if (!v.contains(RegExp(r'[!@#$%^&*()]'))) return 'Need special char';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Phone (optional)', prefixIcon: Icon(Icons.phone_outlined)),
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: TextFormField(
                          controller: _deptCtrl,
                          decoration: const InputDecoration(labelText: 'Department'),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(
                          controller: _posCtrl,
                          decoration: const InputDecoration(labelText: 'Position'),
                        )),
                      ]),
                      const SizedBox(height: 12),

                      // Role selector
                      DropdownButtonFormField<String>(
                        value: _role,
                        decoration: const InputDecoration(
                            labelText: 'Role', prefixIcon: Icon(Icons.shield_outlined)),
                        items: const [
                          DropdownMenuItem(value: 'user', child: Text('User')),
                          DropdownMenuItem(value: 'admin', child: Text('Administrator')),
                        ],
                        onChanged: (v) => setState(() => _role = v!),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _submit,
                          icon: _loading
                              ? const SizedBox(height: 18, width: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.person_add),
                          label: Text(_loading ? 'Creating...' : 'Create User'),
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
    );
  }
}