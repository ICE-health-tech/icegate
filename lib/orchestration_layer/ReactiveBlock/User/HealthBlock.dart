import 'dart:async';
import 'dart:io' show Platform;
import 'package:health/health.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:ice_gate/sensor_layer/phone_sensor/AppleHealthServices.dart';
import 'package:ice_gate/sensor_layer/phone_sensor/HealthSourceService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart'
    show
        HealthLogsDAO,
        HealthMealDAO,
        HealthMetricsDAO,
        HealthMetricsTableCompanion,
        HourlyActivityLogDAO,
        HourlyActivityLogTableCompanion,
        WaterLogsTableCompanion,
        WeightLogsTableCompanion,
        HeartRateLogsTableCompanion,
        OxygenSaturationLogsTableCompanion,
        OxygenSaturationLogData,
        SleepLogsTableCompanion;
import 'package:ice_gate/data_layer/DataSources/local_database/DataSeeder.dart';
import 'package:rxdart/rxdart.dart';
import 'package:signals/signals.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';

part 'HealthBlock_State.dart';
part 'HealthBlock_Init.dart';
part 'HealthBlock_Sync.dart';
part 'HealthBlock_Actions.dart';

class HealthBlock with HealthBlockState {
  String personId;
  final HealthMetricsDAO _healthDao;
  final HourlyActivityLogDAO _hourlyLogDao;
  final HealthLogsDAO _healthLogsDao;
  final HealthMealDAO _healthMealDao;

  StreamSubscription? _metricsSubscription;
  StreamSubscription? _hourlyLogsSubscription;
  StreamSubscription? _waterSubscription;
  StreamSubscription? _mealSubscription;
  StreamSubscription? _exerciseSubscription;
  StreamSubscription? _weightSubscription;
  Timer? _realtimeSyncTimer;

  String? _initializedPersonId;

  /// When > 0, the next [watchDailyCalories]–driven [\_saveCaloriesConsumed] skips Supabase.
  int _mealDerivedMetricsCloudSkipCount = 0;

  HealthBlock({
    required String personId,
    required HealthMetricsDAO healthDao,
    required HealthLogsDAO healthLogsDao,
    required HealthMealDAO healthMealDao,
    required HourlyActivityLogDAO hourlyLogDao,
  }) : personId = personId,
       _healthDao = healthDao,
       _healthLogsDao = healthLogsDao,
       _healthMealDao = healthMealDao,
       _hourlyLogDao = hourlyLogDao;

  bool get _isDesktop =>
      kIsWeb || Platform.isMacOS || Platform.isWindows || Platform.isLinux;
}
