import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:reverie/features/journal/providers/journal_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import '../provider/media_provider.dart';
import '../../journal/widgets/journal_entry_form.dart';
import '../../journal/models/journal_entry.dart';
import 'package:reverie/utils/media_utils.dart';
import 'package:reverie/utils/snackbar_utils.dart';

class AssetThumbnail extends StatelessWidget {
  final AssetEntity asset;
  final String? heroTag;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BoxFit boxFit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool isSelected;
  final bool showSelectionIndicator;
  final bool isSelectionMode;

  const AssetThumbnail({
    super.key,
    required this.asset,
    this.heroTag,
    this.onTap,
    this.boxFit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.onLongPress,
    this.isSelected = false,
    this.showSelectionIndicator = false,
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = Image(
      image: AssetEntityImageProvider(
        asset,
        isOriginal: false,
        thumbnailSize: const ThumbnailSize.square(300),
      ),
      fit: boxFit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        if (asset.type == AssetType.video) {
          return Container(
            width: width,
            height: height,
            color: Colors.black.withOpacity(0.1),
            child: const Center(
              child: Icon(
                Icons.video_library,
                color: Colors.white,
                size: 32,
              ),
            ),
          );
        }
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        if (asset.type == AssetType.video) {
          return Container(
            width: width,
            height: height,
            color: Colors.black.withOpacity(0.1),
            child: const Center(
              child: Icon(
                Icons.video_library,
                color: Colors.white,
                size: 32,
              ),
            ),
          );
        }
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: borderRadius,
            ),
          ),
        );
      },
    );

    if (heroTag != null) {
      image = Hero(
        tag: heroTag!,
        child: image,
      );
    }

    if (onTap != null || onLongPress != null) {
      image = GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: image,
      );
    }

    Widget content = ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: image,
    );

    if (showSelectionIndicator) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          content,
          if (isSelected)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
        ],
      );
    }

    if (!isSelectionMode && onTap != null) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          content,
          if (asset.type == AssetType.video)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Builder(
                      builder: (context) {
                        final duration =
                            context.read<MediaProvider>().getDuration(asset.id);
                        if (duration == null) return const SizedBox();
                        return Text(
                          MediaUtils.formatDuration(duration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: Builder(
                builder: (context) => PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 14,
                  ),
                  padding: EdgeInsets.zero,
                  iconSize: 14,
                  splashRadius: 14,
                  tooltip: 'Options',
                  offset: const Offset(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'journal',
                      height: 32,
                      child: Row(
                        children: [
                          const Icon(Icons.book, size: 14),
                          const SizedBox(width: 8),
                          Builder(
                            builder: (context) {
                              final hasEntries = context
                                  .read<JournalProvider>()
                                  .getEntriesByDateRange(
                                      DateTime.now(), DateTime.now())
                                  .isNotEmpty;
                              return Text(
                                hasEntries
                                    ? 'View in Journal'
                                    : 'Add to Journal',
                                style: const TextStyle(fontSize: 13),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'favorite',
                      height: 32,
                      child: Row(
                        children: [
                          Builder(
                            builder: (context) {
                              final isFavorite = context
                                  .read<MediaProvider>()
                                  .isFavorite(asset.id);
                              return Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 14,
                                color: isFavorite ? Colors.red : null,
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          Builder(
                            builder: (context) {
                              final isFavorite = context
                                  .read<MediaProvider>()
                                  .isFavorite(asset.id);
                              return Text(
                                isFavorite
                                    ? 'Remove from Favorites'
                                    : 'Add to Favorites',
                                style: const TextStyle(fontSize: 13),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'share',
                      height: 32,
                      child: Row(
                        children: [
                          Icon(Icons.share, size: 14),
                          SizedBox(width: 8),
                          Text(
                            'Share',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      height: 32,
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 14, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(fontSize: 13, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'journal':
                        _showQuickJournalEntryDialog(context, asset);
                        break;
                      case 'favorite':
                        _toggleFavorite(context, asset);
                        break;
                      case 'share':
                        _shareMedia(context, asset);
                        break;
                      case 'delete':
                        _deleteMedia(context, asset);
                        break;
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      );
    }

    return content;
  }

  void _showQuickJournalEntryDialog(BuildContext context, AssetEntity asset) {
    showDialog(
      context: context,
      builder: (context) => JournalEntryForm(
        initialMediaIds: [asset.id],
        onSave: (title, content, mediaIds, mood, tags) {
          final entry = JournalEntry(
            id: const Uuid().v4(),
            title: title,
            content: content,
            mediaIds: mediaIds,
            mood: mood,
            tags: tags,
            date: DateTime.now(),
          );
          context.read<JournalProvider>().addEntry(entry);
          Navigator.pop(context);
          SnackbarUtils.showJournalEntryCreated(
            context,
            title: title,
            onView: () {
              // Navigate to journal entry
              Navigator.pushNamed(context, '/journal');
            },
          );
        },
      ),
    );
  }

  void _toggleFavorite(BuildContext context, AssetEntity asset) async {
    try {
      final mediaProvider = context.read<MediaProvider>();
      final wasFavorite = mediaProvider.isFavorite(asset.id);
      await mediaProvider.toggleFavorite(asset);
      if (context.mounted) {
        if (wasFavorite) {
          SnackbarUtils.showMediaRemovedFromFavorites(context, count: 1);
        } else {
          SnackbarUtils.showMediaAddedToFavorites(
            context,
            count: 1,
            onView: () {
              Navigator.pushNamed(context, '/albums/favorites');
            },
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarUtils.showError(
            context, 'Failed to update favorites: ${e.toString()}');
      }
    }
  }

  void _shareMedia(BuildContext context, AssetEntity asset) async {
    try {
      final file = await asset.file;
      if (file != null) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text:
              'Check out this ${asset.type == AssetType.video ? 'video' : 'photo'}!',
        );
        if (context.mounted) {
          SnackbarUtils.showMediaShared(context, count: 1);
        }
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarUtils.showError(context, 'Failed to share: ${e.toString()}');
      }
    }
  }

  void _deleteMedia(BuildContext context, AssetEntity asset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Media'),
        content: const Text(
          'Are you sure you want to delete this item? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        final mediaProvider = context.read<MediaProvider>();
        await mediaProvider.deleteMedia(asset);
        if (context.mounted) {
          SnackbarUtils.showMediaDeleted(context, count: 1);
        }
      } catch (e) {
        if (context.mounted) {
          SnackbarUtils.showError(context, 'Failed to delete: ${e.toString()}');
        }
      }
    }
  }
}
