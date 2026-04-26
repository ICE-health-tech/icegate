import 'package:flutter/material.dart';

enum DeviceType { phone, tablet, laptop, desktop }

class UIResponsiveManager {
  static const double phoneMax = 500;
  static const double tabletMax = 1024;
  static const double laptopMax = 1440;

  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < phoneMax) return DeviceType.phone;
    if (width < tabletMax) return DeviceType.tablet;
    if (width < laptopMax) return DeviceType.laptop;
    return DeviceType.desktop;
  }

  static bool isPhoneValue(BuildContext context) =>
      getDeviceType(context) == DeviceType.phone;
  static bool isTabletValue(BuildContext context) =>
      getDeviceType(context) == DeviceType.tablet;
  static bool isLaptopValue(BuildContext context) =>
      getDeviceType(context) == DeviceType.laptop;
  static bool isDesktopValue(BuildContext context) =>
      getDeviceType(context) == DeviceType.desktop;

  static double get screenWidth => MediaQuery.of(_context!).size.width;
  static double get screenHeight => MediaQuery.of(_context!).size.height;
  static double get shortestSide => MediaQuery.of(_context!).size.shortestSide;
  static double get longestSide => MediaQuery.of(_context!).size.longestSide;

  static BuildContext? _context;
  static void setContext(BuildContext context) => _context = context;

  // --- Merged from UIConstants ---
  static const double widgetBorderWidth = 7.0;
  static const double largeBorderWidth = 10.0;
  static const double thresholdPercentage = 0.4;

  static const double widgetSizePercentage = 0.22;
  static const double minWidgetSize = 80.0;
  static const double maxWidgetSize = 160.0;

  static double getSizeOfWidget(BuildContext context) {
    double size = MediaQuery.of(context).size.width * widgetSizePercentage;
    return size.clamp(minWidgetSize, maxWidgetSize);
  }

  static double getSizeOfDepartment(BuildContext context) {
    return responsiveValue(
      context,
      phone: 205.0,
      tablet: 250.0,
      laptop: 280.0,
      desktop: 300.0,
    );
  }

  static double getBorderWidth(
    BuildContext context,
    double width, [
    double? height,
  ]) {
    final double threshold =
        MediaQuery.of(context).size.width * thresholdPercentage;
    if (width > threshold || (height != null && height > threshold)) {
      return largeBorderWidth;
    }
    return widgetBorderWidth;
  }

  // Timer Dimensions
  static double getTimerTrackSize(BuildContext context) {
    return responsiveValue(
      context,
      phone: 240.0,
      tablet: 340.0,
      laptop: 380.0,
      desktop: 420.0,
    );
  }

  static double getTimerContainerSize(BuildContext context) {
    return responsiveValue(
      context,
      phone: 320.0,
      tablet: 440.0,
      laptop: 480.0,
      desktop: 520.0,
    );
  }

  static double getTimerRippleSize(BuildContext context) {
    return responsiveValue(
      context,
      phone: 600.0,
      tablet: 800.0,
      laptop: 900.0,
      desktop: 1000.0,
    );
  }

  static double getResponsiveFontSize(
    BuildContext context, {
    double factor = 0.02,
    double min = 10.0,
    double max = 30.0,
  }) {
    return (MediaQuery.of(context).size.width * factor).clamp(min, max);
  }

  // Chart Dimensions
  static double getChartContainerHeight(BuildContext context) {
    return responsiveValue(
      context,
      phone: 180.0,
      tablet: 250.0,
      laptop: 280.0,
      desktop: 300.0,
    );
  }

  static double getChartBarMaxHeight(BuildContext context) {
    return responsiveValue(
      context,
      phone: 80.0,
      tablet: 120.0,
      laptop: 140.0,
      desktop: 160.0,
    );
  }

  static double getChartBarWidth(BuildContext context) {
    return responsiveValue(
      context,
      phone: 12.0,
      tablet: 20.0,
      laptop: 24.0,
      desktop: 28.0,
    );
  }
  // --- End Merged ---

  static T responsive<T>(
    BuildContext context, {
    required T phone,
    T? tablet,
    T? laptop,
    T? desktop,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.phone:
        return phone;
      case DeviceType.tablet:
        return tablet ?? phone;
      case DeviceType.laptop:
        return laptop ?? tablet ?? phone;
      case DeviceType.desktop:
        return desktop ?? laptop ?? tablet ?? phone;
    }
  }

  static double responsiveValue(
    BuildContext context, {
    required double phone,
    double? tablet,
    double? laptop,
    double? desktop,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.phone:
        return phone;
      case DeviceType.tablet:
        return tablet ?? phone;
      case DeviceType.laptop:
        return laptop ?? tablet ?? phone;
      case DeviceType.desktop:
        return desktop ?? laptop ?? tablet ?? phone;
    }
  }

  static double responsiveFontScale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < phoneMax) return 1.0;
    if (width < tabletMax) return 1.1;
    if (width < laptopMax) return 1.2;
    return 1.3;
  }

  static EdgeInsets padding(BuildContext context) {
    return responsive(
      context,
      phone: const EdgeInsets.all(12),
      tablet: const EdgeInsets.all(16),
      laptop: const EdgeInsets.all(20),
      desktop: const EdgeInsets.all(24),
    );
  }

  static EdgeInsets horizontalPadding(BuildContext context) {
    return responsive(
      context,
      phone: const EdgeInsets.symmetric(horizontal: 12),
      tablet: const EdgeInsets.symmetric(horizontal: 16),
      laptop: const EdgeInsets.symmetric(horizontal: 24),
      desktop: const EdgeInsets.symmetric(horizontal: 32),
    );
  }

  static EdgeInsets cardPadding(BuildContext context) {
    return responsive(
      context,
      phone: const EdgeInsets.all(12),
      tablet: const EdgeInsets.all(16),
      laptop: const EdgeInsets.all(20),
      desktop: const EdgeInsets.all(24),
    );
  }

  static double cardRadius(BuildContext context) {
    return responsiveValue(
      context,
      phone: 12,
      tablet: 16,
      laptop: 20,
      desktop: 24,
    );
  }

  static int gridCrossAxisCount(
    BuildContext context, {
    double minCellWidth = 200,
  }) {
    final width = MediaQuery.of(context).size.width;
    final padding = responsiveValue(
      context,
      phone: 24.0,
      tablet: 32.0,
      laptop: 48.0,
      desktop: 64.0,
    );
    final availableWidth = width - padding;
    return (availableWidth / minCellWidth).floor().clamp(1, 6);
  }

  static double buttonHeight(BuildContext context) {
    return responsiveValue(
      context,
      phone: 44,
      tablet: 48,
      laptop: 52,
      desktop: 56,
    );
  }

  static double iconSize(BuildContext context) {
    return responsiveValue(
      context,
      phone: 20,
      tablet: 24,
      laptop: 28,
      desktop: 32,
    );
  }

  static double appBarHeight(BuildContext context) {
    return responsiveValue(
      context,
      phone: 56,
      tablet: 64,
      laptop: 72,
      desktop: 80,
    );
  }

  static double bottomNavHeight(BuildContext context) {
    return responsiveValue(
      context,
      phone: 60,
      tablet: 72,
      laptop: 80,
      desktop: 80,
    );
  }

  static double fabSize(BuildContext context) {
    return responsiveValue(
      context,
      phone: 56,
      tablet: 64,
      laptop: 72,
      desktop: 80,
    );
  }

  static double inputFieldSpacing(BuildContext context, {double factor = 1.0}) {
    return responsiveValue(
      context,
      phone: 12 * factor,
      tablet: 12 * factor,
      laptop: 32 * factor,
      desktop: 32 * factor,
    );
  }

  static double horizontalSpacing(BuildContext context) {
    return responsiveValue(
      context,
      phone: 12,
      tablet: 16,
      laptop: 24,
      desktop: 32,
    );
  }

  static double verticalSpacing(BuildContext context) {
    return responsiveValue(
      context,
      phone: 8,
      tablet: 12,
      laptop: 16,
      desktop: 24,
    );
  }

  static double cardElevation(BuildContext context) {
    return responsiveValue(context, phone: 2, tablet: 4, laptop: 6, desktop: 8);
  }

  static double borderWidth(BuildContext context) {
    return responsiveValue(
      context,
      phone: 1,
      tablet: 1.5,
      laptop: 2,
      desktop: 2,
    );
  }

  static double avatarSize(BuildContext context) {
    return responsiveValue(
      context,
      phone: 40,
      tablet: 48,
      laptop: 56,
      desktop: 64,
    );
  }

  static double thumbnailSize(BuildContext context) {
    return responsiveValue(
      context,
      phone: 48,
      tablet: 56,
      laptop: 64,
      desktop: 80,
    );
  }

  static double get dialogWidth {
    return responsiveValue(
      _context!,
      phone: double.infinity,
      tablet: 500,
      laptop: 600,
      desktop: 700,
    );
  }

  static double get sheetMaxWidth {
    return responsiveValue(
      _context!,
      phone: double.infinity,
      tablet: 500,
      laptop: 600,
      desktop: 700,
    );
  }

  static double sheetRadius(BuildContext context) {
    return responsiveValue(
      context,
      phone: 16,
      tablet: 20,
      laptop: 24,
      desktop: 28,
    );
  }

  static bool showTwoPane(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletMax;
  }

  static double get twoPaneBreakpoint => tabletMax;
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;
  final Widget? phone;
  final Widget? tablet;
  final Widget? laptop;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
    this.phone,
    this.tablet,
    this.laptop,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = UIResponsiveManager.getDeviceType(context);

    Widget? child;
    switch (deviceType) {
      case DeviceType.phone:
        child = phone;
        break;
      case DeviceType.tablet:
        child = tablet ?? phone;
        break;
      case DeviceType.laptop:
        child = laptop ?? tablet ?? phone;
        break;
      case DeviceType.desktop:
        child = desktop ?? laptop ?? tablet ?? phone;
        break;
    }

    if (child != null) return child;
    return builder(context, deviceType);
  }
}

class ResponsiveWidget extends StatelessWidget {
  final Widget phone;
  final Widget tablet;
  final Widget? laptop;
  final Widget? desktop;

  const ResponsiveWidget({
    super.key,
    required this.phone,
    required this.tablet,
    this.laptop,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return UIResponsiveManager.responsive(
      context,
      phone: phone,
      tablet: tablet,
      laptop: laptop ?? tablet,
      desktop: desktop ?? laptop ?? tablet,
    );
  }
}
