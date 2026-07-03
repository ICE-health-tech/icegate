import 'dart:convert';
import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

/// One pen stroke — points are stored as plain x/y maps for JSON.
class WhiteboardStroke {
  const WhiteboardStroke({
    required this.points,
    required this.colorArgb,
    required this.width,
  });

  final List<Offset> points;
  final int colorArgb;
  final double width;

  Map<String, dynamic> toJson() => {
    'color': colorArgb,
    'width': width,
    'points': points
        .map((p) => {'x': p.dx, 'y': p.dy})
        .toList(growable: false),
  };

  factory WhiteboardStroke.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'];
    final points = <Offset>[];
    if (rawPoints is List) {
      for (final item in rawPoints) {
        if (item is Map) {
          final x = item['x'];
          final y = item['y'];
          if (x is num && y is num) {
            points.add(Offset(x.toDouble(), y.toDouble()));
          }
        }
      }
    }
    return WhiteboardStroke(
      points: points,
      colorArgb: json['color'] is int ? json['color'] as int : 0xFF111827,
      width: json['width'] is num ? (json['width'] as num).toDouble() : 3,
    );
  }
}

class WhiteboardDocument {
  const WhiteboardDocument({this.strokes = const []});

  final List<WhiteboardStroke> strokes;

  Map<String, dynamic> toJson() => {
    'strokes': strokes.map((s) => s.toJson()).toList(growable: false),
  };

  factory WhiteboardDocument.fromJson(Map<String, dynamic> json) {
    final raw = json['strokes'];
    if (raw is! List) return const WhiteboardDocument();
    final strokes = <WhiteboardStroke>[];
    for (final item in raw) {
      if (item is Map) {
        strokes.add(
          WhiteboardStroke.fromJson(Map<String, dynamic>.from(item)),
        );
      }
    }
    return WhiteboardDocument(strokes: strokes);
  }
}

abstract final class WhiteboardPrefs {
  WhiteboardPrefs._();

  static String storageKey(String personId) => 'whiteboard_$personId';

  static Future<WhiteboardDocument> load(String personId) async {
    if (personId.isEmpty) return const WhiteboardDocument();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey(personId));
    if (raw == null || raw.isEmpty) return const WhiteboardDocument();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const WhiteboardDocument();
      return WhiteboardDocument.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return const WhiteboardDocument();
    }
  }

  static Future<void> save(String personId, WhiteboardDocument doc) async {
    if (personId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey(personId), jsonEncode(doc.toJson()));
  }
}
