import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class MediaControls extends StatelessWidget {
  final bool showControls;
  final bool isFullScreen;
  final bool showInfo;
  final bool showJournal;
  final int currentIndex;
  final int totalItems;
  final VoidCallback onClose;
  final VoidCallback onToggleInfo;
  final VoidCallback onToggleJournal;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onDetectObjects;
  final VoidCallback onAnalyzeImage;
  final VoidCallback onRecognizeText;
  final VoidCallback onEdit;
  final Widget Function(BuildContext) favoriteButtonBuilder;
  final AssetEntity? currentAsset;

  const MediaControls({
    super.key,
    required this.showControls,
    required this.isFullScreen,
    required this.showInfo,
    required this.showJournal,
    required this.currentIndex,
    required this.totalItems,
    required this.onClose,
    required this.onToggleInfo,
    required this.onToggleJournal,
    required this.onShare,
    required this.onDelete,
    required this.onDetectObjects,
    required this.onAnalyzeImage,
    required this.onRecognizeText,
    required this.onEdit,
    required this.favoriteButtonBuilder,
    required this.currentAsset,
  });

  @override
  Widget build(BuildContext context) {
    if (!showControls) return const SizedBox.shrink();

    return Stack(
      children: [
        // Top bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0),
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onClose,
                  ),
                  const Spacer(),
                  Text(
                    '${currentIndex + 1}/$totalItems',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // AI Features Row (only for images)
                  if (currentAsset?.type == AssetType.image)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildAIFeatureButton(
                            icon: Icons.search,
                            label: 'Detect',
                            onPressed: onDetectObjects,
                          ),
                          _buildAIFeatureButton(
                            icon: Icons.auto_awesome,
                            label: 'Analyze',
                            onPressed: onAnalyzeImage,
                          ),
                          _buildAIFeatureButton(
                            icon: Icons.text_fields,
                            label: 'Text',
                            onPressed: onRecognizeText,
                          ),
                        ],
                      ),
                    ),
                  // Main Actions Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      favoriteButtonBuilder(context),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: onEdit,
                      ),
                      IconButton(
                        icon: const Icon(Icons.book_outlined,
                            color: Colors.white),
                        onPressed: onToggleJournal,
                      ),
                      // More options menu
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) {
                          switch (value) {
                            case 'share':
                              onShare();
                              break;
                            case 'info':
                              onToggleInfo();
                              break;
                            case 'delete':
                              onDelete();
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'share',
                            child: Row(
                              children: [
                                Icon(Icons.share, color: Colors.white),
                                SizedBox(width: 8),
                                Text('Share'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'info',
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.white),
                                SizedBox(width: 8),
                                Text('Info'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAIFeatureButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: onPressed,
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
