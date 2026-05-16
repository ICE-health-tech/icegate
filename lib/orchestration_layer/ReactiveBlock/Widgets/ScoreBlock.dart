import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:signals/signals.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Widgets/ScoreData.dart';
import 'package:rxdart/rxdart.dart';

part 'ScoreBlockState.dart';
part 'ScoreBlockInit.dart';
part 'ScoreBlockActions.dart';

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
      batch(() {
        updateScore(initialScore);
      });
    }
  }

  ScoreData get score => _score.value;

  void updateScore(ScoreData scoreValue) {
    _updateScoreSubject.add(scoreValue);
  }

  void _processScoreUpdate(ScoreData scoreValue) {
    untracked(() {
      _score.value = scoreValue;
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

    _score.dispose();
    // Computed signals are automatically managed
    _latestMeals.dispose();
    _latestAccounts.dispose();
    _latestAssets.dispose();
    _latestTransactions.dispose();
    _updateScoreSubject.close();
  }
}
