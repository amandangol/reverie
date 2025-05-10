import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:reverie/utils/media_utils.dart';

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
    final currentSeason = _getSeasonName(now.month);

    if (memories.isEmpty) {
      switch (tabIndex) {
        case 0:
          return 'Today\'s Memories';
        case 1:
          return 'This Week\'s Memories';
        case 2:
          return '$currentMonth Memories';
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
      final seasonName = _getSeasonName(memoryMonths.first);

      switch (tabIndex) {
        case 0:
          return 'Today in $monthName';
        case 1:
          return 'This Week in $monthName';
        case 2:
          return '$monthName\'s $seasonName Memories';
        default:
          return 'Flashback Memories';
      }
    }

    // If memories span multiple months
    final firstMonth = _getMonthName(memoryMonths.first);
    final lastMonth = _getMonthName(memoryMonths.last);

    switch (tabIndex) {
      case 0:
        return 'Today\'s Journey Through Time';
      case 1:
        return 'This Week\'s Time Capsule';
      case 2:
        return '$currentMonth\'s Time Travel';
      default:
        return 'Flashback Memories';
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFlashbacks();
    });
  }

  Future<void> _loadFlashbacks() async {
    final mediaProvider = context.read<MediaProvider>();
    await Future.wait([
      mediaProvider.loadFlashbackPhotos(),
      mediaProvider.loadWeeklyFlashbackPhotos(),
      mediaProvider.loadMonthlyFlashbackPhotos(),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            );
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'This Week'),
            Tab(text: 'This Month'),
          ],
        ),
      ),
      body: Column(
        children: [
          Consumer<MediaProvider>(
            builder: (context, mediaProvider, child) {
              final memories = _getMemoriesForCurrentTab(mediaProvider);
              final availableYears = _getAvailableYears(memories);

              if (availableYears.isEmpty) return const SizedBox.shrink();

              return Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: availableYears.length + 1, // +1 for "All Years"
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
            child: Text(
              '$yearsAgo ${yearsAgo == 1 ? 'year' : 'years'} ago',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
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
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _selectedYear != null
                  ? 'No memories from $_selectedYear'
                  : emptyMessage,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final groupedMemories = _groupMemoriesByDate(filteredFlashbacks);

    return ListView.builder(
      itemCount: groupedMemories.length,
      itemBuilder: (context, index) {
        final date = groupedMemories.keys.elementAt(index);
        final memories = groupedMemories[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      MediaUtils.formatDate(date),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${memories.length} memory${memories.length == 1 ? '' : 'ies'}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildMemoryGrid(memories, date),
            const SizedBox(height: 16),
          ],
        );
      },
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaDetailView(
          asset: asset,
          assetList: context.read<MediaProvider>().mediaItems,
          heroTag: 'flashback_${asset.id}',
        ),
        fullscreenDialog: true,
      ),
    );
  }
}
