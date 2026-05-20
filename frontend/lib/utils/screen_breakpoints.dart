import 'package:flutter/material.dart';

/// Screen size breakpoints for responsive design
class ScreenBreakpoints {
  // Breakpoint thresholds
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1024;
  static const double ultraWide = 1440;

  // Get responsive instance for method chaining
  static _ScreenBreakpointsInstance of(BuildContext context) =>
      _ScreenBreakpointsInstance(context);

  // Get device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    return getDeviceTypeFromWidth(MediaQuery.of(context).size.width);
  }

  static DeviceType getDeviceTypeFromWidth(double width) {
    if (width < mobile) return DeviceType.mobile;
    if (width < tablet) return DeviceType.tablet;
    if (width < ultraWide) return DeviceType.desktop;
    return DeviceType.ultraWide;
  }

  // Check if device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }

  // Check if device is tablet
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= mobile &&
        MediaQuery.of(context).size.width < tablet;
  }

  // Check if device is desktop or larger
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }

  // Check if device is ultra-wide
  static bool isUltraWide(BuildContext context) {
    return MediaQuery.of(context).size.width >= ultraWide;
  }

  // Check if landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  // Check if portrait orientation
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  // Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  // Get screen width
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  // Get screen height
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Get usable height (excludes status bar and navigation bar)
  static double getUsableHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.height - mediaQuery.padding.top;
  }

  // Sidebar width based on device type
  static double getSidebarWidth(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 0; // Drawer instead of sidebar
      case DeviceType.tablet:
        return 200;
      case DeviceType.desktop:
      case DeviceType.ultraWide:
        return 250;
    }
  }

  // Max content width for centered layouts
  static double getMaxContentWidth(BuildContext context) {
    final width = getScreenWidth(context);
    const maxWidth = 1200.0;
    return width < maxWidth ? width : maxWidth;
  }

  // Responsive card width
  static double getCardWidth(BuildContext context, int columnCount) {
    final width = getScreenWidth(context);
    final padding = getHorizontalPadding(context);
    final availableWidth = width - padding;
    const cardSpacing = 16.0; // Gap between cards
    final totalGaps = (columnCount - 1) * cardSpacing;
    return (availableWidth - totalGaps) / columnCount;
  }

  // Responsive padding
  static double getHorizontalPadding(BuildContext context) {
    return getResponsivePadding(context);
  }

  static double getResponsivePadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 16;
      case DeviceType.tablet:
        return 24;
      case DeviceType.desktop:
        return 32;
      case DeviceType.ultraWide:
        return 48;
    }
  }

  // Responsive font sizes
  static double getTitleFontSize(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 20;
      case DeviceType.tablet:
        return 24;
      case DeviceType.desktop:
      case DeviceType.ultraWide:
        return 28;
    }
  }

  static double getSubtitleFontSize(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 14;
      case DeviceType.tablet:
        return 16;
      case DeviceType.desktop:
      case DeviceType.ultraWide:
        return 18;
    }
  }

  static double getBodyFontSize(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 12;
      case DeviceType.tablet:
        return 13;
      case DeviceType.desktop:
      case DeviceType.ultraWide:
        return 14;
    }
  }

  // Avatar sizes
  static double getAvatarRadius(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 48;
      case DeviceType.tablet:
        return 56;
      case DeviceType.desktop:
      case DeviceType.ultraWide:
        return 68;
    }
  }

  static double getSmallAvatarRadius(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 20;
      case DeviceType.tablet:
        return 24;
      case DeviceType.desktop:
      case DeviceType.ultraWide:
        return 28;
    }
  }
}

enum DeviceType {
  mobile,
  tablet,
  desktop,
  ultraWide,
}

/// Responsive instance wrapper for easier method chaining
class _ScreenBreakpointsInstance {
  final BuildContext context;
  _ScreenBreakpointsInstance(this.context);

  DeviceType get deviceType => ScreenBreakpoints.getDeviceType(context);
  bool get isMobile => ScreenBreakpoints.isMobile(context);
  bool get isTablet => ScreenBreakpoints.isTablet(context);
  bool get isDesktop => ScreenBreakpoints.isDesktop(context);
  bool get isUltraWide => ScreenBreakpoints.isUltraWide(context);
  bool get isLandscape => ScreenBreakpoints.isLandscape(context);
  bool get isPortrait => ScreenBreakpoints.isPortrait(context);

  double get screenWidth => ScreenBreakpoints.getScreenWidth(context);
  double get screenHeight => ScreenBreakpoints.getScreenHeight(context);
  double get usableHeight => ScreenBreakpoints.getUsableHeight(context);

  double get horizontalPadding => ScreenBreakpoints.getHorizontalPadding(context);
  double get responsivePadding => ScreenBreakpoints.getResponsivePadding(context);

  double get sidebarWidth => ScreenBreakpoints.getSidebarWidth(context);
  double get maxContentWidth => ScreenBreakpoints.getMaxContentWidth(context);

  double get titleFontSize => ScreenBreakpoints.getTitleFontSize(context);
  double get subtitleFontSize => ScreenBreakpoints.getSubtitleFontSize(context);
  double get bodyFontSize => ScreenBreakpoints.getBodyFontSize(context);

  double get avatarRadius => ScreenBreakpoints.getAvatarRadius(context);
  double get smallAvatarRadius => ScreenBreakpoints.getSmallAvatarRadius(context);
}

/// Extension on BuildContext for easier access
extension ResponsiveContext on BuildContext {
  DeviceType get deviceType => ScreenBreakpoints.getDeviceType(this);
  bool get isMobile => ScreenBreakpoints.isMobile(this);
  bool get isTablet => ScreenBreakpoints.isTablet(this);
  bool get isDesktop => ScreenBreakpoints.isDesktop(this);
  bool get isUltraWide => ScreenBreakpoints.isUltraWide(this);
  bool get isLandscape => ScreenBreakpoints.isLandscape(this);
  bool get isPortrait => ScreenBreakpoints.isPortrait(this);

  double get screenWidth => ScreenBreakpoints.getScreenWidth(this);
  double get screenHeight => ScreenBreakpoints.getScreenHeight(this);
  double get usableHeight => ScreenBreakpoints.getUsableHeight(this);

  double get horizontalPadding => ScreenBreakpoints.getHorizontalPadding(this);
  double get responsivePadding => ScreenBreakpoints.getResponsivePadding(this);

  double get sidebarWidth => ScreenBreakpoints.getSidebarWidth(this);
  double get maxContentWidth => ScreenBreakpoints.getMaxContentWidth(this);

  double get titleFontSize => ScreenBreakpoints.getTitleFontSize(this);
  double get subtitleFontSize => ScreenBreakpoints.getSubtitleFontSize(this);
  double get bodyFontSize => ScreenBreakpoints.getBodyFontSize(this);

  double get avatarRadius => ScreenBreakpoints.getAvatarRadius(this);
  double get smallAvatarRadius => ScreenBreakpoints.getSmallAvatarRadius(this);
}
