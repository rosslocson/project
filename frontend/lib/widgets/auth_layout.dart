import 'package:flutter/material.dart';

// ── Brand colors ──────────────────────────────────────────────────────────────
const kCrimson      = Color(0xFF7B0D1E);
const kCrimsonDark  = Color(0xFF560A16);
const kCrimsonLight = Color(0xFF9B1D2E);

// ── Full-screen split layout  ─────────────────────────────────────────────────
// Wide: left panel (Expanded flex:1) | right panel (Expanded flex:1), full height
// Narrow: left panel fixed 220h on top, right panel scrollable below
Widget buildAuthLayout({
  required BuildContext context,
  required String headline,
  required String subheadline,
  required Widget rightPanel,
}) {
  return Scaffold(
    backgroundColor: Colors.white,
    body: LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 620;
      if (isWide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Left crimson panel ───────────────────────────────────────
            Expanded(
              flex: 1,
              child: _LeftPanel(
                headline: headline,
                subheadline: subheadline,
                isWide: true,
              ),
            ),
            // ── Right form panel ─────────────────────────────────────────
            Expanded(
              flex: 1,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 48, vertical: 48),
                  child: rightPanel,
                ),
              ),
            ),
          ],
        );
      } else {
        // Mobile: stacked
        return SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 220,
                child: _LeftPanel(
                  headline: headline,
                  subheadline: subheadline,
                  isWide: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: rightPanel,
              ),
            ],
          ),
        );
      }
    }),
  );
}

// ── Left crimson panel ────────────────────────────────────────────────────────
class _LeftPanel extends StatelessWidget {
  final String headline;
  final String subheadline;
  final bool isWide;

  const _LeftPanel({
    required this.headline,
    required this.subheadline,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    // Wide: right side of the panel has the large rounded corners (cuts into white)
    // Narrow: bottom corners are rounded
    final borderRadius = isWide
        ? const BorderRadius.only(
            topRight: Radius.circular(80),
            bottomRight: Radius.circular(80),
          )
        : const BorderRadius.only(
            bottomLeft: Radius.circular(80),
            bottomRight: Radius.circular(80),
          );

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: const LinearGradient(
          colors: [kCrimsonDark, kCrimson, kCrimsonLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Diamond pattern
          Positioned.fill(
            child: ClipRRect(
              borderRadius: borderRadius,
              child: CustomPaint(painter: _DiamondPainter()),
            ),
          ),
          // Centered headline text
          Center(
            child: Padding(
              padding: const EdgeInsets.all(36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    headline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subheadline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable form helpers ─────────────────────────────────────────────────────

Widget fieldLabel(String text) => Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2D2D2D),
      ),
    );

InputDecoration _baseDecoration({
  required String hint,
  Widget? suffixIcon,
  bool hasError = false,
}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
      filled: true,
      fillColor: const Color(0xFFEEF2F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: hasError
            ? const BorderSide(color: kCrimson, width: 1.5)
            : BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: kCrimson, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: kCrimson, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: kCrimson, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      suffixIcon: suffixIcon,
      errorStyle: const TextStyle(fontSize: 11, color: kCrimson),
    );

Widget plainTextField({
  required TextEditingController controller,
  required String hint,
  TextInputType? keyboardType,
  String? Function(String?)? validator,
  void Function(String)? onChanged,
  bool enabled = true,
}) =>
    TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 16),
      enabled: enabled,
      onChanged: onChanged,
      validator: validator,
      decoration: _baseDecoration(hint: hint),
    );

Widget passwordTextField({
  required TextEditingController controller,
  required String hint,
  required bool obscure,
  required VoidCallback onToggle,
  String? Function(String?)? validator,
  void Function(String)? onChanged,
  bool hasError = false,
  bool enabled = true,
}) =>
    TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 16),
      enabled: enabled,
      onChanged: onChanged,
      validator: validator,
      decoration: _baseDecoration(
        hint: hint,
        hasError: hasError,
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.grey[500],
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
    );

Widget crimsonButton({
  required String label,
  required VoidCallback? onPressed,
  bool loading = false,
}) =>
    SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kCrimson,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: kCrimson.withOpacity(0.4),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30)),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.5,
                ),
              ),
      ),
    );

// ── Diamond background painter ────────────────────────────────────────────────
class _DiamondPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    void drawDiamond(Offset center, double half) {
      final path = Path()
        ..moveTo(center.dx, center.dy - half)
        ..lineTo(center.dx + half, center.dy)
        ..lineTo(center.dx, center.dy + half)
        ..lineTo(center.dx - half, center.dy)
        ..close();
      canvas.drawPath(path, paint);
    }

    const spacing = 75.0;
    for (double x = -spacing; x < size.width + spacing; x += spacing * 0.75) {
      for (double y = -spacing; y < size.height + spacing; y += spacing) {
        drawDiamond(Offset(x, y), 52);
      }
    }
    for (double x = -spacing / 2;
        x < size.width + spacing;
        x += spacing * 0.75) {
      for (double y = -spacing / 2;
          y < size.height + spacing;
          y += spacing) {
        drawDiamond(Offset(x, y), 52);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}