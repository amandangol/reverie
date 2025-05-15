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
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

enum SortOption { dateDesc, dateAsc, titleAsc, titleDesc, moodAsc, moodDesc }

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
  Map<String, String?> _coverPhotoCache = {};
  GenerativeModel? _model;

  SortOption _currentSort = SortOption.dateDesc;

  // Calendar-related methods
  Map<DateTime, List<JournalEntry>> _calendarEntries = {};
  Map<DateTime, String?> _moodIndicators = {};

  SortOption get currentSort => _currentSort;

  JournalProvider() {
    _initializeModel();
    initialize();
  }

  List<JournalEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  Map<String, AssetEntity?> get imageCache => _imageCache;

  Map<DateTime, List<JournalEntry>> get calendarEntries => _calendarEntries;
  Map<DateTime, String?> get moodIndicators => _moodIndicators;

  Future<void> _initDatabase() async {
    try {
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, 'journal.db');

      _database = await openDatabase(
        path,
        version: 4,
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
              last_edited INTEGER,
              cover_photo_id TEXT
            )
          ''');
        },
        onUpgrade: (Database db, int oldVersion, int newVersion) async {
          if (oldVersion < 2) {
            await db.execute(
                'ALTER TABLE journal_entries ADD COLUMN last_edited INTEGER');
          }
          if (oldVersion < 3) {
            // Check if cover_photo_id column exists before adding it
            final columns =
                await db.query('journal_entries', columns: ['cover_photo_id']);
            if (columns.isEmpty) {
              await db.execute(
                  'ALTER TABLE journal_entries ADD COLUMN cover_photo_id TEXT');
            }
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

      _sortEntries();
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
    _updateCalendarData();

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

  void _updateCalendarData() {
    _calendarEntries.clear();
    _moodIndicators.clear();

    for (var entry in _entries) {
      final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
      _calendarEntries.putIfAbsent(date, () => []).add(entry);

      // Only set mood indicator if there isn't one for this date
      // or if this entry's mood is more recent
      if (entry.mood != null &&
          (!_moodIndicators.containsKey(date) ||
              entry.date.isAfter(_calendarEntries[date]!.first.date))) {
        _moodIndicators[date] = entry.mood;
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
        'cover_photo_id': entry.coverPhotoId,
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

      // Cache all media assets for the entry
      for (final mediaId in entry.mediaIds) {
        try {
          final asset = await AssetEntity.fromId(mediaId);
          if (asset != null) {
            _imageCache[mediaId] = asset;
          }
        } catch (e) {
          debugPrint('Failed to cache media asset: $e');
        }
      }

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
        'cover_photo_id': updatedEntry.coverPhotoId,
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
      final searchQuery = query.toLowerCase();
      final List<Map<String, dynamic>> maps = await _database!.query(
        'journal_entries',
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
      }).where((entry) {
        // Search in title
        if (entry.title.toLowerCase().contains(searchQuery)) {
          return true;
        }

        // Search in content
        if (entry.content.toLowerCase().contains(searchQuery)) {
          return true;
        }

        // Search in tags
        if (entry.tags.any((tag) => tag.toLowerCase().contains(searchQuery))) {
          return true;
        }

        // Search in mood
        if (entry.mood != null &&
            entry.mood!.toLowerCase().contains(searchQuery)) {
          return true;
        }

        return false;
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

  //  streak calculation methods
  int getCurrentStreak() {
    if (_entries.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var currentDate = today;
    var streak = 0;

    // Check if there's an entry for today
    if (_hasEntryForDate(currentDate)) {
      streak = 1;
    } else {
      // If no entry today, check yesterday
      currentDate = currentDate.subtract(const Duration(days: 1));
      if (_hasEntryForDate(currentDate)) {
        streak = 1;
      } else {
        return 0; // No streak if no entry today or yesterday
      }
    }

    // Count consecutive days backwards
    while (true) {
      currentDate = currentDate.subtract(const Duration(days: 1));
      if (_hasEntryForDate(currentDate)) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  int getLongestStreak() {
    if (_entries.isEmpty) return 0;

    // Sort entries by date
    final sortedEntries = List<JournalEntry>.from(_entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    var longestStreak = 0;
    var currentStreak = 1;
    var lastDate = DateTime(
      sortedEntries[0].date.year,
      sortedEntries[0].date.month,
      sortedEntries[0].date.day,
    );

    for (var i = 1; i < sortedEntries.length; i++) {
      final currentDate = DateTime(
        sortedEntries[i].date.year,
        sortedEntries[i].date.month,
        sortedEntries[i].date.day,
      );

      final difference = currentDate.difference(lastDate).inDays;

      if (difference == 1) {
        // Consecutive day
        currentStreak++;
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
      } else if (difference > 1) {
        // Streak broken
        currentStreak = 1;
      }

      lastDate = currentDate;
    }

    return longestStreak;
  }

  bool _hasEntryForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _calendarEntries.containsKey(normalizedDate);
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

  void _sortEntries() {
    switch (_currentSort) {
      case SortOption.dateDesc:
        _entries.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortOption.dateAsc:
        _entries.sort((a, b) => a.date.compareTo(b.date));
        break;
      case SortOption.titleAsc:
        _entries.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortOption.titleDesc:
        _entries.sort((a, b) => b.title.compareTo(a.title));
        break;
      case SortOption.moodAsc:
        _entries.sort((a, b) {
          if (a.mood == null && b.mood == null) return 0;
          if (a.mood == null) return 1;
          if (b.mood == null) return -1;
          return a.mood!.compareTo(b.mood!);
        });
        break;
      case SortOption.moodDesc:
        _entries.sort((a, b) {
          if (a.mood == null && b.mood == null) return 0;
          if (a.mood == null) return 1;
          if (b.mood == null) return -1;
          return b.mood!.compareTo(a.mood!);
        });
        break;
    }
  }

  void setSortOption(SortOption option) {
    _currentSort = option;
    _sortEntries();
    notifyListeners();
  }

  List<JournalEntry> getEntriesForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _calendarEntries[normalizedDate] ?? [];
  }

  String? getMoodForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _moodIndicators[normalizedDate];
  }

  Future<void> exportJournalEntry(JournalEntry entry, String format) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName =
          '${entry.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${DateFormat('yyyyMMdd').format(entry.date)}';

      switch (format.toLowerCase()) {
        case 'pdf':
          await _exportToPDF(entry, tempDir, fileName);
          break;
        case 'json':
          await _exportToJSON(entry, tempDir, fileName);
          break;
        case 'text':
          await _exportToText(entry, tempDir, fileName);
          break;
        default:
          throw Exception('Unsupported export format');
      }
    } catch (e) {
      debugPrint('Error exporting journal entry: $e');
      rethrow;
    }
  }

  Future<void> _exportToPDF(
      JournalEntry entry, Directory tempDir, String fileName) async {
    final pdf = pw.Document();

    // Add content to PDF
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(
              level: 0,
              child: pw.Text(entry.title,
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              DateFormat('EEEE, MMMM d, yyyy').format(entry.date),
              style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
            ),
            if (entry.mood != null) ...[
              pw.SizedBox(height: 10),
              pw.Text('Mood: ${entry.mood}', style: pw.TextStyle(fontSize: 14)),
            ],
            pw.SizedBox(height: 20),
            pw.Text(entry.content, style: pw.TextStyle(fontSize: 16)),
            if (entry.tags.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Wrap(
                spacing: 5,
                children: entry.tags
                    .map((tag) => pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey300,
                            borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(4)),
                          ),
                          child: pw.Text('#$tag',
                              style: pw.TextStyle(fontSize: 12)),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );

    // Save PDF
    final file = File('${tempDir.path}/$fileName.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'Journal Entry Export');
  }

  Future<void> _exportToJSON(
      JournalEntry entry, Directory tempDir, String fileName) async {
    final jsonData = {
      'title': entry.title,
      'content': entry.content,
      'date': entry.date.toIso8601String(),
      'mood': entry.mood,
      'tags': entry.tags,
      'lastEdited': entry.lastEdited?.toIso8601String(),
    };

    final file = File('${tempDir.path}/$fileName.json');
    await file.writeAsString(jsonEncode(jsonData));
    await Share.shareXFiles([XFile(file.path)], text: 'Journal Entry Export');
  }

  Future<void> _exportToText(
      JournalEntry entry, Directory tempDir, String fileName) async {
    final text = '''
${entry.title}

Date: ${DateFormat('EEEE, MMMM d, yyyy').format(entry.date)}
${entry.mood != null ? 'Mood: ${entry.mood}\n' : ''}

${entry.content}

${entry.tags.isNotEmpty ? 'Tags: ${entry.tags.map((tag) => '#$tag').join(' ')}\n' : ''}
Last Edited: ${DateFormat('MMMM d, yyyy • h:mm a').format(entry.lastEdited ?? entry.date)}
''';

    final file = File('${tempDir.path}/$fileName.txt');
    await file.writeAsString(text);
    await Share.shareXFiles([XFile(file.path)], text: 'Journal Entry Export');
  }

  Future<void> setCoverPhoto(String entryId, String? mediaId) async {
    if (_database == null) return;

    try {
      await _database!.update(
        'journal_entries',
        {'cover_photo_id': mediaId},
        where: 'id = ?',
        whereArgs: [entryId],
      );

      final entry = _entryCache[entryId];
      if (entry != null) {
        final updatedEntry = entry.copyWith(coverPhotoId: mediaId);
        _entryCache[entryId] = updatedEntry;
        final index = _entries.indexWhere((e) => e.id == entryId);
        if (index != -1) {
          _entries[index] = updatedEntry;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to set cover photo: $e');
    }
  }

  Future<void> clearAllMedia(String entryId) async {
    if (_database == null) return;

    try {
      await _database!.update(
        'journal_entries',
        {
          'media_ids': json.encode([]),
          'cover_photo_id': null,
        },
        where: 'id = ?',
        whereArgs: [entryId],
      );

      final entry = _entryCache[entryId];
      if (entry != null) {
        final updatedEntry = entry.copyWith(
          mediaIds: [],
          coverPhotoId: null,
        );
        _entryCache[entryId] = updatedEntry;
        final index = _entries.indexWhere((e) => e.id == entryId);
        if (index != -1) {
          _entries[index] = updatedEntry;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to clear media: $e');
    }
  }
}
