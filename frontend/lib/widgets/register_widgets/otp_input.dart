import 'package:flutter/material.dart';

class OtpInputWidget extends StatefulWidget {
  final Function(String) onOtpCompleted;

  const OtpInputWidget({Key? key, required this.onOtpCompleted}) : super(key: key);

  @override
  _OtpInputWidgetState createState() => _OtpInputWidgetState();
}

class _OtpInputWidgetState extends State<OtpInputWidget> {
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _nextField(String value, int index) {
    if (value.length == 1 && index < 5) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    }
    if (index == 5 && value.length == 1) {
      FocusScope.of(context).unfocus();
      String otp = _controllers.map((c) => c.text).join();
      widget.onOtpCompleted(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 50,
          height: 60,
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            maxLength: 1,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 24),
            decoration: InputDecoration(
              counterText: "",
              filled: true,
              fillColor: const Color(0xFF1A1A2E), // Match your dark input background
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 2), // The purple neon color
              ),
            ),
            onChanged: (value) => _nextField(value, index),
          ),
        );
      }),
    );
  }
}