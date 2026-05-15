import 'package:flutter/material.dart';
import '../../models/attendance_constants.dart';
import '../../widgets/app_theme.dart';

class ExportButton extends StatelessWidget {
  final VoidCallback onTap;
  const ExportButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkInternTheme;

    return Material(
      color: const Color(0xFF6C63FF),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.download_rounded, size: 16, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Export PDF',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IconActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const IconActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.internTheme;
    final isDark = context.isDarkInternTheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF4F5F8),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: isDark
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  )
                : null,
            child: Icon(icon, color: theme.mutedText, size: 18),
          ),
        ),
      ),
    );
  }
}

class PageButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const PageButton({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkInternTheme;

    return Material(
      color: enabled
          ? kButtonDark
          : isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFF4F5F8),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? Colors.white
                : isDark
                    ? Colors.white30
                    : kTextLight,
          ),
        ),
      ),
    );
  }
}

class HamburgerIcon extends StatelessWidget {
  const HamburgerIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _bar(22),
          _bar(14, opacity: 0.8),
          _bar(22),
        ],
      ),
    );
  }

  Widget _bar(double w, {double opacity = 1.0}) => Container(
        width: w,
        height: 2.5,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(2),
        ),
      );
}
