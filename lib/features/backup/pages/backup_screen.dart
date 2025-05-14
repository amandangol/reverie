import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import '../provider/backup_provider.dart';
import '../../gallery/provider/media_provider.dart';
import '../../../theme/app_theme.dart';

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Backup & Restore',
          style: journalTextTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
            fontSize: 17,
            letterSpacing: 1,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _GoogleDriveSection(),
            SizedBox(height: 24),
            _BackupSection(),
            SizedBox(height: 24),
            _RestoreSection(),
          ],
        ),
      ),
    );
  }
}

class _GoogleDriveSection extends StatelessWidget {
  const _GoogleDriveSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    return Consumer<BackupProvider>(
      builder: (context, backupProvider, child) {
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4285F4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.cloud_done_rounded,
                        color: Color(0xFF4285F4),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Google Drive',
                            style: journalTextTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Connect your Google Drive account to backup and restore your memories',
                            style: journalTextTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FutureBuilder<bool>(
                  future: backupProvider.isGoogleDriveSignedIn(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final isSignedIn = snapshot.data ?? false;
                    return Column(
                      children: [
                        if (isSignedIn) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFF4285F4),
                                  child: Text(
                                    backupProvider.userEmail?[0]
                                            .toUpperCase() ??
                                        'G',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        backupProvider.userEmail ??
                                            'Google Account',
                                        style: journalTextTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'Connected',
                                        style: journalTextTheme.bodySmall
                                            ?.copyWith(
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (isSignedIn) {
                              await backupProvider.signOutFromGoogleDrive();
                            } else {
                              await backupProvider.signInToGoogleDrive();
                            }
                          },
                          icon: Icon(
                            isSignedIn
                                ? Icons.logout_rounded
                                : Icons.login_rounded,
                            size: 20,
                          ),
                          label: Text(
                              isSignedIn ? 'Sign Out' : 'Sign In with Google'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSignedIn
                                ? colorScheme.primary
                                : const Color(0xFF4285F4),
                            foregroundColor:
                                isSignedIn ? colorScheme.error : Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BackupSection extends StatelessWidget {
  const _BackupSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    return Consumer2<BackupProvider, MediaProvider>(
      builder: (context, backupProvider, mediaProvider, child) {
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34A853).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.backup_rounded,
                        color: Color(0xFF34A853),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Backup Albums',
                            style: journalTextTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select albums to backup to Google Drive',
                            style: journalTextTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: backupProvider.isBackingUp
                      ? _BackupProgressIndicator(
                          progress: backupProvider.backupProgress,
                        )
                      : _AlbumSelectionList(
                          albums: mediaProvider.albums,
                          selectedAlbums: backupProvider.selectedBackupAlbums,
                          onAlbumSelected: (album, selected) {
                            if (selected) {
                              backupProvider.addAlbumToBackup(album);
                            } else {
                              backupProvider.removeAlbumFromBackup(album);
                            }
                          },
                          onBackupPressed: () async {
                            try {
                              await backupProvider.backupSelectedAlbums();
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Backup failed: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BackupProgressIndicator extends StatelessWidget {
  const _BackupProgressIndicator({
    required this.progress,
  });

  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: colorScheme.surfaceVariant,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34A853)),
          ),
          const SizedBox(height: 12),
          Text(
            'Backing up... ${(progress * 100).toStringAsFixed(1)}%',
            style: journalTextTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumSelectionList extends StatelessWidget {
  const _AlbumSelectionList({
    required this.albums,
    required this.selectedAlbums,
    required this.onAlbumSelected,
    required this.onBackupPressed,
  });

  final List<AssetPathEntity> albums;
  final Set<AssetPathEntity> selectedAlbums;
  final Function(AssetPathEntity, bool) onAlbumSelected;
  final VoidCallback onBackupPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              return _AlbumListItem(
                album: album,
                isSelected: selectedAlbums.contains(album),
                onSelected: (selected) => onAlbumSelected(album, selected),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: selectedAlbums.isEmpty ? null : onBackupPressed,
          icon: const Icon(Icons.backup_rounded, size: 20),
          label: const Text('Backup Selected Albums'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF34A853),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
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

    return FutureBuilder<int>(
      future: album.assetCountAsync,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return CheckboxListTile(
          title: Text(
            album.name,
            style: journalTextTheme.bodyMedium,
          ),
          subtitle: Text(
            '$count items',
            style: journalTextTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          value: isSelected,
          onChanged: (selected) => onSelected(selected ?? false),
          activeColor: const Color(0xFF34A853),
        );
      },
    );
  }
}

class _RestoreSection extends StatelessWidget {
  const _RestoreSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    return Consumer<BackupProvider>(
      builder: (context, backupProvider, child) {
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA4335).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.restore_rounded,
                        color: Color(0xFFEA4335),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Restore from Backup',
                            style: journalTextTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Restore your memories from Google Drive backup',
                            style: journalTextTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: backupProvider.isRestoring
                      ? _RestoreProgressIndicator(
                          progress: backupProvider.backupProgress,
                        )
                      : ElevatedButton.icon(
                          onPressed: () =>
                              backupProvider.restoreFromGoogleDrive(),
                          icon: const Icon(Icons.restore_rounded, size: 20),
                          label: const Text('Restore from Backup'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEA4335),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RestoreProgressIndicator extends StatelessWidget {
  const _RestoreProgressIndicator({
    required this.progress,
  });

  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: colorScheme.surfaceVariant,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEA4335)),
          ),
          const SizedBox(height: 12),
          Text(
            'Restoring... ${(progress * 100).toStringAsFixed(1)}%',
            style: journalTextTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
