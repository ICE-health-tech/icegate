import 'dart:convert';

/// Parsed output of the screenshot extraction agent.
///
/// Plain class rather than freezed: the agent's response shape is still being
/// defined by the backend, and hand-rolled parsing lets this tolerate
/// variations (missing keys, string-or-list tags) without a codegen round.
class ScreenshotMemoryProtocol {
  final String title;
  final String summary;

  /// The text injected into future AI prompts.
  final String memory;
  final List<String> tags;

  /// 0..1 relevance assigned by the agent.
  final double memoryWeight;
  final String aiModel;

  const ScreenshotMemoryProtocol({
    required this.title,
    required this.summary,
    required this.memory,
    required this.tags,
    required this.memoryWeight,
    this.aiModel = '',
  });

  factory ScreenshotMemoryProtocol.empty() => const ScreenshotMemoryProtocol(
    title: '',
    summary: '',
    memory: '',
    tags: [],
    memoryWeight: 0.0,
  );

  /// Accepts either the full envelope `{"output": {...}}` or a bare object,
  /// because the food agent returns the former and a stub may return either.
  factory ScreenshotMemoryProtocol.fromJsonString(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return ScreenshotMemoryProtocol.empty();
      }
      final output = decoded['output'];
      final map = (output is Map<String, dynamic>) ? output : decoded;
      return ScreenshotMemoryProtocol.fromMap(map);
    } catch (_) {
      return ScreenshotMemoryProtocol.empty();
    }
  }

  factory ScreenshotMemoryProtocol.fromMap(Map<String, dynamic> map) {
    return ScreenshotMemoryProtocol(
      title: (map['title'] ?? '').toString(),
      summary: (map['summary'] ?? '').toString(),
      memory: (map['memory'] ?? map['content'] ?? '').toString(),
      tags: _parseTags(map['tags']),
      memoryWeight: _parseWeight(map['memory_weight']),
      aiModel: (map['ai_model'] ?? map['model'] ?? '').toString(),
    );
  }

  /// Tags may arrive as a list or as a comma-separated string.
  static List<String> _parseTags(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    return raw
        .toString()
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Clamped to 0..1 so a misbehaving agent cannot poison memory ordering.
  static double _parseWeight(dynamic raw) {
    if (raw == null) return 1.0;
    final parsed = raw is num ? raw.toDouble() : double.tryParse(raw.toString());
    if (parsed == null) return 1.0;
    return parsed.clamp(0.0, 1.0);
  }
}
