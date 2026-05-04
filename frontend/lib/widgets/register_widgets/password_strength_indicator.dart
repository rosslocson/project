import 'package:flutter/material.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final double passValue;
  final Color passColor;
  final String passStrength;

  const PasswordStrengthIndicator({
    super.key,
    required this.passValue,
    required this.passColor,
    required this.passStrength,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: passValue,
              color: passColor,
              backgroundColor: Colors.grey.shade200,
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 48,
          child: Text(
            passStrength,
            style: TextStyle(
              color: passColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}