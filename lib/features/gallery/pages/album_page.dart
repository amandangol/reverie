import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:reverie/utils/media_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../../commonwidgets/empty_state.dart';
import '../../../utils/snackbar_utils.dart';
import '../provider/media_provider.dart';
import '../widgets/asset_thumbnail.dart';
import '../widgets/media_detail_view.dart';
import '../../../commonwidgets/shimmer_loading.dart';
import '../../journal/widgets/journal_entry_form.dart';
import '../../journal/providers/journal_provider.dart';
import '../../journal/models/journal_entry.dart';
import 'package:uuid/uuid.dart';

class AlbumPage extends StatefulWidget {
  final AssetPathEntity album;
  final bool isGridView;
  final int gridCrossAxisCount;
  final bool isFavoritesAlbum;
  final bool isVideosAlbum;

  const AlbumPage({
    super.key,
    required this.album,
    required this.isGridView,
    required this.gridCrossAxisCount,
    this.isFavoritesAlbum = false,
    this.isVideosAlbum = false,
  });

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  List<AssetEntity> _mediaItems = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMorePhotos = true;
  int _currentPage = 0;
  static const int _pageSize = 100;
  bool _mounted = true;
  bool _isInitialized = false;
  bool _isSelectionMode = false;
  final Set<String> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    _loadAlbumContents();
  }

  @override
  void didUpdateWidget(AlbumPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.album.id != widget.album.id ||
        oldWidget.isFavoritesAlbum != widget.isFavoritesAlbum ||
        oldWidget.isVideosAlbum != widget.isVideosAlbum) {
      _isInitialized = false;
      _loadAlbumContents();
    }
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

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
    HapticFeedback.lightImpact();
    setState(() {
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
    final selectedAssets = _mediaItems
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
      final selectedAssets = _mediaItems
          .where((asset) => _selectedItems.contains(asset.id))
          .toList();

      for (var asset in selectedAssets) {
        await mediaProvider.deleteMedia(asset);
      }

      setState(() {
        _selectedItems.clear();
        _isSelectionMode = false;
        _mediaItems.removeWhere((asset) => selectedAssets.contains(asset));
      });
    }
  }

  Future<void> _toggleFavoriteSelected() async {
    final mediaProvider = context.read<MediaProvider>();
    final selectedAssets = _mediaItems
        .where((asset) => _selectedItems.contains(asset.id))
        .toList();

    int addedCount = 0;
    int removedCount = 0;

    for (var asset in selectedAssets) {
      final wasFavorite = mediaProvider.isFavorite(asset.id);
      await mediaProvider.toggleFavorite(asset);
      if (wasFavorite) {
        removedCount++;
      } else {
        addedCount++;
      }
    }

    setState(() {
      _selectedItems.clear();
      _isSelectionMode = false;
    });

    if (mounted) {
      if (addedCount > 0) {
        SnackbarUtils.showMediaAddedToFavorites(
          context,
          count: addedCount,
          onView: () {
            // Navigate to favorites album
            Navigator.pushNamed(context, '/albums/favorites');
          },
        );
      }
      if (removedCount > 0) {
        SnackbarUtils.showMediaRemovedFromFavorites(
          context,
          count: removedCount,
        );
      }
    }
  }

  Future<void> _addToJournalSelected() async {
    final selectedAssets = _mediaItems
        .where((asset) => _selectedItems.contains(asset.id))
        .toList();

    if (selectedAssets.isEmpty) return;

    final mediaIds = selectedAssets.map((asset) => asset.id).toList();

    // Ensure media is loaded in the provider
    final mediaProvider = context.read<MediaProvider>();
    for (var asset in selectedAssets) {
      await mediaProvider.cacheAssetData(asset);
    }

    showDialog(
      context: context,
      builder: (context) => JournalEntryForm(
        initialMediaIds: mediaIds,
        onSave: (title, content, mediaIds, mood, tags,
            {DateTime? lastEdited}) async {
          final journalProvider = context.read<JournalProvider>();
          final entry = JournalEntry(
            id: const Uuid().v4(),
            title: title,
            content: content,
            mediaIds: mediaIds,
            mood: mood,
            tags: tags,
            date: DateTime.now(),
          );

          final success = await journalProvider.addEntry(entry);
          if (success) {
            Navigator.pop(context);
            SnackbarUtils.showSuccess(
                context, 'Journal entry added successfully');
          } else {
            SnackbarUtils.showError(context, 'Failed to add journal entry');
          }
        },
      ),
    );

    setState(() {
      _selectedItems.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _loadAlbumContents() async {
    if (!mounted || _isInitialized) return;

    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _hasMorePhotos = true;
      _mediaItems = [];
    });

    try {
      final mediaProvider = context.read<MediaProvider>();

      if (widget.isFavoritesAlbum) {
        // Load favorites
        _mediaItems = mediaProvider.favoriteItems;
        // Sort favorites by creation date
        _mediaItems
            .sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
        _isLoading = false;
        _isInitialized = true;
        setState(() {});
        return;
      }

      if (widget.isVideosAlbum) {
        // Load videos from the video album
        final videos = await mediaProvider.loadVideoAlbumContents(widget.album);
        if (!mounted) return;

        setState(() {
          _mediaItems = videos;
          _isLoading = false;
          _isInitialized = true;
        });
        return;
      }

      // For regular photo albums
      // Load first page with smaller size for faster initial load
      final assets = await widget.album.getAssetListPaged(
        page: 0,
        size: 20, // Smaller initial page size
      );

      if (!mounted) return;

      setState(() {
        _mediaItems = assets;
        // Sort by creation date
        _mediaItems
            .sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
        _isLoading = false;
        _currentPage = 1;
        _hasMorePhotos = assets.length == 20;
        _isInitialized = true;
      });

      // Cache data for loaded assets with error handling
      for (var asset in assets) {
        if (!mounted) return;
        try {
          await mediaProvider.cacheAssetData(asset);
        } catch (e) {
          debugPrint('Error caching asset data: $e');
          continue;
        }
      }

      // Group photos by date
      if (mounted) {
        mediaProvider.groupPhotosByDate(_mediaItems, albumId: widget.album.id);
      }

      // Load remaining pages in background
      final totalCount = await widget.album.assetCountAsync;
      final totalPages = (totalCount / _pageSize).ceil();

      if (totalPages > 1) {
        for (var page = 1; page < totalPages; page++) {
          if (!mounted) break;

          final moreAssets = await widget.album.getAssetListPaged(
            page: page,
            size: _pageSize,
          );

          // Filter out duplicates
          final newAssets = moreAssets
              .where((asset) => !_mediaItems.any((item) => item.id == asset.id))
              .toList();

          if (newAssets.isEmpty) continue;

          setState(() {
            _mediaItems.addAll(newAssets);
            // Sort by creation date
            _mediaItems
                .sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
          });

          // Cache data for new assets
          for (var asset in newAssets) {
            if (!mounted) break;
            try {
              await mediaProvider.cacheAssetData(asset);
            } catch (e) {
              debugPrint('Error caching asset data: $e');
              continue;
            }
          }

          // Update grouped photos
          if (mounted) {
            mediaProvider.groupPhotosByDate(_mediaItems,
                albumId: widget.album.id);
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading album contents: $e');
    }
  }

  Future<void> _loadMorePhotos() async {
    if (_isLoadingMore ||
        !_hasMorePhotos ||
        !mounted ||
        widget.isFavoritesAlbum ||
        widget.isVideosAlbum) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final assets = await widget.album.getAssetListPaged(
        page: _currentPage,
        size: _pageSize,
      );

      if (!mounted) return;

      if (assets.isEmpty) {
        setState(() {
          _hasMorePhotos = false;
          _isLoadingMore = false;
        });
        return;
      }

      // Filter out duplicates
      final newAssets = assets
          .where((asset) => !_mediaItems.any((item) => item.id == asset.id))
          .toList();

      if (newAssets.isEmpty) {
        setState(() {
          _hasMorePhotos = false;
          _isLoadingMore = false;
        });
        return;
      }

      final mediaProvider = context.read<MediaProvider>();

      setState(() {
        _mediaItems.addAll(newAssets);
        // Sort all items by creation date
        _mediaItems
            .sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
        _currentPage++;
        _isLoadingMore = false;
        _hasMorePhotos = assets.length == _pageSize;
      });

      // Cache data for new assets with error handling
      for (var asset in newAssets) {
        if (!mounted) break;
        try {
          await mediaProvider.cacheAssetData(asset);
        } catch (e) {
          debugPrint('Error caching asset data: $e');
          continue;
        }
      }

      // Update grouped photos
      if (mounted) {
        mediaProvider.groupPhotosByDate(_mediaItems, albumId: widget.album.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
      debugPrint('Error loading more photos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isFavoritesAlbum
              ? 'Favorites'
              : widget.isVideosAlbum
                  ? 'Videos'
                  : widget.album.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _selectedItems.isEmpty ? null : _shareSelectedItems,
              tooltip: 'Share selected',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _selectedItems.isEmpty ? null : _deleteSelectedItems,
              tooltip: 'Delete selected',
            ),
            IconButton(
              icon: const Icon(Icons.favorite),
              onPressed:
                  _selectedItems.isEmpty ? null : _toggleFavoriteSelected,
              tooltip: 'Add to favorites',
            ),
            IconButton(
              icon: const Icon(Icons.book),
              onPressed: _selectedItems.isEmpty ? null : _addToJournalSelected,
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
      body: _isLoading
          ? ShimmerLoading(
              isGridView: widget.isGridView,
              gridCrossAxisCount: widget.gridCrossAxisCount,
            )
          : _mediaItems.isEmpty
              ? EmptyState(
                  title: 'No media found',
                  subtitle: 'There are no photos or videos in this album',
                  onRefresh: _loadAlbumContents,
                )
              : widget.isGridView
                  ? _buildPhotoGridByDate()
                  : _buildPhotoListByDate(),
    );
  }

  Widget _buildPhotoGridByDate() {
    final mediaProvider = context.watch<MediaProvider>();
    final groupedPhotos = widget.isFavoritesAlbum
        ? _groupPhotosByDate(_mediaItems)
        : widget.isVideosAlbum
            ? mediaProvider.getGroupedVideosForAlbum(widget.album.id)
            : mediaProvider.getGroupedPhotosForAlbum(widget.album.id);

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo is ScrollEndNotification &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent * 0.8) {
          _loadMorePhotos();
        }
        return true;
      },
      child: ListView.builder(
        itemCount: groupedPhotos.length + (_hasMorePhotos ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == groupedPhotos.length) {
            if (_isLoadingMore) {
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
              _DateHeader(
                date: date,
                itemCount: photos.length,
                isVideosAlbum: widget.isVideosAlbum,
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
                  return _MediaGridItem(
                    asset: asset,
                    isSelectionMode: _isSelectionMode,
                    isSelected: _selectedItems.contains(asset.id),
                    onTap: _isSelectionMode
                        ? () => _toggleItemSelection(asset.id)
                        : () => _showMediaDetail(context, asset),
                    onLongPress: () {
                      if (!_isSelectionMode) {
                        _toggleSelectionMode();
                        _toggleItemSelection(asset.id);
                      }
                    },
                    heroTag: 'media_${asset.id}',
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPhotoListByDate() {
    final mediaProvider = context.watch<MediaProvider>();
    final groupedPhotos = widget.isFavoritesAlbum
        ? _groupPhotosByDate(_mediaItems)
        : mediaProvider.getGroupedPhotosForAlbum(widget.album.id);

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo is ScrollEndNotification &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent * 0.8) {
          _loadMorePhotos();
        }
        return true;
      },
      child: ListView.builder(
        itemCount: groupedPhotos.length + (_hasMorePhotos ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == groupedPhotos.length) {
            if (_isLoadingMore) {
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
              _DateHeader(
                date: date,
                itemCount: photos.length,
              ),
              ...photos.map((asset) => _MediaListItem(
                    asset: asset,
                    isSelectionMode: _isSelectionMode,
                    isSelected: _selectedItems.contains(asset.id),
                    onTap: _isSelectionMode
                        ? () => _toggleItemSelection(asset.id)
                        : () => _showMediaDetail(context, asset),
                    onLongPress: () {
                      if (!_isSelectionMode) {
                        _toggleSelectionMode();
                        _toggleItemSelection(asset.id);
                      }
                    },
                    heroTag: 'media_${asset.id}',
                  )),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  void _showMediaDetail(BuildContext context, AssetEntity asset) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaDetailView(
          asset: asset,
          assetList: _mediaItems,
          heroTag: 'media_${asset.id}',
        ),
        fullscreenDialog: true,
      ),
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

class _DateHeader extends StatelessWidget {
  final DateTime date;
  final int itemCount;
  final bool isVideosAlbum;

  const _DateHeader({
    required this.date,
    required this.itemCount,
    this.isVideosAlbum = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              MediaUtils.formatDate(date),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$itemCount ${MediaUtils.getMediaTypeLabel(AssetType.image, isVideosAlbum: isVideosAlbum).toLowerCase()}${itemCount == 1 ? '' : 's'}',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaGridItem extends StatelessWidget {
  final AssetEntity asset;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final String heroTag;

  const _MediaGridItem({
    required this.asset,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final mediaProvider = context.watch<MediaProvider>();

    return Stack(
      fit: StackFit.expand,
      children: [
        AssetThumbnail(
          asset: asset,
          heroTag: heroTag,
          onTap: onTap,
          onLongPress: onLongPress,
          isSelected: isSelected,
          showSelectionIndicator: isSelectionMode,
          isSelectionMode: isSelectionMode,
        ),
        if (!isSelectionMode && mediaProvider.isFavorite(asset.id))
          Positioned(
            top: 4,
            left: 4,
            child: Container(
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
          ),
      ],
    );
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
            onView: () {},
          );
        },
      ),
    );
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

class _MediaListItem extends StatelessWidget {
  final AssetEntity asset;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final String heroTag;

  const _MediaListItem({
    required this.asset,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final mediaProvider = context.watch<MediaProvider>();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
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
                    boxFit: BoxFit.cover,
                    heroTag: heroTag,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                    isSelected: isSelected,
                    showSelectionIndicator: isSelectionMode,
                    isSelectionMode: isSelectionMode,
                  ),
                  if (!isSelectionMode && mediaProvider.isFavorite(asset.id))
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
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
                      final date = mediaProvider.getCreateDate(asset.id);
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
            if (!isSelectionMode)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  switch (value) {
                    case 'journal':
                      _showQuickJournalEntryDialog(context, asset);
                      break;
                    case 'favorite':
                      mediaProvider.toggleFavorite(asset);
                      break;
                    case 'share':
                      _shareMedia(context, asset);
                      break;
                    case 'delete':
                      _deleteMedia(context, asset);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'journal',
                    child: Row(
                      children: [
                        const Icon(Icons.book, size: 16),
                        const SizedBox(width: 8),
                        Consumer<JournalProvider>(
                          builder: (context, journalProvider, _) {
                            final hasEntries = journalProvider
                                .getEntriesByDateRange(
                                    DateTime.now(), DateTime.now())
                                .isNotEmpty;
                            return Text(
                              hasEntries ? 'View in Journal' : 'Add to Journal',
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
                        Icon(
                          mediaProvider.isFavorite(asset.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 16,
                          color: mediaProvider.isFavorite(asset.id)
                              ? Colors.red
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          mediaProvider.isFavorite(asset.id)
                              ? 'Remove from Favorites'
                              : 'Add to Favorites',
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
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
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
