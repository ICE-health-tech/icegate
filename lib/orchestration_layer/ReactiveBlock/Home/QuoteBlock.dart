import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:signals/signals.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/Services/MindWeeklyTopicPrefs.dart';
import 'package:ice_gate/orchestration_layer/Services/MorningLoopPrefs.dart';

class WeeklyTopicView {
  const WeeklyTopicView({
    required this.quoteId,
    required this.topicTitle,
    required this.content,
    this.author,
  });

  final String quoteId;
  final String topicTitle;
  final String content;
  final String? author;
}

class QuoteBlock {
  final currentQuote = signal<String>(
    "The only way to do great work is to love what you do.",
  );
  final currentAuthor = signal<String?>("");
  final weeklyTopic = signal<WeeklyTopicView?>(null);

  StreamSubscription? _quotesSubscription;
  Timer? _rotationTimer;
  List<QuoteData> _cachedQuotes = [];
  int _currentIndex = 0;
  bool _morningMotivationActive = false;
  QuoteDAO? _dao;
  String? _weeklyLoadedForPerson;

  static const _defaultQuotes = [
    "The only way to do great work is to love what you do.",
    "Innovation distinguishes between a leader and a follower.",
    "Stay hungry, stay foolish.",
    "Your time is limited, don't waste it living someone else's life.",
    "Design is not just what it looks like and feels like. Design is how it works.",
  ];

  void init(QuoteDAO dao) {
    _dao = dao;
    unawaited(_restoreMorningQuote());

    _quotesSubscription?.cancel();
    _quotesSubscription = dao.watchActiveQuotes().listen((quotes) {
      _cachedQuotes = quotes;
      _pickQuoteByHour();
    });

    // Rotate every hour
    _rotationTimer?.cancel();
    _rotationTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _pickQuoteByHour();
    });
  }

  Future<void> _restoreMorningQuote() async {
    final text = await MorningLoopPrefs.loadMorningHomeQuoteIfToday();
    if (text == null || text.isEmpty) return;
    _morningMotivationActive = true;
    _deferQuoteUpdate(() {
      currentQuote.value = text;
      currentAuthor.value = null;
    });
  }

  /// Replaces the home quote strip after the morning briefing.
  Future<void> setMorningMotivation(String text) async {
    _morningMotivationActive = true;
    currentQuote.value = text;
    currentAuthor.value = null;
    await MorningLoopPrefs.saveMorningHomeQuote(text);
  }

  void _deferQuoteUpdate(void Function() apply) {
    untracked(() {
      scheduleMicrotask(() {
        untracked(apply);
      });
    });
  }

  void _pickQuoteByHour() {
    if (_morningMotivationActive) return;

    _deferQuoteUpdate(() {
      if (_morningMotivationActive) return;

      final hourKey = DateTime.now().hour + DateTime.now().day * 24;

      if (_cachedQuotes.isNotEmpty) {
        _currentIndex = hourKey % _cachedQuotes.length;
        final q = _cachedQuotes[_currentIndex];
        currentQuote.value = q.content;
        currentAuthor.value = q.author;
      } else {
        _currentIndex = hourKey % _defaultQuotes.length;
        currentQuote.value = _defaultQuotes[_currentIndex];
        currentAuthor.value = null;
      }
    });
  }

  /// Loads pinned Mind dashboard weekly topic from prefs + quotes table.
  Future<void> loadWeeklyTopic(String personId) async {
    if (personId.isEmpty) {
      weeklyTopic.value = null;
      _weeklyLoadedForPerson = null;
      return;
    }
    if (_weeklyLoadedForPerson == personId) return;
    _weeklyLoadedForPerson = personId;

    final dao = _dao;
    if (dao == null) {
      weeklyTopic.value = null;
      return;
    }

    final row = await dao.getFocusWeekQuote(personId);
    if (row == null) {
      weeklyTopic.value = null;
      return;
    }

    final prefs = await MindWeeklyTopicPrefs.load(personId);

    weeklyTopic.value = WeeklyTopicView(
      quoteId: row.id,
      topicTitle: prefs?.topicTitle ?? '',
      content: row.content,
      author: row.author,
    );
  }

  /// Creates or updates the weekly topic row in [quotes] and pins it for Mind.
  Future<void> saveWeeklyTopic({
    required String personId,
    required String topicTitle,
    required String content,
    String? author,
  }) async {
    final dao = _dao;
    if (dao == null || personId.isEmpty) return;

    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) return;

    final trimmedTopic = topicTitle.trim();
    final resolvedTopic =
        trimmedTopic.isEmpty ? trimmedContent : trimmedTopic;
    final trimmedAuthor = author?.trim();
    final resolvedAuthor =
        trimmedAuthor == null || trimmedAuthor.isEmpty ? null : trimmedAuthor;

    final existing = await dao.getFocusWeekQuote(personId);
    late final String quoteId;

    if (existing != null) {
      quoteId = existing.id;
      await dao.updateQuote(
        existing.copyWith(
          content: trimmedContent,
          author: Value(resolvedAuthor),
          typeQuote: Value(QuoteType.focusWeek),
        ),
      );
    } else {
      quoteId = IDGen.UUIDV7();
      await dao.insertQuote(
        QuotesTableCompanion.insert(
          id: quoteId,
          content: trimmedContent,
          author: Value(resolvedAuthor),
          personID: Value(personId),
          typeQuote: Value(QuoteType.focusWeek),
        ),
      );
    }

    await MindWeeklyTopicPrefs.save(
      personId: personId,
      quoteId: quoteId,
      topicTitle: resolvedTopic,
    );

    weeklyTopic.value = WeeklyTopicView(
      quoteId: quoteId,
      topicTitle: resolvedTopic,
      content: trimmedContent,
      author: resolvedAuthor,
    );
    _weeklyLoadedForPerson = personId;
  }

  void shuffle() {
    _morningMotivationActive = false;
    unawaited(MorningLoopPrefs.clearMorningHomeQuote());

    if (_cachedQuotes.isNotEmpty) {
      _currentIndex = Random().nextInt(_cachedQuotes.length);
      final q = _cachedQuotes[_currentIndex];
      currentQuote.value = q.content;
      currentAuthor.value = q.author;
    } else {
      _currentIndex = Random().nextInt(_defaultQuotes.length);
      currentQuote.value = _defaultQuotes[_currentIndex];
      currentAuthor.value = null;
    }
  }

  void dispose() {
    _quotesSubscription?.cancel();
    _rotationTimer?.cancel();
  }
}
