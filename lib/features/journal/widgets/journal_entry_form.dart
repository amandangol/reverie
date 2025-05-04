import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:provider/provider.dart';
import 'package:reverie/utils/media_utils.dart';
import '../../../utils/snackbar_utils.dart';
import '../../gallery/provider/media_provider.dart';
import '../models/journal_entry.dart';
import '../pages/journal_screen.dart';
import '../providers/journal_provider.dart';
import 'media_selection_screen.dart';
import 'package:flutter/services.dart';
import 'package:reverie/theme/app_theme.dart';

class JournalEntryForm extends StatefulWidget {
  final String? initialTitle;
  final String? initialContent;
  final List<String>? initialMediaIds;
  final String? initialMood;
  final List<String>? initialTags;
  final Function(String, String, List<String>, String?, List<String>) onSave;
  final VoidCallback? onDelete;

  const JournalEntryForm({
    super.key,
    this.initialTitle,
    this.initialContent,
    this.initialMediaIds,
    this.initialMood,
    this.initialTags,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<JournalEntryForm> createState() => _JournalEntryFormState();
}

class _JournalEntryFormState extends State<JournalEntryForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  String? _mood;
  List<String> _tags = [];
  List<AssetEntity> _selectedMedia = [];
  bool _isLoading = true;
  bool _isSaving = false;
  final FocusNode _contentFocusNode = FocusNode();
  final FocusNode _tagFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final List<String> _availableMoods = [
    'Happy',
    'Sad',
    'Angry',
    'Scared',
    'Tired',
    'Excited',
    'Calm',
    'Lonely',
    'Confident',
    'Surprised',
    'Thoughtful',
    'Disappointed',
    'Celebratory',
    'Frustrated',
  ].map((mood) => '${MediaUtils.getMoodEmoji(mood)} $mood').toList();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? '';
    _contentController.text = widget.initialContent ?? '';
    _mood = widget.initialMood;
    _tags = List.from(widget.initialTags ?? []);
    _loadInitialMedia();
  }

