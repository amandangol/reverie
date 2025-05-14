import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import '../provider/backup_provider.dart';
import '../../../theme/app_theme.dart';

class AlbumSelectionList extends StatelessWidget {
  const AlbumSelectionList({
    super.key,
    required this.albums,
    required this.selectedAlbums,
    required this.onAlbumSelected,
  });

  final List<AssetPathEntity> albums;
  final Set<AssetPathEntity> selectedAlbums;
  final Function(AssetPathEntity, bool) onAlbumSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Sort albums: backed up first, then by name
    final sortedAlbums = List<AssetPathEntity>.from(albums);
    sortedAlbums.sort((a, b) {
      final aBackedUp = Provider.of<BackupProvider>(context, listen: false)
          .isAlbumBackedUp(a);
      final bBackedUp = Provider.of<BackupProvider>(context, listen: false)
          .isAlbumBackedUp(b);

      if (aBackedUp && !bBackedUp) return -1;
      if (!aBackedUp && bBackedUp) return 1;
      return a.name.compareTo(b.name);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header for selection
        Row(
          children: [
            Icon(
              Icons.photo_library_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Text(
              'Select albums to backup',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const Spacer(),
            // Select all button
            if (albums.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  final allSelected = albums.length == selectedAlbums.length;
                  for (var album in albums) {
                    if (allSelected) {
                      onAlbumSelected(album, false);
                    } else {
                      onAlbumSelected(album, true);
                    }
                  }
                },
                icon: Icon(
                  albums.length == selectedAlbums.length
                      ? Icons.deselect_rounded
                      : Icons.select_all_rounded,
                  size: 18,
                ),
                label: Text(
                  albums.length == selectedAlbums.length
                      ? 'Deselect All'
                      : 'Select All',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Album list
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              if (albums.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.photo_album_outlined,
                          size: 48,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No albums found',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedAlbums.length,
                    separatorBuilder: (context, index) => Divider(
                      color: colorScheme.outline.withOpacity(0.2),
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final album = sortedAlbums[index];
                      return _AlbumListItem(
                        album: album,
                        isSelected: selectedAlbums.contains(album),
                        onSelected: (selected) =>
                            onAlbumSelected(album, selected),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AlbumListItem extends StatelessWidget {
  const _AlbumListItem({
    required this.album,
    required this.isSelected,
    required this.onSelected,
  });

  final AssetPathEntity album;
  final bool isSelected;
  final Function(bool) onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    return Consumer<BackupProvider>(
      builder: (context, backupProvider, child) {
        final isBackedUp = backupProvider.isAlbumBackedUp(album);

        return InkWell(
          onTap: () => onSelected(!isSelected),
          borderRadius: BorderRadius.circular(0),
          child: FutureBuilder<int>(
            future: album.assetCountAsync,
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          album.name,
                          style: journalTextTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isBackedUp)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF34A853).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.cloud_done_rounded,
                                size: 12,
                                color: Color(0xFF34A853),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Backed up',
                                style: journalTextTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF34A853),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '$count ${count == 1 ? 'item' : 'items'}',
                      style: journalTextTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      album.name.toLowerCase().contains('album')
                          ? Icons.photo_album_rounded
                          : Icons.folder_rounded,
                      color: colorScheme.primary,
                    ),
                  ),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (value) => onSelected(value ?? false),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    activeColor: const Color(0xFF34A853),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
