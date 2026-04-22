import 'package:flutter/material.dart';

// ── Brand colours ─────────────────────────────────────────────────────────────
const kCosmicBlue    = Color(0xFF00022E);
const kCrimsonDeep   = Color(0xFF00022E); // Kept for legacy, maps to blue
const kNavyDeep      = Color(0xFF1A1F5A);
const kGlowBlue      = Color(0xFF4C6FFF);
const kBgLight       = Color(0xFFF5F7FF);
const kBgGradientEnd = Color(0xFFEDEFFF);
const kTextSecondary = Color(0xFFA0A3BD);
const kBorderLight   = Color(0xFFE0E3F0);
const kCardBg        = Colors.white;

// ── Shared pill input decoration (auth screens) ───────────────────────────────
InputDecoration pillInputDecoration({
  String? hint,
  Widget? suffix,
  Widget? prefix,
}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      suffixIcon: suffix,
      prefixIcon: prefix,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: kCosmicBlue.withOpacity(0.5), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: const Color(0xFF00022E).withOpacity(0.6), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFF00022E), width: 2),
      ),
    );

// ── Shared label widget ───────────────────────────────────────────────────────
Widget fieldLabel(String text) => Text(
      text,
      style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF00022E)),
    );

// ── Primary cosmic blue button (remapped from crimson) ────────────────────────
class BlueButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const BlueButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: kCosmicBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
      ).copyWith(
        elevation: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.hovered) ? 8 : 0,
        ),
      ),
      child: loading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5),
            )
          : Text(
              label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0),
            ),
    );
  }
}

// ── Pill dropdown container ───────────────────────────────────────────────────
class PillDropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final List<String> items;
  final void Function(String?)? onChanged;
  final String? Function(String?)? validator;

  const PillDropdown({
    super.key,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      validator: validator,
      decoration: pillInputDecoration(),
      hint: Text(hint,
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
      icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade500),
      style: const TextStyle(color: Colors.black87, fontSize: 13),
      items: items
          .map((s) => DropdownMenuItem(
              value: s,
              child: Text(s,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13))))
          .toList(),
      onChanged: onChanged,
    );
  }
}

