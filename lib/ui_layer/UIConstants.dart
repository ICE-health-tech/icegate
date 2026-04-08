import 'package:ice_gate/ui_layer/ReusableWidget/UIResponsiveManager.dart';
import 'package:flutter/widgets.dart';

/// @deprecated Use UIResponsiveManager instead.
/// This class is maintained for backward compatibility.
class UIConstants {
  static const double widgetBorderWidth = UIResponsiveManager.widgetBorderWidth;
  static const double largeBorderWidth = UIResponsiveManager.largeBorderWidth;
  static const double thresholdPercentage = UIResponsiveManager.thresholdPercentage;

  static const double widgetSizePercentage = UIResponsiveManager.widgetSizePercentage;
  static const double minWidgetSize = UIResponsiveManager.minWidgetSize;
  static const double maxWidgetSize = UIResponsiveManager.maxWidgetSize;

  static double getSizeOfWidget(BuildContext context) => UIResponsiveManager.getSizeOfWidget(context);
  static double getSizeOfDepartment(BuildContext context) => UIResponsiveManager.getSizeOfDepartment(context);
  static double getBorderWidth(BuildContext context, double width, [double? height]) => UIResponsiveManager.getBorderWidth(context, width, height);
  
  static double getTimerTrackSize(BuildContext context) => UIResponsiveManager.getTimerTrackSize(context);
  static double getTimerContainerSize(BuildContext context) => UIResponsiveManager.getTimerContainerSize(context);
  static double getTimerRippleSize(BuildContext context) => UIResponsiveManager.getTimerRippleSize(context);

  static double getResponsiveFontSize(BuildContext context, {double factor = 0.02, double min = 10.0, double max = 30.0}) => 
    UIResponsiveManager.getResponsiveFontSize(context, factor: factor, min: min, max: max);

  static double getChartContainerHeight(BuildContext context) => UIResponsiveManager.getChartContainerHeight(context);
  static double getChartBarMaxHeight(BuildContext context) => UIResponsiveManager.getChartBarMaxHeight(context);
  static double getChartBarWidth(BuildContext context) => UIResponsiveManager.getChartBarWidth(context);
}
