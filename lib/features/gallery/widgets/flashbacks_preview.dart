import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import '../provider/media_provider.dart';
import 'asset_thumbnail.dart';

class FlashbacksPreview extends StatefulWidget {
  const FlashbacksPreview({super.key});

  @override
  State<FlashbacksPreview> createState() => _FlashbacksPreviewState();
}

class _FlashbacksPreviewState extends State<FlashbacksPreview> {
  @override
  void initState() {
    super.initState();
    // Load flashbacks when the preview is first shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFlashbacks();
    });
  }

  Future<void> _loadFlashbacks() async {
    final mediaProvider = context.read<MediaProvider>();
    // Always reload flashbacks when preview is shown
    await mediaProvider.clearFlashbacksCache();
    await Future.wait([
      mediaProvider.loadFlashbackPhotos(),
      mediaProvider.loadWeeklyFlashbackPhotos(),
      mediaProvider.loadMonthlyFlashbackPhotos(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (context, mediaProvider, child) {
        // Show loading state if any of the flashback types are loading
        if (mediaProvider.isLoadingFlashbacks ||
            mediaProvider.isLoadingWeeklyFlashbacks ||
            mediaProvider.isLoadingMonthlyFlashbacks) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final totalMemories = mediaProvider.flashbackPhotos.length +
            mediaProvider.weeklyFlashbackPhotos.length +
            mediaProvider.monthlyFlashbackPhotos.length;

        if (totalMemories == 0) {
          return const SizedBox.shrink();
        }

        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/flashbacks');
            },
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.amber[700]!,
                    Colors.orange[800]!,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Flashback preview images
                  Positioned.fill(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildPreviewImage(
                            mediaProvider.flashbackPhotos.isNotEmpty
                                ? mediaProvider.flashbackPhotos.first
                                : null,
                          ),
                        ),
                        Expanded(
                          child: _buildPreviewImage(
                            mediaProvider.weeklyFlashbackPhotos.isNotEmpty
                                ? mediaProvider.weeklyFlashbackPhotos.first
                                : null,
                          ),
                        ),
                        Expanded(
                          child: _buildPreviewImage(
                            mediaProvider.monthlyFlashbackPhotos.isNotEmpty
                                ? mediaProvider.monthlyFlashbackPhotos.first
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.history,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Flashback Memories',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$totalMemories memories',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewImage(AssetEntity? asset) {
    return Container(
      color: Colors.black.withOpacity(0.1),
      child: asset != null
          ? AssetThumbnail(
              asset: asset,
              boxFit: BoxFit.cover,
            )
          : const Center(
              child: Icon(
                Icons.photo,
                color: Colors.white54,
                size: 32,
              ),
            ),
    );
  }
}
