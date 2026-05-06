import 'package:flutter/material.dart';

class InternCarouselPalette {
  static const Color accent = Color(0xFF6366F1);
  static const Color dotActive = Color(0xFF6366F1);
  static const Color cardStart = Color(0xFF1E1B4B);
  static const Color cardEnd = Color(0xFF4C1D95);
  static const Color cardText = Colors.white;
  static const Color cardMutedText = Color(0xB3FFFFFF);
  static const Color shadow = Color(0x660F172A);
  static const Color _lightCardStart = Color(0xFF5B74FF);
  static const Color _lightCardEnd = Color(0xFF8EA3FF);
  static const Color _lightCardText = Colors.white;
  static const Color _lightCardMutedText = Color(0xE6FFFFFF);
  static const Color _lightArrowBackground = Color(0xFF5E69E8);
  static const Color _lightArrowHoverBackground = Color(0xFF5262F4);
  static const Color _lightArrowBorder = Color(0xFF8EA3FF);
  static const Color _lightArrowIcon = Colors.white;

  const InternCarouselPalette._();

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static List<Color> cardGradient(BuildContext context) {
    if (_isDark(context)) {
      return const [cardStart, cardEnd];
    }

    return const [_lightCardStart, _lightCardEnd];
  }

  static Color cardForeground(BuildContext context) {
    return _isDark(context) ? cardText : _lightCardText;
  }

  static Color cardForegroundMuted(BuildContext context) {
    return _isDark(context) ? cardMutedText : _lightCardMutedText;
  }

  static List<BoxShadow> cardShadows(BuildContext context) {
    if (!_isDark(context)) {
      return const [];
    }

    return [
      BoxShadow(
        color: shadow,
        blurRadius: 32,
        offset: const Offset(0, 16),
      ),
    ];
  }

  static Color arrowBackground(BuildContext context, {required bool hovered}) {
    if (_isDark(context)) {
      return cardStart.withValues(alpha: hovered ? 0.9 : 0.78);
    }

    return hovered ? _lightArrowHoverBackground : _lightArrowBackground;
  }

  static Color arrowBorder(BuildContext context, {required bool hovered}) {
    if (_isDark(context)) {
      return accent.withValues(alpha: hovered ? 0.6 : 0.35);
    }

    return _lightArrowBorder.withValues(alpha: hovered ? 0.95 : 0.72);
  }

  static Color arrowIcon(BuildContext context, {required bool hovered}) {
    if (_isDark(context)) {
      return cardText.withValues(alpha: hovered ? 1.0 : 0.9);
    }

    return _lightArrowIcon.withValues(alpha: hovered ? 1.0 : 0.96);
  }
}


