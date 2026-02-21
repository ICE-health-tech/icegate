import 'package:flutter/widgets.dart';

class UIConstants {
  static const double widgetBorderWidth = 7.0;
  static const double largeBorderWidth = 10.0;
  static const double thresholdPercentage = 0.4;

  static const double widgetSizePercentage = 0.3;
  static const double minWidgetSize = 100.0;
  static const double maxWidgetSize = 200.0;

  static double getSizeOfWidget(BuildContext context) {
    double size = MediaQuery.of(context).size.width * widgetSizePercentage;
    return size.clamp(minWidgetSize, maxWidgetSize);
  }

  static double getSizeOfDepartment(BuildContext context) {
    // If screen width is small (phone), use 222, else 222
    // Increased from 190.0 to 222.0 to accommodate 4 metrics grid
    return MediaQuery.of(context).size.width < 600 ? 222.0 : 222.0;
  }

  static double getBorderWidth(
    BuildContext context,
    double width, [
    double? height,
  ]) {
    // Threshold calculation based on screen width percentage
    final double threshold =
        MediaQuery.of(context).size.width * thresholdPercentage;

    if (width > threshold || (height != null && height > threshold)) {
      return largeBorderWidth;
    }
    return widgetBorderWidth;
  }

  // Timer Dimensions
  // Base sizes for Phone
  static const double _baseTimerSize = 240.0; // Inner track
  static const double _baseOuterRingSize = 320.0; // Glow/Container
  static const double _baseRippleSize = 600.0; // Pulse effect

  // Base sizes for Tablet/Desktop
  static const double _tabletTimerSize = 340.0;
  static const double _tabletOuterRingSize = 440.0;
  static const double _tabletRippleSize = 800.0;

  static double getTimerTrackSize(BuildContext context) {
    return MediaQuery.of(context).size.width < 600
        ? _baseTimerSize
        : _tabletTimerSize;
  }

  static double getTimerContainerSize(BuildContext context) {
    return MediaQuery.of(context).size.width < 600
        ? _baseOuterRingSize
        : _tabletOuterRingSize;
  }

  static double getTimerRippleSize(BuildContext context) {
    return MediaQuery.of(context).size.width < 600
        ? _baseRippleSize
        : _tabletRippleSize;
  }

  static double getResponsiveFontSize(
    BuildContext context, {
    double factor = 0.02,
    double min = 10.0,
    double max = 30.0,
  }) {
    return (MediaQuery.of(context).size.width * factor).clamp(min, max);
  }
}
