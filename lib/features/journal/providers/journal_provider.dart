import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/journal_entry.dart';
import 'package:url_launcher/url_launcher.dart';

class JournalProvider with ChangeNotifier {
  List<JournalEntry> _entries = [];
  bool _isLoading = true;
  String? _error;
  Database? _database;
  bool _isInitialized = false;
  Map<String, JournalEntry> _entryCache = {};
  Map<String, List<JournalEntry>> _tagCache = {};
  Map<String, List<JournalEntry>> _moodCache = {};
  Map<String, AssetEntity?> _imageCache = {};

  JournalProvider() {
    initialize();
  }

  List<JournalEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  Map<String, AssetEntity?> get imageCache => _imageCache;

  Future<void> _initDatabase() async {
    try {
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, 'journal.db');

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
            CREATE TABLE journal_entries(
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              content TEXT NOT NULL,
              date INTEGER NOT NULL,
              media_ids TEXT,
              mood TEXT,
              tags TEXT
            )
          ''');
        },
      );

      await loadEntries();
      await _preloadImages();
      _isInitialized = true;
    } catch (e) {
      _error = 'Failed to initialize database: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _preloadImages() async {
    for (var entry in _entries) {
      if (entry.mediaIds.isNotEmpty) {
        try {
          final asset = await AssetEntity.fromId(entry.mediaIds.first);
          if (asset != null) {
            _imageCache[entry.mediaIds.first] = asset;
          }
        } catch (e) {
          debugPrint('Failed to preload image: $e');
        }
      }
    }
    notifyListeners();
  }

  Future<AssetEntity?> getImageAsset(String mediaId) async {
    if (_imageCache.containsKey(mediaId)) {
      return _imageCache[mediaId];
    }

    try {
      final asset = await AssetEntity.fromId(mediaId);
      if (asset != null) {
        _imageCache[mediaId] = asset;
        notifyListeners();
      }
      return asset;
    } catch (e) {
      debugPrint('Failed to load image: $e');
      return null;
    }
  }

  Future<void> loadEntries() async {
    if (_database == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        'journal_entries',
        orderBy: 'date DESC, id DESC',
      );

      _entries = maps.map((map) {
        final mediaIdsJson = map['media_ids'] as String?;
        final mediaIds = mediaIdsJson != null
            ? List<String>.from(json.decode(mediaIdsJson))
            : <String>[];

        final tagsJson = map['tags'] as String?;
        final tags = tagsJson != null
            ? List<String>.from(json.decode(tagsJson))
            : <String>[];

        final entry = JournalEntry(
          id: map['id'] as String,
          title: map['title'] as String,
          content: map['content'] as String,
          date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
          mediaIds: mediaIds,
          mood: map['mood'] as String?,
          tags: tags,
        );

        _entryCache[entry.id] = entry;
        return entry;
      }).toList();

      _updateCaches();
    } catch (e) {
      _error = 'Failed to load journal entries: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateCaches() {
    _tagCache.clear();
    _moodCache.clear();

    for (final entry in _entries) {
      // Update tag cache
      for (final tag in entry.tags) {
        _tagCache.putIfAbsent(tag, () => []).add(entry);
      }

      // Update mood cache
      if (entry.mood != null) {
        _moodCache.putIfAbsent(entry.mood!, () => []).add(entry);
      }
    }
  }

  Future<bool> addEntry(JournalEntry entry) async {
    if (_database == null) {
      _error = 'Database not initialized';
      notifyListeners();
      return false;
    }

    try {
      final map = {
        'id': entry.id,
        'title': entry.title,
        'content': entry.content,
        'date': entry.date.millisecondsSinceEpoch,
        'media_ids': json.encode(entry.mediaIds),
        'mood': entry.mood,
        'tags': json.encode(entry.tags),
      };

      await _database!.insert(
        'journal_entries',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _entryCache[entry.id] = entry;
      _entries.insert(0, entry);
      _updateCaches();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add entry: $e';
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEntry(JournalEntry updatedEntry) async {
    if (_database == null) {
      _error = 'Database not initialized';
      notifyListeners();
      return false;
    }

    try {
      final map = {
        'id': updatedEntry.id,
        'title': updatedEntry.title,
        'content': updatedEntry.content,
        'date': updatedEntry.date.millisecondsSinceEpoch,
        'media_ids': json.encode(updatedEntry.mediaIds),
        'mood': updatedEntry.mood,
        'tags': json.encode(updatedEntry.tags),
      };

      await _database!.update(
        'journal_entries',
        map,
        where: 'id = ?',
        whereArgs: [updatedEntry.id],
      );

      _entryCache[updatedEntry.id] = updatedEntry;
      final index = _entries.indexWhere((e) => e.id == updatedEntry.id);
      if (index != -1) {
        _entries.removeAt(index);
        _entries.insert(0, updatedEntry);
      }
      _updateCaches();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update entry: $e';
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEntry(String id) async {
    if (_database == null) {
      _error = 'Database not initialized';
      notifyListeners();
      return false;
    }

    try {
      await _database!.delete(
        'journal_entries',
        where: 'id = ?',
        whereArgs: [id],
      );

      _entryCache.remove(id);
      _entries.removeWhere((e) => e.id == id);
      _updateCaches();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete entry: $e';
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }

  List<String> getAllTags() {
    return _tagCache.keys.toList()..sort();
  }

  List<JournalEntry> getEntriesWithTag(String tag) {
    return _tagCache[tag] ?? [];
  }

  Future<List<JournalEntry>> searchEntries(String query) async {
    if (_database == null) return [];
    if (query.isEmpty) return entries;

    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        'journal_entries',
        where: 'title LIKE ? OR content LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'date DESC',
      );

      return maps.map((map) {
        final mediaIdsJson = map['media_ids'] as String?;
        final mediaIds = mediaIdsJson != null
            ? List<String>.from(json.decode(mediaIdsJson))
            : <String>[];

        final tagsJson = map['tags'] as String?;
        final tags = tagsJson != null
            ? List<String>.from(json.decode(tagsJson))
            : <String>[];

        return JournalEntry(
          id: map['id'] as String,
          title: map['title'] as String,
          content: map['content'] as String,
          date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
          mediaIds: mediaIds,
          mood: map['mood'] as String?,
          tags: tags,
        );
      }).toList();
    } catch (e) {
      _error = 'Failed to search entries: $e';
      debugPrint(_error);
      return [];
    }
  }

  List<JournalEntry> getEntriesByDateRange(DateTime start, DateTime end) {
    return _entries.where((entry) {
      final date = entry.date;
      return date.isAfter(start) && date.isBefore(end) ||
          date.isAtSameMomentAs(start) ||
          date.isAtSameMomentAs(end);
    }).toList();
  }

  List<JournalEntry> getEntriesByMood(String mood) {
    return _moodCache[mood] ?? [];
  }

  Future<void> refresh() async {
    await loadEntries();
  }

  Future<void> shareJournalEntry(JournalEntry entry,
      {bool includeMedia = true}) async {
    try {
      String shareText = '${entry.title}\n\n${entry.content}\n\n';

      // Add tags as hashtags
      if (entry.tags.isNotEmpty) {
        shareText += entry.tags.map((tag) => '#$tag').join(' ') + '\n\n';
      }

      // Add mood if available
      if (entry.mood != null) {
        shareText += 'Mood: ${entry.mood}\n';
      }

      // Add date
      shareText += 'Date: ${DateFormat('MMMM d, yyyy').format(entry.date)}';

      if (includeMedia && entry.mediaIds.isNotEmpty) {
        // Create temporary directory for media files
        final tempDir = await getTemporaryDirectory();
        final mediaFiles = <XFile>[];

        // Get all media files
        for (final mediaId in entry.mediaIds) {
          final asset = await AssetEntity.fromId(mediaId);
          if (asset != null) {
            final file = await asset.file;
            if (file != null) {
              // Create a copy in temp directory with a unique name and correct extension
              final extension = asset.type == AssetType.video ? '.mp4' : '.jpg';
              final tempFile = File(
                  '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_$mediaId$extension');
              await file.copy(tempFile.path);
              mediaFiles.add(XFile(tempFile.path));
            }
          }
        }

        // Share with media
        await Share.shareXFiles(
          mediaFiles,
          text: shareText,
          subject: entry.title,
        );

        // Clean up temporary files
        for (final file in mediaFiles) {
          await File(file.path).delete();
        }
      } else {
        // Share text only
        await Share.share(shareText, subject: entry.title);
      }
    } catch (e) {
      debugPrint('Error sharing journal entry: $e');
      rethrow;
    }
  }

  Future<void> shareToSocialMedia(JournalEntry entry, String platform) async {
    List<XFile>? mediaFiles;
    try {
      String shareText = '';
      String? appUrl;
      String? webUrl;

      // Prepare media files if available
      if (entry.mediaIds.isNotEmpty) {
        final tempDir = await getTemporaryDirectory();
        mediaFiles = [];

        for (final mediaId in entry.mediaIds) {
          final asset = await AssetEntity.fromId(mediaId);
          if (asset != null) {
            final file = await asset.file;
            if (file != null) {
              final extension = asset.type == AssetType.video ? '.mp4' : '.jpg';
              final tempFile = File(
                  '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_$mediaId$extension');
              await file.copy(tempFile.path);
              mediaFiles.add(XFile(tempFile.path));
            }
          }
        }
      }

      switch (platform.toLowerCase()) {
        case 'facebook':
          // Facebook format: Title + content + hashtags
          shareText = '${entry.title}\n\n${entry.content}\n\n';
          if (entry.tags.isNotEmpty) {
            shareText += entry.tags.map((tag) => '#$tag').join(' ') + '\n';
          }
          if (entry.mood != null) {
            shareText += '#${entry.mood!.toLowerCase()} ';
          }

          // Try to open Facebook app first
          final encodedText = Uri.encodeComponent(shareText);
          appUrl = 'fb://post?text=$encodedText';
          final fbUri = Uri.parse(appUrl);

          if (await canLaunchUrl(fbUri)) {
            if (mediaFiles != null && mediaFiles.isNotEmpty) {
              // Share with media using Share.shareXFiles
              await Share.shareXFiles(
                mediaFiles,
                text: shareText,
                subject: entry.title,
              );
            } else {
              // Share text only using Facebook app
              await launchUrl(fbUri);
            }
            return;
          }

          // Fallback to web URL
          webUrl =
              'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(shareText)}';
          break;

        case 'twitter':
          // Twitter format: Title + content + hashtags (limited to 280 chars)
          shareText = '${entry.title}\n\n';
          if (entry.content.length > 100) {
            shareText += entry.content.substring(0, 97) + '...\n\n';
          } else {
            shareText += entry.content + '\n\n';
          }

          if (entry.tags.isNotEmpty) {
            shareText += entry.tags.map((tag) => '#$tag').join(' ') + '\n';
          }
          if (entry.mood != null) {
            shareText += '#${entry.mood!.toLowerCase()} ';
          }

          // Truncate if too long
          if (shareText.length > 280) {
            shareText = shareText.substring(0, 277) + '...';
          }

          // Try to open Twitter app first
          final encodedText = Uri.encodeComponent(shareText);
          appUrl = 'twitter://post?message=$encodedText';
          final twitterUri = Uri.parse(appUrl);

          if (await canLaunchUrl(twitterUri)) {
            if (mediaFiles != null && mediaFiles.isNotEmpty) {
              // Share with media using Share.shareXFiles
              await Share.shareXFiles(
                mediaFiles,
                text: shareText,
                subject: entry.title,
              );
            } else {
              // Share text only using Twitter app
              await launchUrl(twitterUri);
            }
            return;
          }

          // Fallback to web URL
          webUrl =
              'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(shareText)}';
          break;

        case 'instagram':
          if (mediaFiles != null && mediaFiles.isNotEmpty) {
            final caption =
                '${entry.title}\n\n${entry.content}\n\n${entry.tags.map((tag) => '#$tag').join(' ')}';

            // Try to open Instagram app first
            final instagramUri = Uri.parse('instagram://camera');

            if (await canLaunchUrl(instagramUri)) {
              await launchUrl(instagramUri);
              // Wait for Instagram to open
              await Future.delayed(const Duration(seconds: 1));
              await Share.shareXFiles(
                mediaFiles,
                text: caption,
              );
            } else {
              // Fallback to general share if Instagram app is not installed
              await Share.shareXFiles(
                mediaFiles,
                text: caption,
              );
            }
            return;
          }
          break;

        default:
          shareText = '${entry.title}\n\n${entry.content}';
      }

      // Try to open the web URL if app launch failed
      if (webUrl != null) {
        final uri = Uri.parse(webUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }

      // If both app and web URLs fail, fall back to general share
      if (mediaFiles != null && mediaFiles.isNotEmpty) {
        await Share.shareXFiles(
          mediaFiles,
          text: shareText,
          subject: entry.title,
        );
      } else {
        await Share.share(shareText, subject: entry.title);
      }
    } catch (e) {
      debugPrint('Error sharing to social media: $e');
      rethrow;
    } finally {
      // Clean up temporary files
      if (mediaFiles != null) {
        for (final file in mediaFiles) {
          try {
            await File(file.path).delete();
          } catch (e) {
            debugPrint('Error deleting temporary file: $e');
          }
        }
      }
    }
  }

  Future<void> clearAll() async {
    if (_database == null) {
      _error = 'Database not initialized';
      notifyListeners();
      return;
    }

    try {
      await _database!.delete('journal_entries');
      _entries.clear();
      _entryCache.clear();
      _tagCache.clear();
      _moodCache.clear();
      _imageCache.clear();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to clear journal entries: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _database?.close();
    _imageCache.clear();
    super.dispose();
  }

  Future<void> initialize() async {
    if (!_isInitialized) {
      _isLoading = true;
      notifyListeners();
      await _initDatabase();
    }
  }
}
