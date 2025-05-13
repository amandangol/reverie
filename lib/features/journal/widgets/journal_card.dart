import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:intl/intl.dart';
import '../providers/journal_provider.dart';
import '../models/journal_entry.dart';

class JournalCard extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onTap;
  final bool showHero;
  final double aspectRatio;

  const JournalCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.showHero = true,
    this.aspectRatio = 0.85,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildEntryImage(context),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatDate(entry.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    // if (entry.mood != null && entry.mood!.isNotEmpty)
                    //   Positioned(
                    //     top: 8,
                    //     right: 8,
                    //     child: Container(
                    //       padding: const EdgeInsets.symmetric(
                    //         horizontal: 8,
                    //         vertical: 4,
                    //       ),
                    //       decoration: BoxDecoration(
                    //         color: Colors.black.withOpacity(0.5),
                    //         borderRadius: BorderRadius.circular(8),
                    //       ),
                    //       child: Row(
                    //         mainAxisSize: MainAxisSize.min,
                    //         children: [
                    //           Icon(
                    //             MediaUtils.getMoodIcon(entry.mood!),
                    //             size: 16,
                    //             color: _getMoodColor(entry.mood!),
                    //           ),
                    //           const SizedBox(width: 4),
                    //           Text(
                    //             entry.mood!,
                    //             style: theme.textTheme.bodySmall?.copyWith(
                    //               color: Colors.white,
                    //               fontWeight: FontWeight.w500,
                    //             ),
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          entry.content,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (entry.tags.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        _buildTagsRow(theme),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return showHero
        ? Hero(
            tag: 'journal_${entry.id}',
            child: card,
          )
        : card;
  }

  Widget _buildEntryImage(BuildContext context) {
    if (entry.mediaIds.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.3),
              Theme.of(context).colorScheme.secondary.withOpacity(0.3),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.auto_stories_rounded,
            size: 32,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ),
        ),
      );
    }

    final journalProvider = Provider.of<JournalProvider>(context);
    final cachedAsset = journalProvider.imageCache[entry.mediaIds.first];

    if (cachedAsset != null) {
      return _buildImageWithShader(cachedAsset);
    }

    return FutureBuilder<AssetEntity?>(
      future: journalProvider.getImageAsset(entry.mediaIds.first),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
            ),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          );
        }

        final asset = snapshot.data;
        if (asset != null) {
          return _buildImageWithShader(asset);
        }

        return _buildImageErrorPlaceholder(context);
      },
    );
  }

  Widget _buildImageWithShader(AssetEntity asset) {
    return ShaderMask(
      shaderCallback: (rect) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.6),
            Colors.black.withOpacity(0.1),
          ],
          stops: const [0.0, 0.3],
        ).createShader(rect);
      },
      blendMode: BlendMode.darken,
      child: Image(
        image: AssetEntityImageProvider(
          asset,
          isOriginal: false,
          thumbnailSize: const ThumbnailSize(600, 600),
        ),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImageErrorPlaceholder(context);
        },
      ),
    );
  }

  Widget _buildImageErrorPlaceholder(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_rounded,
              size: 32,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Image unavailable',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsRow(ThemeData theme) {
    return SizedBox(
      height: 18,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          for (var i = 0; i < entry.tags.length && i < 2; i++)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  entry.tags[i],
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.surfaceContainerHighest,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          if (entry.tags.length > 2)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+${entry.tags.length - 2}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'excited':
      case 'joyful':
        return Colors.amber;
      case 'calm':
      case 'relaxed':
        return Colors.lightBlue;
      case 'sad':
      case 'depressed':
        return Colors.blueGrey;
      case 'angry':
      case 'frustrated':
        return Colors.redAccent;
      case 'anxious':
      case 'worried':
        return Colors.deepPurple;
      default:
        return Colors.white;
    }
  }
}
