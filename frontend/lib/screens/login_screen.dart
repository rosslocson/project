import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/auth_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool  _obscure    = true;
  bool  _rememberMe = false;

  // Lockout state
  bool   _isLocked     = false;
  int    _lockSecsLeft = 0;
  int    _attemptsLeft = 3;
  Timer? _lockTimer;

  // Reset password controllers
  final _resetEmailCtrl = TextEditingController();
  final resetTokenCtrl = TextEditingController();
  final _newPassCtrl    = TextEditingController();
  final _confPassCtrl   = TextEditingController();

  @override
  void dispose() {
    _lockTimer?.cancel();
    for (final c in [
      _emailCtrl, _passCtrl, _resetEmailCtrl,
      resetTokenCtrl, _newPassCtrl, _confPassCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Countdown ──────────────────────────────────────────────────────────────
  void _startLockCountdown(int seconds) {
    setState(() { _isLocked = true; _lockSecsLeft = seconds; });
    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _lockSecsLeft--);
      if (_lockSecsLeft <= 0) {
        t.cancel();
        setState(() { _isLocked = false; _attemptsLeft = 3; });
        context.read<AuthProvider>().clearError();
      }
    });
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth   = context.read<AuthProvider>();
    final result = await auth.loginWithDetails(
        _emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (result['ok'] == true) {
      context.go('/dashboard');
    } else if (result['locked'] == true) {
      _startLockCountdown(result['retry_after_secs'] as int? ?? 60);
    } else {
      setState(() =>
          _attemptsLeft = result['attempts_left'] as int? ?? _attemptsLeft - 1);
    }
  }

  // ── Forgot password sheet ──────────────────────────────────────────────────
  void _showForgotPassword() {
    String? resetToken;
    String? stepMsg;
    bool    stepLoading = false;
    int     step        = 1;
    _resetEmailCtrl.text = _emailCtrl.text.trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Future<void> requestReset() async {
            if (_resetEmailCtrl.text.isEmpty) return;
            setSheet(() { stepLoading = true; stepMsg = null; });
            final res =
                await ApiService.forgotPassword(_resetEmailCtrl.text.trim());
            setSheet(() => stepLoading = false);
            if (res['ok'] == true) {
              resetToken = res['reset_token'];
              setSheet(() {
                step    = 2;
                stepMsg = res['message'];
                if (resetToken != null) resetTokenCtrl.text = resetToken!;
              });
            } else {
              setSheet(() => stepMsg = res['error'] ?? 'Request failed');
            }
          }

          Future<void> doReset() async {
            if (resetTokenCtrl.text.isEmpty || _newPassCtrl.text.isEmpty) return;
            if (_newPassCtrl.text != _confPassCtrl.text) {
              setSheet(() => stepMsg = 'Passwords do not match');
              return;
            }
            setSheet(() { stepLoading = true; stepMsg = null; });
            final res = await ApiService.resetPassword(
                resetTokenCtrl.text.trim(),
                _newPassCtrl.text,
                _confPassCtrl.text);
            setSheet(() => stepLoading = false);
            if (res['ok'] == true) {
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Password reset! You can now log in.'),
                  backgroundColor: Colors.green.shade700,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ));
                setState(() { _isLocked = false; _attemptsLeft = 3; });
                _lockTimer?.cancel();
                context.read<AuthProvider>().clearError();
              }
            } else {
              setSheet(() => stepMsg = res['error'] ?? 'Reset failed');
            }
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 28, right: 28, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kCrimson.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lock_reset, color: kCrimson),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Reset Password',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                      Text(
                        step == 1
                            ? 'Step 1 of 2 — Enter your email'
                            : 'Step 2 of 2 — Set new password',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ]),
                const SizedBox(height: 16),
                if (stepMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(stepMsg!,
                        style: TextStyle(
                            color: Colors.blue.shade800, fontSize: 13)),
                  ),
                  const SizedBox(height: 12),
                ],
                if (step == 1) ...[
                  fieldLabel('Email address'),
                  const SizedBox(height: 8),
                  plainTextField(
                    controller: _resetEmailCtrl,
                    hint: 'Enter your registered email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  crimsonButton(
                    label: 'SEND RESET TOKEN',
                    onPressed: stepLoading ? null : requestReset,
                    loading: stepLoading,
                  ),
                ] else ...[
                  fieldLabel('Reset Token'),
                  const SizedBox(height: 8),
                  plainTextField(
                      controller: resetTokenCtrl,
                      hint: 'Paste token from email'),
                  const SizedBox(height: 12),
                  fieldLabel('New Password'),
                  const SizedBox(height: 8),
                  passwordTextField(
                    controller: _newPassCtrl,
                    hint: 'Enter new password',
                    obscure: true,
                    onToggle: () {},
                  ),
                  const SizedBox(height: 12),
                  fieldLabel('Confirm New Password'),
                  const SizedBox(height: 8),
                  passwordTextField(
                    controller: _confPassCtrl,
                    hint: 'Confirm new password',
                    obscure: true,
                    onToggle: () {},
                  ),
                  const SizedBox(height: 16),
                  crimsonButton(
                    label: 'RESET PASSWORD',
                    onPressed: stepLoading ? null : doReset,
                    loading: stepLoading,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        setSheet(() { step = 1; stepMsg = null; }),
                    child: const Text('← Back'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
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
            // Title
            const Text(
              'LOGIN TO YOUR ACCOUNT',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: kCrimson,
                letterSpacing: 1.5,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 28),

            // ── Lock / error banners ───────────────────────────────────
            if (_isLocked) ...[
              _lockedBanner(),
              const SizedBox(height: 16),
            ] else if (auth.error != null) ...[
              _errorBanner(auth),
              const SizedBox(height: 16),
            ],

            // Email
            fieldLabel('Email'),
            const SizedBox(height: 10),
            plainTextField(
              controller: _emailCtrl,
              hint: 'Enter Email',
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLocked,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password
            fieldLabel('Password'),
            const SizedBox(height: 10),
            passwordTextField(
              controller: _passCtrl,
              hint: 'Enter Password',
              obscure: _obscure,
              enabled: !_isLocked,
              onToggle: () => setState(() => _obscure = !_obscure),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Password is required' : null,
            ),
            const SizedBox(height: 16),

            // Remember me + forgot password row
            Row(children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (v) =>
                      setState(() => _rememberMe = v ?? false),
                  activeColor: kCrimson,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3)),
                  side: BorderSide(color: Colors.grey[400]!),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Remember Me',
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFF555555))),
              const Spacer(),
              GestureDetector(
                onTap: _showForgotPassword,
                child: const Text(
                  'Forgot Password',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2979FF),
                    decorationColor: Color(0xFF2979FF),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 40),

            // Login button
            crimsonButton(
              label: _isLocked
                  ? 'LOCKED — WAIT ${_lockSecsLeft}s'
                  : 'LOGIN',
              onPressed: (auth.isLoading || _isLocked) ? null : _login,
              loading: auth.isLoading,
            ),
            const SizedBox(height: 20),

            // FIX: added const to Wrap and its children list
            const Wrap(
              alignment: WrapAlignment.center,
              children: [
                Text("Don't have an account? ",
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF777777))),
                // GestureDetector cannot be const (has a callback),
                // so we keep just the static text widgets as const
                // and leave GestureDetector outside the const list.
              ],
            ),
            // Separate the interactive part that can't be const
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? ",
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF777777))),
                GestureDetector(
                  onTap: () => context.go('/register'),
                  child: const Text('Sign Up Now',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2979FF),
                        fontWeight: FontWeight.w600,
                        decorationColor: Color(0xFF2979FF),
                      )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Banners ────────────────────────────────────────────────────────────────
  Widget _lockedBanner() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kCrimson.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kCrimson.withValues(alpha: 0.4)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.lock, color: kCrimson, size: 16),
            SizedBox(width: 6),
            Text('Account temporarily locked',
                style: TextStyle(
                    color: kCrimson,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.timer_outlined, color: kCrimson, size: 14),
            const SizedBox(width: 6),
            Text(
                'Try again in $_lockSecsLeft second${_lockSecsLeft != 1 ? 's' : ''}',
                style: const TextStyle(color: kCrimson, fontSize: 12)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _lockSecsLeft / 60,
              backgroundColor: kCrimson.withValues(alpha: 0.15),
              color: kCrimson,
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showForgotPassword,
            child: const Text('Forgot your password? Reset it now →',
                style: TextStyle(
                  color: Color(0xFF2979FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  decorationColor: Color(0xFF2979FF),
                )),
          ),
        ]),
      );

  Widget _errorBanner(AuthProvider auth) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.orange.shade700, size: 16),
            const SizedBox(width: 6),
            Expanded(
                child: Text(auth.error!,
                    style: TextStyle(
                        color: Colors.orange.shade900, fontSize: 13))),
            GestureDetector(
              onTap: () => context.read<AuthProvider>().clearError(),
              child: Icon(Icons.close,
                  size: 16, color: Colors.orange.shade400),
            ),
          ]),
          if (_attemptsLeft > 0) ...[
            const SizedBox(height: 8),
            Row(children: [
              Text('Attempts left: ',
                  style: TextStyle(
                      color: Colors.orange.shade800, fontSize: 12)),
              ...List.generate(
                  3,
                  (i) => Container(
                        width: 10,
                        height: 10,
                        margin:
                            const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < _attemptsLeft
                              ? Colors.orange.shade500
                              : Colors.grey.shade300,
                        ),
                      )),
            ]),
          ],
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _showForgotPassword,
            child: const Text('Forgot password? Reset it →',
                style: TextStyle(
                  color: Color(0xFF2979FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  decorationColor: Color(0xFF2979FF),
                )),
          ),
        ]),
      );
}