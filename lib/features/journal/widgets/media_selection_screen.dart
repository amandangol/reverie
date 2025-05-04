import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:provider/provider.dart';
import '../../gallery/provider/media_provider.dart';

class MediaSelectionScreen extends StatefulWidget {
  final List<AssetEntity> initiallySelected;
  final List<AssetEntity> availableMedia;

  const MediaSelectionScreen({
    super.key,
    required this.initiallySelected,
    required this.availableMedia,
  });

  @override
  State<MediaSelectionScreen> createState() => _MediaSelectionScreenState();
}

class _MediaSelectionScreenState extends State<MediaSelectionScreen> {
  late List<AssetEntity> _selectedMedia;
  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _currentAlbum;
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  static const int _pageSize = 50;
  bool _hasMorePhotos = true;
  bool _isLoadingMore = false;
  String? _error;
  List<AssetEntity> _currentAlbumItems = [];

  @override
  void initState() {
    super.initState();
    _selectedMedia = List.from(widget.initiallySelected);
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final mediaProvider = context.read<MediaProvider>();
      final permission = await PhotoManager.requestPermissionExtend();

      if (!mounted) return;

      if (!permission.isAuth) {
        setState(() {
          _isLoading = false;
          _error = 'Permission denied';
        });
        return;
      }

      // Get albums from media provider
      _albums = mediaProvider.albums;

      if (_albums.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'No albums found';
        });
        return;
      }

      // Set current album to first album
      _currentAlbum = _albums.first;

      // Load first album contents
      await _loadCurrentAlbumContents();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadCurrentAlbumContents() async {
    if (_currentAlbum == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final assets = await _currentAlbum!.getAssetListRange(
        start: 0,
        end: _pageSize,
      );

      if (!mounted) return;

      setState(() {
        _currentAlbumItems = assets;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadMorePhotos() async {
    if (_isLoadingMore || !_hasMorePhotos || _currentAlbum == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final start = _currentAlbumItems.length;
      final end = start + _pageSize;
      final assets = await _currentAlbum!.getAssetListRange(
        start: start,
        end: end,
      );

      if (!mounted) return;

      setState(() {
        _currentAlbumItems.addAll(assets);
        _isLoadingMore = false;
        _hasMorePhotos = assets.length == _pageSize;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
        _error = e.toString();
      });
    }
  }

  void _toggleMediaSelection(AssetEntity asset) {
    setState(() {
      if (_isSelected(asset)) {
        _selectedMedia.removeWhere((item) => item.id == asset.id);
      } else {
        _selectedMedia.add(asset);
      }
    });
  }

  bool _isSelected(AssetEntity asset) {
    return _selectedMedia.any((item) => item.id == asset.id);
  }

  @override
  Widget build(BuildContext context) {
    final filteredMedia = _searchQuery.isEmpty
        ? _currentAlbumItems
        : _currentAlbumItems.where((media) {
            final filename = media.title?.toLowerCase() ?? '';
            final type = media.type.toString().toLowerCase();
            return filename.contains(_searchQuery) ||
                type.contains(_searchQuery);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Media'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search media...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterMedia('');
                        },
                      )
                    : null,
              ),
              onChanged: _filterMedia,
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _showAlbumPicker,
            icon: const Icon(Icons.photo_album),
            label: Text(_currentAlbum?.name ?? 'All Media'),
          ),
          TextButton(
            onPressed: () async {
              // Cache all selected media before returning
              final mediaProvider = context.read<MediaProvider>();
              for (var asset in _selectedMedia) {
                await mediaProvider.cacheAssetData(asset);
              }
              Navigator.pop(context, _selectedMedia);
            },
            child: Text('Done (${_selectedMedia.length})'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (scrollInfo is ScrollEndNotification &&
                    scrollInfo.metrics.pixels >=
                        scrollInfo.metrics.maxScrollExtent * 0.8) {
                  _loadMorePhotos();
                }
                return true;
              },
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: filteredMedia.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == filteredMedia.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final asset = filteredMedia[index];
                  final isSelected = _isSelected(asset);

                  return GestureDetector(
                    onTap: () => _toggleMediaSelection(asset),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Media thumbnail
                        Image(
                          image: AssetEntityImageProvider(
                            asset,
                            isOriginal: false,
                            thumbnailSize: const ThumbnailSize.square(300),
                          ),
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),

                        // Video indicator
                        if (asset.type == AssetType.video)
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
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
                                  Text(
                                    _formatDuration(asset.duration),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Selection overlay
                        if (isSelected)
                          Container(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.3),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  '${_selectedMedia.indexWhere((e) => e.id == asset.id) + 1}',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final secondsStr = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$secondsStr';
  }

  void _filterMedia(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  void _showAlbumPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select Album',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _albums.length,
                  itemBuilder: (context, index) {
                    final album = _albums[index];
                    return ListTile(
                      title: Text(album.name),
                      subtitle: FutureBuilder<int>(
                        future: album.assetCountAsync,
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          return Text('$count items');
                        },
                      ),
                      selected: _currentAlbum?.id == album.id,
                      onTap: () async {
                        setState(() {
                          _currentAlbum = album;
                        });
                        Navigator.pop(context); // Close the bottom sheet
                        await _loadCurrentAlbumContents();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
