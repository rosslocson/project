import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kCosmicBlue = Color(0xFF00022E);
const kCrimsonDeep = Color(0xFF00022E);
const kNavyDeep = Color(0xFF1A1F5A);
const kGlowBlue = Color(0xFF4C6FFF);
const kAccentPurple = Color(0xFF7367F0);
const kBgLight = Color(0xFFF5F7FF);
const kBgGradientEnd = Color(0xFFEDEFFF);
const kTextSecondary = Color(0xFFA0A3BD);
const kBorderLight = Color(0xFFE0E3F0);
const kCardBg = Colors.white;

@immutable
class InternSpaceThemeColors extends ThemeExtension<InternSpaceThemeColors> {
  final Color appBackground;
  final bool useSpaceBackground;
  final Color sidebarBackground;
  final Color sidebarText;
  final Color sidebarMutedText;
  final Color sidebarActiveBackground;
  final Color sidebarActiveForeground;
  final Color sidebarHoverBackground;
  final Color topbarText;
  final Color topbarMutedText;
  final Color topbarScrim;
  final Color surface;
  final Color surfaceText;
  final Color mutedText;
  final Color border;
  final Color dashboardCardStart;
  final Color dashboardCardEnd;
  final Color dashboardCardText;
  final Color metricCardBackground;
  final Color metricCardText;
  final Color metricCardMutedText;
  final Color listBackground;
  final Color listText;
  final Color listMutedText;
  final Color userBadgeBackground;
  final Color adminBadgeBackground;
  final Color formFill;
  final Color dialogBackground;
  final Color shadowColor;

  const InternSpaceThemeColors({
    required this.appBackground,
    required this.useSpaceBackground,
    required this.sidebarBackground,
    required this.sidebarText,
    required this.sidebarMutedText,
    required this.sidebarActiveBackground,
    required this.sidebarActiveForeground,
    required this.sidebarHoverBackground,
    required this.topbarText,
    required this.topbarMutedText,
    required this.topbarScrim,
    required this.surface,
    required this.surfaceText,
    required this.mutedText,
    required this.border,
    required this.dashboardCardStart,
    required this.dashboardCardEnd,
    required this.dashboardCardText,
    required this.metricCardBackground,
    required this.metricCardText,
    required this.metricCardMutedText,
    required this.listBackground,
    required this.listText,
    required this.listMutedText,
    required this.userBadgeBackground,
    required this.adminBadgeBackground,
    required this.formFill,
    required this.dialogBackground,
    required this.shadowColor,
  });

  static const light = InternSpaceThemeColors(
    appBackground: Color(0xFFFFFFFF),
    useSpaceBackground: false,
    // Sidebar untouched
    sidebarBackground: Color(0xFFF2F7FF),
    sidebarText: Color(0xFF050816),
    sidebarMutedText: Color(0xFF66738F),
    sidebarActiveBackground: Color(0xFFDCE6FF),
    sidebarActiveForeground: Color(0xFF4F5DE6),
    sidebarHoverBackground: Color(0xFFE8F0FF),
    // Brand Colors Applied
    topbarText: Color(0xFF00022E), 
    topbarMutedText: Color(0xFF6B7280),
    topbarScrim: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceText: Color(0xFF000000), 
    mutedText: Color(0xFF6B7280), 
    border: Color(0xFFD9E3F7),
    // Cards untouched
    dashboardCardStart: Color(0xFFFFFFFF),
    dashboardCardEnd: Color(0xFFFFFFFF),
    dashboardCardText: Color(0xFF050816),
    metricCardBackground: Color(0xFFF2F7FF),
    metricCardText: Color(0xFF0A1425),
    metricCardMutedText: Color(0xFF6B7280),
    listBackground: Color(0xFFFFFFFF),
    listText: Color(0xFF000000), 
    listMutedText: Color(0xFF6B7280), 
    userBadgeBackground: Color(0xFFEAFBF1),
    adminBadgeBackground: Color(0xFFFDECEC),
    formFill: Color(0xFFF9FAFB),
    dialogBackground: Color(0xFFFFFFFF),
    shadowColor: Color(0x14000000),
  );

