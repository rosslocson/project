import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../app_theme.dart';

class ForgotPasswordSheet extends StatefulWidget {
  final String initialEmail;
  final VoidCallback onResetSuccess;

  const ForgotPasswordSheet({
    super.key,
    required this.initialEmail,
    required this.onResetSuccess,
  });

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  late final TextEditingController _resetEmailCtrl;
  final List<TextEditingController> _otpDigitCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _newPassCtrl = TextEditingController();
  final _confPassCtrl = TextEditingController();

  String? stepMsg;
  bool stepLoading = false;
  int step = 1;
  Timer? _otpTimer;
  int _otpSecondsLeft = 0;
  bool obscureNewPass = true;
  bool obscureConfPass = true;

  @override
  void initState() {
    super.initState();
    _resetEmailCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _otpTimer?.cancel();
    _resetEmailCtrl.dispose();
    for (final controller in _otpDigitCtrls) {
      controller.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.dispose();
    }
    _newPassCtrl.dispose();
    _confPassCtrl.dispose();
    super.dispose();
  }

  Future<void> requestReset() async {
    if (_resetEmailCtrl.text.isEmpty) return;

    setState(() {
      stepLoading = true;
      stepMsg = null;
    });

    final res = await ApiService.forgotPassword(_resetEmailCtrl.text.trim());
    setState(() => stepLoading = false);

    if (res['ok'] == true) {
      final expirySeconds = res['expires_in_secs'] is int
          ? res['expires_in_secs'] as int
          : int.tryParse('${res['expires_in_secs']}') ?? 120;

      setState(() {
        step = 2;
        stepMsg = null;
        _clearOtpBoxes();
        _newPassCtrl.clear();
        _confPassCtrl.clear();
      });
      _startOtpTimer(expirySeconds);
      _otpFocusNodes.first.requestFocus();
    } else {
      setState(() => stepMsg = res['error'] ?? 'Request failed');
    }
  }

  Future<void> verifyOtpStep() async {
    if (_otpSecondsLeft <= 0) {
      setState(() => stepMsg = 'OTP has expired. Please request a new code.');
      return;
    }
    if (_otpCode.length != 6) {
      setState(() => stepMsg = 'Please enter the 6-digit OTP.');
      return;
    }

    setState(() {
      stepLoading = true;
      stepMsg = null;
    });

    final res = await ApiService.verifyResetOtp(_otpCode);
    setState(() => stepLoading = false);

    if (res['ok'] != true) {
      setState(() => stepMsg = res['error'] ?? 'Invalid or expired OTP');
      return;
    }

    setState(() {
      step = 3;
      stepMsg = null;
    });
  }

  Future<void> doReset() async {
    if (_otpSecondsLeft <= 0) {
      setState(() => stepMsg = 'OTP has expired. Please request a new code.');
      return;
    }
    if (_otpCode.length != 6 || _newPassCtrl.text.isEmpty) return;
    if (_newPassCtrl.text != _confPassCtrl.text) {
      setState(() => stepMsg = 'Passwords do not match');
      return;
    }

    setState(() {
      stepLoading = true;
      stepMsg = null;
    });

    final res = await ApiService.resetPassword(
      _otpCode,
      _newPassCtrl.text,
      _confPassCtrl.text,
    );
    setState(() => stepLoading = false);

    if (res['ok'] == true) {
      _otpTimer?.cancel();
      if (mounted) Navigator.pop(context);
      widget.onResetSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password reset! You can now log in.'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      setState(() => stepMsg = res['error'] ?? 'Reset failed');
    }
  }

