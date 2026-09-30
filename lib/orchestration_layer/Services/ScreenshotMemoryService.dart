import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:ice_gate/data_layer/Protocol/Screenshot/ScreenshotMemoryProtocol.dart';
import 'package:ice_gate/link_layer/capture/on_device_caption_service.dart';

/// Parsed result of a screen-capture extraction request.
/// Mirrors the `requestOk` pattern already used by AIFoodCaloriesService so a
/// failed or malformed agent response never throws into the UI.
class ScreenshotMemoryOutcome {
  final ScreenshotMemoryProtocol memory;

  /// False when the HTTP request failed, threw, or returned non-200.
  final bool requestOk;
  final String? error;

  const ScreenshotMemoryOutcome({
    required this.memory,
    required this.requestOk,
    this.error,
  });

  factory ScreenshotMemoryOutcome.failure(String error) =>
      ScreenshotMemoryOutcome(
        memory: ScreenshotMemoryProtocol.empty(),
        requestOk: false,
        error: error,
      );
}

/// Calls the extraction agent with a public HTTPS screenshot URL and parses
/// the memory it returns.
///
/// AGENT_URL is read at CALL time, not at construction, so switching between
/// the local stub server and production is an environment change only.
class ScreenshotMemoryService {
  static String get _agentUrl =>
      dotenv.env['AGENT_URL'] ??
      dotenv.env['FOOD_AGENT_URL'] ??
      'http://localhost:8001';

  /// Sends [imageUrl] to the agent for extraction. [route] is the in-app
  /// route when the capture came from our own UI, null for cross-app.
  static Future<ScreenshotMemoryOutcome> analyzeScreenshotUrl(
    String imageUrl, {
    String? route,
    int? width,
    int? height,
    String? locale,
    String? personContext,
  }) async {
    if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
      return ScreenshotMemoryOutcome.failure(
        'Screenshot URL is not publicly reachable: $imageUrl',
      );
    }

    try {
      final requestBody = <String, dynamic>{
        's3_url': imageUrl,
        'route': route ?? '',
        'width': width ?? 0,
        'height': height ?? 0,
        'captured_at': DateTime.now().toUtc().toIso8601String(),
        'locale': locale ?? 'en',
        if (personContext != null && personContext.isNotEmpty)
          'person_context': personContext,
      };

      final response = await http
          .post(
            Uri.parse('$_agentUrl/analyze_screenshot_url'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        return ScreenshotMemoryOutcome.failure(
          'Agent returned ${response.statusCode}',
        );
      }

      return ScreenshotMemoryOutcome(
        memory: ScreenshotMemoryProtocol.fromJson(response.body),
        requestOk: true,
      );
    } on TimeoutException {
      return ScreenshotMemoryOutcome.failure('Agent request timed out');
    } catch (e) {
      debugPrint('ScreenshotMemoryService: request failed — $e');
      return ScreenshotMemoryOutcome.failure(e.toString());
    }
  }

  /// Uploads a local PNG and extracts it in one call.
  ///
  /// On iOS with a capable device the caption is produced on-device and
  /// [imageUrl] is never required — the screenshot stays local. The agent is
  /// called only when on-device captioning is unavailable or fails.
  static Future<ScreenshotMemoryOutcome> captureAndAnalyze(
    File file, {
    required Future<String> Function(File file, {String? subFolder}) uploader,
    String? subFolder,
    String? route,
    int? width,
    int? height,
    String? locale,
    String? personContext,
  }) async {
    final onDevice = await OnDeviceCaptionService.captionOrSignalFallback(
      file.path,
    );
    if (onDevice.hasCaption) {
      return ScreenshotMemoryOutcome(
        memory: ScreenshotMemoryProtocol(
          title: route ?? 'Screen',
          summary: onDevice.caption!,
          memory: onDevice.caption!,
          tags: const [],
          memoryWeight: 1.0,
          aiModel: 'apple-foundation-models',
        ),
        requestOk: true,
      );
    }

    try {
      final imageUrl = await uploader(file, subFolder: subFolder);
      return await analyzeScreenshotUrl(
        imageUrl,
        route: route,
        width: width,
        height: height,
        locale: locale,
        personContext: personContext,
      );
    } catch (e) {
      return ScreenshotMemoryOutcome.failure('Upload failed: $e');
    }
  }
}
