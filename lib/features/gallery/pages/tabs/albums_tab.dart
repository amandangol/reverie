import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../commonwidgets/empty_state.dart';
import '../../provider/media_provider.dart';
import '../../widgets/asset_thumbnail.dart';
import '../album_page.dart';
import '../video_albums_page.dart';
import '../../../permissions/provider/permission_provider.dart';

class AlbumsTab extends StatefulWidget {
  final bool isGridView;
  final int gridCrossAxisCount;

  const AlbumsTab({
    super.key,
    required this.isGridView,
    required this.gridCrossAxisCount,
  });

  @override
  State<AlbumsTab> createState() => _AlbumsTabState();
}

class _AlbumsTabState extends State<AlbumsTab> {
  bool _isInitialized = false;
  List<AssetPathEntity> _cachedAlbums = [];
  List<AssetPathEntity> _cachedVideoAlbums = [];
  int _cachedFavoriteCount = 0;
  Map<String, Future<AssetEntity?>> _thumbnailCache = {};
  Map<String, Future<int>> _assetCountCache = {};
  bool _isSorting = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (_isInitialized) return;

    final mediaProvider = context.read<MediaProvider>();
    if (!mediaProvider.isInitialized) {
      await mediaProvider.loadMedia();
    }

    if (!mounted) return;

    // Load albums in parallel
    final albums = await mediaProvider.getSortedAlbums();
    final videoAlbums = mediaProvider.videoAlbums;
    final favoriteCount = mediaProvider.favoriteItems.length;

    // Pre-cache thumbnails for the first few albums
    for (var i = 0; i < 3 && i < albums.length; i++) {
      _precacheThumbnail(albums[i]);
    }

    setState(() {
      _cachedAlbums = albums;
      _cachedVideoAlbums = videoAlbums;
      _cachedFavoriteCount = favoriteCount;
      _isInitialized = true;
    });

