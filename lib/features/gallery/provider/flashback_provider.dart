import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';

class FlashbackProvider extends ChangeNotifier {
  // Flashback properties
  List<AssetEntity> _flashbackPhotos = [];
  bool _isLoadingFlashbacks = false;
  String? _flashbackError;

  // Weekly flashback properties
  List<AssetEntity> _weeklyFlashbackPhotos = [];
  bool _isLoadingWeeklyFlashbacks = false;
  String? _weeklyFlashbackError;

  // Monthly flashback properties
  List<AssetEntity> _monthlyFlashbackPhotos = [];
  bool _isLoadingMonthlyFlashbacks = false;
  String? _monthlyFlashbackError;

  // Slideshow properties
  final Map<String, List<File>> _slideshowCache = {};
  bool _isGeneratingSlideshow = false;
  bool _isFlashbacksInitialized = false;
  static const String _flashbacksCacheKey = 'flashbacks_cache';
  static const String _weeklyFlashbacksCacheKey = 'weekly_flashbacks_cache';
  static const String _monthlyFlashbacksCacheKey = 'monthly_flashbacks_cache';

  // Audio player for slideshow
  AudioPlayer? _audioPlayer;
  bool _isMusicPlaying = false;

  // Monthly recap properties
  List<AssetEntity> _monthlyRecapPhotos = [];
  bool _isLoadingMonthlyRecap = false;
  String? _monthlyRecapError;
  DateTime? _lastMonthRecapDate;
  int _recapPhotoLimit = 20; // Increased from 10 to 20 photos
  final Map<String, List<AssetEntity>> _recapCategories = {
    'highlights': [],
    'people': [],
    'places': [],
    'moments': [],
  };

  // Getters
  List<AssetEntity> get flashbackPhotos => _flashbackPhotos;
  bool get isLoadingFlashbacks => _isLoadingFlashbacks;
  String? get flashbackError => _flashbackError;
  List<AssetEntity> get weeklyFlashbackPhotos => _weeklyFlashbackPhotos;
  bool get isLoadingWeeklyFlashbacks => _isLoadingWeeklyFlashbacks;
  String? get weeklyFlashbackError => _weeklyFlashbackError;
  List<AssetEntity> get monthlyFlashbackPhotos => _monthlyFlashbackPhotos;
  bool get isLoadingMonthlyFlashbacks => _isLoadingMonthlyFlashbacks;
  String? get monthlyFlashbackError => _monthlyFlashbackError;
  bool get isGeneratingSlideshow => _isGeneratingSlideshow;
  bool get isFlashbacksInitialized => _isFlashbacksInitialized;
  bool get isMusicPlaying => _isMusicPlaying;
  List<AssetEntity> get monthlyRecapPhotos => _monthlyRecapPhotos;
  bool get isLoadingMonthlyRecap => _isLoadingMonthlyRecap;
  String? get monthlyRecapError => _monthlyRecapError;
  DateTime? get lastMonthRecapDate => _lastMonthRecapDate;
  int get recapPhotoLimit => _recapPhotoLimit;
  Map<String, List<AssetEntity>> get recapCategories => _recapCategories;

