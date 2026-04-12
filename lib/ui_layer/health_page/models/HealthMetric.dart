import 'package:flutter/material.dart';

/// Data model representing a health metric
class HealthMetric {
  final String id;
  final String name;
  final String value;
  final IconData icon;
  final Color color;
  final String unit;
  final String? trend; // e.g., "+5%", "-2%"
  final bool? trendPositive; // true if trend is good, false if bad
  final bool isFuture;
  final String? detailPage;
  final double? progress;
  final String? subtitle;
  final String? availabilityMessage; // e.g., "Apple Watch Required"

  const HealthMetric({
    required this.id,
    required this.name,
    required this.value,
    required this.icon,
    required this.color,
    required this.unit,
    this.detailPage,
    this.progress,
    this.subtitle,
    this.trend,
    this.trendPositive,
    this.isFuture = false,
    this.availabilityMessage,
  });

  /// Creates a copy with updated values
  HealthMetric copyWith({
    String? id,
    String? name,
    String? value,
    IconData? icon,
    Color? color,
    String? unit,
    String? detailPage,
    double? progress,
    String? subtitle,
    String? trend,
    bool? trendPositive,
    bool? isFuture,
    String? availabilityMessage,
  }) {
    return HealthMetric(
      id: id ?? this.id,
      name: name ?? this.name,
      value: value ?? this.value,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      unit: unit ?? this.unit,
      detailPage: detailPage ?? this.detailPage,
      progress: progress ?? this.progress,
      subtitle: subtitle ?? this.subtitle,
      trend: trend ?? this.trend,
      trendPositive: trendPositive ?? this.trendPositive,
      isFuture: isFuture ?? this.isFuture,
      availabilityMessage: availabilityMessage ?? this.availabilityMessage,
    );
  }
}
