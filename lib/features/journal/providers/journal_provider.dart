import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/journal_entry.dart';

class JournalProvider with ChangeNotifier {
  List<JournalEntry> _entries = [];
  bool _isLoading = false;
  String? _error;
  Database? _database;
  bool _isInitialized = false;
  Map<String, JournalEntry> _entryCache = {};
  Map<String, List<JournalEntry>> _tagCache = {};
  Map<String, List<JournalEntry>> _moodCache = {};
  Map<String, AssetEntity?> _imageCache = {};

  JournalProvider() {
    _initDatabase();
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
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize database: $e';
      debugPrint(_error);
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

  @override
  void dispose() {
    _database?.close();
    _imageCache.clear();
    super.dispose();
  }
}
