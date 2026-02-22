import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeService {
  final YoutubeExplode _yt = YoutubeExplode();

  /// Gets the best audio stream URL for a given YouTube URL.
  Future<String?> getAudioStreamUrl(String url) async {
    try {
      final Video video = await _yt.videos.get(url);
      final StreamManifest manifest = await _yt.videos.streamsClient
          .getManifest(video.id);

      // Get the best audio-only stream
      final AudioOnlyStreamInfo audioStream = manifest.audioOnly
          .withHighestBitrate();

      return audioStream.url.toString();
    } catch (e) {
      if (e.toString().contains('RateLimitExceededException') ||
          e.toString().contains('rate limiting')) {
        print(
          'YoutubeService: YouTube Rate Limit exceeded. Please try again later.',
        );
      } else {
        print('YoutubeService Error: $e');
      }
      return null;
    }
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
