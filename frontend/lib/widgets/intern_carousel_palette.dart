import 'package:flutter/material.dart';

class InternCarouselPalette {
  static const Color accent = Color(0xFF6366F1);
  static const Color dotActive = Color(0xFF6366F1);
  static const Color cardStart = Color(0xFF1E1B4B);
  static const Color cardEnd = Color(0xFF4C1D95);
  static const Color cardText = Colors.white;
  static const Color cardMutedText = Color(0xB3FFFFFF);
  static const Color shadow = Color(0x660F172A);

  // Light mode card gradient
  static const Color _lightCardStart = Color(0xFF5B74FF);
  static const Color _lightCardEnd = Color(0xFF8EA3FF);
  static const Color _lightCardText = Colors.white;
  static const Color _lightCardMutedText = Color(0xE6FFFFFF);

  const InternCarouselPalette._();

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // ─── Card ────────────────────────────────────────────────────────────────

  static List<Color> cardGradient(BuildContext context) {
    if (_isDark(context)) return const [cardStart, cardEnd];
    return const [_lightCardStart, _lightCardEnd];
  }

  static Color cardForeground(BuildContext context) =>
      _isDark(context) ? cardText : _lightCardText;

  static Color cardForegroundMuted(BuildContext context) =>
      _isDark(context) ? cardMutedText : _lightCardMutedText;

  static List<BoxShadow> cardShadows(BuildContext context) {
    if (!_isDark(context)) return const [];
    return const [
      BoxShadow(color: shadow, blurRadius: 32, offset: Offset(0, 16)),
    ];
  }

  // ─── Arrow buttons (glass) ────────────────────────────────────────────────

  /// Fill color of the circular arrow button.
  static Color arrowBackground(BuildContext context, {required bool hovered}) {
    if (_isDark(context)) {
      // Dark: deep indigo glass, darkens slightly on hover
      return cardStart.withValues(alpha: hovered ? 0.90 : 0.78);
    }
    // Light: translucent indigo tint, brightens on hover
    return accent.withValues(alpha: hovered ? 0.28 : 0.18);
  }

  /// Border color of the circular arrow button.
  static Color arrowBorder(BuildContext context, {required bool hovered}) {
    if (_isDark(context)) {
      return accent.withValues(alpha: hovered ? 0.60 : 0.35);
    }
    return accent.withValues(alpha: hovered ? 0.55 : 0.35);
  }

  /// Icon / chevron color inside the arrow button.
  static Color arrowIcon(BuildContext context, {required bool hovered}) {
    if (_isDark(context)) {
      return cardText.withValues(alpha: hovered ? 1.0 : 0.90);
    }
    // Light: accent-colored icon so it reads on the translucent bg
    return accent.withValues(alpha: hovered ? 1.0 : 0.95);
  }

  /// Blur sigma for the BackdropFilter on the arrow button.
  /// Both modes get a frosted-glass blur.
  static double arrowBlurSigma(BuildContext context) => 8.0;

  // ─── Dot indicators ───────────────────────────────────────────────────────

  /// Fill of an inactive dot.
  static Color dotInactiveFill(BuildContext context) {
    if (_isDark(context)) return accent.withValues(alpha: 0.22);
    return accent.withValues(alpha: 0.15);
  }

  /// Border of an inactive dot.
  static Color dotInactiveBorder(BuildContext context) {
    if (_isDark(context)) return accent.withValues(alpha: 0.30);
    return accent.withValues(alpha: 0.30);
  }

  /// Fill of the active (pill-shaped) dot.
  static Color dotActiveFill(BuildContext context) {
    if (_isDark(context)) return accent.withValues(alpha: 0.85);
    return accent.withValues(alpha: 0.55);
  }

  /// Border of the active dot.
  static Color dotActiveBorder(BuildContext context) {
    if (_isDark(context)) return accent.withValues(alpha: 0.60);
    return accent.withValues(alpha: 0.45);
  }
}
