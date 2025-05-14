import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:io';
import 'package:reverie/utils/media_utils.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';

import '../provider/media_provider.dart';
import '../widgets/asset_thumbnail.dart';
import '../widgets/media_detail_view.dart';

class FlashbacksScreen extends StatefulWidget {
  const FlashbacksScreen({super.key});

  @override
  State<FlashbacksScreen> createState() => _FlashbacksScreenState();
}

class _FlashbacksScreenState extends State<FlashbacksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _selectedYear;
  List<File>? _currentSlideshow;
  bool _isViewingSlideshow = false;
  int _currentSlideshowIndex = 0;
  bool _isAutoPlaying = false;
  Timer? _autoPlayTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isMusicPlaying = false;
  VideoPlayerController? _videoController;

  String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }

  String _getSeasonName(int month) {
    if (month >= 3 && month <= 5) return 'Spring';
    if (month >= 6 && month <= 8) return 'Summer';
    if (month >= 9 && month <= 11) return 'Autumn';
    return 'Winter';
  }

  String _getTitleForTab(int tabIndex, List<AssetEntity> memories) {
    final now = DateTime.now();
    final currentMonth = _getMonthName(now.month);

    if (memories.isEmpty) {
      switch (tabIndex) {
        case 0:
          return 'Today in $currentMonth';
        case 1:
          return 'This Week in $currentMonth';
        case 2:
          return currentMonth;
        default:
          return 'Flashback Memories';
      }
    }

    // Get unique months from memories
    final memoryMonths =
        memories.map((m) => m.createDateTime.month).toSet().toList()..sort();

    if (memoryMonths.isEmpty) return 'Flashback Memories';

    // If all memories are from the same month
    if (memoryMonths.length == 1) {
      final monthName = _getMonthName(memoryMonths.first);
      final oldestMemory = memories.reduce(
          (a, b) => a.createDateTime.isBefore(b.createDateTime) ? a : b);
      final yearsAgo = now.year - oldestMemory.createDateTime.year;

      switch (tabIndex) {
        case 0:
          if (yearsAgo == 1) {
            return 'A Year Ago in $monthName';
          } else if (yearsAgo > 1) {
            return '$yearsAgo Years Ago in $monthName';
          }
          return 'Today in $monthName';
        case 1:
          if (yearsAgo == 1) {
            return 'Last Year in $monthName';
          } else if (yearsAgo > 1) {
            return '$yearsAgo Years Ago in $monthName';
          }
          return 'This Week in $monthName';
        case 2:
          if (yearsAgo == 1) {
            return 'Last Year\'s $monthName';
          } else if (yearsAgo > 1) {
            return '$yearsAgo Years Ago in $monthName';
          }
          return monthName;
        default:
          return 'Flashback Memories';
      }
    }

    switch (tabIndex) {
      case 0:
        return 'Today\'s Memories';
      case 1:
        return 'This Week\'s Memories';
      case 2:
        return '$currentMonth\'s Memories';
      default:
        return 'Flashback Memories';
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initAudioPlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFlashbacks();
    });
  }

  Future<void> _initAudioPlayer() async {
    try {
      // Load a soothing background music file
      await _audioPlayer.setAsset('assets/audio/floating-castle.mp3');
      await _audioPlayer.setLoopMode(LoopMode.all);
      await _audioPlayer.setVolume(0.5);
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
      // Don't throw the error, just log it and continue without audio
    }
  }

  Future<void> _loadFlashbacks() async {
    final mediaProvider = context.read<MediaProvider>();
    // Always reload flashbacks when screen is shown
    await mediaProvider.clearFlashbacksCache();
    await Future.wait([
      mediaProvider.loadFlashbackPhotos(),
      mediaProvider.loadWeeklyFlashbackPhotos(),
      mediaProvider.loadMonthlyFlashbackPhotos(),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _autoPlayTimer?.cancel();
    _audioPlayer.dispose();
    _disposeVideoController();
    super.dispose();
  }

  List<int> _getAvailableYears(List<AssetEntity> memories) {
    final years = memories.map((m) => m.createDateTime.year).toSet().toList();
    years.sort((a, b) => b.compareTo(a)); // Sort in descending order
    return years;
  }

  List<AssetEntity> _filterMemoriesByYear(List<AssetEntity> memories) {
    if (_selectedYear == null) return memories;
    return memories
        .where((m) => m.createDateTime.year == _selectedYear)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<MediaProvider>(
          builder: (context, mediaProvider, child) {
            final memories = _getMemoriesForCurrentTab(mediaProvider);
            final filteredMemories = _filterMemoriesByYear(memories);
            return Text(
              _getTitleForTab(_tabController.index, filteredMemories),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            );
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 2,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'This Week'),
            Tab(text: 'This Month'),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Consumer<MediaProvider>(
                builder: (context, mediaProvider, child) {
                  final memories = _getMemoriesForCurrentTab(mediaProvider);
                  final availableYears = _getAvailableYears(memories);

                  if (availableYears.isEmpty) return const SizedBox.shrink();

                  return Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: availableYears.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: const Text('All Years'),
                              selected: _selectedYear == null,
                              onSelected: (selected) {
                                setState(() => _selectedYear = null);
                              },
                            ),
                          );
                        }
                        final year = availableYears[index - 1];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(year.toString()),
                            selected: _selectedYear == year,
                            onSelected: (selected) {
                              setState(
                                  () => _selectedYear = selected ? year : null);
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDailyFlashbacks(),
                    _buildWeeklyFlashbacks(),
                    _buildMonthlyFlashbacks(),
                  ],
                ),
              ),
            ],
          ),
          if (_isViewingSlideshow && _currentSlideshow != null)
            _buildSlideshowView(),
        ],
      ),
    );
  }

  List<AssetEntity> _getMemoriesForCurrentTab(MediaProvider mediaProvider) {
    switch (_tabController.index) {
      case 0:
        return mediaProvider.flashbackPhotos;
      case 1:
        return mediaProvider.weeklyFlashbackPhotos;
      case 2:
        return mediaProvider.monthlyFlashbackPhotos;
      default:
        return [];
    }
  }

  Map<DateTime, List<AssetEntity>> _groupMemoriesByDate(
      List<AssetEntity> memories) {
    final Map<DateTime, List<AssetEntity>> grouped = {};

    for (var memory in memories) {
      final date = memory.createDateTime;
      final dateKey = DateTime(date.year, date.month, date.day);

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(memory);
    }

    // Sort each group by time
    for (var photos in grouped.values) {
      photos.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
    }

    // Sort the dates in descending order
    return Map.fromEntries(
        grouped.entries.toList()..sort((a, b) => b.key.compareTo(a.key)));
  }

  Widget _buildMemoryGrid(List<AssetEntity> memories, DateTime date) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2.0,
        mainAxisSpacing: 2.0,
      ),
      itemCount: memories.length,
      itemBuilder: (context, index) {
        final asset = memories[index];
        return _buildMemoryItem(asset);
      },
    );
  }

  Widget _buildMemoryItem(AssetEntity asset) {
    final year = asset.createDateTime.year;
    final now = DateTime.now();
    final yearsAgo = now.year - year;
    final isToday = asset.createDateTime.day == now.day &&
        asset.createDateTime.month == now.month;

    return Stack(
      fit: StackFit.expand,
      children: [
        AssetThumbnail(
          asset: asset,
          heroTag: 'flashback_${asset.id}',
          onTap: () => _showMediaDetail(context, asset),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isToday && _tabController.index == 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      yearsAgo == 1 ? '1 Year Ago' : '$yearsAgo Years Ago',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Text(
                  DateFormat('h:mm a').format(asset.createDateTime),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlashbackSection(
      List<AssetEntity> flashbacks, String emptyMessage) {
    final filteredFlashbacks = _filterMemoriesByYear(flashbacks);

    if (filteredFlashbacks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 40,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              _selectedYear != null
                  ? 'No memories from $_selectedYear'
                  : emptyMessage,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    final groupedMemories = _groupMemoriesByDate(filteredFlashbacks);

    return Stack(
      children: [
        ListView.builder(
          itemCount: groupedMemories.length,
          itemBuilder: (context, index) {
            final date = groupedMemories.keys.elementAt(index);
            final memories = groupedMemories[date]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        MediaUtils.formatDate(date),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${memories.length} ${memories.length == 1 ? 'memory' : 'memories'}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildMemoryGrid(memories, date),
                const SizedBox(height: 12),
              ],
            );
          },
        ),
        if (filteredFlashbacks.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton.icon(
                  onPressed: () => _generateSlideshow(filteredFlashbacks),
                  icon: const Icon(Icons.slideshow),
                  label: const Text('View Slideshow'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDailyFlashbacks() {
    return Consumer<MediaProvider>(
      builder: (context, mediaProvider, child) {
        if (mediaProvider.isLoadingFlashbacks) {
          return const Center(child: CircularProgressIndicator());
        }

        if (mediaProvider.flashbackError != null) {
          return Center(
            child: Text('Error: ${mediaProvider.flashbackError}'),
          );
        }

        return _buildFlashbackSection(
          mediaProvider.flashbackPhotos,
          'No flashback memories for today',
        );
      },
    );
  }

  Widget _buildWeeklyFlashbacks() {
    return Consumer<MediaProvider>(
      builder: (context, mediaProvider, child) {
        if (mediaProvider.isLoadingWeeklyFlashbacks) {
          return const Center(child: CircularProgressIndicator());
        }

        if (mediaProvider.weeklyFlashbackError != null) {
          return Center(
            child: Text('Error: ${mediaProvider.weeklyFlashbackError}'),
          );
        }

        return _buildFlashbackSection(
          mediaProvider.weeklyFlashbackPhotos,
          'No flashback memories for this week',
        );
      },
    );
  }

  Widget _buildMonthlyFlashbacks() {
    return Consumer<MediaProvider>(
      builder: (context, mediaProvider, child) {
        if (mediaProvider.isLoadingMonthlyFlashbacks) {
          return const Center(child: CircularProgressIndicator());
        }

        if (mediaProvider.monthlyFlashbackError != null) {
          return Center(
            child: Text('Error: ${mediaProvider.monthlyFlashbackError}'),
          );
        }

        return _buildFlashbackSection(
          mediaProvider.monthlyFlashbackPhotos,
          'No flashback memories for this month',
        );
      },
    );
  }

  void _showMediaDetail(BuildContext context, AssetEntity asset) {
    // Get all memories for the current tab
    final mediaProvider = context.read<MediaProvider>();
    final memories = _getMemoriesForCurrentTab(mediaProvider);
    final filteredMemories = _filterMemoriesByYear(memories);

    // Group memories by date
    final groupedMemories = _groupMemoriesByDate(filteredMemories);

    // Find the date group that contains the selected asset
    final selectedDate = DateTime(
      asset.createDateTime.year,
      asset.createDateTime.month,
      asset.createDateTime.day,
    );

    // Get only the memories from the same date
    final sameDayMemories = groupedMemories[selectedDate] ?? [];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaDetailView(
          asset: asset,
          assetList: sameDayMemories,
          heroTag: 'flashback_${asset.id}',
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _generateSlideshow(List<AssetEntity> memories) async {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    // Filter out videos and only keep images
    final imageMemories =
        memories.where((asset) => asset.type == AssetType.image).toList();
    final slideshow = await mediaProvider.generateSlideshow(imageMemories);
    if (slideshow != null) {
      setState(() {
        _currentSlideshow = slideshow;
        _isViewingSlideshow = true;
        _currentSlideshowIndex = 0;
        _isAutoPlaying = true;
      });
      // Start auto-play immediately
      _startAutoPlay();
      // Start music
      await _audioPlayer.play();
      setState(() {
        _isMusicPlaying = true;
      });
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentSlideshowIndex < _currentSlideshow!.length - 1) {
        setState(() => _currentSlideshowIndex++);
      } else {
        setState(() {
          _currentSlideshowIndex = 0;
        });
      }
    });
  }

  Future<void> _disposeVideoController() async {
    if (_videoController != null) {
      await _videoController!.pause();
      await _videoController!.dispose();
      _videoController = null;
    }
  }

  void _closeSlideshow() async {
    _autoPlayTimer?.cancel();
    await _audioPlayer.pause();
    setState(() {
      _isViewingSlideshow = false;
      _currentSlideshow = null;
      _currentSlideshowIndex = 0;
      _isAutoPlaying = false;
      _isMusicPlaying = false;
    });
  }

  Future<void> _toggleMusic() async {
    try {
      if (_isMusicPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
      setState(() {
        _isMusicPlaying = !_isMusicPlaying;
      });
    } catch (e) {
      debugPrint('Error toggling music: $e');
      // Show a snackbar to inform the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to play music. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildSlideshowView() {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: Builder(
              key: ValueKey(_currentSlideshowIndex),
              builder: (context) {
                try {
                  return PhotoView(
                    imageProvider:
                        FileImage(_currentSlideshow![_currentSlideshowIndex]),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2,
                    backgroundDecoration:
                        const BoxDecoration(color: Colors.black),
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Error loading image: $error');
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Unable to load image',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, event) {
                      return Center(
                        child: CircularProgressIndicator(
                          value: event == null
                              ? null
                              : event.cumulativeBytesLoaded /
                                  event.expectedTotalBytes!,
                        ),
                      );
                    },
                  );
                } catch (e) {
                  debugPrint('Error in slideshow view: $e');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error displaying image',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
          // Top controls
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _closeSlideshow,
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isMusicPlaying ? Icons.music_note : Icons.music_off,
                        color: Colors.white,
                      ),
                      onPressed: _toggleMusic,
                    ),
                    IconButton(
                      icon: Icon(
                        _isAutoPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _isAutoPlaying = !_isAutoPlaying;
                          if (_isAutoPlaying) {
                            _startAutoPlay();
                          } else {
                            _autoPlayTimer?.cancel();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Bottom controls
          if (_currentSlideshow!.length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: LinearProgressIndicator(
                      value: (_currentSlideshowIndex + 1) /
                          _currentSlideshow!.length,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Navigation controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.chevron_left, color: Colors.white),
                        onPressed: _currentSlideshowIndex > 0
                            ? () => setState(() => _currentSlideshowIndex--)
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentSlideshowIndex + 1}/${_currentSlideshow!.length}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right,
                            color: Colors.white),
                        onPressed: _currentSlideshowIndex <
                                _currentSlideshow!.length - 1
                            ? () => setState(() => _currentSlideshowIndex++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