  static const dark = InternSpaceThemeColors(
    appBackground: Color(0xFF050510),
    useSpaceBackground: true,
    // Sidebar untouched
    sidebarBackground: Color(0xFF0B0F2F),
    sidebarText: Colors.white,
    sidebarMutedText: Color(0xFFA78BFA),
    sidebarActiveBackground: Color(0xFF6366F1),
    sidebarActiveForeground: Color(0xFFFFFFFF),
    sidebarHoverBackground: Color(0x1AFFFFFF),
    // Brand Colors Applied
    topbarText: Color(0xFFFFFFFF),
    topbarMutedText: Color(0xB3FFFFFF), 
    topbarScrim: Color(0xFF050505),
    surface: Color(0xFF0B0B13),
    surfaceText: Color(0xFFFFFFFF), 
    mutedText: Color(0xB3FFFFFF), 
    border: Color(0xFF2A2A38),
    // Cards untouched
    dashboardCardStart: Color(0xFF0B0B13),
    dashboardCardEnd: Color(0xFF000000),
    dashboardCardText: Color(0xFFFFFFFF),
    metricCardBackground: Color(0xFF0B0F2F),
    metricCardText: Color(0xFFFFFFFF),
    metricCardMutedText: Color(0xFFAEB4C4),
    listBackground: Color(0xFF0B0B13),
    listText: Color(0xFFFFFFFF), 
    listMutedText: Color(0xB3FFFFFF), 
    userBadgeBackground: Color(0x3316A34A),
    adminBadgeBackground: Color(0x33DC2626),
    formFill: Color(0xFF14141D),
    dialogBackground: Color(0xFF0B0B13),
    shadowColor: Color(0x00000000),
  );

  @override
  InternSpaceThemeColors copyWith({
    Color? appBackground,
    bool? useSpaceBackground,
    Color? sidebarBackground,
    Color? sidebarText,
    Color? sidebarMutedText,
    Color? sidebarActiveBackground,
    Color? sidebarActiveForeground,
    Color? sidebarHoverBackground,
    Color? topbarText,
    Color? topbarMutedText,
    Color? topbarScrim,
    Color? surface,
    Color? surfaceText,
    Color? mutedText,
    Color? border,
    Color? dashboardCardStart,
    Color? dashboardCardEnd,
    Color? dashboardCardText,
    Color? metricCardBackground,
    Color? metricCardText,
    Color? metricCardMutedText,
    Color? listBackground,
    Color? listText,
    Color? listMutedText,
    Color? userBadgeBackground,
    Color? adminBadgeBackground,
    Color? formFill,
    Color? dialogBackground,
    Color? shadowColor,
  }) {
    return InternSpaceThemeColors(
      appBackground: appBackground ?? this.appBackground,
      useSpaceBackground: useSpaceBackground ?? this.useSpaceBackground,
      sidebarBackground: sidebarBackground ?? this.sidebarBackground,
      sidebarText: sidebarText ?? this.sidebarText,
      sidebarMutedText: sidebarMutedText ?? this.sidebarMutedText,
      sidebarActiveBackground:
          sidebarActiveBackground ?? this.sidebarActiveBackground,
      sidebarActiveForeground:
          sidebarActiveForeground ?? this.sidebarActiveForeground,
      sidebarHoverBackground:
          sidebarHoverBackground ?? this.sidebarHoverBackground,
      topbarText: topbarText ?? this.topbarText,
      topbarMutedText: topbarMutedText ?? this.topbarMutedText,
      topbarScrim: topbarScrim ?? this.topbarScrim,
      surface: surface ?? this.surface,
      surfaceText: surfaceText ?? this.surfaceText,
      mutedText: mutedText ?? this.mutedText,
      border: border ?? this.border,
      dashboardCardStart: dashboardCardStart ?? this.dashboardCardStart,
      dashboardCardEnd: dashboardCardEnd ?? this.dashboardCardEnd,
      dashboardCardText: dashboardCardText ?? this.dashboardCardText,
      metricCardBackground:
          metricCardBackground ?? this.metricCardBackground,
      metricCardText: metricCardText ?? this.metricCardText,
      metricCardMutedText:
          metricCardMutedText ?? this.metricCardMutedText,
      listBackground: listBackground ?? this.listBackground,
      listText: listText ?? this.listText,
      listMutedText: listMutedText ?? this.listMutedText,
      userBadgeBackground: userBadgeBackground ?? this.userBadgeBackground,
      adminBadgeBackground: adminBadgeBackground ?? this.adminBadgeBackground,
      formFill: formFill ?? this.formFill,
      dialogBackground: dialogBackground ?? this.dialogBackground,
      shadowColor: shadowColor ?? this.shadowColor,
    );
  }

