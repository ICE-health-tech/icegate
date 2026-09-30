// Local stub for the screenshot extraction agent.
//
// Serves POST /analyze_screenshot_url with a canned response so the capture
// pipeline is developable before the real backend exists. Varies the reply by
// `route` so the review UI can be exercised against more than one shape.
//
// Lives in tool/ so it is excluded from release app builds and cannot ship by
// accident.
//
// Run:
//   dart run tool/screenshot_agent_stub/server.dart
//   AGENT_URL=http://localhost:8123  (in .env)
//
// Then force a capture from the app: the Screen Memory page's "Sync now"
// drains the queue, and an "in_app" capture can be forced by enabling
// automatic capture on a high-value route.

import 'dart:convert';
import 'dart:io';

const int _defaultPort = 8123;

const Map<String, Map<String, Object>> _cannedByRoute = {
  '/health': {
    'title': 'Health overview',
    'summary': 'Health dashboard with sleep, heart rate, and activity rings.',
    'memory':
        'User checks their health dashboard regularly; sleep and heart rate '
            'are the metrics they look at most.',
    'tags': ['health', 'dashboard', 'sleep', 'heart-rate'],
    'memory_weight': 0.8,
  },
  '/finance': {
    'title': 'Finance overview',
    'summary': 'Net worth and recent transactions.',
    'memory': 'User tracks net worth and reviews recent transactions.',
    'tags': ['finance', 'net-worth', 'transactions'],
    'memory_weight': 0.7,
  },
};

const Map<String, Object> _cannedDefault = {
  'title': 'App screen',
  'summary': 'A screen from the ice_gate app.',
  'memory': 'User was using a generic ice_gate screen.',
  'tags': ['app', 'general'],
  'memory_weight': 0.5,
};

void main(List<String> args) {
  final port = args.isNotEmpty
      ? int.tryParse(args.first) ?? _defaultPort
      : _defaultPort;

  final server = HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('🖼️  Screenshot agent stub listening on :$port');
  stdout.writeln('   POST http://localhost:$port/analyze_screenshot_url');

  server.listen((request) async {
    if (request.method == 'OPTIONS') {
      request.response
        ..statusCode = HttpStatus.noContent
        ..headers.set('Access-Control-Allow-Origin', '*');
      await request.response.close();
      return;
    }

    if (request.method != 'POST' ||
        !request.uri.path.endsWith('/analyze_screenshot_url')) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    final body = await utf8.decoder.bind(request).join();
    Map<String, dynamic> payload = {};
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) payload = decoded;
    } catch (_) {
      // Fall through with an empty payload.
    }

    final route = (payload['route'] as String?) ?? '';
    final output = _cannedByRoute[route] ?? _cannedDefault;

    stdout.writeln('📸 ${DateTime.now().toIso8601String()} '
        'route="${payload['route']}" url=${payload['s3_url']}');

    final response = jsonEncode({
      'output': output,
      'intermediate_steps': <Object>[],
    });

    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..headers.set('Access-Control-Allow-Origin', '*')
      ..write(response);
    await request.response.close();
  });
}
