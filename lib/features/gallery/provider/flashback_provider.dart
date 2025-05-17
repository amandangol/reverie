import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

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
        await _audioPlayer?.stop();
      } else {
        await _audioPlayer?.stop(); // Stop any existing playback
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
      await _audioPlayer?.stop();
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

      // Sort by creation date
      lastMonthPhotos
          .sort((a, b) => b.createDateTime.compareTo(a.createDateTime));

      // Store the date for which we generated the recap
      _lastMonthRecapDate = DateTime(lastMonthYear, lastMonth);

      // If we have more than 10 photos, randomly select 10
      if (lastMonthPhotos.length > 10) {
        lastMonthPhotos.shuffle();
        _monthlyRecapPhotos = lastMonthPhotos.take(10).toList();
      } else {
        _monthlyRecapPhotos = lastMonthPhotos;
      }

      _isLoadingMonthlyRecap = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMonthlyRecap = false;
      _monthlyRecapError = e.toString();
      notifyListeners();
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

  @override
  void dispose() {
    _audioPlayer?.pause();
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    _audioPlayer = null;
    _isMusicPlaying = false;
    super.dispose();
  }
}
