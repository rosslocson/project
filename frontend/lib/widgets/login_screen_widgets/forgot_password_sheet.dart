import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../app_theme.dart'; // Adjust path if needed

class ForgotPasswordSheet extends StatefulWidget {
  final String initialEmail;
  final VoidCallback onResetSuccess;

  const ForgotPasswordSheet({super.key, required this.initialEmail, required this.onResetSuccess});

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  late final TextEditingController _resetEmailCtrl;
  final _otpCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confPassCtrl = TextEditingController();

  String? stepMsg;
  bool stepLoading = false;
  int step = 1;
  bool obscureNewPass = true;
  bool obscureConfPass = true;

  @override
  void initState() {
    super.initState();
    _resetEmailCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _resetEmailCtrl.dispose();
    _otpCtrl.dispose();
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
      setState(() {
        step = 2;
        stepMsg = res['message'];
        _otpCtrl.clear();
      });
    } else {
      setState(() => stepMsg = res['error'] ?? 'Request failed');
    }
  }

  Future<void> doReset() async {
    if (_otpCtrl.text.isEmpty || _newPassCtrl.text.isEmpty) return;
    if (_newPassCtrl.text != _confPassCtrl.text) {
      setState(() => stepMsg = 'Passwords do not match');
      return;
    }
    setState(() {
      stepLoading = true;
      stepMsg = null;
    });
    
    final res = await ApiService.resetPassword(_otpCtrl.text.trim(), _newPassCtrl.text, _confPassCtrl.text);
    setState(() => stepLoading = false);
    
    if (res['ok'] == true) {
      if (mounted) Navigator.pop(context);
      widget.onResetSuccess();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Password reset! You can now log in.'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } else {
      setState(() => stepMsg = res['error'] ?? 'Reset failed');
    }
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
        left: 32, right: 32, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 48, height: 5,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2.5)),
            ),
          ),
          const SizedBox(height: 28),
          Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kCosmicBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.lock_reset, color: kCosmicBlue, size: 26),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reset Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(
                  step == 1 ? 'Step 1 of 2 — Enter your email' : 'Step 2 of 2 — Verify OTP & set password',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
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
              child: Text(stepMsg!, style: TextStyle(color: Colors.blue.shade800, fontSize: 13, height: 1.4)),
            ),
            const SizedBox(height: 14),
          ],
          if (step == 1) ...[
            fieldLabel('Email Address'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _resetEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: dec.copyWith(hintText: 'Enter your registered email'),
            ),
            const SizedBox(height: 20),
            BlueButton(label: 'SEND OTP', onPressed: stepLoading ? null : requestReset, loading: stepLoading),
          ] else ...[
            fieldLabel('6-Digit OTP'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: dec.copyWith(hintText: 'Enter 6-digit OTP from email', counterText: ''),
            ),
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
                    icon: Icon(obscureNewPass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF9CA3AF), size: 22),
                    onPressed: () => setState(() => obscureNewPass = !obscureNewPass),
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
                    icon: Icon(obscureConfPass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF9CA3AF), size: 22),
                    onPressed: () => setState(() => obscureConfPass = !obscureConfPass),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            BlueButton(label: 'RESET PASSWORD', onPressed: stepLoading ? null : doReset, loading: stepLoading),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => setState(() { step = 1; stepMsg = null; }),
              child: Text('← Back to Email', style: TextStyle(color: Colors.grey.shade600)),
            ),
          ],
        ],
      ),
    );
  }
}