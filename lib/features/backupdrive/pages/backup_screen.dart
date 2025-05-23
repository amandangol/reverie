import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../journal/providers/journal_provider.dart';
import '../provider/backup_provider.dart';
import '../../gallery/provider/media_provider.dart';
import '../../../theme/app_theme.dart';
import '../widgets/backup_button.dart';
import '../widgets/album_selection_list.dart';
import '../widgets/google_drive_section.dart';
import '../widgets/backup_progress_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  _BackupScreenState createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Set the context for BackupProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BackupProvider>().setContext(context);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
            fontSize: 18,
            letterSpacing: 0.15,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.background,
      ),
      body: Column(
        children: [
          // Google Drive Connection Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: const GoogleDriveSection(),
          ),

          // Header Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Keep your memories safe by backing them up to Google Drive',
              style: journalTextTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              indicator: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorPadding: const EdgeInsets.all(2),
              dividerColor: Colors.transparent,
              labelStyle: journalTextTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: journalTextTheme.titleSmall?.copyWith(
                fontSize: 12,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.photo_library_rounded, size: 16),
                  text: 'Albums',
                ),
                Tab(
                  icon: Icon(Icons.book_rounded, size: 16),
                  text: 'Journals',
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AlbumBackupTab(),
                _JournalBackupTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumBackupTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<BackupProvider, MediaProvider>(
      builder: (context, backupProvider, mediaProvider, child) {
        return Stack(
          children: [
            ListView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: backupProvider.selectedBackupAlbums.isNotEmpty &&
                        !backupProvider.isBackingUp &&
                        backupProvider.isSignedIn
                    ? 80
                    : 16,
              ),
              children: [
                if (backupProvider.isSignedIn) ...[
                  _QuickActionsCard(
                    title: 'Album Backup',
                    subtitle: '${mediaProvider.albums.length} albums available',
                    icon: Icons.photo_library_rounded,
                    color: const Color(0xFF34A853),
                    actions: [
                      if (backupProvider.driveFolderUrl != null)
                        _ActionButton(
                          icon: Icons.folder_open,
                          label: 'View in Drive',
                          onPressed: () =>
                              _openDriveFolder(context, backupProvider),
                        )
                      else
                        _ActionButton(
                          icon: Icons.refresh,
                          label: 'Get Drive Link',
                          onPressed: () =>
                              _refreshDriveLink(context, backupProvider),
                        ),
                      _ActionButton(
                        icon: Icons.restore_rounded,
                        label: 'Restore',
                        onPressed: () =>
                            backupProvider.showRestoreDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Progress or Album List
                backupProvider.isBackingUp
                    ? Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: BackupProgressIndicator(
                            progress: backupProvider.backupProgress,
                          ),
                        ),
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
              ],
            ),
            if (backupProvider.selectedBackupAlbums.isNotEmpty &&
                !backupProvider.isBackingUp &&
                backupProvider.isSignedIn)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BackupButton(
                  selectedAlbums: backupProvider.selectedBackupAlbums,
                  isBackingUp: backupProvider.isBackingUp,
                  onBackupPressed: () => _backupAlbums(context, backupProvider),
                ),
              ),
          ],
        );
      },
    );
  }

  void _openDriveFolder(BuildContext context, BackupProvider provider) async {
    final url = provider.driveFolderUrl;
    if (url != null) {
      try {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        if (context.mounted) {
          _showErrorSnackBar(context, 'Could not open Drive folder: $e');
        }
      }
    }
  }

  void _refreshDriveLink(BuildContext context, BackupProvider provider) async {
    await provider.getDriveFolderUrl();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refreshing Drive folder link...')),
      );
    }
  }

  Future<void> _backupAlbums(
      BuildContext context, BackupProvider provider) async {
    try {
      await provider.backupSelectedAlbums();
      if (context.mounted) {
        _showSuccessSnackBar(
          context,
          'Successfully backed up ${provider.selectedBackupAlbums.length} album${provider.selectedBackupAlbums.length == 1 ? '' : 's'}',
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, e.toString());
      }
    }
  }
}

