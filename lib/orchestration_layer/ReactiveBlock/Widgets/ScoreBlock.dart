import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/orchestration_layer/Services/GamificationService.dart';
import 'package:ice_gate/orchestration_layer/Services/PowerPoint/GameConst.dart';
import 'package:signals/signals.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Widgets/ScoreData.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:rxdart/rxdart.dart';


part 'ScoreBlock_State.dart';
part 'ScoreBlock_Init.dart';
part 'ScoreBlock_Actions.dart';

class ScoreBlock with ScoreBlockState {
  final _updateScoreSubject = PublishSubject<ScoreData>();

  ScoreBlock({ScoreData? initialScore}) {
    // 0. Listen to score updates via RxDart to decouple from reactive scopes
    _subscriptions.add(
      _updateScoreSubject
          .debounceTime(const Duration(milliseconds: 50))
          .listen(_processScoreUpdate),
    );

    if (initialScore != null) {
      updateScore(initialScore);
    }
  }

  ScoreData get score => _score.value;

  void updateScore(ScoreData scoreValue) {
    _updateScoreSubject.add(scoreValue);
  }

  void _processScoreUpdate(ScoreData scoreValue) {
    untracked(() {
      batch(() {
        // 1. Update the primary signal
        _score.value = scoreValue;

        // 2. Calculate local variables
        final double xp = scoreValue.healthGlobalScore +
            scoreValue.socialGlobalScore +
            scoreValue.financialGlobalScore +
            scoreValue.careerGlobalScore;

        final double avg = xp / 4;
        final int level = GamificationService.getLevel(xp.toInt());
        final double progress = GamificationService.getProgressToNextLevel(
          xp.toInt(),
        );

        // 3. Update related signals
        totalXP.value = xp;
        averageScore.value = avg;
        globalLevel.value = level;
        levelProgress.value = progress;
      });
    });
  }

  void dispose() {
    for (var s in _subscriptions) {
      if (s is StreamSubscription) {
        s.cancel();
      } else if (s is void Function()) {
        s();
      }
    }
    _subscriptions.clear();
    _scoreUpdateTimer?.cancel();
    _todaySocialUpdateTimer?.cancel();
    _healthUpdateSubject.close();
    _careerUpdateSubject.close();
    _financeUpdateSubject.close();
    _mindUpdateSubject.close();
    _score.dispose();
    averageScore.dispose();
    totalXP.dispose();
    globalLevel.dispose();
    levelProgress.dispose();
    rankTitle.dispose();
    _latestMeals.dispose();
    _totalHealthQuestPoints.dispose();
    _totalSocialQuestPoints.dispose();
    _totalProjectQuestPoints.dispose();
    _totalFinanceQuestPoints.dispose();
    _historicalHealthMetricPoints.dispose();
    todayHealthPoints.dispose();
    todaySocialPoints.dispose();
    todayFinancePoints.dispose();
    todayProjectPoints.dispose();
    _latestAccounts.dispose();
    _latestAssets.dispose();
    _latestTransactions.dispose();
    _updateScoreSubject.close();
  }
}

