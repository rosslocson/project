import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../app_theme.dart';

// --- Global Brand Colors ---
const kCosmicBlue = Color(0xFF00022E);
const kAccentPurple = Color(0xFF7367F0);

/// A bottom sheet widget that handles the 3-step "Forgot Password" flow:
/// 1. Request OTP via email.
/// 2. Verify the 6-digit OTP.
/// 3. Create and confirm a new password.
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
  // --- Controllers & Focus Nodes ---
  // Controls the email input field
  late final TextEditingController _resetEmailCtrl;
  
  // Controllers and FocusNodes for the 6 separate OTP digit boxes
  final List<TextEditingController> _otpDigitCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  
  // Controllers for the new password and confirmation fields
  final _newPassCtrl = TextEditingController();
  final _confPassCtrl = TextEditingController();

  // --- State Variables ---
  String? stepMsg;          // Displays success/error messages to the user
  bool stepLoading = false; // Tracks if an API call is currently in progress
  int step = 1;             // Tracks the current step (1 = Email, 2 = OTP, 3 = New Password)
  
  // --- OTP Timer State ---
  Timer? _otpTimer;         // Background timer counting down the OTP validity
  int _otpSecondsLeft = 0;  // Remaining seconds before the OTP expires
  
  // --- Password Visibility State ---
  bool obscureNewPass = true;
  bool obscureConfPass = true;

  @override
  void initState() {
    super.initState();
    // Pre-fill the email field if the user already typed it in the login screen
    _resetEmailCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    // Clean up memory to prevent leaks when the sheet is closed
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

  // ==========================================
  // API & LOGIC METHODS
  // ==========================================

  /// STEP 1: Sends the password reset request to the server.
  Future<void> requestReset() async {
    if (_resetEmailCtrl.text.isEmpty) return;

    setState(() {
      stepLoading = true;
      stepMsg = null;
    });

    // Call API to send OTP to the provided email
    final res = await ApiService.forgotPassword(_resetEmailCtrl.text.trim());
    setState(() => stepLoading = false);

    if (res['ok'] == true) {
      // Determine how long the OTP is valid from the server response (fallback to 120s)
      final expirySeconds = res['expires_in_secs'] is int
          ? res['expires_in_secs'] as int
          : int.tryParse('${res['expires_in_secs']}') ?? 120;

      setState(() {
        step = 2; // Move to OTP verification step
        // SECURITY: Use a generic message so we don't reveal if an email exists in our DB
        stepMsg = 'If an account exists for this email, a reset code has been sent.';
        _clearOtpBoxes();
        _newPassCtrl.clear();
        _confPassCtrl.clear();
      });
      
      // Start the countdown timer and focus the first OTP box
      _startOtpTimer(expirySeconds);
      _otpFocusNodes.first.requestFocus();
    } else {
      setState(() => stepMsg = res['error'] ?? 'Request failed');
    }
  }

  /// STEP 2: Verifies if the entered 6-digit OTP is correct.
  Future<void> verifyOtpStep() async {
    // Basic local validation
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

    // Call API to verify the OTP code
    final res = await ApiService.verifyResetOtp(_otpCode);
    setState(() => stepLoading = false);

    if (res['ok'] != true) {
      setState(() => stepMsg = res['error'] ?? 'Invalid or expired OTP');
      return;
    }

    // Success! Move to the final "Set New Password" step
    setState(() {
      step = 3; 
      stepMsg = null;
    });
  }

  /// STEP 3: Submits the new password using the validated OTP.
  Future<void> doReset() async {
    // Local validations
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

    // Call API to finalize the password reset
    final res = await ApiService.resetPassword(
      _otpCode,
      _newPassCtrl.text,
      _confPassCtrl.text,
    );
    
    setState(() => stepLoading = false);

    if (res['ok'] == true) {
      _otpTimer?.cancel();
      
      // GUARD: Ensure the widget is still in the tree before using context after an async gap
      if (!mounted) return; 
      
      // Close the bottom sheet and trigger the success callback
      Navigator.pop(context);
      widget.onResetSuccess();
      
      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password reset! You can now log in.'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      setState(() => stepMsg = res['error'] ?? 'Reset failed');
    }
  }

  // ==========================================
  // HELPER & UI LOGIC METHODS
  // ==========================================

  /// Initializes and handles the OTP countdown timer.
  void _startOtpTimer([int seconds = 120]) {
    _otpTimer?.cancel();
    setState(() => _otpSecondsLeft = seconds.clamp(0, 9999));

    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // If widget is removed from tree, kill the timer
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

  /// Formats the remaining seconds into a MM:SS string.
  String get _otpTimeText {
    final minutes = (_otpSecondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_otpSecondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Combines the 6 individual OTP text fields into a single string.
  String get _otpCode =>
      _otpDigitCtrls.map((controller) => controller.text).join();

  /// Returns the subtitle based on the current step.
  String get _stepSubtitle {
    if (step == 1) return 'Step 1 of 3 - Enter your email';
    if (step == 2) return 'Step 2 of 3 - Verify OTP';
    return 'Step 3 of 3 - Set new password';
  }

  /// Clears all 6 OTP input fields.
  void _clearOtpBoxes() {
    for (final controller in _otpDigitCtrls) {
      controller.clear();
    }
  }

  /// Handles OTP text input. Automatically advances focus to the next box,
  /// and supports pasting a full 6-digit code.
  void _handleOtpChanged(String value, int index) {
    // Handle pasting multiple numbers into a single box
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '').split('');
      for (var i = index; i < _otpDigitCtrls.length; i++) {
        final digitIndex = i - index;
        _otpDigitCtrls[i].text =
            digitIndex < digits.length ? digits[digitIndex] : '';
      }
      // Jump focus to the end of the pasted string
      final focusIndex = (index + digits.length).clamp(0, 5);
      _otpFocusNodes[focusIndex].requestFocus();
      setState(() => stepMsg = null);
      return;
    }

    // Auto-advance to next text box when a single digit is entered
    if (value.isNotEmpty && index < _otpFocusNodes.length - 1) {
      _otpFocusNodes[index + 1].requestFocus();
    }

    setState(() => stepMsg = null);
  }

  /// Handles keyboard events for OTP boxes, specifically allowing the user 
  /// to use backspace to delete and move back to the previous box.
  KeyEventResult _handleOtpKey(KeyEvent event, int index) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      // If current box is empty and backspace is pressed, delete previous box and move focus back
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

  /// Returns the user to Step 1 and resets the OTP state.
  void _backToEmail() {
    _otpTimer?.cancel();
    setState(() {
      step = 1;
      stepMsg = null;
      _otpSecondsLeft = 0;
    });
  }

  // ==========================================
  // WIDGET BUILDERS
  // ==========================================

  /// Builds a colored banner indicating how much time is left for the OTP.
  /// Turns red when expired.
  Widget _timerCard(bool isDark) {
    final active = _otpSecondsLeft > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: active
            ? (isDark ? Colors.green.withValues(alpha: 0.1) : Colors.green.shade50)
            : (isDark ? Colors.red.withValues(alpha: 0.1) : Colors.red.shade50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active
              ? (isDark ? Colors.green.withValues(alpha: 0.3) : Colors.green.shade100)
              : (isDark ? Colors.red.withValues(alpha: 0.3) : Colors.red.shade100),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            size: 20,
            color: active
                ? (isDark ? Colors.green.shade400 : Colors.green.shade700)
                : (isDark ? Colors.red.shade400 : Colors.red.shade700),
          ),
          const SizedBox(width: 10),
          Text(
            active ? 'OTP expires in $_otpTimeText' : 'OTP expired',
            style: TextStyle(
              color: active
                  ? (isDark ? Colors.green.shade300 : Colors.green.shade800)
                  : (isDark ? Colors.red.shade300 : Colors.red.shade800),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the 6 individual OTP input squares.
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
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : kCosmicBlue,
                  ),
                  cursorColor: kAccentPurple,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: '', // Hide default character counter
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF14141D) : Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF2A2A38) : Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF6366F1) : kCosmicBlue,
                        width: 2,
                      ),
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

  /// Builds the primary action button for each step. 
  /// Shows a circular progress indicator when `loading` is true.
  Widget _buildActionButton({
    required String label,
    required VoidCallback? onPressed,
    required bool loading,
    required bool isDark,
  }) {
    if (isDark) {
      return SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: kAccentPurple,
            foregroundColor: Colors.white,
            disabledBackgroundColor: kAccentPurple.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      );
    }
    
    // Assumes BlueButton is defined in your existing widget/theme collection
    return BlueButton(
      label: label,
      onPressed: onPressed,
      loading: loading,
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- Shared Styling Elements ---
    final dec = pillInputDecoration(); 
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final labelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white : const Color(0xFF00022E),
    );

    final inputTextStyle = TextStyle(
      fontSize: 14,
      color: isDark ? Colors.white : Colors.black,
    );

    final defaultBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(
        color: isDark ? const Color(0xFF2A2A38) : Colors.grey.shade300,
        width: 1.5,
      ),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(
        color: Color(0xFF6366F1), 
        width: 2,
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F16) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      // Padding pushes the sheet up when the keyboard is active
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
            // Handlebar indicator for bottom sheet
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 28),
            
            // Header Title Area
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? kAccentPurple.withValues(alpha: 0.15)
                        : kCosmicBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.lock_reset,
                      color: isDark ? kAccentPurple : kCosmicBlue, size: 26),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : kCosmicBlue,
                      ),
                    ),
                    Text(
                      _stepSubtitle,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Shared Error / Success Message Banner
            if (stepMsg != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.blue.withValues(alpha: 0.1)
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.blue.withValues(alpha: 0.3)
                        : Colors.blue.shade100,
                  ),
                ),
                child: Text(
                  stepMsg!,
                  style: TextStyle(
                    color: isDark ? Colors.blue.shade200 : Colors.blue.shade800,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            
            // =========================
            // STEP 1: EMAIL INPUT UI
            // =========================
            if (step == 1) ...[
              Text('Email Address', style: labelStyle),
              const SizedBox(height: 8),
              TextFormField(
                controller: _resetEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: inputTextStyle,
                cursorColor: kAccentPurple,
                decoration: dec.copyWith(
                  hintText: 'Enter your registered email',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  fillColor: isDark ? const Color(0xFF14141D) : null,
                  enabledBorder: defaultBorder,
                  focusedBorder: focusedBorder,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),
              _buildActionButton(
                label: 'SEND OTP',
                onPressed: stepLoading ? null : requestReset,
                loading: stepLoading,
                isDark: isDark,
              ),
              
            // =========================
            // STEP 2: OTP INPUT UI
            // =========================
            ] else if (step == 2) ...[
              _timerCard(isDark),
              const SizedBox(height: 14),
              Text('6-Digit OTP', style: labelStyle),
              const SizedBox(height: 8),
              _otpBoxes(isDark),
              const SizedBox(height: 20),
              _buildActionButton(
                label: 'VERIFY OTP',
                onPressed: stepLoading || _otpSecondsLeft <= 0 ? null : verifyOtpStep,
                loading: stepLoading,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _backToEmail,
                child: Text(
                  'Back to Email',
                  style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey.shade600),
                ),
              ),
              
            // =========================
            // STEP 3: NEW PASSWORD UI
            // =========================
            ] else ...[
              _timerCard(isDark),
              const SizedBox(height: 14),
              Text('New Password', style: labelStyle),
              const SizedBox(height: 8),
              TextFormField(
                controller: _newPassCtrl,
                obscureText: obscureNewPass,
                style: inputTextStyle,
                cursorColor: kAccentPurple,
                decoration: dec.copyWith(
                  hintText: 'Enter new password',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  fillColor: isDark ? const Color(0xFF14141D) : null,
                  enabledBorder: defaultBorder,
                  focusedBorder: focusedBorder,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
              Text('Confirm New Password', style: labelStyle),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confPassCtrl,
                obscureText: obscureConfPass,
                style: inputTextStyle,
                cursorColor: kAccentPurple,
                decoration: dec.copyWith(
                  hintText: 'Confirm new password',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  fillColor: isDark ? const Color(0xFF14141D) : null,
                  enabledBorder: defaultBorder,
                  focusedBorder: focusedBorder,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
              _buildActionButton(
                label: 'RESET PASSWORD',
                onPressed: stepLoading || _otpSecondsLeft <= 0 ? null : doReset,
                loading: stepLoading,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => setState(() {
                  step = 2; // Allows user to go back to correct a typo in OTP
                  stepMsg = null;
                }),
                child: Text(
                  'Back to OTP',
                  style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey.shade600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}