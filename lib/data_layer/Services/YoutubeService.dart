import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeService {
  final YoutubeExplode _yt = YoutubeExplode();

  /// Gets the best audio stream URL for a given YouTube URL.
  Future<String?> getAudioStreamUrl(String url) async {
    int retries = 3;
    while (retries > 0) {
      try {
        final Video video = await _yt.videos.get(url);
        final StreamManifest manifest = await _yt.videos.streamsClient
            .getManifest(video.id);

        if (manifest.audioOnly.isEmpty) {
          debugPrint('YoutubeService: No audio streams found for $url');
          return null;
        }

        final AudioOnlyStreamInfo audioStream = manifest.audioOnly
            .withHighestBitrate();

        return audioStream.url.toString();
      } catch (e) {
        retries--;
        debugPrint('YoutubeService Error (Retries left: $retries): $e');
        if (retries == 0) return null;
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    return null;
  }

  /// Gets video metadata like title and thumbnail.
  Future<VideoMetadata?> getVideoMetadata(String url) async {
    try {
      final Video video = await _yt.videos.get(url);
      return VideoMetadata(
        title: video.title,
        author: video.author,
        thumbnailUrl: video.thumbnails.highResUrl,
        duration: video.duration,
      );
    } catch (e) {
      if (e.toString().contains('RateLimitExceededException') ||
          e.toString().contains('rate limiting')) {
        print('YoutubeService: YouTube Rate Limit exceeded.');
      } else {
        print('YoutubeService Error: $e');
      }
      return null;
    }
  }

  /// Downloads the highest-bitrate audio stream to local storage.
  Future<File?> downloadAudio(
    String url, {
    String? subFolder,
    void Function(double)? onProgress,
  }) async {
    try {
      debugPrint('YoutubeService: Starting download for $url');
      final Video video = await _yt.videos.get(url);
      final StreamManifest manifest = await _yt.videos.streamsClient
          .getManifest(video.id);

      if (manifest.audioOnly.isEmpty) {
        debugPrint(
          'YoutubeService Error: No audio streams found for this video.',
        );
        return null;
      }

      final AudioOnlyStreamInfo audioStream = manifest.audioOnly
          .withHighestBitrate();

      // Prepare local file path
      final Directory docDir = await getApplicationDocumentsDirectory();
      final String baseDirPath = "${docDir.path}/focus_music";
      final String musicDirPath = subFolder != null
          ? "$baseDirPath/$subFolder"
          : baseDirPath;

      final Directory musicDir = Directory(musicDirPath);
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }

      final String filePath = "$musicDirPath/${video.id}.mp3";
      final File file = File(filePath);

      // If file exists and is not zero KB, return it
      if (await file.exists() && await file.length() > 0) {
        debugPrint('YoutubeService: Using existing file at $filePath');
        return file;
      }

      debugPrint('YoutubeService: Downloading stream: ${audioStream.url}');

      // Download the stream using a more robust method
      final Stream<List<int>> stream = _yt.videos.streamsClient.get(
        audioStream,
      );
      final IOSink output = file.openWrite(mode: FileMode.write);

      final totalSize = audioStream.size.totalBytes;
      int downloadedBytes = 0;

      try {
        await for (final List<int> data in stream) {
          downloadedBytes += data.length;
          if (onProgress != null && totalSize > 0) {
            onProgress(downloadedBytes / totalSize);
          }
          output.add(data);
        }

        await output.flush();
        await output.close();

        final finalSize = await file.length();
        debugPrint(
          'YoutubeService: Download completed. Final size: $finalSize bytes',
        );

        if (finalSize == 0) {
          debugPrint('YoutubeService Warning: Downloaded file is zero KB.');
          await file.delete();
          return null;
        }

        return file;
      } catch (streamError) {
        debugPrint('YoutubeService Stream Error: $streamError');
        await output.close();
        if (await file.exists()) await file.delete();
        return null;
      }
    } catch (e) {
      debugPrint('YoutubeService Download Error: $e');
      return null;
    }
  }

  void dispose() {
    _yt.close();
  }
}

class VideoMetadata {
  final String title;
  final String author;
  final String thumbnailUrl;
  final Duration? duration;

  VideoMetadata({
    required this.title,
    required this.author,
    required this.thumbnailUrl,
    this.duration,
  });
}
