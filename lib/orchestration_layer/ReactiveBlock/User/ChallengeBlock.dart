import 'dart:math';
import 'package:signals/signals.dart';
import 'package:ice_gate/data_layer/Protocol/Social/SocialBlockProtocol.dart';

class ChallengeState {
  final String question;
  final String? answer; // Only for math
  final String? phrase; // Only for typing
  final ChallengeType type;
  final ChallengeLevel level;

  ChallengeState({
    required this.question,
    this.answer,
    this.phrase,
    required this.type,
    required this.level,
  });
}

class ChallengeBlock {
  // Signals
  final activeChallenge = signal<ChallengeState?>(null);
  final isVerifying = signal<bool>(false);
  final error = signal<String?>(null);

  ChallengeBlock();

  void generateChallenge(ChallengeType type, ChallengeLevel level) {
    error.value = null;
    if (type == ChallengeType.math) {
      activeChallenge.value = _generateMath(level);
    } else if (type == ChallengeType.typing) {
      activeChallenge.value = _generateTyping(level);
    } else {
      activeChallenge.value = null;
    }
  }

  ChallengeState _generateMath(ChallengeLevel level) {
    final rand = Random();
    int a, b, c;
    String question;
    String answer;

    switch (level) {
      case ChallengeLevel.easy:
        a = rand.nextInt(20);
        b = rand.nextInt(20);
        question = "$a + $b";
        answer = (a + b).toString();
        break;
      case ChallengeLevel.normal:
        a = rand.nextInt(12) + 2;
        b = rand.nextInt(12) + 2;
        c = rand.nextInt(20);
        question = "($a × $b) + $c";
        answer = (a * b + c).toString();
        break;
      case ChallengeLevel.hard:
        a = rand.nextInt(20) + 5;
        b = rand.nextInt(15) + 5;
        c = rand.nextInt(50) + 10;
        question = "($a × $b) - $c";
        answer = (a * b - c).toString();
        break;
    }

    return ChallengeState(
      question: question,
      answer: answer,
      type: ChallengeType.math,
      level: level,
    );
  }

  ChallengeState _generateTyping(ChallengeLevel level) {
    final easyPhrases = [
      "I am focused.",
      "Today is a good day.",
      "Stay in the flow.",
    ];
    final normalPhrases = [
      "Discipline is the bridge between goals and accomplishment.",
      "Small steps every day lead to big results.",
      "Focus on the process, not just the outcome.",
    ];
    final hardPhrases = [
      "The only way to do great work is to love what you do, and to keep pushing through distractions.",
      "Excellence is not an act, but a habit. What we do repeatedly defines who we become.",
      "Your time is limited, so don't waste it living someone else's life or being trapped by distractions.",
    ];

    final rand = Random();
    String phrase;
    switch (level) {
      case ChallengeLevel.easy:
        phrase = easyPhrases[rand.nextInt(easyPhrases.length)];
        break;
      case ChallengeLevel.normal:
        phrase = normalPhrases[rand.nextInt(normalPhrases.length)];
        break;
      case ChallengeLevel.hard:
        phrase = hardPhrases[rand.nextInt(hardPhrases.length)];
        break;
    }

    return ChallengeState(
      question: "Type the phrase below exactly:",
      phrase: phrase,
      type: ChallengeType.typing,
      level: level,
    );
  }

  bool verify(String input) {
    final challenge = activeChallenge.value;
    if (challenge == null) return true;

    bool success = false;
    if (challenge.type == ChallengeType.math) {
      success = input.trim() == challenge.answer;
    } else if (challenge.type == ChallengeType.typing) {
      success = input.trim() == challenge.phrase?.trim();
    }

    if (success) {
      activeChallenge.value = null;
      error.value = null;
    } else {
      error.value = "Incorrect. Please try again.";
    }

    return success;
  }

  void cancel() {
    activeChallenge.value = null;
    error.value = null;
  }
}
