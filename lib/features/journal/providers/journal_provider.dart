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
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/material.dart';

class JournalProvider extends ChangeNotifier {
  List<JournalEntry> _entries = [];
  bool _isLoading = true;
  String? _error;
  Database? _database;
  bool _isInitialized = false;
  Map<String, JournalEntry> _entryCache = {};
  Map<String, List<JournalEntry>> _tagCache = {};
  Map<String, List<JournalEntry>> _moodCache = {};
  Map<String, AssetEntity?> _imageCache = {};
  GenerativeModel? _model;

  JournalProvider() {
    _initializeModel();
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
        version: 2,
        onCreate: (Database db, int version) async {
          await db.execute('''
            CREATE TABLE journal_entries(
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              content TEXT NOT NULL,
              date INTEGER NOT NULL,
              media_ids TEXT,
              mood TEXT,
              tags TEXT,
              last_edited INTEGER
            )
          ''');
        },
        onUpgrade: (Database db, int oldVersion, int newVersion) async {
          if (oldVersion < 2) {
            await db.execute(
                'ALTER TABLE journal_entries ADD COLUMN last_edited INTEGER');
          }
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
          lastEdited: map['last_edited'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['last_edited'] as int)
              : DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
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
      // Check if entry with same ID already exists
      final existingEntry = _entryCache[entry.id];
      if (existingEntry != null) {
        _error = 'Entry already exists';
        notifyListeners();
        return false;
      }

      final now = DateTime.now();
      final map = {
        'id': entry.id,
        'title': entry.title,
        'content': entry.content,
        'date': now.millisecondsSinceEpoch,
        'media_ids': json.encode(entry.mediaIds),
        'mood': entry.mood,
        'tags': json.encode(entry.tags),
        'last_edited': now.millisecondsSinceEpoch,
      };

      await _database!.insert(
        'journal_entries',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final newEntry = entry.copyWith(
        date: now,
        lastEdited: now,
      );

      _entryCache[entry.id] = newEntry;
      _entries.insert(0, newEntry);
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
      final originalEntry = _entryCache[updatedEntry.id];
      if (originalEntry == null) {
        throw Exception('Entry not found in cache');
      }

      final map = {
        'id': updatedEntry.id,
        'title': updatedEntry.title,
        'content': updatedEntry.content,
        'date': originalEntry.date.millisecondsSinceEpoch,
        'media_ids': json.encode(updatedEntry.mediaIds),
        'mood': updatedEntry.mood,
        'tags': json.encode(updatedEntry.tags),
        'last_edited': DateTime.now().millisecondsSinceEpoch,
      };

      await _database!.update(
        'journal_entries',
        map,
        where: 'id = ?',
        whereArgs: [updatedEntry.id],
      );

      final finalEntry = updatedEntry.copyWith(
        date: originalEntry.date,
        lastEdited: DateTime.now(),
      );

      _entryCache[updatedEntry.id] = finalEntry;
      final index = _entries.indexWhere((e) => e.id == updatedEntry.id);
      if (index != -1) {
        _entries.removeAt(index);
        _entries.insert(0, finalEntry);
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
          lastEdited: map['last_edited'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['last_edited'] as int)
              : DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
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
      return entry.date.isAfter(start.subtract(const Duration(days: 1))) &&
          entry.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  List<JournalEntry> getEntriesByMood(String mood) {
    return _moodCache[mood] ?? [];
  }

  int getEntriesThisMonth() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    return _entries
        .where((entry) =>
            entry.date.isAfter(firstDayOfMonth) ||
            entry.date.isAtSameMomentAs(firstDayOfMonth))
        .length;
  }

  double getAverageEntryLength() {
    if (_entries.isEmpty) return 0;
    final totalWords = _entries.fold<int>(
        0, (sum, entry) => sum + entry.content.split(' ').length);
    return totalWords / _entries.length;
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

  void _initializeModel() {
    try {
      final apiKey = 'AIzaSyCyCzEzKjHpkacME7Y8wj1u2E787Q-NAu4';
      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
      );
    } catch (e) {
      debugPrint('Error initializing Gemini model: $e');
    }
  }

  Future<Map<String, String>> generateJournalContent({
    required String userContext,
    required String mood,
    required List<String> tags,
    required List<String> mediaDescriptions,
  }) async {
    try {
      if (_model == null) {
        throw Exception('AI model not initialized');
      }

      final prompt = '''
        Create a journal entry based on the following context:
        User's Context: $userContext
        Mood: $mood
        Tags: ${tags.join(", ")}
        Media Context: ${mediaDescriptions.join(" | ")}

        Generate:
        1. A creative and engaging title (1-5 words) that captures the essence of the user's context
        2. A thoughtful journal entry (2-3 paragraphs) that reflects the user's context, mood, and incorporates the tags naturally.
        Make it personal and authentic, as if the user wrote it themselves.

        Return ONLY a JSON object in this exact format, with no markdown formatting or additional text:
        {
          "title": "the generated title",
          "content": "the generated content"
        }
      ''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      final responseText = response.text ?? '{}';

      try {
        // Clean the response text to handle markdown formatting
        String cleanJson =
            responseText.replaceAll('```json', '').replaceAll('```', '').trim();

        final Map<String, dynamic> jsonResponse = json.decode(cleanJson);
        return {
          'title': jsonResponse['title'] ?? '',
          'content': jsonResponse['content'] ?? '',
        };
      } catch (e) {
        debugPrint('Error parsing AI response: $e');
        debugPrint('Raw response: $responseText');
        return {
          'title': 'AI Generation Failed',
          'content': 'Please try again or write your own entry.',
        };
      }
    } catch (e) {
      debugPrint('Error generating journal content: $e');
      return {
        'title': 'AI Generation Failed',
        'content': 'Please try again or write your own entry.',
      };
    }
  }
}
