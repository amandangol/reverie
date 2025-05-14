import 'package:flutter/material.dart';
import 'package:reverie/features/gallery/pages/flashbacks_screen.dart';
import 'package:reverie/features/journal/pages/calendar_screen.dart';
import 'package:reverie/features/gallery/pages/album_page.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:reverie/theme/app_theme.dart';
import 'package:reverie/features/backup/pages/backup_screen.dart';
import '../../gallery/pages/video_albums_page.dart';

class QuicFeatureScreen extends StatelessWidget {
  const QuicFeatureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Reverie',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero section with welcome message
            Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello,',
                    style: journalTextTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'What would you like to do today?',
                    style: journalTextTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // Main features section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Access',
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

            // Backup & Security section
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: colorScheme.primaryContainer.withOpacity(0.5),
              ),
              child: _buildBackupSection(context),
            ),

            // Recent memories section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Memories',
                    style: journalTextTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRecentMemoriesRow(context),
                ],
              ),
            ),
          ],
        ),
      ),
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
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
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

    return GestureDetector(
      onTap: onTap,
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
    );
  }

  Widget _buildBackupSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    return ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.backup_rounded,
          color: colorScheme.primary,
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
          'Keep your memories safe with automatic backups',
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
  }

  Widget _buildRecentMemoriesRow(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    // Placeholder for recent memories
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 140,
            margin: EdgeInsets.only(right: index < 4 ? 16 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.withOpacity(0.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Container(
                    height: 120,
                    color: Color.fromARGB(255, 226, 226, 226),
                    child: Center(
                      child: Icon(
                        Icons.image,
                        color: Colors.grey,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Memory ${index + 1}',
                    style: journalTextTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
