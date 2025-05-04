import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class MediaUtils {
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  static String formatDimensions(Size size) {
    return '${size.width.toInt()} × ${size.height.toInt()}';
  }

  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String getMediaTypeLabel(AssetType type,
      {bool isVideosAlbum = false}) {
    if (isVideosAlbum) {
      return 'Video';
    }
    switch (type) {
      case AssetType.image:
        return 'Photo';
      case AssetType.video:
        return 'Video';
      case AssetType.audio:
        return 'Audio';
      case AssetType.other:
        return 'File';
    }
  }

  static IconData getMediaTypeIcon(AssetType type,
      {bool isVideosAlbum = false}) {
    if (isVideosAlbum) {
      return Icons.videocam;
    }
    switch (type) {
      case AssetType.image:
        return Icons.photo;
      case AssetType.video:
        return Icons.videocam;
      case AssetType.audio:
        return Icons.audiotrack;
      case AssetType.other:
        return Icons.insert_drive_file;
    }
  }

  static String getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'angry':
        return '😡';
      case 'scared':
        return '😨';
      case 'tired':
        return '😴';
      case 'excited':
        return '😍';
      case 'calm':
        return '😌';
      case 'lonely':
        return '😔';
      case 'confident':
        return '😎';
      case 'surprised':
        return '😮';
      case 'thoughtful':
        return '🤔';
      case 'disappointed':
        return '😞';
      case 'celebratory':
        return '🥳';
      case 'frustrated':
        return '😤';
      default:
        return '😊';
    }
  }

  static IconData getMoodIcon(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'angry':
        return Icons.mood_bad;
      case 'scared':
        return Icons.sentiment_very_dissatisfied;
      case 'tired':
        return Icons.sentiment_neutral;
      case 'excited':
        return Icons.mood;
      case 'calm':
        return Icons.air;
      case 'lonely':
        return Icons.sentiment_dissatisfied;
      case 'confident':
        return Icons.sentiment_very_satisfied;
      case 'surprised':
        return Icons.sentiment_satisfied;
      case 'thoughtful':
        return Icons.psychology;
      case 'disappointed':
        return Icons.sentiment_dissatisfied;
      case 'celebratory':
        return Icons.celebration;
      case 'frustrated':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.emoji_emotions_outlined;
    }
  }

  static Color getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return Colors.amber;
      case 'sad':
        return Colors.blueGrey;
      case 'angry':
        return Colors.red;
      case 'scared':
        return Colors.purple;
      case 'tired':
        return Colors.grey;
      case 'excited':
        return Colors.orange;
      case 'calm':
        return Colors.lightBlue;
      case 'lonely':
        return Colors.blueGrey;
      case 'confident':
        return Colors.green;
      case 'surprised':
        return Colors.yellow;
      case 'thoughtful':
        return Colors.indigo;
      case 'disappointed':
        return Colors.brown;
      case 'celebratory':
        return Colors.pink;
      case 'frustrated':
        return Colors.deepOrange;
      default:
        return Colors.blue;
    }
  }

  static Future<File?> getFileForAsset(AssetEntity asset) async {
    try {
      return await asset.file;
    } catch (e) {
      debugPrint('Error loading file: $e');
      return null;
    }
  }

  static Future<Uint8List?> getThumbnailData(
    AssetEntity asset, {
    int width = 300,
    int height = 300,
  }) async {
    try {
      return await asset.thumbnailDataWithSize(
        ThumbnailSize(width, height),
        quality: 80,
      );
    } catch (e) {
      debugPrint('Error loading thumbnail: $e');
      return null;
    }
  }

  static Future<File?> saveThumbnailToFile(
    Uint8List thumbnailData,
    String assetId,
  ) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/thumb_$assetId.jpg');
      await tempFile.writeAsBytes(thumbnailData);
      return tempFile;
    } catch (e) {
      debugPrint('Error saving thumbnail: $e');
      return null;
    }
  }

  static Color getMediaTypeColor(AssetType type) {
    return type == AssetType.video ? Colors.red : Colors.blue;
  }

  static Future<Map<String, dynamic>> getMediaMetadata(
      AssetEntity asset) async {
    try {
      final createDate = asset.createDateTime;
      final size = asset.size;
      final file = await asset.file;
      final fileSize = file != null ? await file.length() : 0;
      Duration? duration;

      if (asset.type == AssetType.video) {
        duration = Duration(seconds: asset.duration);
      }

      return {
        'createDate': createDate,
        'size': size,
        'fileSize': fileSize,
        'duration': duration,
      };
    } catch (e) {
      debugPrint('Error getting media metadata: $e');
      return {};
    }
  }
}
