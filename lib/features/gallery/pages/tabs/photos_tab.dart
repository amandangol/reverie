import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:reverie/widgets/empty_state.dart';
import 'package:reverie/widgets/shimmer_loading.dart';
import 'package:uuid/uuid.dart';
import '../../../../utils/snackbar_utils.dart';
import '../../../journal/providers/journal_provider.dart';
import '../../../journal/models/journal_entry.dart';
import '../../../journal/widgets/journal_entry_form.dart';
import '../../provider/media_provider.dart';
import '../../provider/photo_operations_provider.dart';
import '../../widgets/asset_thumbnail.dart';
import '../media_detail_view.dart';
import 'package:reverie/utils/media_utils.dart';
import '../../../permissions/provider/permission_provider.dart';

class PhotosTab extends StatefulWidget {
  final bool isGridView;
  final int gridCrossAxisCount;

  const PhotosTab({
    super.key,
    required this.isGridView,
    required this.gridCrossAxisCount,
  });

  @override
  State<PhotosTab> createState() => _PhotosTabState();
}

class _PhotosTabState extends State<PhotosTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<MediaProvider, PhotoOperationsProvider>(
      builder: (context, mediaProvider, photoOps, child) {
        if (mediaProvider.isLoading && !mediaProvider.isInitialized) {
          return Column(
            children: [
              Expanded(
                child: ShimmerLoading(
                  isGridView: widget.isGridView,
                  gridCrossAxisCount: widget.gridCrossAxisCount,
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('Loading photos...'),
                  ],
                ),
              ),
            ],
          );
        }

        if (mediaProvider.mediaItems.isEmpty) {
          return Column(
            children: [
              const Divider(),
              Expanded(
                child: EmptyState(
                  title: 'No media found',
                  subtitle: 'There are no photos in your gallery',
                  onRefresh: () => _checkAndRequestPermission(context),
                ),
              ),
            ],
          );
        }

        final groupedPhotos = _groupPhotosByDate(mediaProvider.mediaItems);

        return Column(
          children: [
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        photoOps.isSelectionMode
                            ? Row(
                                children: [
                                  Text(
                                    '${photoOps.selectedCount} selected',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  TextButton(
                                    onPressed: photoOps.toggleSelectionMode,
                                    child: const Text('Cancel'),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  const Text(
                                    'All Photos',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '(${mediaProvider.mediaItems.length} photos)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                ],
                              ),
                        IconButton(
                          icon: photoOps.isSelectionMode
                              ? const Icon(Icons.check_box)
                              : const Icon(Icons.select_all),
                          onPressed: photoOps.toggleSelectionMode,
                          tooltip: 'Select items',
                        ),
                      ],
                    ),
                  ),
                  if (photoOps.isSelectionMode)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSelectionActionButton(
                            icon: Icons.share,
                            onPressed: photoOps.selectedItems.isEmpty
                                ? null
                                : () => _handleShareSelected(
                                    photoOps, mediaProvider),
                          ),
                          _buildSelectionActionButton(
                            icon: Icons.delete,
                            onPressed: photoOps.selectedItems.isEmpty
                                ? null
                                : () => _handleDeleteSelected(
                                    photoOps, mediaProvider),
                          ),
                          _buildSelectionActionButton(
                            icon: Icons.favorite,
                            onPressed: photoOps.selectedItems.isEmpty
                                ? null
                                : () => _handleFavoriteSelected(
                                    photoOps, mediaProvider),
                          ),
                          _buildSelectionActionButton(
                            icon: Icons.book,
                            onPressed: photoOps.selectedItems.isEmpty
                                ? null
                                : () => _handleJournalSelected(photoOps),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  if (widget.isGridView)
                    _buildPhotoGridByDate(
                        groupedPhotos, mediaProvider, photoOps)
                  else
                    _buildPhotoListByDate(
                        groupedPhotos, mediaProvider, photoOps),
                  if (mediaProvider.isLoadingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSelectionActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      color: onPressed == null ? Colors.grey : null,
    );
  }

  Future<void> _handleShareSelected(
      PhotoOperationsProvider photoOps, MediaProvider mediaProvider) async {
    try {
      await photoOps.shareSelectedItems(mediaProvider.mediaItems);
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to share: ${e.toString()}');
      }
    }
  }

  Future<void> _handleDeleteSelected(
      PhotoOperationsProvider photoOps, MediaProvider mediaProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Items'),
        content: Text(
          'Are you sure you want to delete ${photoOps.selectedCount} item${photoOps.selectedCount == 1 ? '' : 's'}? This action cannot be undone.',
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
        await photoOps.deleteSelectedItems(
            mediaProvider.mediaItems, mediaProvider);
        if (mounted) {
          SnackbarUtils.showMediaDeleted(context,
              count: photoOps.selectedCount);
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtils.showError(context, 'Failed to delete: ${e.toString()}');
        }
      }
    }
  }

  Future<void> _handleFavoriteSelected(
      PhotoOperationsProvider photoOps, MediaProvider mediaProvider) async {
    try {
      final successCount =
          await photoOps.toggleFavoriteSelected(mediaProvider.mediaItems);
      if (mounted && successCount > 0) {
        SnackbarUtils.showMediaAddedToFavorites(
          context,
          count: successCount,
          onView: () {
            Navigator.pushNamed(context, '/albums/favorites');
          },
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(
            context, 'Failed to update favorites: ${e.toString()}');
      }
    }
  }

  Future<void> _handleJournalSelected(PhotoOperationsProvider photoOps) async {
    try {
      final mediaIds = await photoOps
          .addToJournalSelected(context.read<MediaProvider>().mediaItems);
      if (!mounted || mediaIds.isEmpty) return;

      // Check if any of these media items are already in journal entries
      final journalProvider = context.read<JournalProvider>();
      final existingEntries = journalProvider.entries
          .where((entry) => entry.mediaIds.any((id) => mediaIds.contains(id)))
          .toList();

      if (existingEntries.isNotEmpty) {
        if (!mounted) return;
        // Show dialog to inform user
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Media Already in Journal'),
            content: Text(
                'Some of the selected media are already in ${existingEntries.length} journal entry${existingEntries.length == 1 ? '' : 's'}. '
                'Would you like to create a new entry anyway?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Create New Entry'),
              ),
            ],
          ),
        );
      }

      if (!mounted) return;

      // Show journal entry form as a dialog
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => JournalEntryForm(
          initialMediaIds: mediaIds,
          onSave: (title, content, mediaIds, mood, tags, {lastEdited}) async {
            try {
              final journalProvider = context.read<JournalProvider>();
              final entry = JournalEntry(
                id: const Uuid().v4(),
                title: title,
                content: content,
                date: DateTime.now(),
                mediaIds: mediaIds,
                mood: mood,
                tags: tags,
                lastEdited: lastEdited,
              );

              final success = await journalProvider.addEntry(entry);
              if (success && mounted) {
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Journal entry created successfully'),
                    backgroundColor: Color(0xFF34A853),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                Navigator.pop(context, false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Failed to create journal entry: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      );

      // Refresh the media provider to update any changes
      if (result == true && mounted) {
        await context.read<MediaProvider>().loadMedia();
        // Ensure we're still mounted after the async operation
        if (mounted) {
          setState(() {}); // Force UI refresh
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(
            context, 'Failed to add to journal: ${e.toString()}');
      }
    }
  }

  Future<void> _checkAndRequestPermission(BuildContext context) async {
    final permissionProvider = context.read<PermissionProvider>();
    final granted = await permissionProvider.requestMediaPermission();
    if (granted) {
      context.read<MediaProvider>().requestPermission();
    }
  }

  Widget _buildPhotoGridByDate(
    Map<DateTime, List<AssetEntity>> groupedPhotos,
    MediaProvider mediaProvider,
    PhotoOperationsProvider photoOps,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == groupedPhotos.length) {
            return const SizedBox.shrink();
          }

          final date = groupedPhotos.keys.elementAt(index);
          final photos = groupedPhotos[date]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _formatDate(date),
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
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${photos.length} item${photos.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(2),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: widget.gridCrossAxisCount,
                  crossAxisSpacing: 2.0,
                  mainAxisSpacing: 2.0,
                ),
                itemCount: photos.length,
                itemBuilder: (context, photoIndex) {
                  final asset = photos[photoIndex];
                  return _buildMediaGridItem(asset, mediaProvider, photoOps);
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        },
        childCount: groupedPhotos.length + 1,
      ),
    );
  }

  Widget _buildMediaGridItem(
    AssetEntity asset,
    MediaProvider mediaProvider,
    PhotoOperationsProvider photoOps,
  ) {
    // Create a unique hero tag that includes the creation timestamp
    final heroTag =
        'grid_media_${asset.id}_${asset.createDateTime.millisecondsSinceEpoch}';

    return Stack(
      fit: StackFit.expand,
      children: [
        AssetThumbnail(
          asset: asset,
          heroTag: heroTag,
          onTap: photoOps.isSelectionMode
              ? () => photoOps.toggleItemSelection(asset.id)
              : () => _showMediaDetail(context, asset, mediaProvider),
          onLongPress: () {
            if (!photoOps.isSelectionMode) {
              photoOps.toggleSelectionMode();
              photoOps.toggleItemSelection(asset.id);
            }
          },
          isSelected: photoOps.selectedItems.contains(asset.id),
          showSelectionIndicator: photoOps.isSelectionMode,
          isSelectionMode: photoOps.isSelectionMode,
        ),
        if (!photoOps.isSelectionMode &&
            (mediaProvider.isFavorite(asset.id) ||
                asset.type == AssetType.video))
          Positioned(
            bottom: 4,
            right: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (mediaProvider.isFavorite(asset.id))
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 12,
                    ),
                  ),
                const SizedBox(width: 2),
                if (asset.type == AssetType.video)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
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
                        Consumer<MediaProvider>(
                          builder: (context, mediaProvider, _) {
                            final duration =
                                mediaProvider.getDuration(asset.id);
                            if (duration == null) {
                              return const SizedBox();
                            }
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
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoListByDate(
    Map<DateTime, List<AssetEntity>> groupedPhotos,
    MediaProvider mediaProvider,
    PhotoOperationsProvider photoOps,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == groupedPhotos.length) {
            return const SizedBox.shrink();
          }

          final date = groupedPhotos.keys.elementAt(index);
          final photos = groupedPhotos[date]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Text(
                      MediaUtils.formatDate(date),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${photos.length} photo${photos.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ...photos.map((asset) {
                // Create a unique hero tag that includes the creation timestamp
                final heroTag =
                    'list_media_${asset.id}_${asset.createDateTime.millisecondsSinceEpoch}';

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    onTap: photoOps.isSelectionMode
                        ? () => photoOps.toggleItemSelection(asset.id)
                        : () => _showMediaDetail(
                              context,
                              asset,
                              mediaProvider,
                            ),
                    onLongPress: () {
                      if (!photoOps.isSelectionMode) {
                        photoOps.toggleSelectionMode();
                        photoOps.toggleItemSelection(asset.id);
                      }
                    },
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              AssetThumbnail(
                                asset: asset,
                                heroTag: heroTag,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  bottomLeft: Radius.circular(8),
                                ),
                                isSelected:
                                    photoOps.selectedItems.contains(asset.id),
                                showSelectionIndicator:
                                    photoOps.isSelectionMode,
                              ),
                              if (asset.type == AssetType.video)
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    asset.type == AssetType.video
                                        ? Icons.videocam
                                        : Icons.photo,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      asset.title ?? 'Untitled',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Consumer<MediaProvider>(
                                builder: (context, mediaProvider, child) {
                                  final date =
                                      mediaProvider.getCreateDate(asset.id);
                                  if (date == null) return const SizedBox();

                                  return Text(
                                    MediaUtils.formatDimensions(asset.size),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        if (!photoOps.isSelectionMode)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            itemBuilder: (context) => [
                              PopupMenuItem<String>(
                                value: 'journal',
                                child: Row(
                                  children: [
                                    const Icon(Icons.book, size: 16),
                                    const SizedBox(width: 8),
                                    Builder(
                                      builder: (context) {
                                        final hasEntries = context
                                            .read<JournalProvider>()
                                            .entries
                                            .any((entry) => entry.mediaIds
                                                .contains(asset.id));
                                        return Text(
                                          hasEntries
                                              ? 'View in Journal'
                                              : 'Add to Journal',
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'favorite',
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
                                          size: 16,
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
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'share',
                                child: Row(
                                  children: [
                                    Icon(Icons.share, size: 16),
                                    SizedBox(width: 8),
                                    Text('Share'),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) async {
                              switch (value) {
                                case 'journal':
                                  final mediaIds =
                                      await photoOps.addToJournal(asset);
                                  if (mounted && mediaIds.isNotEmpty) {
                                    // Show journal entry form as a dialog
                                    final result = await showDialog<bool>(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) => JournalEntryForm(
                                        initialMediaIds: mediaIds,
                                        onSave: (title, content, mediaIds, mood,
                                            tags,
                                            {lastEdited}) async {
                                          try {
                                            final journalProvider =
                                                context.read<JournalProvider>();
                                            final entry = JournalEntry(
                                              id: const Uuid().v4(),
                                              title: title,
                                              content: content,
                                              date: DateTime.now(),
                                              mediaIds: mediaIds,
                                              mood: mood,
                                              tags: tags,
                                              lastEdited: lastEdited,
                                            );

                                            final success =
                                                await journalProvider
                                                    .addEntry(entry);
                                            if (success && mounted) {
                                              Navigator.pop(context, true);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Journal entry created successfully'),
                                                  backgroundColor:
                                                      Color(0xFF34A853),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              Navigator.pop(context, false);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Failed to create journal entry: ${e.toString()}'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    );

                                    // Refresh the media provider to update any changes
                                    if (result == true && mounted) {
                                      await context
                                          .read<MediaProvider>()
                                          .loadMedia();
                                      // Ensure we're still mounted after the async operation
                                      if (mounted) {
                                        setState(() {}); // Force UI refresh
                                      }
                                    }
                                  } else if (mounted) {
                                    // Show message if media is already in a journal entry
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'This media is already in a journal entry'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                  break;
                                case 'favorite':
                                  await photoOps.toggleFavorite(asset);
                                  break;
                                case 'share':
                                  await photoOps.shareMedia(asset);
                                  break;
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
          );
        },
        childCount: groupedPhotos.length + 1,
      ),
    );
  }

  void _showMediaDetail(
      BuildContext context, AssetEntity asset, MediaProvider mediaProvider) {
    // Create a unique hero tag that includes the creation timestamp
    final heroTag =
        'detail_media_${asset.id}_${asset.createDateTime.millisecondsSinceEpoch}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaDetailView(
          asset: asset,
          assetList: mediaProvider.mediaItems,
          heroTag: heroTag,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return MediaUtils.formatDate(date);
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

  void _openMediaDetail(AssetEntity asset) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaDetailView(asset: asset),
      ),
    );

    if (result != null && result is AssetEntity) {
      // Refresh the media list to show the edited image
      context.read<MediaProvider>().refreshMedia();
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverAppBarDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 100.0;

  @override
  double get minExtent => 100.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