class _JournalBackupTab extends StatelessWidget {
  Future<void> _refreshDriveLink(
      BuildContext context, BackupProvider provider) async {
    await provider.getDriveFolderUrl();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refreshing Drive folder link...')),
      );
    }
  }

  void _openDriveFolder(BuildContext context, BackupProvider provider) async {
    final url = provider.driveFolderUrl;
    if (url != null) {
      try {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        if (context.mounted) {
          _showErrorSnackBar(context, 'Could not open Drive folder: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BackupProvider, JournalProvider>(
      builder: (context, backupProvider, journalProvider, child) {
        // Calculate journals that need backup
        final journalsToBackup = journalProvider.entries
            .where((journal) => !backupProvider.isJournalBackedUp(journal.id))
            .toList();

        return Stack(
          children: [
            ListView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: journalsToBackup.isNotEmpty &&
                        !backupProvider.isBackingUpJournals &&
                        backupProvider.isSignedIn
                    ? 80
                    : 16,
              ),
              children: [
                _StatsCard(
                  title: 'Journal Entries',
                  subtitle: '${journalProvider.entries.length} total entries',
                  icon: Icons.book_rounded,
                  color: const Color(0xFF4285F4),
                  stats: [
                    _StatItem(
                      label: 'Total Entries',
                      value: '${journalProvider.entries.length}',
                    ),
                    if (journalProvider.entries.isNotEmpty)
                      _StatItem(
                        label: 'Last Updated',
                        value: _formatDate(journalProvider.entries.last.date),
                      ),
                    _StatItem(
                      label: 'To Backup',
                      value: '${journalsToBackup.length}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (backupProvider.isSignedIn)
                  _QuickActionsCard(
                    title: 'Journal Backup',
                    subtitle: journalsToBackup.isEmpty
                        ? 'All journals are backed up'
                        : '${journalsToBackup.length} journals need backup',
                    icon: Icons.backup_rounded,
                    color: const Color(0xFF4285F4),
                    actions: [
                      if (backupProvider.driveFolderUrl != null)
                        _ActionButton(
                          icon: Icons.folder_open,
                          label: 'View in Drive',
                          onPressed: () =>
                              _openDriveFolder(context, backupProvider),
                        )
                      else
                        _ActionButton(
                          icon: Icons.refresh,
                          label: 'Get Drive Link',
                          onPressed: () =>
                              _refreshDriveLink(context, backupProvider),
                        ),
                      _ActionButton(
                        icon: Icons.restore_rounded,
                        label: 'Restore',
                        onPressed: () =>
                            backupProvider.showRestoreDialog(context),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                if (backupProvider.isBackingUpJournals)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: BackupProgressIndicator(
                        progress: backupProvider.backupProgress,
                        isJournalBackup: true,
                      ),
                    ),
                  )
                else if (journalProvider.entries.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.book_outlined,
                            size: 40,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No Journal Entries',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start writing in your journal to backup your thoughts and memories.',
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withOpacity(0.7),
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (journalsToBackup.isNotEmpty &&
                !backupProvider.isBackingUpJournals &&
                backupProvider.isSignedIn)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BackupButton(
                  selectedAlbums: const {},
                  isBackingUp: backupProvider.isBackingUpJournals,
                  onBackupPressed: () =>
                      _backupJournals(context, backupProvider, journalProvider),
                  isJournalBackup: true,
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _backupJournals(BuildContext context,
      BackupProvider backupProvider, JournalProvider journalProvider) async {
    try {
      await backupProvider.backupJournals(journalProvider.entries);
      if (context.mounted) {
        _showSuccessSnackBar(
          context,
          'Successfully backed up ${journalProvider.entries.length} journal entries',
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, e.toString());
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _QuickActionsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Widget> actions;

  const _QuickActionsCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: isPrimary ? const Color(0xFF4285F4) : null,
        foregroundColor: isPrimary ? Colors.white : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<_StatItem> stats;

  const _StatsCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (stats.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: stats
                    .map((stat) => Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stat.value,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                stat.label,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });
}

void _showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: const Color(0xFF34A853),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 3),
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
