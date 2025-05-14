import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
                      const _GoogleDriveSection(),
                      const SizedBox(height: 20),
                      const _BackupSection(),
                      const SizedBox(
                          height: 100), // Add padding for the bottom button
                    ]),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Consumer<BackupProvider>(
              builder: (context, provider, _) {
                final selectedAlbums = provider.selectedBackupAlbums;
                final isBackingUp = provider.isBackingUp;

                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (selectedAlbums.isEmpty || isBackingUp)
                        ? null
                        : () async {
                            try {
                              await provider.backupSelectedAlbums();
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.error_outline,
                                            color: Colors.white),
                                        const SizedBox(width: 12),
                                        Expanded(child: Text(e.toString())),
                                      ],
                                    ),
                                    backgroundColor: Colors.red.shade700,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    margin: const EdgeInsets.all(12),
                                    duration: const Duration(seconds: 5),
                                  ),
                                );
                              }
                            }
                          },
                    icon: Icon(
                      isBackingUp
                          ? Icons.hourglass_empty_rounded
                          : Icons.backup_rounded,
                      size: 20,
                    ),
                    label: Text(
                      selectedAlbums.isEmpty
                          ? 'Select albums to backup'
                          : isBackingUp
                              ? 'Backing up...'
                              : 'Backup ${selectedAlbums.length} ${selectedAlbums.length == 1 ? 'album' : 'albums'}',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: colorScheme.surfaceVariant,
                      disabledForegroundColor: colorScheme.onSurfaceVariant,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BackupStatusBanner extends StatelessWidget {
  final DateTime lastBackupDate;

  const _BackupStatusBanner({required this.lastBackupDate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    final formattedDate = _formatDate(lastBackupDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history_rounded,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Last backup: $formattedDate',
              style: journalTextTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _GoogleDriveSection extends StatelessWidget {
  const _GoogleDriveSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    return Card(
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
                    color: const Color(0xFF4285F4).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SvgPicture.asset(
                    'assets/svg/google_drive.svg',
                    width: 24,
                    height: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Google Drive',
                        style: journalTextTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Connect to save your memories securely',
                        style: journalTextTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Selector<BackupProvider, bool>(
              selector: (_, provider) => provider.isSignedIn,
              builder: (context, isSignedIn, _) {
                return Column(
                  children: [
                    if (isSignedIn) ...[
                      Selector<BackupProvider, Map<String, String?>>(
                        selector: (_, provider) => {
                          'email': provider.userEmail,
                          'name': provider.userName,
                          'photoUrl': provider.userPhotoUrl,
                        },
                        builder: (context, userInfo, _) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.surfaceVariant.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                if (userInfo['photoUrl'] != null &&
                                    userInfo['photoUrl']!.isNotEmpty)
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundImage:
                                        NetworkImage(userInfo['photoUrl']!),
                                  )
                                else
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: const Color(0xFF4285F4),
                                    child: Text(
                                      userInfo['name']?[0].toUpperCase() ??
                                          userInfo['email']?[0].toUpperCase() ??
                                          'G',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userInfo['name'] ??
                                            userInfo['email'] ??
                                            'Google Account',
                                        style: journalTextTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (userInfo['email'] != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          userInfo['email']!,
                                          style: journalTextTheme.bodySmall
                                              ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFF34A853),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Connected',
                                            style: journalTextTheme.bodySmall
                                                ?.copyWith(
                                              color: const Color(0xFF34A853),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    _GoogleDriveButton(
                      isSignedIn: isSignedIn,
                      onPressed: () async {
                        final provider = context.read<BackupProvider>();
                        if (isSignedIn) {
                          await provider.signOutFromGoogleDrive();
                        } else {
                          await provider.signInToGoogleDrive();
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleDriveButton extends StatelessWidget {
  final bool isSignedIn;
  final VoidCallback onPressed;

  const _GoogleDriveButton({
    required this.isSignedIn,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSignedIn ? Colors.white : const Color(0xFF4285F4),
          foregroundColor: isSignedIn ? const Color(0xFF4285F4) : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSignedIn
                ? const BorderSide(color: Color(0xFF4285F4), width: 1.5)
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isSignedIn) ...[
              SvgPicture.asset(
                'assets/svg/google.svg',
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 12),
            ],
            Icon(
              isSignedIn ? Icons.logout_rounded : Icons.login_rounded,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isSignedIn ? 'Sign Out' : 'Sign in with Google',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
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
                          const SizedBox(height: 4),
                          Text(
                            'Select albums to back up to Google Drive',
                            style: journalTextTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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
                                _showErrorSnackBar(
                                    context, 'Backup failed: ${e.toString()}');
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF34A853).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF34A853)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Backing up your memories...',
                  style: journalTextTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  context.read<BackupProvider>().cancelBackup();
                },
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Cancel'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: colorScheme.surfaceVariant,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF34A853)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}% complete',
                style: journalTextTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF34A853),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Please wait...',
                style: journalTextTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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

  @override
  int get hashCode => Object.hash(albums.length, selectedAlbums.length);
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
