import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';

Color achievementDomainRingColor(String domain) {
  switch (domain.toLowerCase()) {
    case 'health':
      return Colors.greenAccent;
    case 'finance':
      return Colors.amberAccent;
    case 'relationship':
      return Colors.pinkAccent;
    case 'knowledge':
      return Colors.deepPurpleAccent;
    case 'good social impact':
      return Colors.cyanAccent;
    default:
      return Colors.lightBlueAccent;
  }
}

bool achievementIsPhotoStory(AchievementData a) {
  final path = a.localImagePath;
  return path != null && path.trim().isNotEmpty;
}

List<AchievementData> achievementPhotoStories(List<AchievementData> all) {
  return all.where(achievementIsPhotoStory).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

List<AchievementData> achievementLoggedFeats(List<AchievementData> all) {
  return all.where((a) => !achievementIsPhotoStory(a)).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
