import 'dart:async';
import 'dart:math';
import 'package:signals/signals.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/Services/MorningLoopPrefs.dart';

class QuoteBlock {
  final currentQuote = signal<String>(
    "The only way to do great work is to love what you do.",
  );
  final currentAuthor = signal<String?>("");

  StreamSubscription? _quotesSubscription;
  Timer? _rotationTimer;
  List<QuoteData> _cachedQuotes = [];
  int _currentIndex = 0;
  bool _morningMotivationActive = false;

  static const _defaultQuotes = [
    "The only way to do great work is to love what you do.",
    "Innovation distinguishes between a leader and a follower.",
    "Stay hungry, stay foolish.",
    "Your time is limited, don't waste it living someone else's life.",
    "Design is not just what it looks like and feels like. Design is how it works.",
  ];

  void init(QuoteDAO dao) {
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
    currentQuote.value = text;
    currentAuthor.value = null;
  }

  /// Replaces the home quote strip after the morning briefing.
  Future<void> setMorningMotivation(String text) async {
    _morningMotivationActive = true;
    currentQuote.value = text;
    currentAuthor.value = null;
    await MorningLoopPrefs.saveMorningHomeQuote(text);
  }

  void _pickQuoteByHour() {
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
