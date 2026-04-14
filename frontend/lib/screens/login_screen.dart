import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for input formatters
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/star_background.dart';
import '../widgets/app_theme.dart';
import 'dart:math' as math;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;

  // Lockout
  bool   _isLocked     = false;
  int    _lockSecsLeft = 0;
  int    _attemptsLeft = 3;
  Timer? _lockTimer;

  // Reset password
  final _resetEmailCtrl = TextEditingController();
  final _otpCtrl        = TextEditingController(); // Renamed from _resetTokenCtrl
  final _newPassCtrl    = TextEditingController();
  final _confPassCtrl   = TextEditingController();

  // Galaxy
  late AnimationController _bgCtrl;
  late List<Star> _stars;

  @override
  void initState() {
    super.initState();
    _stars = _generateFastStars();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _lockTimer?.cancel();
    for (final c in [
      _emailCtrl, _passCtrl, _resetEmailCtrl,
      _otpCtrl, _newPassCtrl, _confPassCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Lock countdown ─────────────────────────────────────────────────────────
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
        _emailCtrl.text.trim(), _passCtrl.text.trim());
    if (!mounted) return;
    if (result['ok'] == true) {
      if (auth.isAdmin) {
        context.go('/dashboard');
      } else {
        context.go('/home');
      }
    } else if (result['locked'] == true) {
      _startLockCountdown(result['retry_after_secs'] as int? ?? 60);
    } else {
      setState(() => _attemptsLeft =
          result['attempts_left'] as int? ?? _attemptsLeft - 1);
    }
  }

  // ── Forgot password sheet ──────────────────────────────────────────────────
  void _showForgotPassword() {
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
            final res = await ApiService.forgotPassword(
                _resetEmailCtrl.text.trim());
            setSheet(() => stepLoading = false);
            if (res['ok'] == true) {
              setSheet(() {
                step    = 2;
                stepMsg = res['message'];
                _otpCtrl.clear();
              });
            } else {
              setSheet(() => stepMsg = res['error'] ?? 'Request failed');
            }
          }

          Future<void> doReset() async {
            if (_otpCtrl.text.isEmpty || _newPassCtrl.text.isEmpty) {
              return;
            }
            if (_newPassCtrl.text != _confPassCtrl.text) {
              setSheet(() => stepMsg = 'Passwords do not match');
              return;
            }
            setSheet(() { stepLoading = true; stepMsg = null; });
            final res = await ApiService.resetPassword(
                _otpCtrl.text.trim(),
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

          final dec = pillInputDecoration();

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: EdgeInsets.only(
              left: 32, right: 32, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 40,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48, height: 5,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2.5)),
                  ),
                ),
                const SizedBox(height: 28),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kCrimsonDeep.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lock_reset,
                        color: kCrimsonDeep, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Reset Password',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      Text(
                        step == 1
                            ? 'Step 1 of 2 — Enter your email'
                            : 'Step 2 of 2 — Verify OTP & set password',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ]),
                const SizedBox(height: 20),
                if (stepMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Text(stepMsg!,
                        style: TextStyle(
                            color: Colors.blue.shade800,
                            fontSize: 13,
                            height: 1.4)),
                  ),
                  const SizedBox(height: 14),
                ],
                if (step == 1) ...[
                  fieldLabel('Email Address'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _resetEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: dec.copyWith(
                        hintText: 'Enter your registered email'),
                  ),
                  const SizedBox(height: 20),
                  CrimsonButton(
                    label: 'SEND OTP',
                    onPressed: stepLoading ? null : requestReset,
                    loading: stepLoading,
                  ),
                ] else ...[
                  fieldLabel('6-Digit OTP'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _otpCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6, // Restricts input to 6 characters visually
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Only allows numbers
                    decoration: dec.copyWith(
                      hintText: 'Enter 6-digit OTP from email',
                      counterText: '', // Hides the "0/6" counter below the text field
                    ),
                  ),
                  const SizedBox(height: 14),
                  fieldLabel('New Password'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _newPassCtrl,
                    obscureText: true,
                    decoration:
                        dec.copyWith(hintText: 'Enter new password'),
                  ),
                  const SizedBox(height: 14),
                  fieldLabel('Confirm New Password'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confPassCtrl,
                    obscureText: true,
                    decoration:
                        dec.copyWith(hintText: 'Confirm new password'),
                  ),
                  const SizedBox(height: 20),
                  CrimsonButton(
                    label: 'RESET PASSWORD',
                    onPressed: stepLoading ? null : doReset,
                    loading: stepLoading,
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () =>
                        setSheet(() { step = 1; stepMsg = null; }),
                    child: Text('← Back to Email',
                        style: TextStyle(color: Colors.grey.shade600)),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Form panel ─────────────────────────────────────────────────────────────
  Widget _buildForm(AuthProvider auth) {
    final dec = pillInputDecoration();

    return Container(
      alignment: Alignment.center,
      color: Colors.transparent,
      padding:
          const EdgeInsets.symmetric(horizontal: 64, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'LOGIN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: kCrimsonDeep,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 40),

              if (_isLocked) ...[
                _lockedBanner(),
                const SizedBox(height: 20),
              ] else if (auth.error != null) ...[
                _errorBanner(auth),
                const SizedBox(height: 20),
              ],

              fieldLabel('Email Address'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLocked,
                decoration: dec.copyWith(hintText: 'Enter your email'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              fieldLabel('Password'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                enabled: !_isLocked,
                decoration: dec.copyWith(
                  hintText: 'Enter your password',
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF9CA3AF),
                        size: 22,
                      ),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Password is required' : null,
              ),
              const SizedBox(height: 12),

              Row(children: [
                const Spacer(),
                GestureDetector(
                  onTap: _showForgotPassword,
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 13,
                      color: kCrimsonDeep,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 36),

              CrimsonButton(
                label: _isLocked
                    ? 'LOCKED — WAIT ${_lockSecsLeft}s'
                    : 'LOGIN',
                onPressed: (auth.isLoading || _isLocked) ? null : _login,
                loading: auth.isLoading,
              ),
              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ",
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF6B7280))),
                  GestureDetector(
                    onTap: () => context.go('/register'),
                    child: const Text('Sign Up Now',
                        style: TextStyle(
                          fontSize: 13,
                          color: kCrimsonDeep,
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

  // ── Build ──────────────────────────────────────────────────────────────────
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
                    color: kCrimsonDeep,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: GalaxyBackground(
                            animation: _bgCtrl,
                            stars: _stars,
                          ),
                        ),
                        const Positioned.fill(
                          child: GalaxyLeftPanel(
                            headline: "BACK IN THE COSMOS.", 
                            subheadline:
                                'Securely access your dashboard and monitor your workspace within the InternSpace galaxy.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: _buildForm(auth),
                  ),
                ),
              ],
            );
          } else {
            return Stack(
              children: [
                Container(color: kCrimsonDeep),
                Positioned.fill(
                  child: GalaxyBackground(
                    animation: _bgCtrl,
                    stars: _stars,
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: _buildForm(auth),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  List<Star> _generateFastStars() {
    final rng = math.Random();
    return List.generate(
      200,
      (_) => Star(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: rng.nextDouble() * 1.5 + 0.3,
        baseOpacity: rng.nextDouble() * 0.4 + 0.1,
        speed: rng.nextDouble() * 0.04 + 0.01,
        twinklePhase: rng.nextDouble() * 2 * math.pi,
      ),
    );
  }

  Widget _lockedBanner() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCrimsonDeep.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: kCrimsonDeep.withValues(alpha: 0.2)),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.lock, color: kCrimsonDeep, size: 18),
                SizedBox(width: 8),
                Text('Account temporarily locked',
                    style: TextStyle(
                        color: kCrimsonDeep,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.timer_outlined,
                    color: kCrimsonDeep, size: 16),
                const SizedBox(width: 8),
                Text(
                    'Try again in $_lockSecsLeft second${_lockSecsLeft != 1 ? 's' : ''}',
                    style:
                        const TextStyle(color: kCrimsonDeep, fontSize: 12)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _lockSecsLeft / 60,
                  backgroundColor:
                      kCrimsonDeep.withValues(alpha: 0.15),
                  color: kCrimsonDeep,
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showForgotPassword,
                child: const Text('Forgot your password? Reset it now →',
                    style: TextStyle(
                        color: kCrimsonDeep,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
      );

  Widget _errorBanner(AuthProvider auth) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(auth.error!,
                        style: TextStyle(
                            color: Colors.orange.shade900,
                            fontSize: 12,
                            fontWeight: FontWeight.w500))),
                GestureDetector(
                  onTap: () =>
                      context.read<AuthProvider>().clearError(),
                  child: Icon(Icons.close,
                      size: 20, color: Colors.orange.shade400),
                ),
              ]),
              if (_attemptsLeft > 0) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Text('Attempts left: ',
                      style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 12)),
                  ...List.generate(
                      3,
                      (i) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < _attemptsLeft
                                  ? Colors.orange.shade500
                                  : Colors.orange.shade100,
                            ),
                          )),
                ]),
              ],
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showForgotPassword,
                child: Text('Forgot password? Reset it →',
                    style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
      );
}