  @override
  InternSpaceThemeColors lerp(
    ThemeExtension<InternSpaceThemeColors>? other,
    double t,
  ) {
    if (other is! InternSpaceThemeColors) return this;
    return t < 0.5 ? this : other;
  }
}

extension InternSpaceThemeContext on BuildContext {
  InternSpaceThemeColors get internTheme =>
      Theme.of(this).extension<InternSpaceThemeColors>() ??
      InternSpaceThemeColors.dark;

  bool get isDarkInternTheme => Theme.of(this).brightness == Brightness.dark;
}

ThemeData internSpaceTheme({required Brightness brightness}) {
  final isDark = brightness == Brightness.dark;
  final colors =
      isDark ? InternSpaceThemeColors.dark : InternSpaceThemeColors.light;
  final baseTextTheme =
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;

  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: isDark ? const Color(0xFF7367F0) : const Color(0xFF00022E),
      brightness: brightness,
      surface: colors.surface,
    ),
    scaffoldBackgroundColor: colors.appBackground,
    textTheme: GoogleFonts.poppinsTextTheme(baseTextTheme),
    useMaterial3: true,
    extensions: <ThemeExtension<dynamic>>[colors],
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
      },
    ),
  );

  return base.copyWith(
    cardTheme: CardThemeData(
      color: colors.surface,
      elevation: isDark ? 0 : 8,
      shadowColor: colors.shadowColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.dialogBackground,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: colors.surface,
      surfaceTintColor: Colors.transparent,
      textStyle: TextStyle(color: colors.surfaceText, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: isDark ? const Color(0xFF7367F0) : const Color(0xFF00022E),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.formFill,
      hintStyle: TextStyle(
        color: isDark ? const Color(0xB3FFFFFF) : const Color(0x8A000000), 
        fontSize: 13
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF7367F0) : const Color(0xFF00022E), 
          width: 1.5
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.6)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.9)),
      ),
    ),
  );
}

InputDecoration pillInputDecoration({
  BuildContext? context,
  String? hint,
  Widget? suffix,
  Widget? prefix,
}) {
  final isDark = context != null ? Theme.of(context).brightness == Brightness.dark : false;
  final primaryColor = isDark ? const Color(0xFF7367F0) : const Color(0xFF00022E);
  final hintColor = isDark ? const Color(0xB3FFFFFF) : const Color(0x8A000000);

  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: hintColor, fontSize: 13),
    filled: true,
    fillColor: null,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    suffixIcon: suffix,
    prefixIcon: prefix,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, 
        width: 1.5
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.5), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(
        color: primaryColor.withValues(alpha: 0.6),
        width: 1.5,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(color: primaryColor, width: 2),
    ),
  );
}

Widget fieldLabel(String text) => Builder(
  builder: (context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : const Color(0xFF00022E),
      ),
    );
  }
);

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btnColor = isDark ? const Color(0xFF7367F0) : const Color(0xFF00022E);

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: btnColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
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
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
    );
  }
}

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DropdownButtonFormField<String>(
      initialValue: value,
      validator: validator,
      decoration: pillInputDecoration(
        context: context,
      ),
      hint: Text(
        hint,
        style: TextStyle(
          color: isDark ? const Color(0xB3FFFFFF) : const Color(0x8A000000), 
          fontSize: 13
        ),
      ),
      icon: Icon(
        Icons.keyboard_arrow_down, 
        color: isDark ? Colors.white70 : Colors.grey.shade500
      ),
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87, 
        fontSize: 13
      ),
      dropdownColor: isDark ? const Color(0xFF14141D) : Colors.white,
      items: items
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(
                s,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}