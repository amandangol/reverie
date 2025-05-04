import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:intl/intl.dart';
import '../providers/journal_provider.dart';
import '../models/journal_entry.dart';
import 'journal_detail_screen.dart';
import 'package:reverie/theme/app_theme.dart';
import 'package:reverie/utils/media_utils.dart';

class AllJournalsScreen extends StatefulWidget {
  const AllJournalsScreen({super.key});

  @override
  State<AllJournalsScreen> createState() => _AllJournalsScreenState();
}

class _AllJournalsScreenState extends State<AllJournalsScreen> {
  int _gridCrossAxisCount = 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'All Journals',
          style: journalTextTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _gridCrossAxisCount == 2
                  ? Icons.grid_view_rounded
                  : Icons.grid_on_rounded,
              color: colorScheme.primary,
            ),
            onPressed: () {
              setState(() {
                _gridCrossAxisCount = _gridCrossAxisCount == 2 ? 3 : 2;
              });
            },
            tooltip: 'Change grid size',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<JournalProvider>(
        builder: (context, journalProvider, child) {
          if (journalProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = journalProvider.entries;
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    size: 64,
                    color: colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Journal Entries',
                    style: journalTextTheme.titleLarge?.copyWith(
                      color: colorScheme.onBackground,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _gridCrossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: _gridCrossAxisCount == 2 ? 0.85 : 0.75,
            ),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _buildGridCard(entry, theme, index);
            },
          );
        },
      ),
    );
  }

  Widget _buildGridCard(JournalEntry entry, ThemeData theme, int index) {
    return Hero(
      tag: 'journal_${entry.id}',
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => _navigateToJournalDetail(entry),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: _gridCrossAxisCount == 2 ? 3 : 2,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildEntryImage(entry),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatDate(entry.date),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      if (entry.mood != null && entry.mood!.isNotEmpty)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  MediaUtils.getMoodIcon(entry.mood!),
                                  size: 16,
                                  color: _getMoodColor(entry.mood!),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  entry.mood!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: _gridCrossAxisCount == 2 ? 2 : 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Text(
                            entry.content,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                            maxLines: _gridCrossAxisCount == 2 ? 3 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (entry.tags.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildTagsRow(entry, theme),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntryImage(JournalEntry entry) {
    if (entry.mediaIds.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.3),
              Theme.of(context).colorScheme.secondary.withOpacity(0.3),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.auto_stories_rounded,
            size: 32,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ),
        ),
      );
    }

    final journalProvider = Provider.of<JournalProvider>(context);
    final cachedAsset = journalProvider.imageCache[entry.mediaIds.first];

    if (cachedAsset != null) {
      return ShaderMask(
        shaderCallback: (rect) {
          return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.black.withOpacity(0.1),
            ],
            stops: const [0.0, 0.3],
          ).createShader(rect);
        },
        blendMode: BlendMode.darken,
        child: Image(
          image: AssetEntityImageProvider(
            cachedAsset,
            isOriginal: false,
            thumbnailSize: const ThumbnailSize(600, 600),
          ),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildImageErrorPlaceholder(context);
          },
        ),
      );
    }

    return FutureBuilder<AssetEntity?>(
      future: journalProvider.getImageAsset(entry.mediaIds.first),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
            ),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          );
        }

        final asset = snapshot.data;
        if (asset != null) {
          return ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.1),
                ],
                stops: const [0.0, 0.3],
              ).createShader(rect);
            },
            blendMode: BlendMode.darken,
            child: Image(
              image: AssetEntityImageProvider(
                asset,
                isOriginal: false,
                thumbnailSize: const ThumbnailSize(600, 600),
              ),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildImageErrorPlaceholder(context);
              },
            ),
          );
        }

        return _buildImageErrorPlaceholder(context);
      },
    );
  }

  Widget _buildImageErrorPlaceholder(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_rounded,
              size: 32,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Image unavailable',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsRow(JournalEntry entry, ThemeData theme) {
    if (entry.tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 18,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          for (var i = 0; i < entry.tags.length && i < 2; i++)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  entry.tags[i],
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.surfaceContainerHighest,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          if (entry.tags.length > 2)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+${entry.tags.length - 2}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'excited':
      case 'joyful':
        return Colors.amber;
      case 'calm':
      case 'relaxed':
        return Colors.lightBlue;
      case 'sad':
      case 'depressed':
        return Colors.blueGrey;
      case 'angry':
      case 'frustrated':
        return Colors.redAccent;
      case 'anxious':
      case 'worried':
        return Colors.deepPurple;
      default:
        return Colors.white;
    }
  }

  void _navigateToJournalDetail(JournalEntry entry) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            JournalDetailScreen(entry: entry),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 0.05);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ).then((_) {
      final journalProvider =
          Provider.of<JournalProvider>(context, listen: false);
      journalProvider.loadEntries();
    });
  }
}