  void _startOtpTimer([int seconds = 120]) {
    _otpTimer?.cancel();
    setState(() => _otpSecondsLeft = seconds.clamp(0, 9999));

    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_otpSecondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _otpSecondsLeft = 0;
          stepMsg = 'OTP has expired. Please request a new code.';
        });
        return;
      }

      setState(() => _otpSecondsLeft--);
    });
  }

  String get _otpTimeText {
    final minutes = (_otpSecondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_otpSecondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _otpCode =>
      _otpDigitCtrls.map((controller) => controller.text).join();

  String get _stepSubtitle {
    if (step == 1) return 'Step 1 of 3 - Enter your email';
    if (step == 2) return 'Step 2 of 3 - Verify OTP';
    return 'Step 3 of 3 - Set new password';
  }

  void _clearOtpBoxes() {
    for (final controller in _otpDigitCtrls) {
      controller.clear();
    }
  }

  void _handleOtpChanged(String value, int index) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '').split('');
      for (var i = index; i < _otpDigitCtrls.length; i++) {
        final digitIndex = i - index;
        _otpDigitCtrls[i].text =
            digitIndex < digits.length ? digits[digitIndex] : '';
      }
      final focusIndex = (index + digits.length).clamp(0, 5);
      _otpFocusNodes[focusIndex].requestFocus();
      setState(() => stepMsg = null);
      return;
    }

    if (value.isNotEmpty && index < _otpFocusNodes.length - 1) {
      _otpFocusNodes[index + 1].requestFocus();
    }

    setState(() => stepMsg = null);
  }

  KeyEventResult _handleOtpKey(KeyEvent event, int index) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_otpDigitCtrls[index].text.isEmpty && index > 0) {
        _otpDigitCtrls[index - 1].clear();
        _otpFocusNodes[index - 1].requestFocus();
        setState(() => stepMsg = null);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.delete) {
      _otpDigitCtrls[index].clear();
      setState(() => stepMsg = null);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _backToEmail() {
    _otpTimer?.cancel();
    setState(() {
      step = 1;
      stepMsg = null;
      _otpSecondsLeft = 0;
    });
  }

  Widget _timerCard() {
    final active = _otpSecondsLeft > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: active ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? Colors.green.shade100 : Colors.red.shade100,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            size: 20,
            color: active ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 10),
          Text(
            active ? 'OTP expires in $_otpTimeText' : 'OTP expired',
            style: TextStyle(
              color: active ? Colors.green.shade800 : Colors.red.shade800,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _otpBoxes() {
    return Row(
      children: List.generate(6, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 5 ? 0 : 8),
            child: SizedBox(
              height: 58,
              child: Focus(
                onKeyEvent: (_, event) => _handleOtpKey(event, index),
                child: TextFormField(
                  controller: _otpDigitCtrls[index],
                  focusNode: _otpFocusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  textInputAction:
                      index == 5 ? TextInputAction.done : TextInputAction.next,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: kCosmicBlue,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: kCosmicBlue, width: 2),
                    ),
                  ),
                  onChanged: (value) => _handleOtpChanged(value, index),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dec = pillInputDecoration();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 32,
        right: 32,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kCosmicBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lock_reset,
                      color: kCosmicBlue, size: 26),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reset Password',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _stepSubtitle,
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (stepMsg != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Text(
                  stepMsg!,
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (step == 1) ...[
              fieldLabel('Email Address'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _resetEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    dec.copyWith(hintText: 'Enter your registered email'),
              ),
              const SizedBox(height: 20),
              BlueButton(
                label: 'SEND OTP',
                onPressed: stepLoading ? null : requestReset,
                loading: stepLoading,
              ),
            ] else if (step == 2) ...[
              _timerCard(),
              const SizedBox(height: 14),
              fieldLabel('6-Digit OTP'),
              const SizedBox(height: 8),
              _otpBoxes(),
              const SizedBox(height: 20),
              BlueButton(
                label: 'VERIFY OTP',
                onPressed:
                    stepLoading || _otpSecondsLeft <= 0 ? null : verifyOtpStep,
                loading: stepLoading,
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _backToEmail,
                child: Text(
                  'Back to Email',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ] else ...[
              _timerCard(),
              const SizedBox(height: 14),
              fieldLabel('New Password'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _newPassCtrl,
                obscureText: obscureNewPass,
                decoration: dec.copyWith(
                  hintText: 'Enter new password',
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: Icon(
                        obscureNewPass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF9CA3AF),
                        size: 22,
                      ),
                      onPressed: () =>
                          setState(() => obscureNewPass = !obscureNewPass),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              fieldLabel('Confirm New Password'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confPassCtrl,
                obscureText: obscureConfPass,
                decoration: dec.copyWith(
                  hintText: 'Confirm new password',
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: Icon(
                        obscureConfPass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF9CA3AF),
                        size: 22,
                      ),
                      onPressed: () =>
                          setState(() => obscureConfPass = !obscureConfPass),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              BlueButton(
                label: 'RESET PASSWORD',
                onPressed: stepLoading || _otpSecondsLeft <= 0 ? null : doReset,
                loading: stepLoading,
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => setState(() {
                  step = 2;
                  stepMsg = null;
                }),
                child: Text(
                  'Back to OTP',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
