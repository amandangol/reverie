import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/media_provider.dart';
import 'flashback_card.dart';
import 'package:photo_manager/photo_manager.dart';

class FlashbacksSection extends StatefulWidget {
  const FlashbacksSection({Key? key}) : super(key: key);

  @override
  State<FlashbacksSection> createState() => _FlashbacksSectionState();
}

class _FlashbacksSectionState extends State<FlashbacksSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mediaProvider = context.read<MediaProvider>();
      if (mediaProvider.isInitialized) {
        mediaProvider.loadWeeklyFlashbackPhotos();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (context, mediaProvider, _) {
        // Don't show anything if media is still loading
        if (!mediaProvider.isInitialized) {
          return const SizedBox.shrink();
        }

        if (mediaProvider.isLoadingWeeklyFlashbacks) {
          return Container(
            height: 220,
            padding: const EdgeInsets.all(16),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading memories...'),
                ],
              ),
            ),
          );
        }

        if (mediaProvider.weeklyFlashbackError != null) {
          return Container(
            height: 220,
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${mediaProvider.weeklyFlashbackError}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => mediaProvider.loadWeeklyFlashbackPhotos(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        final groupedPhotos =
            _groupPhotosByDate(mediaProvider.weeklyFlashbackPhotos);

        if (groupedPhotos.isEmpty) {
          return Container(
            height: 220,
            padding: const EdgeInsets.all(16),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined,
                      size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No memories found for this week',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          height: 220,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_view_week, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'On This Week',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () =>
                          mediaProvider.loadWeeklyFlashbackPhotos(),
                      tooltip: 'Refresh memories',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: groupedPhotos.length,
                  itemBuilder: (context, index) {
                    final date = groupedPhotos.keys.elementAt(index);
                    final photos = groupedPhotos[date]!;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FlashbackCard(
                        asset: photos.first,
                        assetList: photos,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<DateTime, List<AssetEntity>> _groupPhotosByDate(
      List<AssetEntity> photos) {
    final Map<DateTime, List<AssetEntity>> grouped = {};

    for (var photo in photos) {
      final date = photo.createDateTime;
      final dateKey = DateTime(date.year, date.month, date.day);

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(photo);
    }

    // Sort each group by time
    for (var photos in grouped.values) {
      photos.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
    }

    // Sort the dates in descending order
    return Map.fromEntries(
        grouped.entries.toList()..sort((a, b) => b.key.compareTo(a.key)));
  }
}
