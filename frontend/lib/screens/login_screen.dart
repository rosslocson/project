import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey        = GlobalKey<FormState>();
  final _emailCtrl      = TextEditingController();
  final _passCtrl       = TextEditingController();
  bool  _obscure        = true;

  // Lockout state
  bool  _isLocked       = false;
  int   _lockSecsLeft   = 0;
  int   _attemptsLeft   = 3;
  Timer? _lockTimer;

  // Reset password dialog state
  final _resetEmailCtrl = TextEditingController();
  final _resetTokenCtrl = TextEditingController();
  final _newPassCtrl    = TextEditingController();
  final _confPassCtrl   = TextEditingController();

  @override
  void dispose() {
    _lockTimer?.cancel();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _resetEmailCtrl.dispose();
    _resetTokenCtrl.dispose();
    _newPassCtrl.dispose();
    _confPassCtrl.dispose();
    super.dispose();
  }

  // ── Countdown timer ──────────────────────────────────────────────────────

  void _startLockCountdown(int seconds) {
    setState(() {
      _isLocked     = true;
      _lockSecsLeft = seconds;
    });
    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _lockSecsLeft--);
      if (_lockSecsLeft <= 0) {
        t.cancel();
        setState(() {
          _isLocked     = false;
          _attemptsLeft = 3;
        });
        context.read<AuthProvider>().clearError();
      }
    });
  }

  // ── Login ────────────────────────────────────────────────────────────────

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();

    final result = await auth.loginWithDetails(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );

    if (!mounted) return;

    if (result['ok'] == true) {
      context.go('/dashboard');
    } else if (result['locked'] == true) {
      final secs = result['retry_after_secs'] as int? ?? 60;
      _startLockCountdown(secs);
    } else {
      setState(() => _attemptsLeft = result['attempts_left'] as int? ?? _attemptsLeft - 1);
    }
  }

  // ── Forgot Password Sheet ────────────────────────────────────────────────

  void _showForgotPassword() {
    String? _resetToken;
    String? _stepMsg;
    bool    _stepLoading = false;
    int     _step        = 1; // 1=enter email, 2=enter token+new pass

    _resetEmailCtrl.text = _emailCtrl.text.trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          Future<void> requestReset() async {
            if (_resetEmailCtrl.text.isEmpty) return;
            setSheetState(() { _stepLoading = true; _stepMsg = null; });
            final res = await ApiService.forgotPassword(_resetEmailCtrl.text.trim());
            setSheetState(() => _stepLoading = false);
            if (res['ok'] == true) {
              // In dev mode the token is returned directly
              _resetToken = res['reset_token'];
              setSheetState(() {
                _step    = 2;
                _stepMsg = res['message'];
                if (_resetToken != null) {
                  _resetTokenCtrl.text = _resetToken!;
                }
              });
            } else {
              setSheetState(() => _stepMsg = res['error'] ?? 'Request failed');
            }
          }

          Future<void> doReset() async {
            if (_resetTokenCtrl.text.isEmpty || _newPassCtrl.text.isEmpty) return;
            if (_newPassCtrl.text != _confPassCtrl.text) {
              setSheetState(() => _stepMsg = 'Passwords do not match');
              return;
            }
            setSheetState(() { _stepLoading = true; _stepMsg = null; });
            final res = await ApiService.resetPassword(
              _resetTokenCtrl.text.trim(),
              _newPassCtrl.text,
              _confPassCtrl.text,
            );
            setSheetState(() => _stepLoading = false);
            if (res['ok'] == true) {
              Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password reset! You can now log in.'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Also unlock if they were locked
                setState(() { _isLocked = false; _attemptsLeft = 3; });
                _lockTimer?.cancel();
                context.read<AuthProvider>().clearError();
              }
            } else {
              setSheetState(() => _stepMsg = res['error'] ?? 'Reset failed');
            }
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.lock_reset, color: Colors.orange.shade700),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reset Password',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(_step == 1 ? 'Step 1 of 2 — Enter your email' : 'Step 2 of 2 — Set new password',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Status message
                if (_stepMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(_stepMsg!, style: TextStyle(color: Colors.blue.shade800, fontSize: 13)),
                  ),
                  const SizedBox(height: 12),
                ],

                if (_step == 1) ...[
                  TextField(
                    controller: _resetEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _stepLoading ? null : requestReset,
                    icon: _stepLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send),
                    label: Text(_stepLoading ? 'Sending...' : 'Send Reset Token'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ] else ...[
                  // Step 2 — token + new password
                  TextField(
                    controller: _resetTokenCtrl,
                    decoration: InputDecoration(
                      labelText: 'Reset Token',
                      prefixIcon: const Icon(Icons.vpn_key_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      helperText: 'Paste the token from your email (or the one shown above in dev)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPassCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      helperText: 'Min 8 chars, uppercase, number, special char',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confPassCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _stepLoading ? null : doReset,
                    icon: _stepLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline),
                    label: Text(_stepLoading ? 'Resetting...' : 'Reset Password'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setSheetState(() { _step = 1; _stepMsg = null; }),
                    child: const Text('← Back to email step'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthProvider>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.people_alt, color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 24),
                      Text('Welcome back',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Sign in to your account',
                          style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 28),

                      // ── Locked banner ──────────────────────────────────
                      if (_isLocked) ...[
                        _LockedBanner(
                          secsLeft: _lockSecsLeft,
                          onForgotPassword: _showForgotPassword,
                        ),
                        const SizedBox(height: 16),
                      ]

                      // ── Error / attempts banner ────────────────────────
                      else if (auth.error != null) ...[
                        _ErrorBanner(
                          message: auth.error!,
                          attemptsLeft: _attemptsLeft,
                          onDismiss: () => context.read<AuthProvider>().clearError(),
                          onForgotPassword: _showForgotPassword,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── Fields ─────────────────────────────────────────
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isLocked,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email is required';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        enabled: !_isLocked,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Forgot password link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPassword,
                          style: TextButton.styleFrom(
                            foregroundColor: colors.primary,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                          ),
                          child: const Text('Forgot password?', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Sign In button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (auth.isLoading || _isLocked) ? null : _login,
                          child: auth.isLoading
                              ? const SizedBox(
                                  height: 20, width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : _isLocked
                                  ? Text('Locked — wait ${_lockSecsLeft}s')
                                  : const Text('Sign In'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account? ",
                              style: TextStyle(color: Colors.grey.shade600)),
                          GestureDetector(
                            onTap: () => context.go('/register'),
                            child: Text('Sign up',
                                style: TextStyle(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
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

// ── Locked Banner Widget ──────────────────────────────────────────────────────

class _LockedBanner extends StatelessWidget {
  final int secsLeft;
  final VoidCallback onForgotPassword;
  const _LockedBanner({required this.secsLeft, required this.onForgotPassword});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock, color: Colors.red.shade600, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Account temporarily locked',
                  style: TextStyle(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Countdown
          Row(
            children: [
              Icon(Icons.timer_outlined, color: Colors.red.shade400, size: 15),
              const SizedBox(width: 6),
              Text(
                'Try again in $secsLeft second${secsLeft != 1 ? 's' : ''}',
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar for countdown
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: secsLeft / 60,
              backgroundColor: Colors.red.shade100,
              color: Colors.red.shade400,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onForgotPassword,
            child: Text(
              'Forgot your password? Reset it now →',
              style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error Banner Widget ───────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final int attemptsLeft;
  final VoidCallback onDismiss;
  final VoidCallback onForgotPassword;

  const _ErrorBanner({
    required this.message,
    required this.attemptsLeft,
    required this.onDismiss,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(message,
                    style: TextStyle(color: Colors.orange.shade900, fontSize: 13)),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: onDismiss,
                color: Colors.orange.shade400,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          if (attemptsLeft > 0) ...[
            const SizedBox(height: 6),
            // Attempts indicator dots
            Row(
              children: [
                Text('Attempts left: ',
                    style: TextStyle(color: Colors.orange.shade800, fontSize: 12)),
                ...List.generate(3, (i) => Container(
                  width: 10, height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < attemptsLeft
                        ? Colors.orange.shade500
                        : Colors.grey.shade300,
                  ),
                )),
              ],
            ),
          ],
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onForgotPassword,
            child: Text(
              'Forgot password? Reset it →',
              style: TextStyle(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }
} 