    // Continue caching thumbnails in the background
    for (var i = 3; i < albums.length; i++) {
      if (!mounted) break;
      _precacheThumbnail(albums[i]);
    }
  }

  Future<void> _updateSortedAlbums() async {
    if (_isSorting) return;

    setState(() {
      _isSorting = true;
    });

    try {
      final mediaProvider = context.read<MediaProvider>();
      final sortedAlbums = await mediaProvider.getSortedAlbums();

      if (mounted) {
        setState(() {
          _cachedAlbums = sortedAlbums;
          _isSorting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSorting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sorting albums: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _precacheThumbnail(AssetPathEntity album) {
    final cacheKey = '${album.id}_thumbnail';
    if (!_thumbnailCache.containsKey(cacheKey)) {
      _thumbnailCache[cacheKey] = album
          .getAssetListRange(start: 0, end: 1)
          .then((value) => value.isNotEmpty ? value.first : null);
    }
  }

  Future<int> _getAssetCount(AssetPathEntity album) {
    final cacheKey = '${album.id}_count';
    if (!_assetCountCache.containsKey(cacheKey)) {
      _assetCountCache[cacheKey] = album.assetCountAsync;
    }
    return _assetCountCache[cacheKey]!;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (context, mediaProvider, child) {
        if (!_isInitialized) {
          return _buildShimmerLoading();
        }

        if (_cachedAlbums.isEmpty) {
          return EmptyState(
            title: 'No albums found',
            subtitle: 'There are no albums in your gallery',
            onRefresh: () => _checkAndRequestPermission(context),
          );
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Favorites and Videos section
                    if (widget.isGridView)
                      Column(
                        children: [
                          // First row: Favorites and Videos
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            padding: const EdgeInsets.all(8),
                            children: [
                              // Favorites card
                              Card(
                                clipBehavior: Clip.antiAlias,
                                elevation: 0.5,
                                color: Colors.black.withOpacity(0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: InkWell(
                                  onTap: _cachedFavoriteCount > 0
                                      ? () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => AlbumPage(
                                                album: _cachedAlbums.first,
                                                isGridView: widget.isGridView,
                                                gridCrossAxisCount:
                                                    widget.gridCrossAxisCount,
                                                isFavoritesAlbum: true,
                                              ),
                                            ),
                                          );
                                        }
                                      : null,
                                  child: _buildFavoritesAlbumCard(
                                      _cachedFavoriteCount),
                                ),
                              ),
                              // Videos card
                              if (_cachedVideoAlbums.isNotEmpty)
                                Card(
                                  clipBehavior: Clip.antiAlias,
                                  elevation: 0.5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const VideoAlbumsPage(),
                                        ),
                                      );
                                    },
                                    child: _buildVideosCard(),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          // Favorites card
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 0.5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: InkWell(
                              onTap: _cachedFavoriteCount > 0
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AlbumPage(
                                            album: _cachedAlbums.first,
                                            isGridView: widget.isGridView,
                                            gridCrossAxisCount:
                                                widget.gridCrossAxisCount,
                                            isFavoritesAlbum: true,
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              child: _buildFavoritesAlbumListItem(
                                  _cachedFavoriteCount),
                            ),
                          ),
                          // Videos card
                          if (_cachedVideoAlbums.isNotEmpty)
                            Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 0.5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const VideoAlbumsPage(),
                                    ),
                                  );
                                },
                                child: _buildVideosListItem(),
                              ),
                            ),
                        ],
                      ),
                    // Add sort button in the header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          const Text(
                            'More Albums',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          if (_isSorting)
                            const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          PopupMenuButton<AlbumSortOption>(
                            icon: const Icon(Icons.sort, color: Colors.grey),
                            onSelected: (option) async {
                              await mediaProvider.changeSortOption(option);
                              await _updateSortedAlbums();
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: AlbumSortOption.nameAsc,
                                child: Row(
                                  children: [
                                    Icon(Icons.sort_by_alpha, size: 20),
                                    SizedBox(width: 8),
                                    Text('Name (A-Z)'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: AlbumSortOption.nameDesc,
                                child: Row(
                                  children: [
                                    Icon(Icons.sort_by_alpha, size: 20),
                                    SizedBox(width: 8),
                                    Text('Name (Z-A)'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: AlbumSortOption.countAsc,
                                child: Row(
                                  children: [
                                    Icon(Icons.sort, size: 20),
                                    SizedBox(width: 8),
                                    Text('Count (Low to High)'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: AlbumSortOption.countDesc,
                                child: Row(
                                  children: [
                                    Icon(Icons.sort, size: 20),
                                    SizedBox(width: 8),
                                    Text('Count (High to Low)'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Other albums
                    widget.isGridView
                        ? GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(8),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8.0,
                              mainAxisSpacing: 8.0,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: _cachedAlbums.length,
                            itemBuilder: (context, index) {
                              final album = _cachedAlbums[index];
                              return Card(
                                clipBehavior: Clip.antiAlias,
                                elevation: 0.5,
                                color: Colors.black.withOpacity(0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AlbumPage(
                                          album: album,
                                          isGridView: widget.isGridView,
                                          gridCrossAxisCount:
                                              widget.gridCrossAxisCount,
                                        ),
                                      ),
                                    );
                                  },
                                  child: _buildAlbumCard(album),
                                ),
                              );
                            },
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(8),
                            itemCount: _cachedAlbums.length,
                            itemBuilder: (context, index) {
                              final album = _cachedAlbums[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 0.5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AlbumPage(
                                          album: album,
                                          isGridView: widget.isGridView,
                                          gridCrossAxisCount:
                                              widget.gridCrossAxisCount,
                                        ),
                                      ),
                                    );
                                  },
                                  child: _buildAlbumListItem(album),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAlbumCard(AssetPathEntity album) {
    final cacheKey = '${album.id}_thumbnail';
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: FutureBuilder<AssetEntity?>(
              future: _thumbnailCache[cacheKey],
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(color: Colors.white),
                  );
                }

                if (snapshot.data != null) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      AssetThumbnail(
                        asset: snapshot.data!,
                        boxFit: BoxFit.cover,
                      ),
                      Container(
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
                    ],
                  );
                }

                return Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.photo_album, size: 64),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  album.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                FutureBuilder<int>(
                  future: _getAssetCount(album),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Text(
                      '$count item${count == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesAlbumCard(int favoriteCount) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.favorite,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(8),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Favorites',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$favoriteCount item${favoriteCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesAlbumListItem(int favoriteCount) {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.favorite,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Favorites',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '$favoriteCount item${favoriteCount == 1 ? '' : 's'}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: Colors.grey),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAlbumListItem(AssetPathEntity album) {
    final cacheKey = '${album.id}_thumbnail';
    return Row(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: FutureBuilder<AssetEntity?>(
            future: _thumbnailCache[cacheKey],
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.white),
                );
              }

              if (snapshot.data != null) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    AssetThumbnail(
                      asset: snapshot.data!,
                      boxFit: BoxFit.cover,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    Container(
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
                  ],
                );
              }

              return Container(
                color: Colors.grey[200],
                child: const Icon(Icons.photo_album, size: 32),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                album.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              FutureBuilder<int>(
                future: _getAssetCount(album),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Text(
                    '$count item${count == 1 ? '' : 's'}',
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
        const Icon(Icons.chevron_right, color: Colors.grey),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surface,
      highlightColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
      child: widget.isGridView
          ? GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 0.8,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return Container(color: Colors.white);
              },
            )
          : ListView.builder(
              itemCount: 6,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 100,
                              height: 12,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildVideosCard() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.red[700]!,
                Colors.red[900]!,
              ],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.video_library,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(8),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Videos',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                FutureBuilder<int>(
                  future: Future.wait(_cachedVideoAlbums
                          .where((album) => album.name != 'Recent')
                          .map((album) => album.assetCountAsync))
                      .then((counts) => counts.reduce((a, b) => a + b)),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Text(
                      '$count video${count == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideosListItem() {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.red[700]!,
                Colors.red[900]!,
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.video_library,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Videos',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              FutureBuilder<int>(
                future: Future.wait(_cachedVideoAlbums
                        .where((album) => album.name != 'Recent')
                        .map((album) => album.assetCountAsync))
                    .then((counts) => counts.reduce((a, b) => a + b)),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Text(
                    '$count video${count == 1 ? '' : 's'}',
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
        const Icon(Icons.chevron_right, color: Colors.grey),
        const SizedBox(width: 8),
      ],
    );
  }

  Future<void> _checkAndRequestPermission(BuildContext context) async {
    final permissionProvider = context.read<PermissionProvider>();
    final granted = await permissionProvider.requestMediaPermission();
    if (granted) {
      context.read<MediaProvider>().requestPermission();
    }
  }
}
