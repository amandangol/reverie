import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/backup_provider.dart';
import '../../gallery/provider/media_provider.dart';
import '../../../theme/app_theme.dart';
import '../widgets/backup_button.dart';
import '../widgets/album_selection_list.dart';
import '../widgets/google_drive_section.dart';
import '../widgets/backup_progress_indicator.dart';

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
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
            fontSize: 20,
            letterSpacing: 0.15,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.background,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      'Keep your memories safe by backing them up to Google Drive',
                      style: journalTextTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const GoogleDriveSection(),
                      const SizedBox(height: 20),
                      const _BackupSection(),
                      const SizedBox(
                          height: 100), // Space for the bottom button
                    ]),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Consumer<BackupProvider>(
              builder: (context, provider, _) {
                return BackupButton(
                  selectedAlbums: provider.selectedBackupAlbums,
                  isBackingUp: provider.isBackingUp,
                  onBackupPressed: () async {
                    try {
                      await provider.backupSelectedAlbums();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_outline,
                                    color: Colors.white),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Successfully backed up ${provider.selectedBackupAlbums.length} ${provider.selectedBackupAlbums.length == 1 ? 'album' : 'albums'}',
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFF34A853),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            margin: const EdgeInsets.all(12),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        _showErrorSnackBar(context, e.toString());
                      }
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 5),
      ),
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
          color: colorScheme.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34A853).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.backup_rounded,
                        color: Color(0xFF34A853),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Backup Albums',
                            style: journalTextTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (backupProvider.isSignedIn)
                      TextButton.icon(
                        onPressed: () =>
                            backupProvider.showRestoreDialog(context),
                        icon: const Icon(Icons.restore_rounded),
                        label: const Text('Restore'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4285F4),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: backupProvider.isBackingUp
                      ? BackupProgressIndicator(
                          progress: backupProvider.backupProgress,
                        )
                      : AlbumSelectionList(
                          albums: mediaProvider.albums,
                          selectedAlbums: backupProvider.selectedBackupAlbums,
                          onAlbumSelected: (album, selected) {
                            if (selected) {
                              backupProvider.addAlbumToBackup(album);
                            } else {
                              backupProvider.removeAlbumFromBackup(album);
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
