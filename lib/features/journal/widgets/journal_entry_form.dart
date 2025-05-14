import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:provider/provider.dart';
import 'package:reverie/utils/media_utils.dart';
import '../../../utils/snackbar_utils.dart';
import '../../gallery/provider/media_provider.dart';
import '../models/journal_entry.dart';
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
  final DateTime? initialDate;
  final Function(String title, String content, List<String> mediaIds,
      String? mood, List<String> tags) onSave;
  final VoidCallback? onDelete;

  const JournalEntryForm({
    super.key,
    this.initialTitle,
    this.initialContent,
    this.initialMediaIds,
    this.initialMood,
    this.initialTags,
    this.initialDate,
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
  final _contextController = TextEditingController();
  String? _mood;
  List<String> _tags = [];
  List<AssetEntity> _selectedMedia = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isGenerating = false;
  final FocusNode _contentFocusNode = FocusNode();
  final FocusNode _tagFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  DateTime _selectedDate = DateTime.now();

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
    'Anxious',
    'Grateful',
    'Inspired',
    'Nostalgic',
    'Peaceful',
    'Energetic',
    'Curious',
    'Proud',
    'Hopeful',
    'Relaxed',
    'Motivated',
    'Creative',
    'Adventurous',
  ].map((mood) => '${MediaUtils.getMoodEmoji(mood)} $mood').toList();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? '';
    _contentController.text = widget.initialContent ?? '';
    _mood = widget.initialMood;
    _tags = List.from(widget.initialTags ?? []);
    _selectedDate = widget.initialDate ?? DateTime.now();
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
      final loadedMedia = <AssetEntity>[];

      for (final id in widget.initialMediaIds!) {
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
          loadedMedia.add(item);
        } catch (e) {
          debugPrint('Error finding media with ID $id: $e');
          // Try to load the asset directly if not found in any list
          try {
            final asset = await AssetEntity.fromId(id);
            if (asset != null) {
              loadedMedia.add(asset);
              // Cache the asset data
              await mediaProvider.cacheAssetData(asset);
            }
          } catch (e) {
            debugPrint('Error loading asset directly: $e');
          }
        }
      }

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
    _contextController.dispose();
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

    if (_isSaving) return; // Prevent multiple saves

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
        date: _selectedDate,
        mediaIds: _selectedMedia.map((e) => e.id).toList(),
        mood: _mood,
        tags: _tags,
        lastEdited: DateTime.now(),
      );

      bool success = false;
      if (widget.initialTitle != null) {
        success = await journalProvider.updateEntry(entry);
      } else {
        success = await journalProvider.addEntry(entry);
      }

      if (success && mounted) {
        widget.onSave(
          entry.title,
          entry.content,
          entry.mediaIds,
          entry.mood,
          entry.tags,
        );
        Navigator.pop(context);

        if (widget.initialTitle == null) {
          SnackbarUtils.showJournalEntryCreated(
            context,
            title: entry.title,
            onView: () {
              Navigator.pushNamed(context, '/journal');
            },
          );
        }
      } else if (mounted) {
        SnackbarUtils.showError(context, 'Failed to save journal entry');
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

  Future<void> _showContextDialog() async {
    final theme = Theme.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Help AI Understand',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Tell us about these moments:',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'What happened? How did you feel? What made these moments special?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contextController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Share your thoughts...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () {
                      if (_contextController.text.trim().isNotEmpty) {
                        Navigator.pop(context, _contextController.text.trim());
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Generate'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      await _generateAIContent(result);
    }
  }

  Future<void> _generateAIContent(String userContext) async {
    if (_mood == null) {
      SnackbarUtils.showError(context, 'Please select a mood first');
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final journalProvider = context.read<JournalProvider>();

      // Get media descriptions
      final mediaDescriptions = await Future.wait(
        _selectedMedia.map((media) async {
          if (media.type == AssetType.video) {
            return 'Video';
          }
          return 'Photo';
        }),
      );

      final generatedContent = await journalProvider.generateJournalContent(
        userContext: userContext,
        mood: _mood!,
        tags: _tags,
        mediaDescriptions: mediaDescriptions,
      );

      if (mounted) {
        setState(() {
          _titleController.text = generatedContent['title'] ?? '';
          _contentController.text = generatedContent['content'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to generate content: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
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
                if (_selectedMedia.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    onPressed: () => _showMediaOptions(theme),
                    tooltip: 'Media options',
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

  void _showMediaOptions(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
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
                'Media Options',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.star_rounded),
                title: const Text('Set as Cover Photo'),
                subtitle: const Text('Use this photo as journal cover'),
                onTap: () {
                  Navigator.pop(context);
                  _showCoverPhotoSelection(theme);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('Clear All Media'),
                subtitle: const Text('Remove all photos and videos'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmClearMedia(theme);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showCoverPhotoSelection(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Cover Photo',
                    style: theme.textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: _selectedMedia.length,
                itemBuilder: (context, index) {
                  final asset = _selectedMedia[index];
                  final isSelected = asset.id == widget.initialMediaIds?.first;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        // Move the selected photo to the beginning of the list
                        _selectedMedia.removeAt(index);
                        _selectedMedia.insert(0, asset);
                      });
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image(
                            image: AssetEntityImageProvider(
                              asset,
                              isOriginal: false,
                              thumbnailSize: const ThumbnailSize(300, 300),
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (isSelected)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: theme.colorScheme.primary,
                                size: 32,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearMedia(ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Media'),
        content: const Text(
            'Are you sure you want to remove all photos and videos from this entry? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedMedia.clear();
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('Clear'),
          ),
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

  Widget _buildAIGenerationButton(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Assistant',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _showContextDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _isGenerating
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(
                _isGenerating ? 'Generating...' : 'Generate with AI',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
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
              if (widget.onDelete != null && isEditing)
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
                    child: DropdownButtonFormField<String>(
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
                  ),
                  const SizedBox(height: 10),
                  _buildAIGenerationButton(theme),
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
                            suffixText: '${_titleController.text.length}/50',
                            suffixStyle: TextStyle(
                              color: _titleController.text.length > 40
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                          ),
                          maxLength: 40,
                          buildCounter: (BuildContext context,
                                  {required int currentLength,
                                  required bool isFocused,
                                  required int? maxLength}) =>
                              null, // Hide the default counter
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title';
                            }
                            if (value.length > 50) {
                              return 'Title must be 50 characters or less';
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
