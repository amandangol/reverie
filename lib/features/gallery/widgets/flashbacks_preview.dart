import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/media_provider.dart';
import 'asset_thumbnail.dart';

class FlashbacksPreview extends StatelessWidget {
  final VoidCallback onTap;
  final bool showInSelectionMode;

  const FlashbacksPreview({
    super.key,
    required this.onTap,
    this.showInSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
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
                      child: Consumer<MediaProvider>(
                        builder: (context, mediaProvider, _) {
                          final memories = mediaProvider.flashbackPhotos;
                          if (memories.isEmpty) {
                            return Container(
                              color: Colors.black.withOpacity(0.1),
                              child: const Center(
                                child: Icon(
                                  Icons.history,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            );
                          }
                          return AssetThumbnail(
                            asset: memories.first,
                            boxFit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: Consumer<MediaProvider>(
                        builder: (context, mediaProvider, _) {
                          final memories = mediaProvider.weeklyFlashbackPhotos;
                          if (memories.isEmpty) {
                            return Container(
                              color: Colors.black.withOpacity(0.1),
                            );
                          }
                          return AssetThumbnail(
                            asset: memories.first,
                            boxFit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: Consumer<MediaProvider>(
                        builder: (context, mediaProvider, _) {
                          final memories = mediaProvider.monthlyFlashbackPhotos;
                          if (memories.isEmpty) {
                            return Container(
                              color: Colors.black.withOpacity(0.1),
                            );
                          }
                          return AssetThumbnail(
                            asset: memories.first,
                            boxFit: BoxFit.cover,
                          );
                        },
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
                      Consumer<MediaProvider>(
                        builder: (context, mediaProvider, _) {
                          final totalMemories =
                              mediaProvider.flashbackPhotos.length +
                                  mediaProvider.weeklyFlashbackPhotos.length +
                                  mediaProvider.monthlyFlashbackPhotos.length;
                          return Text(
                            '$totalMemories memories',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          );
                        },
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
  }
}
