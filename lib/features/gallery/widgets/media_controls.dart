import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:summer_momentum/features/gallery/models/media.dart';

class MediaControls extends StatelessWidget {
  final MediaAsset asset;
  final bool isFullscreen;
  final VoidCallback onToggleFullscreen;
  final VoidCallback onClose;
  final VoidCallback onFavorite;
  final VoidCallback onShare;
  final VoidCallback onInfo;
  final VoidCallback onJournal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDetectObjects;
  final VoidCallback onAnalyzeImage;
  final VoidCallback onRecognizeText;
  final int? currentIndex;
  final int? totalCount;

  const MediaControls({
    super.key,
    required this.asset,
    required this.isFullscreen,
    required this.onToggleFullscreen,
    required this.onClose,
    required this.onFavorite,
    required this.onShare,
    required this.onInfo,
    required this.onJournal,
    required this.onEdit,
    required this.onDelete,
    required this.onDetectObjects,
    required this.onAnalyzeImage,
    required this.onRecognizeText,
    this.currentIndex,
    this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top bar with navigation and fullscreen
        _buildTopBar(context),

        // Bottom bar with main actions
        _buildBottomBar(context),

        // AI features bar (only for images)
        if (asset.type == MediaType.image) _buildAIFeaturesBar(context),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          right: 8,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onClose,
            ),
            if (currentIndex != null && totalCount != null)
              Expanded(
                child: Text(
                  '${currentIndex! + 1} / $totalCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            IconButton(
              icon: Icon(
                isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                color: Colors.white,
              ),
              onPressed: onToggleFullscreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                asset.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: asset.isFavorite ? Colors.red : Colors.white,
              ),
              onPressed: onFavorite,
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: onShare,
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              onPressed: onInfo,
            ),
            IconButton(
              icon: const Icon(Icons.book_outlined, color: Colors.white),
              onPressed: onJournal,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIFeaturesBar(BuildContext context) {
    return Positioned(
      bottom: 80, // Position above the bottom bar
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAIFeatureButton(
              icon: Icons.auto_awesome,
              label: 'Detect',
              onPressed: onDetectObjects,
            ),
            _buildAIFeatureButton(
              icon: Icons.analytics,
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
