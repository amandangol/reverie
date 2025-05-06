import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:provider/provider.dart';
import 'package:reverie/utils/media_utils.dart';
import 'package:reverie/features/journal/models/journal_entry.dart';
import 'package:reverie/features/journal/providers/journal_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../utils/snackbar_utils.dart';
import '../../gallery/provider/media_provider.dart';
import '../../gallery/widgets/media_detail_view.dart';
import '../widgets/journal_entry_form.dart';

class JournalDetailScreen extends StatefulWidget {
  final JournalEntry entry;

  const JournalDetailScreen({
    super.key,
    required this.entry,
  });

  @override
  State<JournalDetailScreen> createState() => _JournalDetailScreenState();
}

class _JournalDetailScreenState extends State<JournalDetailScreen> {
  late JournalEntry _currentEntry;

  @override
  void initState() {
    super.initState();
    _currentEntry = widget.entry;
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Share Entry',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.share_rounded),
                title: const Text('Share Entry'),
                subtitle: const Text('Share as text'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await context.read<JournalProvider>().shareJournalEntry(
                          widget.entry,
                          includeMedia: false,
                        );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to share entry')),
                      );
                    }
                  }
                },
              ),
              if (widget.entry.mediaIds.isNotEmpty) ...[
                ListTile(
                  leading: SvgPicture.asset(
                    'assets/svg/photos.svg',
                    width: 24,
                    height: 24,
                  ),
                  title: const Text('Share with Photos'),
                  subtitle: const Text('Include attached media'),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await context.read<JournalProvider>().shareJournalEntry(
                            widget.entry,
                            includeMedia: true,
                          );
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Failed to share entry with photos')),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: SvgPicture.asset(
                    'assets/svg/insta.svg',
                    width: 24,
                    height: 24,
                  ),
                  title: const Text('Share on Instagram'),
                  subtitle: const Text('Share photos with caption'),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await context.read<JournalProvider>().shareToSocialMedia(
                            widget.entry,
                            'instagram',
                          );
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Failed to share on Instagram')),
                        );
                      }
                    }
                  },
                ),
              ],
              ListTile(
                leading: SvgPicture.asset(
                  'assets/svg/fb.svg',
                  width: 24,
                  height: 24,
                ),
                title: const Text('Share on Facebook'),
                subtitle: const Text('Open Facebook app'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await context.read<JournalProvider>().shareToSocialMedia(
                          widget.entry,
                          'facebook',
                        );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Failed to share on Facebook')),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: SvgPicture.asset(
                  'assets/svg/x_twitter.svg',
                  width: 24,
                  height: 24,
                ),
                title: const Text('Share on Twitter'),
                subtitle: const Text('Open Twitter app'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await context.read<JournalProvider>().shareToSocialMedia(
                          widget.entry,
                          'twitter',
                        );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Failed to share on Twitter')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaProvider = context.watch<MediaProvider>();
    final journalProvider = context.watch<JournalProvider>();

    // Update current entry from provider if available
    final updatedEntry = journalProvider.entries.firstWhere(
      (e) => e.id == _currentEntry.id,
      orElse: () => _currentEntry,
    );

    if (updatedEntry != _currentEntry) {
      _currentEntry = updatedEntry;
    }

    // Load media if not already loaded
    if (!mediaProvider.isInitialized) {
      mediaProvider.loadMedia();
    }

    // Get all media items from the provider
    final allMediaItems = mediaProvider.allMediaItems;
    final currentMediaItems = mediaProvider.currentAlbumItems;
    final mediaItems = mediaProvider.mediaItems;

    // Find media items by ID, checking all available sources
    final loadedMediaItems = _currentEntry.mediaIds
        .map((id) {
          try {
            // First check all media items
            final item = allMediaItems.firstWhere(
              (item) => item.id == id,
              orElse: () => mediaItems.firstWhere(
                (item) => item.id == id,
                orElse: () => currentMediaItems.firstWhere(
                  (item) => item.id == id,
                  orElse: () => throw Exception('Media not found'),
                ),
              ),
            );
            return item;
          } catch (e) {
            debugPrint('Error finding media with ID $id: $e');
            return null;
          }
        })
        .whereType<AssetEntity>()
        .toList();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Sliver app bar with parallax effect for header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            stretch: true,
            backgroundColor: colorScheme.surface,
            title: Container(
              margin: const EdgeInsets.only(right: 16),
              child: Text(
                "Journal",
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  letterSpacing: 0.15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            centerTitle: false,
            titleSpacing: 16,
            elevation: 0,
            scrolledUnderElevation: 0,
            flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.blurBackground,
                ],
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (loadedMediaItems.isNotEmpty)
                      Image(
                        image: AssetEntityImageProvider(
                          loadedMediaItems.first,
                          isOriginal: true,
                        ),
                        fit: BoxFit.cover,
                      )
                    else
                      Container(
                        color: colorScheme.primaryContainer,
                        child: Center(
                          child: Icon(
                            Icons.auto_stories_rounded,
                            size: 64,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),

                    // Blur layer
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: Container(
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ),

                    // ShaderMask on top of blur
                    ShaderMask(
                      shaderCallback: (rect) {
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: const [0.6, 1.0],
                        ).createShader(rect);
                      },
                      blendMode: BlendMode.srcOver,
                      child: Container(),
                    ),
                  ],
                )),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded),
                tooltip: 'Share Entry',
                onPressed: _showShareOptions,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete Entry',
                onPressed: () => _confirmDeleteEntry(context),
              ),
            ],
          ),

          // Journal content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date, mood, and tags in a more prominent position
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date and mood row
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.calendar_month_rounded,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('EEEE, MMMM d, yyyy')
                                          .format(_currentEntry.date),
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (_currentEntry.lastEdited != null &&
                                        _currentEntry.lastEdited !=
                                            _currentEntry.date)
                                      Text(
                                        'Edited: ${DateFormat('MMM d • h:mm a').format(_currentEntry.lastEdited!)}',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurface
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Divider between date and mood
                          const SizedBox(height: 16),
                          Divider(height: 1, color: colorScheme.outlineVariant),
                          const SizedBox(height: 16),

                          // Mood with more visual appeal
                          if (_currentEntry.mood != null)
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: _getMoodIcon(
                                    _currentEntry.mood!,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _currentEntry.mood!,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Content with styled typography
                  Card(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    elevation: 1,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.book_rounded,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _currentEntry.title,
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    letterSpacing: 0.15,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SelectableText(
                            _currentEntry.content,
                            style: textTheme.bodyLarge?.copyWith(
                              height: 1.7,
                              letterSpacing: 0.3,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Media gallery (if there are media items)
          if (loadedMediaItems.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      color:
                          colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.photo_library_rounded,
                                  size: 20,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Media Gallery',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${loadedMediaItems.length}',
                                    style: TextStyle(
                                      color: colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            GridView.builder(
                              padding: const EdgeInsets.all(8),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 1,
                              ),
                              itemCount: loadedMediaItems.length,
                              itemBuilder: (context, index) {
                                final asset = loadedMediaItems[index];
                                return GestureDetector(
                                  onTap: () => _showFullScreenImage(
                                    context,
                                    asset,
                                    index,
                                    loadedMediaItems,
                                  ),
                                  child: Hero(
                                    tag:
                                        'journal_media_${_currentEntry.id}_$index',
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image(
                                            image: AssetEntityImageProvider(
                                              asset,
                                              isOriginal: false,
                                              thumbnailSize:
                                                  const ThumbnailSize(300, 300),
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                          if (asset.type == AssetType.video)
                                            Positioned(
                                              bottom: 8,
                                              right: 8,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.6),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      MediaUtils
                                                          .getMediaTypeIcon(
                                                              asset.type),
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Consumer<MediaProvider>(
                                                      builder: (context,
                                                          mediaProvider, _) {
                                                        final duration =
                                                            mediaProvider
                                                                .getDuration(
                                                                    asset.id);
                                                        if (duration == null) {
                                                          return const SizedBox();
                                                        }
                                                        return Text(
                                                          MediaUtils
                                                              .formatDuration(
                                                                  duration),
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w500,
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
            ),
          ],

          // Tags section at the bottom
          if (_currentEntry.tags.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.tag_rounded,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tags',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _currentEntry.tags.map((tag) {
                            return Container(
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditJournalEntryDialog(context),
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _getMoodIcon(String mood) {
    return Icon(
      MediaUtils.getMoodIcon(mood),
      color: MediaUtils.getMoodColor(mood),
    );
  }

  void _showFullScreenImage(BuildContext context, AssetEntity asset,
      int initialIndex, List<AssetEntity> mediaItems) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaDetailView(
          asset: asset,
          assetList: mediaItems,
          heroTag: 'journal_media_${_currentEntry.id}_$initialIndex',
        ),
      ),
    );
  }

  void _confirmDeleteEntry(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text(
            'Are you sure you want to delete this journal entry? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final journalProvider = context.read<JournalProvider>();
              journalProvider.deleteEntry(_currentEntry.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to journal list
              SnackbarUtils.showError(
                context,
                'Journal entry deleted',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditJournalEntryDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: JournalEntryForm(
          initialTitle: _currentEntry.title,
          initialContent: _currentEntry.content,
          initialMediaIds: _currentEntry.mediaIds,
          initialMood: _currentEntry.mood,
          initialTags: _currentEntry.tags,
          onSave: (title, content, mediaIds, mood, tags,
              {DateTime? lastEdited}) async {
            final updatedEntry = _currentEntry.copyWith(
              title: title,
              content: content,
              mediaIds: mediaIds,
              mood: mood,
              tags: tags,
              lastEdited: lastEdited ?? DateTime.now(),
            );
            await context.read<JournalProvider>().updateEntry(updatedEntry);
            if (mounted) {
              setState(() {
                _currentEntry = updatedEntry;
              });
            }
          },
        ),
      ),
    );
  }
}
