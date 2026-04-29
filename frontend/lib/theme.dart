import 'package:flutter/material.dart';

// Centralized theme constants for the app

class AppTheme {
  // Space background gradient
  static const BoxDecoration spaceBackground = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF080812), // Start color (top)
        Color(0xFF121629), // End color (bottom)
      ],
    ),
  );

  // Other theme constants can be added here
}