  FlashbackProvider() {
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer?.setAsset('assets/audio/floating-castle.mp3');
      await _audioPlayer?.setLoopMode(LoopMode.all);
      await _audioPlayer?.setVolume(0.5);
      await _audioPlayer?.stop();
      _isMusicPlaying = false;
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
      _isMusicPlaying = false;
    }
  }

  Future<void> clearFlashbacksCache() async {
    _isFlashbacksInitialized = false;
    _slideshowCache.clear();
    notifyListeners();
  }

  Future<void> loadFlashbackPhotos(List<AssetEntity> allMediaList) async {
    if (_isLoadingFlashbacks) return;

    try {
      _isLoadingFlashbacks = true;
      _flashbackError = null;
      notifyListeners();

      final today = DateTime.now();
      final currentDay = today.day;
      final currentMonth = today.month;

      // Get all photos from previous years for the same day and month
      final allPhotos = allMediaList.where((asset) {
        final date = asset.createDateTime;
        return date.day == currentDay &&
            date.month == currentMonth &&
            date.year < today.year;
      }).toList();

      // Sort by year in descending order
      allPhotos.sort(
          (a, b) => b.createDateTime.year.compareTo(a.createDateTime.year));

      _flashbackPhotos = allPhotos;
      _isLoadingFlashbacks = false;
      _isFlashbacksInitialized = true;
      notifyListeners();
    } catch (e) {
      _isLoadingFlashbacks = false;
      _flashbackError = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadWeeklyFlashbackPhotos(List<AssetEntity> allMediaList) async {
    if (_isLoadingWeeklyFlashbacks) return;

    try {
      _isLoadingWeeklyFlashbacks = true;
      _weeklyFlashbackError = null;
      notifyListeners();

      final now = DateTime.now();
      final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
      final currentWeekEnd = currentWeekStart.add(const Duration(days: 6));

      final weeklyPhotos = <AssetEntity>[];

      for (final photo in allMediaList) {
        final photoDate = photo.createDateTime;
        if (photoDate.year < now.year) {
          final photoWeekStart = DateTime(
            photoDate.year,
            photoDate.month,
            photoDate.day - (photoDate.weekday - 1),
          );

          final photoWeekEnd = photoWeekStart.add(const Duration(days: 6));

          if (photoDate.month == currentWeekStart.month &&
              photoDate.day >= currentWeekStart.day &&
              photoDate.day <= currentWeekEnd.day) {
            weeklyPhotos.add(photo);
          }
        }
      }

      weeklyPhotos.sort((a, b) {
        final yearCompare =
            b.createDateTime.year.compareTo(a.createDateTime.year);
        if (yearCompare != 0) return yearCompare;
        return b.createDateTime.compareTo(a.createDateTime);
      });

      _weeklyFlashbackPhotos = weeklyPhotos;
      _isLoadingWeeklyFlashbacks = false;
      notifyListeners();
    } catch (e) {
      _weeklyFlashbackError = e.toString();
      _isLoadingWeeklyFlashbacks = false;
      notifyListeners();
    }
  }

  Future<void> loadMonthlyFlashbackPhotos(
      List<AssetEntity> allMediaList) async {
    if (_isLoadingMonthlyFlashbacks) return;

    try {
      _isLoadingMonthlyFlashbacks = true;
      _monthlyFlashbackError = null;
      notifyListeners();

      final now = DateTime.now();
      final currentMonth = now.month;

      final monthlyPhotos = <AssetEntity>[];

      for (final photo in allMediaList) {
        final photoDate = photo.createDateTime;
        if (photoDate.month == currentMonth && photoDate.year < now.year) {
          monthlyPhotos.add(photo);
        }
      }

      monthlyPhotos.sort((a, b) {
        final yearCompare =
            b.createDateTime.year.compareTo(a.createDateTime.year);
        if (yearCompare != 0) return yearCompare;
        return b.createDateTime.compareTo(a.createDateTime);
      });

      _monthlyFlashbackPhotos = monthlyPhotos;
      _isLoadingMonthlyFlashbacks = false;
      notifyListeners();
    } catch (e) {
      _monthlyFlashbackError = e.toString();
      _isLoadingMonthlyFlashbacks = false;
      notifyListeners();
    }
  }

  Future<List<File>?> generateSlideshow(List<AssetEntity> memories) async {
    if (_isGeneratingSlideshow) return null;
    if (memories.isEmpty) return null;

    try {
      _isGeneratingSlideshow = true;
      notifyListeners();

      final memoryIds = memories.map((m) => m.id).join('_');

      if (_slideshowCache.containsKey(memoryIds)) {
        return _slideshowCache[memoryIds];
      }

      final files = await Future.wait(
        memories.map((asset) => asset.file),
      );
      final validFiles = files.whereType<File>().toList();

      if (validFiles.isEmpty) return null;

      _slideshowCache[memoryIds] = validFiles;
      notifyListeners();

      return validFiles;
    } catch (e) {
      debugPrint('Error generating slideshow: $e');
      return null;
    } finally {
      _isGeneratingSlideshow = false;
      notifyListeners();
    }
  }

  Future<void> toggleMusic() async {
    if (_audioPlayer == null) {
      await _initAudioPlayer();
    }

    try {
      if (_isMusicPlaying) {
        await _audioPlayer?.pause();
      } else {
        await _audioPlayer?.seek(Duration.zero); // Reset to start
        await _audioPlayer?.play();
      }
      _isMusicPlaying = !_isMusicPlaying;
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling music: $e');
      _isMusicPlaying = false;
      notifyListeners();
    }
  }

  Future<void> stopMusic() async {
    try {
      await _audioPlayer?.pause();
      await _audioPlayer?.seek(Duration.zero); // Reset to start
      _isMusicPlaying = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping music: $e');
      _isMusicPlaying = false;
      notifyListeners();
    }
  }

  Future<void> loadMonthlyRecap(List<AssetEntity> allMediaList) async {
    if (_isLoadingMonthlyRecap) return;

    try {
      _isLoadingMonthlyRecap = true;
      _monthlyRecapError = null;
      notifyListeners();

      final now = DateTime.now();
      final lastMonth = now.month == 1 ? 12 : now.month - 1;
      final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;

      // Get all photos from last month
      final lastMonthPhotos = allMediaList.where((asset) {
        final date = asset.createDateTime;
        return date.month == lastMonth && date.year == lastMonthYear;
      }).toList();

      // Sort by creation date (newest first)
      lastMonthPhotos
          .sort((a, b) => b.createDateTime.compareTo(a.createDateTime));

      // Store the date for which we generated the recap
      _lastMonthRecapDate = DateTime(lastMonthYear, lastMonth);

      // Clear previous categories
      _recapCategories.forEach((key, value) => value.clear());

      // If we have more than the limit, use smart selection
      if (lastMonthPhotos.length > _recapPhotoLimit) {
        // First, add the first photo of each day (to ensure good coverage)
        final dailyPhotos = <AssetEntity>[];
        final seenDays = <int>{};

        for (final photo in lastMonthPhotos) {
          final day = photo.createDateTime.day;
          if (!seenDays.contains(day)) {
            dailyPhotos.add(photo);
            seenDays.add(day);
          }
        }

        // Add remaining photos randomly until we reach the limit
        final remainingPhotos = lastMonthPhotos
            .where((photo) => !dailyPhotos.contains(photo))
            .toList()
          ..shuffle();

        final remainingCount = _recapPhotoLimit - dailyPhotos.length;
        if (remainingCount > 0) {
          _monthlyRecapPhotos = [
            ...dailyPhotos,
            ...remainingPhotos.take(remainingCount),
          ];
        } else {
          _monthlyRecapPhotos = dailyPhotos.take(_recapPhotoLimit).toList();
        }

        // Categorize photos
        _categorizeRecapPhotos(_monthlyRecapPhotos);
      } else {
        _monthlyRecapPhotos = lastMonthPhotos;
        _categorizeRecapPhotos(_monthlyRecapPhotos);
      }

      _isLoadingMonthlyRecap = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMonthlyRecap = false;
      _monthlyRecapError = e.toString();
      notifyListeners();
    }
  }

  /// Categorizes photos into different categories for the recap
  void _categorizeRecapPhotos(List<AssetEntity> photos) {
    // Clear previous categories
    _recapCategories.forEach((key, value) => value.clear());

    // Simple categorization based on time of day and photo count
    for (final photo in photos) {
      final hour = photo.createDateTime.hour;

      // Morning photos (6-11)
      if (hour >= 6 && hour < 12) {
        _recapCategories['moments']!.add(photo);
      }
      // Afternoon photos (12-17)
      else if (hour >= 12 && hour < 18) {
        _recapCategories['places']!.add(photo);
      }
      // Evening photos (18-23)
      else if (hour >= 18 && hour < 24) {
        _recapCategories['highlights']!.add(photo);
      }
      // Night photos (0-5)
      else {
        _recapCategories['people']!.add(photo);
      }
    }

    // Ensure each category has at least one photo
    for (final category in _recapCategories.keys) {
      if (_recapCategories[category]!.isEmpty && photos.isNotEmpty) {
        _recapCategories[category]!.add(photos.first);
      }
    }
  }

  /// Gets the category name for a photo
  String getPhotoCategory(AssetEntity photo) {
    for (final entry in _recapCategories.entries) {
      if (entry.value.contains(photo)) {
        return entry.key;
      }
    }
    return 'moments';
  }

  /// Gets the category icon for a photo
  IconData getCategoryIcon(String category) {
    switch (category) {
      case 'highlights':
        return Icons.star_rounded;
      case 'people':
        return Icons.people_rounded;
      case 'places':
        return Icons.place_rounded;
      case 'moments':
        return Icons.access_time_rounded;
      default:
        return Icons.photo_rounded;
    }
  }

  bool shouldShowMonthlyRecap() {
    if (_lastMonthRecapDate == null) return true;

    final now = DateTime.now();
    final lastMonth = now.month == 1 ? 12 : now.month - 1;
    final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;

    // Show recap if it's a new month and we haven't shown the recap yet
    return _lastMonthRecapDate!.month != lastMonth ||
        _lastMonthRecapDate!.year != lastMonthYear;
  }

  void setRecapPhotoLimit(int limit) {
    if (limit > 0 && limit != _recapPhotoLimit) {
      _recapPhotoLimit = limit;
      notifyListeners();
    }
  }

  String getLastRecapMonthName() {
    if (_lastMonthRecapDate == null) return '';

    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return months[_lastMonthRecapDate!.month - 1];
  }

  int getLastRecapYear() {
    return _lastMonthRecapDate?.year ?? DateTime.now().year;
  }

  int getLastMonthTotalPhotos(List<AssetEntity> allMediaList) {
    final now = DateTime.now();
    final lastMonth = now.month == 1 ? 12 : now.month - 1;
    final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;

    return allMediaList.where((asset) {
      final date = asset.createDateTime;
      return date.month == lastMonth && date.year == lastMonthYear;
    }).length;
  }

  void clearMonthlyRecap() {
    _monthlyRecapPhotos = [];
    _lastMonthRecapDate = null;
    _monthlyRecapError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopMusic(); // Stop music before disposing
    _audioPlayer?.dispose();
    _audioPlayer = null;
    _isMusicPlaying = false;
    super.dispose();
  }
}
