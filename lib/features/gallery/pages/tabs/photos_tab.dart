import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../../../../commonwidgets/empty_state.dart';
import '../../../../utils/snackbar_utils.dart';
import '../../../journal/models/journal_entry.dart';
import '../../../journal/providers/journal_provider.dart';
import '../../../journal/widgets/journal_entry_form.dart';
import '../../provider/media_provider.dart';
import '../../widgets/asset_thumbnail.dart';
import '../../widgets/media_detail_view.dart';
import 'package:reverie/utils/media_utils.dart';
import '../../../permissions/provider/permission_provider.dart';
import '../../../permissions/widgets/permission_dialog.dart';
import '../../../../commonwidgets/shimmer_loading.dart';

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
  bool _isSelectionMode = false;
  final Set<String> _selectedItems = {};
  String? _selectedCategory;

  void _toggleSelectionMode() {
    HapticFeedback.lightImpact();
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedItems.clear();
      }
    });
  }

  void _toggleItemSelection(String itemId) {
    setState(() {
      HapticFeedback.lightImpact();

      if (_selectedItems.contains(itemId)) {
        _selectedItems.remove(itemId);
      } else {
        _selectedItems.add(itemId);
      }
      if (_selectedItems.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  Future<void> _shareSelectedItems() async {
    final mediaProvider = context.read<MediaProvider>();
    final selectedAssets = mediaProvider.mediaItems
        .where((asset) => _selectedItems.contains(asset.id))
        .toList();

    if (selectedAssets.isEmpty) return;

    try {
      final files = await Future.wait(
        selectedAssets.map((asset) => asset.file),
      );
      final validFiles = files.where((file) => file != null).cast<File>();

      if (validFiles.isNotEmpty) {
        await Share.shareXFiles(
          validFiles.map((file) => XFile(file.path)).toList(),
          text: 'Check out these photos!',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to share: ${e.toString()}');
      }
    }
  }

  Future<void> _deleteSelectedItems() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Items'),
        content: Text(
          'Are you sure you want to delete ${_selectedItems.length} item${_selectedItems.length == 1 ? '' : 's'}? This action cannot be undone.',
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
      final mediaProvider = context.read<MediaProvider>();
      final selectedAssets = mediaProvider.mediaItems
          .where((asset) => _selectedItems.contains(asset.id))
          .toList();

      for (var asset in selectedAssets) {
        await mediaProvider.deleteMedia(asset);
      }

      setState(() {
        _selectedItems.clear();
        _isSelectionMode = false;
      });
    }
  }

  Future<void> _toggleFavoriteSelected() async {
    final mediaProvider = context.read<MediaProvider>();
    final selectedAssets = _selectedItems
        .map((id) =>
            mediaProvider.mediaItems.firstWhere((asset) => asset.id == id))
        .toList();

    for (var asset in selectedAssets) {
      await mediaProvider.toggleFavorite(asset);
    }

    setState(() {
      _selectedItems.clear();
      _isSelectionMode = false;
    });

    if (mounted) {
      SnackbarUtils.showMediaAddedToFavorites(
        context,
        count: selectedAssets.length,
        onView: () {
          Navigator.pushNamed(context, '/albums/favorites');
        },
      );
    }
  }

  Future<void> _addToJournalSelected() async {
    final mediaProvider = context.read<MediaProvider>();
    final selectedAssets = _selectedItems
        .map((id) =>
            mediaProvider.mediaItems.firstWhere((asset) => asset.id == id))
        .toList();

    if (selectedAssets.isEmpty) return;

    final mediaIds = selectedAssets.map((asset) => asset.id).toList();

    showDialog(
      context: context,
      builder: (context) => JournalEntryForm(
        initialMediaIds: mediaIds,
        onSave: (title, content, mediaIds, mood, tags, {DateTime? lastEdited}) {
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
        },
      ),
    );

    setState(() {
      _selectedItems.clear();
      _isSelectionMode = false;
    });
  }

  String _formatDate(DateTime date) {
    return MediaUtils.formatDate(date);
  }

  void _showMediaDetail(
      BuildContext context, AssetEntity asset, MediaProvider mediaProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaDetailView(
          asset: asset,
          assetList: mediaProvider.mediaItems,
          heroTag: 'media_${asset.id}',
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _handleMediaAction(
      BuildContext context, String action, AssetEntity asset) {
    switch (action) {
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
  }

  void _showQuickJournalEntryDialog(BuildContext context, AssetEntity asset) {
    showDialog(
      context: context,
      builder: (context) => JournalEntryForm(
        initialMediaIds: [asset.id],
        onSave: (title, content, mediaIds, mood, tags, {DateTime? lastEdited}) {
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
              // Navigate to favorites album
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

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (context, mediaProvider, child) {
        if (mediaProvider.isLoading) {
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
          return EmptyState(
            title: 'No media found',
            subtitle: 'There are no photos in your gallery',
            onRefresh: () => _checkAndRequestPermission(context),
          );
        }

        // Get filtered media items based on selected category
        final mediaItems = _selectedCategory != null
            ? mediaProvider.getAssetsByCategory(_selectedCategory!)
            : mediaProvider.mediaItems;

        final groupedPhotos = _groupPhotosByDate(mediaItems);

        return Column(
          children: [
            if (mediaProvider.isBackgroundProcessing)
              LinearProgressIndicator(
                value: mediaProvider.categorizationProgress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  _isSelectionMode
                      ? Text('${_selectedItems.length} selected')
                      : const Text(
                          'All Photos',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                  const Spacer(),
                  if (!_isSelectionMode) ...[
                    if (!mediaProvider.isInitialCategorizationDone)
                      TextButton.icon(
                        icon: const Icon(Icons.category),
                        label: const Text('Categorize Photos'),
                        onPressed: () => mediaProvider.startCategorization(),
                      ),
                    if (mediaProvider.isCategorizing)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(mediaProvider.categorizationProgress * 100).toInt()}%',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                  ],
                  if (_isSelectionMode) ...[
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed:
                          _selectedItems.isEmpty ? null : _shareSelectedItems,
                      tooltip: 'Share selected',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed:
                          _selectedItems.isEmpty ? null : _deleteSelectedItems,
                      tooltip: 'Delete selected',
                    ),
                    IconButton(
                      icon: const Icon(Icons.favorite),
                      onPressed: _selectedItems.isEmpty
                          ? null
                          : _toggleFavoriteSelected,
                      tooltip: 'Add to favorites',
                    ),
                    IconButton(
                      icon: const Icon(Icons.book),
                      onPressed:
                          _selectedItems.isEmpty ? null : _addToJournalSelected,
                      tooltip: 'Add to journal',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _toggleSelectionMode,
                      tooltip: 'Exit selection mode',
                    ),
                  ],
                  IconButton(
                    icon: _isSelectionMode
                        ? const Icon(Icons.check_box)
                        : const Icon(Icons.select_all),
                    onPressed: _toggleSelectionMode,
                    tooltip: 'Select items',
                  ),
                ],
              ),
            ),
            _buildCategoryChips(mediaProvider),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (scrollInfo is ScrollEndNotification) {
                    // Process visible assets when scrolling stops
                    final visibleAssets = _getVisibleAssets(scrollInfo.metrics);
                    mediaProvider.processVisibleAssets(visibleAssets);

                    // Load more photos if needed
                    if (scrollInfo.metrics.pixels >=
                        scrollInfo.metrics.maxScrollExtent * 0.8) {
                      mediaProvider.loadMorePhotos();
                    }
                  }
                  return true;
                },
                child: widget.isGridView
                    ? _buildPhotoGridByDate(groupedPhotos, mediaProvider)
                    : _buildPhotoListByDate(groupedPhotos, mediaProvider),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkAndRequestPermission(BuildContext context) async {
    final permissionProvider = context.read<PermissionProvider>();
    final granted = await permissionProvider.requestMediaPermission();
    if (granted) {
      context.read<MediaProvider>().requestPermission();
    }
  }

  void _showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onRequestPermission,
    required VoidCallback onOpenSettings,
  }) {
    showDialog(
      context: context,
      builder: (context) => PermissionDialog(
        title: title,
        message: message,
        onRequestPermission: onRequestPermission,
        onOpenSettings: onOpenSettings,
      ),
    );
  }

  Widget _buildPhotoGridByDate(Map<DateTime, List<AssetEntity>> groupedPhotos,
      MediaProvider mediaProvider) {
    return ListView.builder(
      itemCount: groupedPhotos.length + (mediaProvider.hasMorePhotos ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == groupedPhotos.length) {
          if (mediaProvider.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
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
                return _buildMediaGridItem(asset, mediaProvider);
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildMediaGridItem(AssetEntity asset, MediaProvider mediaProvider) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AssetThumbnail(
          asset: asset,
          heroTag: 'media_${asset.id}',
          onTap: _isSelectionMode
              ? () => _toggleItemSelection(asset.id)
              : () => _showMediaDetail(context, asset, mediaProvider),
          onLongPress: () {
            if (!_isSelectionMode) {
              _toggleSelectionMode();
              _toggleItemSelection(asset.id);
            }
          },
          isSelected: _selectedItems.contains(asset.id),
          showSelectionIndicator: _isSelectionMode,
          isSelectionMode: _isSelectionMode,
        ),
        if (!_isSelectionMode &&
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

  Widget _buildPhotoListByDate(Map<DateTime, List<AssetEntity>> groupedPhotos,
      MediaProvider mediaProvider) {
    return ListView.builder(
      itemCount: groupedPhotos.length + (mediaProvider.hasMorePhotos ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == groupedPhotos.length) {
          if (mediaProvider.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
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
            ...photos.map((asset) => Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    onTap: _isSelectionMode
                        ? () => _toggleItemSelection(asset.id)
                        : () => _showMediaDetail(
                              context,
                              asset,
                              mediaProvider,
                            ),
                    onLongPress: () {
                      if (!_isSelectionMode) {
                        _toggleSelectionMode();
                        _toggleItemSelection(asset.id);
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
                                heroTag: 'media_${asset.id}',
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  bottomLeft: Radius.circular(8),
                                ),
                                isSelected: _selectedItems.contains(asset.id),
                                showSelectionIndicator: _isSelectionMode,
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
                        if (!_isSelectionMode)
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
                                            .getEntriesByDateRange(
                                                DateTime.now(), DateTime.now())
                                            .isNotEmpty;
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
                            onSelected: (value) {
                              _handleMediaAction(context, value, asset);
                            },
                          ),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 16),
          ],
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

  Widget _buildCategoryChips(MediaProvider mediaProvider) {
    final categories = mediaProvider.getAllCategories();
    if (categories.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1, // +1 for "All" category
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: FilterChip(
                avatar: const Icon(Icons.photo_library, size: 16),
                label: const Text('All'),
                selected: _selectedCategory == null,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = null;
                  });
                },
              ),
            );
          }

          final category = categories[index - 1];
          return Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: FilterChip(
              avatar: Icon(
                mediaProvider.getCategoryIcon(category),
                size: 16,
                color: _selectedCategory == category
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
              ),
              label: Text(category),
              selected: _selectedCategory == category,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? category : null;
                });
              },
            ),
          );
        },
      ),
    );
  }

  List<AssetEntity> _getVisibleAssets(ScrollMetrics metrics) {
    final mediaProvider = context.read<MediaProvider>();
    final items = mediaProvider.mediaItems;
    final itemHeight = 200.0; // Approximate height of each item
    final startIndex = (metrics.pixels / itemHeight).floor();
    final endIndex =
        ((metrics.pixels + metrics.viewportDimension) / itemHeight).ceil();

    return items.sublist(
      startIndex.clamp(0, items.length),
      endIndex.clamp(0, items.length),
    );
  }
}
