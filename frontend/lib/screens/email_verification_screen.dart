import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';


const kCosmicBlue = Color(0xFF00022E);
const kAccentPurple = Color(0xFF7C4DFF);

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final VoidCallback onBack;
  final VoidCallback onSuccess;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.onBack,
    required this.onSuccess,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  // Match ForgotPasswordSheet OTP behavior
  final List<TextEditingController> _otpDigitCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  String? stepMsg;
  bool stepLoading = false;

  Timer? _otpTimer;
  int _otpSecondsLeft = 0;

  // Resend OTP state
  Timer? _resendCooldownTimer;
  int _resendCooldownSeconds = 0;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startOtpTimer(300); // 5 minutes for email verification
    // Focus first box when the widget appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _otpFocusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    _otpTimer?.cancel();
    _resendCooldownTimer?.cancel();
    for (final controller in _otpDigitCtrls) {
      controller.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startOtpTimer([int seconds = 300]) {
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

  void _startResendCooldown([int seconds = 60]) {
    _resendCooldownTimer?.cancel();
    setState(() => _resendCooldownSeconds = seconds);

    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendCooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _resendCooldownSeconds = 0);
        return;
      }

      setState(() => _resendCooldownSeconds--);
    });
  }

  String get _otpTimeText {
    final minutes = (_otpSecondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_otpSecondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _otpCode =>
      _otpDigitCtrls.map((controller) => controller.text).join();

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

  Future<void> _verifyOtp() async {
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

    try {
      final res = await ApiService.verifyRegistrationOtp(_otpCode);

      if (!mounted) return;

      if (res['ok'] == true && res['token'] != null) {
        // Save token securely
        await ApiService.saveToken(res['token']);

        // ApiService reads the token from SharedPreferences for authenticated requests.
        // No extra global header attachment is needed.


        setState(() {
          stepLoading = false;
          stepMsg = null;
        });

        // Trigger success callback
        widget.onSuccess();
      } else {
        setState(() {
          stepLoading = false;
          stepMsg = (res['error'] ?? 'Invalid OTP. Please try again.').toString();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        stepLoading = false;
        stepMsg = 'Could not verify OTP. Please try again.';
      });
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCooldownSeconds > 0) return;

    setState(() {
      _isResending = true;
      stepMsg = null;
    });

    try {
      final res = await ApiService.resendRegistrationOtp(widget.email);

      if (!mounted) return;

      if (res['ok'] == true) {
        setState(() {
          _isResending = false;
          stepMsg = 'New verification code sent to your email!';
        });
        
        // Restart OTP timer (5 minutes)
        _startOtpTimer(300);
        
        // Start resend cooldown (60 seconds)
        _startResendCooldown(60);
      } else {
        setState(() {
          _isResending = false;
          stepMsg = res['error'] ?? 'Failed to resend code. Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
        stepMsg = 'Connection error. Please try again.';
      });
    }
  }

  Widget _timerCard(bool isDark) {
    final active = _otpSecondsLeft > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1A14),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            color: active ? Colors.greenAccent : Colors.redAccent,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            active ? 'OTP expires in $_otpTimeText' : 'OTP Expired',
            style: TextStyle(
              color: active ? Colors.greenAccent : Colors.redAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resendButton(bool isDark) {
    final canResend = _resendCooldownSeconds == 0;
    
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: (canResend && !_isResending) ? _resendOtp : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: canResend ? kAccentPurple : Colors.grey,
          side: BorderSide(
            color: canResend ? kAccentPurple : Colors.grey.withOpacity(0.5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: _isResending
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: kAccentPurple,
                  strokeWidth: 2,
                ),
              )
            : Text(
                canResend
                    ? 'Resend Code'
                    : 'Resend in ${_resendCooldownSeconds}s',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  // Exact spacing/layout requirement: Row > Expanded > Padding(right: 8)
  Widget _otpBoxes(bool isDark) {
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
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : kCosmicBlue,
                  ),
                  cursorColor: kAccentPurple,
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF14141D) : Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF2A2A38)
                            : Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? kAccentPurple : kCosmicBlue,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (v) => _handleOtpChanged(v, index),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      color: isDark ? const Color(0xFF0D0B1A) : Colors.white,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'VERIFY ACCOUNT',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : kCosmicBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Step 2 of 2 - Enter OTP',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),

            if (stepMsg != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.red.withOpacity(0.1) : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.red.withOpacity(0.3) : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        stepMsg!,
                        style: TextStyle(
                          color: isDark ? Colors.redAccent : Colors.red.shade800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF101828) : Colors.blue.shade50,
                border: Border.all(
                  color: isDark
                      ? Colors.blueAccent.withOpacity(0.3)
                      : Colors.blue.shade200,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'A verification code has been sent to ${widget.email}',
                      style: TextStyle(
                        color: isDark ? Colors.blueGrey : Colors.blue.shade900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _timerCard(isDark),
            const SizedBox(height: 32),

            Text(
              '6-Digit OTP',
              style: TextStyle(
                color: isDark ? Colors.white : kCosmicBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _otpBoxes(isDark),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: (_otpSecondsLeft > 0 && _otpCode.length == 6 && !stepLoading)
                    ? _verifyOtp
                    : null,
                child: stepLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'VERIFY ACCOUNT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),
            _resendButton(isDark),

            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: widget.onBack,
                child: Text(
                  'Back to Create Account',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

