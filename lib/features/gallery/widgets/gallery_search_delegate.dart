import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:provider/provider.dart';
import '../provider/media_provider.dart';
import '../pages/mediadetail/media_detail_view.dart';
import '../../../providers/gallery_preferences_provider.dart';
import 'package:reverie/utils/media_utils.dart';

class GallerySearchDelegate extends SearchDelegate<AssetEntity?> {
  final MediaProvider mediaProvider;

  GallerySearchDelegate(this.mediaProvider);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      Consumer<GalleryPreferencesProvider>(
        builder: (context, preferences, _) {
          return IconButton(
            icon: Icon(
              preferences.isGridView
                  ? Icons.list_rounded
                  : Icons.grid_view_rounded,
            ),
            onPressed: () => preferences.toggleViewMode(),
            tooltip: preferences.isGridView ? 'List view' : 'Grid view',
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          if (query.isEmpty) {
            close(context, null);
          } else {
            query = '';
            showResults(context);
          }
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('Start typing to search...'),
      );
    }

    return FutureBuilder<void>(
      future: mediaProvider.searchMedia(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (mediaProvider.searchResults.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No results found for "$query"',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        return Consumer<GalleryPreferencesProvider>(
          builder: (context, preferences, _) {
            if (preferences.isGridView) {
              return _buildGridView(context);
            } else {
              return _buildListView(context);
            }
          },
        );
      },
    );
  }

  Widget _buildGridView(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: mediaProvider.searchResults.length,
      itemBuilder: (context, index) {
        final asset = mediaProvider.searchResults[index];
        return _buildGridItem(context, asset);
      },
    );
  }

  Widget _buildListView(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: mediaProvider.searchResults.length,
      itemBuilder: (context, index) {
        final asset = mediaProvider.searchResults[index];
        return _buildListItem(context, asset);
      },
    );
  }

  Widget _buildGridItem(BuildContext context, AssetEntity asset) {
    return GestureDetector(
      onTap: () => _openMediaDetail(context, asset),
      child: Hero(
        tag: 'search_${asset.id}',
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image(
                image: AssetEntityImageProvider(
                  asset,
                  isOriginal: false,
                  thumbnailSize: const ThumbnailSize(300, 300),
                ),
                fit: BoxFit.cover,
              ),
            ),
            if (asset.type == AssetType.video)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Consumer<MediaProvider>(
                        builder: (context, mediaProvider, _) {
                          final duration = mediaProvider.getDuration(asset.id);
                          if (duration == null) {
                            return const SizedBox();
                          }
                          return Text(
                            MediaUtils.formatDuration(duration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, AssetEntity asset) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _openMediaDetail(context, asset),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'search_${asset.id}',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                      child: Image(
                        image: AssetEntityImageProvider(
                          asset,
                          isOriginal: false,
                          thumbnailSize: const ThumbnailSize(300, 300),
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
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
                  Text(
                    MediaUtils.formatDimensions(asset.size),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openMediaDetail(BuildContext context, AssetEntity asset) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaDetailView(
          asset: asset,
          assetList: mediaProvider.searchResults,
          heroTag: 'search_${asset.id}',
        ),
      ),
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(
          color: theme.colorScheme.primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
