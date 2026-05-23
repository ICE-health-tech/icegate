import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'HealthMetricProtocol.freezed.dart';

/// UI model for a single health dashboard tile (steps, sleep, weight, etc.).
@freezed
abstract class HealthMetricProtocol with _$HealthMetricProtocol {
  const factory HealthMetricProtocol({
    required String id,
    required String name,
    required String value,
    required IconData icon,
    required Color color,
    required String unit,
    String? detailPage,
    double? progress,
    String? subtitle,
    String? trend,
    bool? trendPositive,
    @Default(false) bool isFuture,
    @Default(false) bool isLoading,
    String? availabilityMessage,
    String? source,
    IconData? sourceIcon,
  }) = _HealthMetricProtocol;
}