  Future<void> _loadInitialMedia() async {
    if (widget.initialMediaIds == null || widget.initialMediaIds!.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final mediaProvider = context.read<MediaProvider>();

      // Load media if not already loaded
      if (!mediaProvider.isInitialized) {
        await mediaProvider.loadMedia();
      }

      // Get all media items from the provider
      final allMediaItems = mediaProvider.allMediaItems;
      final currentMediaItems = mediaProvider.currentAlbumItems;
      final mediaItems = mediaProvider.mediaItems;

      // Find media items by ID, checking all available sources
      final loadedMedia = widget.initialMediaIds!
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

      if (mounted) {
        setState(() {
          _selectedMedia = loadedMedia;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading initial media: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _contentFocusNode.dispose();
    _tagFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });

      // Subtle animation for feedback
      HapticFeedback.lightImpact();
    }
    _tagFocusNode.requestFocus();
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) {
      SnackbarUtils.showError(context, 'Please fix the highlighted fields');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final journalProvider = context.read<JournalProvider>();
      final entry = JournalEntry(
        id: widget.initialTitle != null
            ? journalProvider.entries
                .firstWhere((e) => e.title == widget.initialTitle)
                .id
            : DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        content: _contentController.text,
        date: DateTime.now(),
        mediaIds: _selectedMedia.map((m) => m.id).toList(),
        mood: _mood,
        tags: _tags,
      );

      if (widget.initialTitle != null) {
        await journalProvider.updateEntry(entry);
        if (mounted) {
          Navigator.pop(context);
          SnackbarUtils.showSuccess(
              context, 'Journal entry updated successfully');
        }
      } else {
        await journalProvider.addEntry(entry);
        if (mounted) {
          Navigator.pop(context);
          SnackbarUtils.showJournalEntryCreated(
            context,
            title: entry.title,
            onView: () {},
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to save journal entry: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _selectMedia() async {
    final mediaProvider = context.read<MediaProvider>();

    try {
      if (!mediaProvider.isInitialized) {
        await mediaProvider.loadMedia();
      }

      final result = await Navigator.push<List<AssetEntity>>(
        context,
        MaterialPageRoute(
          builder: (context) => MediaSelectionScreen(
            initiallySelected: _selectedMedia,
            availableMedia: mediaProvider.allMediaItems,
          ),
        ),
      );

      if (result != null) {
        setState(() {
          _selectedMedia = result;
        });

        if (_selectedMedia.isNotEmpty) {
          HapticFeedback.mediumImpact();
        }
      }
    } catch (e) {
      debugPrint('Error selecting media: $e');
      if (mounted) {
        SnackbarUtils.showError(context, 'Error selecting media: $e');
      }
    }
  }

  Widget _buildMediaSection(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.photo_library_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Media',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_selectedMedia.isEmpty)
            _buildEmptyMediaPlaceholder(theme)
          else
            _buildMediaGrid(),
        ],
      ),
    );
  }

  Widget _buildEmptyMediaPlaceholder(ThemeData theme) {
    return GestureDetector(
      onTap: _selectMedia,
      child: Container(
        height: 200,
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Add Photos & Videos',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Capture your moments visually',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaGrid() {
    final theme = Theme.of(context);
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedMedia.length,
            itemBuilder: (context, index) {
              final asset = _selectedMedia[index];
              return Container(
                width: 200,
                margin: EdgeInsets.only(
                  right: index == _selectedMedia.length - 1 ? 0 : 12,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'media_${asset.id}',
                      child: Material(
                        elevation: 2,
                        shadowColor: Colors.black45,
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: AssetEntityImage(
                          asset,
                          isOriginal: false,
                          thumbnailSize: const ThumbnailSize(400, 400),
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                    if (asset.type == AssetType.video)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                MediaUtils.getMediaTypeIcon(asset.type),
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Consumer<MediaProvider>(
                                builder: (context, mediaProvider, _) {
                                  final duration =
                                      mediaProvider.getDuration(asset.id);
                                  if (duration == null) {
                                    return const SizedBox();
                                  }
                                  return Text(
                                    MediaUtils.formatDuration(duration),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedMedia.removeAt(index);
                            });
                            HapticFeedback.mediumImpact();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _selectMedia,
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagItem(String tag, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _removeTag(tag),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '#$tag',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.close,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.initialTitle != null;
    final colorScheme = theme.colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    return Dialog.fullscreen(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: colorScheme.background,
          appBar: AppBar(
            title: Text(
              isEditing ? 'Edit Journal Entry' : 'New Journal Entry',
              style: journalTextTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
                fontSize: 17,
              ),
            ),
            centerTitle: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: colorScheme.background,
            leading: IconButton(
              icon: Icon(Icons.close_rounded,
                  color: colorScheme.onSurface, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (widget.onDelete != null && !isEditing)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.red, size: 20),
                  tooltip: 'Delete entry',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: colorScheme.surface,
                        surfaceTintColor: Colors.transparent,
                        title: const Text(
                          'Delete Entry',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        content: const Text(
                          'Are you sure you want to delete this entry? This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: colorScheme.primary),
                            ),
                          ),
                          FilledButton(
                            onPressed: () {
                              widget.onDelete!();
                              Navigator.pop(context); // Close dialog
                              Navigator.pop(context); // Close form
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _isSaving ? null : _saveEntry,
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  disabledBackgroundColor: colorScheme.primary.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Save',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: colorScheme.onPrimary,
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: SingleChildScrollView(
            controller: _scrollController,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMediaSection(theme),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          style: journalTextTheme.bodyLarge,
                          decoration: InputDecoration(
                            labelText: 'Title',
                            hintText: 'Give your entry a title',
                            labelStyle: journalTextTheme.bodyMedium,
                            hintStyle: journalTextTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            prefixIcon: Icon(
                              Icons.title,
                              color: colorScheme.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _contentController,
                          focusNode: _contentFocusNode,
                          maxLines: 10,
                          style: journalTextTheme.bodyLarge,
                          decoration: InputDecoration(
                            labelText: 'Content',
                            hintText: 'Write your thoughts here...',
                            alignLabelWithHint: true,
                            labelStyle: journalTextTheme.bodyMedium,
                            hintStyle: journalTextTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter some content';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _mood,
                          style: journalTextTheme.bodyLarge,
                          decoration: InputDecoration(
                            labelText: 'Mood',
                            labelStyle: journalTextTheme.bodyMedium,
                            prefixIcon: Icon(
                              Icons.mood,
                              color: colorScheme.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          items: _availableMoods.map((mood) {
                            return DropdownMenuItem(
                              value: mood,
                              child: Text(mood),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _mood = value;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Icon(
                              Icons.tag,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tags',
                              style: journalTextTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _tagController,
                          focusNode: _tagFocusNode,
                          style: journalTextTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: 'Add a tag...',
                            hintStyle: journalTextTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                Icons.add_circle_outline,
                                color: colorScheme.primary,
                              ),
                              onPressed: _addTag,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: colorScheme.outline.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 1,
                              ),
                            ),
                            filled: true,
                            fillColor:
                                colorScheme.surfaceVariant.withOpacity(0.5),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          onSubmitted: (_) => _addTag(),
                        ),
                        const SizedBox(height: 16),
                        if (_tags.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _tags
                                .map((tag) => _buildTagItem(tag, theme))
                                .toList(),
                          ),
                        const SizedBox(height: 16),
                        // Suggested keywords
                        Text(
                          'Suggested Keywords',
                          style: journalTextTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            'gratitude',
                            'reflection',
                            'achievement',
                            'challenge',
                            'learning',
                            'growth',
                            'family',
                            'friends',
                            'work',
                            'health',
                            'goals',
                            'ideas'
                          ]
                              .map((keyword) => ActionChip(
                                    label: Text(
                                      keyword,
                                      style: TextStyle(
                                        color: colorScheme.onSurface,
                                        fontSize: 13,
                                      ),
                                    ),
                                    onPressed: () {
                                      if (!_tags.contains(keyword)) {
                                        setState(() {
                                          _tags.add(keyword);
                                        });
                                        HapticFeedback.lightImpact();
                                      }
                                    },
                                    backgroundColor: colorScheme.surfaceVariant
                                        .withOpacity(0.5),
                                    side: BorderSide(
                                      color:
                                          colorScheme.outline.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
