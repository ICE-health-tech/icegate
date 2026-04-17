import 'package:flutter/material.dart';

enum SocialPlatform {
  instagram('Instagram', 'https://instagram.com', Icons.camera_alt_rounded),
  tiktok('TikTok', 'https://tiktok.com', Icons.music_note_rounded),
  facebook('Facebook', 'https://facebook.com', Icons.facebook_rounded),
  x('X (Twitter)', 'https://x.com', Icons.close_rounded),
  youtube('YouTube', 'https://youtube.com', Icons.play_circle_fill_rounded),
  reddit('Reddit', 'https://reddit.com', Icons.reddit_rounded),
  zalo('Zalo', 'https://zalo.me', Icons.chat_rounded),
  custom('Custom', '', Icons.link_rounded);

  final String name;
  final String domain;
  final IconData icon;
  const SocialPlatform(this.name, this.domain, this.icon);
}

enum ChallengeType {
  none('None', Icons.block_rounded),
  math('Math Problem', Icons.calculate_rounded),
  typing('Typing Phrase', Icons.keyboard_rounded);

  final String name;
  final IconData icon;
  const ChallengeType(this.name, this.icon);
}

enum ChallengeLevel {
  easy('Easy', Colors.green),
  normal('Normal', Colors.orange),
  hard('Hard', Colors.red);

  final String name;
  final Color color;
  const ChallengeLevel(this.name, this.color);
}

class SocialBlockRule {
  final String id;
  final String ruleName;
  final SocialPlatform platform;
  final bool isEnabled;
  final bool blockDuringFocus;
  final TimeOfDay? scheduleStart;
  final TimeOfDay? scheduleEnd;
  final List<int> blockedDays; // 1=Mon, 7=Sun
  final ChallengeType challengeType;
  final ChallengeLevel challengeLevel;
  final int? _totalChallenges;
  final int? _challengesPassed;

  int get totalChallenges => _totalChallenges ?? 0;
  int get challengesPassed => _challengesPassed ?? 0;

  SocialBlockRule({
    required this.id,
    this.ruleName = '',
    required this.platform,
    this.isEnabled = true,
    this.blockDuringFocus = true,
    this.scheduleStart,
    this.scheduleEnd,
    this.blockedDays = const [1, 2, 3, 4, 5, 6, 7],
    this.challengeType = ChallengeType.none,
    this.challengeLevel = ChallengeLevel.normal,
    int totalChallenges = 0,
    int challengesPassed = 0,
  })  : _totalChallenges = totalChallenges,
        _challengesPassed = challengesPassed;

  String get displayName => ruleName.isNotEmpty ? ruleName : platform.name;

  double get successRate => totalChallenges > 0 ? (challengesPassed / totalChallenges) : 0.0;

  SocialBlockRule copyWith({
    String? id,
    String? ruleName,
    SocialPlatform? platform,
    bool? isEnabled,
    bool? blockDuringFocus,
    TimeOfDay? scheduleStart,
    TimeOfDay? scheduleEnd,
    List<int>? blockedDays,
    ChallengeType? challengeType,
    ChallengeLevel? challengeLevel,
    int? totalChallenges,
    int? challengesPassed,
  }) {
    return SocialBlockRule(
      id: id ?? this.id,
      ruleName: ruleName ?? this.ruleName,
      platform: platform ?? this.platform,
      isEnabled: isEnabled ?? this.isEnabled,
      blockDuringFocus: blockDuringFocus ?? this.blockDuringFocus,
      scheduleStart: scheduleStart ?? this.scheduleStart,
      scheduleEnd: scheduleEnd ?? this.scheduleEnd,
      blockedDays: blockedDays ?? this.blockedDays,
      challengeType: challengeType ?? this.challengeType,
      challengeLevel: challengeLevel ?? this.challengeLevel,
      totalChallenges: totalChallenges ?? this.totalChallenges,
      challengesPassed: challengesPassed ?? this.challengesPassed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ruleName': ruleName,
      'platform': platform.name,
      'isEnabled': isEnabled,
      'blockDuringFocus': blockDuringFocus,
      'scheduleStart':
          scheduleStart != null
              ? '${scheduleStart!.hour}:${scheduleStart!.minute}'
              : null,
      'scheduleEnd':
          scheduleEnd != null
              ? '${scheduleEnd!.hour}:${scheduleEnd!.minute}'
              : null,
      'blockedDays': blockedDays,
      'challengeType': challengeType.name,
      'challengeLevel': challengeLevel.name,
      'totalChallenges': totalChallenges,
      'challengesPassed': challengesPassed,
    };
  }

  factory SocialBlockRule.fromJson(Map<String, dynamic> json) {
    return SocialBlockRule(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      ruleName: json['ruleName'] ?? '',
      platform: SocialPlatform.values.firstWhere(
        (e) => e.name == json['platform'],
        orElse: () => SocialPlatform.custom,
      ),
      isEnabled: json['isEnabled'] ?? true,
      blockDuringFocus: json['blockDuringFocus'] ?? true,
      scheduleStart:
          json['scheduleStart'] != null ? _parseTime(json['scheduleStart']) : null,
      scheduleEnd:
          json['scheduleEnd'] != null ? _parseTime(json['scheduleEnd']) : null,
      blockedDays: List<int>.from(json['blockedDays'] ?? [1, 2, 3, 4, 5, 6, 7]),
      challengeType: ChallengeType.values.firstWhere(
        (e) => e.name == json['challengeType'],
        orElse: () => ChallengeType.none,
      ),
      challengeLevel: ChallengeLevel.values.firstWhere(
        (e) => e.name == json['challengeLevel'],
        orElse: () => ChallengeLevel.normal,
      ),
      totalChallenges: (json['totalChallenges'] as num?)?.toInt() ?? 0,
      challengesPassed: (json['challengesPassed'] as num?)?.toInt() ?? 0,
    );
  }

  static TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
