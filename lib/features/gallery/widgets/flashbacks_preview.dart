import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import '../provider/media_provider.dart';
import '../provider/flashback_provider.dart';
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
    final flashbackProvider = context.read<FlashbackProvider>();

    await flashbackProvider.clearFlashbacksCache();
    await Future.wait([
      flashbackProvider.loadFlashbackPhotos(mediaProvider.allMediaItems),
      flashbackProvider.loadWeeklyFlashbackPhotos(mediaProvider.allMediaItems),
      flashbackProvider.loadMonthlyFlashbackPhotos(mediaProvider.allMediaItems),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MediaProvider, FlashbackProvider>(
      builder: (context, mediaProvider, flashbackProvider, child) {
        // Show loading state if any of the flashback types are loading
        if (flashbackProvider.isLoadingFlashbacks ||
            flashbackProvider.isLoadingWeeklyFlashbacks ||
            flashbackProvider.isLoadingMonthlyFlashbacks) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final totalMemories = flashbackProvider.flashbackPhotos.length +
            flashbackProvider.weeklyFlashbackPhotos.length +
            flashbackProvider.monthlyFlashbackPhotos.length;

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
                            flashbackProvider.flashbackPhotos.isNotEmpty
                                ? flashbackProvider.flashbackPhotos.first
                                : null,
                          ),
                        ),
                        Expanded(
                          child: _buildPreviewImage(
                            flashbackProvider.weeklyFlashbackPhotos.isNotEmpty
                                ? flashbackProvider.weeklyFlashbackPhotos.first
                                : null,
                          ),
                        ),
                        Expanded(
                          child: _buildPreviewImage(
                            flashbackProvider.monthlyFlashbackPhotos.isNotEmpty
                                ? flashbackProvider.monthlyFlashbackPhotos.first
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
                          Text(
                            '${_getMonthName(DateTime.now().month)} Memories',
                            style: const TextStyle(
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (asset != null)
            AssetThumbnail(
              asset: asset,
              boxFit: BoxFit.cover,
            )
          else
            const Center(
              child: Icon(
                Icons.photo,
                color: Colors.white54,
                size: 32,
              ),
            ),
          // Month name overlay
          // if (asset != null)
          //   Positioned(
          //     top: 8,
          //     left: 8,
          //     child: Container(
          //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          //       decoration: BoxDecoration(
          //         color: Colors.black.withOpacity(0.6),
          //         borderRadius: BorderRadius.circular(4),
          //       ),
          //       child: Text(
          //         _getMonthName(asset.createDateTime.month),
          //         style: const TextStyle(
          //           color: Colors.white,
          //           fontSize: 12,
          //           fontWeight: FontWeight.w500,
          //         ),
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }

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
}
