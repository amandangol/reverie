import 'package:flutter/material.dart';
import 'package:reverie/features/gallery/pages/flashbacks_screen.dart';
import 'package:reverie/features/journal/pages/calendar_screen.dart';
import 'package:reverie/features/gallery/pages/gallery_page.dart';
import 'package:reverie/features/journal/pages/journal_screen.dart';
import 'package:reverie/features/gallery/pages/album_page.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:reverie/features/onboarding/pages/onboarding_screen.dart';

import '../../gallery/pages/video_albums_page.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Discover',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Explore Features',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Discover new ways to relive your memories',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _buildFeatureGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final features = [
      {
        'title': 'Gallery',
        'description': 'Browse your photos and videos',
        'icon': Icons.photo_library_rounded,
        'color': colorScheme.primary,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GalleryPage()),
            ),
      },
      {
        'title': 'Journal',
        'description': 'Write and organize your thoughts',
        'icon': Icons.auto_stories_rounded,
        'color': colorScheme.secondary,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const JournalScreen()),
            ),
      },
      {
        'title': 'Flashbacks',
        'description': 'Relive your past memories',
        'icon': Icons.history_rounded,
        'color': Colors.orange,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FlashbacksScreen()),
            ),
      },
      {
        'title': 'Calendar',
        'description': 'View your journal entries by date',
        'icon': Icons.calendar_month_rounded,
        'color': Colors.blue,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CalendarScreen()),
            ),
      },
      {
        'title': 'Favorites',
        'description': 'Access your favorite memories',
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
        'description': 'Watch your video collection',
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
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return _buildFeatureCard(
          context,
          title: feature['title'] as String,
          description: feature['description'] as String,
          icon: feature['icon'] as IconData,
          color: feature['color'] as Color,
          onTap: feature['onTap'] as VoidCallback,
        );
      },
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
