import 'package:flutter/material.dart';
import 'package:reverie/features/gallery/pages/flashbacks/flashbacks_screen.dart';
import 'package:reverie/features/journal/pages/calendar_screen.dart';
import 'package:reverie/features/gallery/pages/albums/album_page.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:reverie/theme/app_theme.dart';
import 'package:reverie/features/backupdrive/pages/backup_screen.dart';
import 'package:reverie/features/gallery/pages/albums/video_albums_page.dart';
import 'package:provider/provider.dart';
import 'package:reverie/features/backupdrive/provider/backup_provider.dart';
import 'package:reverie/features/gallery/provider/media_provider.dart';
import 'package:reverie/features/journal/providers/journal_provider.dart';
import 'package:reverie/features/journal/widgets/journal_search_delegate.dart';

class QuickAccessScreen extends StatelessWidget {
  const QuickAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Quick Glance',
          style: journalTextTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
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
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            context.read<MediaProvider>().loadMedia(),
            context.read<JournalProvider>().refresh(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: _buildStatsRow(context),
              ),

              // Main features section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: journalTextTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMainFeaturesGrid(context),
                  ],
                ),
              ),

              // Recent Journals section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Journals',
                          style: journalTextTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/journals');
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildRecentJournals(context),
                  ],
                ),
              ),

              // Backup & Security section
              Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: colorScheme.primaryContainer.withOpacity(0.5),
                ),
                child: _buildBackupSection(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Consumer2<MediaProvider, JournalProvider>(
      builder: (context, mediaProvider, journalProvider, _) {
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.photo_library_rounded,
                value: mediaProvider.mediaItems.length.toString(),
                label: 'Photos',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.edit_note_rounded,
                value: journalProvider.entries.length.toString(),
                label: 'Journal Entries',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.calendar_today_rounded,
                value: journalProvider.getCurrentStreak().toString(),
                label: 'Day Streak',
                color: Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: journalTextTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: journalTextTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentJournals(BuildContext context) {
    return Consumer<JournalProvider>(
      builder: (context, journalProvider, _) {
        final recentEntries = journalProvider.entries.take(2).toList();

        if (recentEntries.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_stories_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'No journal entries yet',
                  style: AppTheme.journalTextTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return Column(
          children: recentEntries.map((entry) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_note_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(
                  entry.title,
                  style: AppTheme.journalTextTheme.titleMedium,
                ),
                subtitle: Text(
                  entry.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.journalTextTheme.bodyMedium,
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/journal-detail',
                    arguments: entry,
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMainFeaturesGrid(BuildContext context) {
    final features = [
      {
        'title': 'Flashbacks',
        'icon': Icons.history_rounded,
        'color': Colors.orange,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FlashbacksScreen()),
            ),
      },
      {
        'title': 'Calendar',
        'icon': Icons.calendar_month_rounded,
        'color': Colors.blue,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CalendarScreen()),
            ),
      },
      {
        'title': 'Favorites',
        'icon': Icons.favorite_rounded,
        'color': Colors.red,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AlbumPage(
                  album: AssetPathEntity(id: 'favorites', name: 'Favorites'),
                  isGridView: true,
                  gridCrossAxisCount: 3,
                  isFavoritesAlbum: true,
                ),
              ),
            ),
      },
      {
        'title': 'Videos',
        'icon': Icons.video_library_rounded,
        'color': Colors.purple,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const VideoAlbumsPage(),
              ),
            ),
      },
      {
        'title': 'All Journals',
        'icon': Icons.auto_stories_rounded,
        'color': Colors.green,
        'onTap': () => Navigator.pushNamed(context, '/journals'),
      },
      {
        'title': 'Search',
        'icon': Icons.search_rounded,
        'color': Colors.teal,
        'onTap': () {
          showSearch(
            context: context,
            delegate: JournalSearchDelegate(context.read<JournalProvider>()),
          );
        },
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return _buildFeatureItem(
          context,
          title: feature['title'] as String,
          icon: feature['icon'] as IconData,
          color: feature['color'] as Color,
          onTap: feature['onTap'] as VoidCallback,
        );
      },
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: journalTextTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackupSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    return Consumer<BackupProvider>(
      builder: (context, backupProvider, _) {
        return ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: backupProvider.isSignedIn
                  ? const Color(0xFF34A853).withOpacity(0.2)
                  : colorScheme.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              backupProvider.isSignedIn
                  ? Icons.cloud_done_rounded
                  : Icons.backup_rounded,
              color: backupProvider.isSignedIn
                  ? const Color(0xFF34A853)
                  : colorScheme.primary,
              size: 24,
            ),
          ),
          title: Text(
            'Backup & Security',
            style: journalTextTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Keep your memories safe with backups and restorations',
              style: journalTextTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BackupScreen()),
            );
          },
        );
      },
    );
  }
}
