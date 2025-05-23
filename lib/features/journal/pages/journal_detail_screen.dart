import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:provider/provider.dart';
import 'package:reverie/utils/media_utils.dart';
import 'package:reverie/features/journal/models/journal_entry.dart';
import 'package:reverie/features/journal/providers/journal_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:reverie/widgets/custom_markdown.dart';
import 'package:share_plus/share_plus.dart';
import '../../../utils/snackbar_utils.dart';
import '../../gallery/provider/media_provider.dart';
import '../widgets/journal_entry_form.dart';
import 'package:reverie/features/gallery/pages/mediadetail/media_detail_view.dart';
import '../providers/translation_provider.dart';

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
  String? _translatedTitle;
  String? _translatedContent;
  String? _currentLanguage;
  bool _isTranslating = false;

  @override
  void initState() {
    super.initState();
    _currentEntry = widget.entry;
  }

  Future<void> _translateEntry(String targetLanguage) async {
    if (_isTranslating) return;

    setState(() {
      _isTranslating = true;
    });

    try {
      final translationProvider = context.read<TranslationProvider>();

      // Translate title
      final titleResult = await translationProvider.translateText(
        text: _currentEntry.title,
        targetLanguage: targetLanguage,
      );

      // Translate content
      final contentResult = await translationProvider.translateText(
        text: _currentEntry.content,
        targetLanguage: targetLanguage,
      );

      if (mounted) {
        setState(() {
          _translatedTitle = titleResult['translatedText'];
          _translatedContent = contentResult['translatedText'];
          _currentLanguage = targetLanguage;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Translation failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTranslating = false;
        });
      }
    }
  }

  void _showTranslationOptions() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Translate Entry',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_currentLanguage != null)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _translatedTitle = null;
                              _translatedContent = null;
                              _currentLanguage = null;
                            });
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.restore),
                          label: const Text('Show Original'),
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Consumer<TranslationProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) {
                      return const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        _buildLanguageOption(
                          context,
                          'Arabic',
                          'ar',
                          '🇸🇦',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Bengali',
                          'bn',
                          '🇧🇩',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Chinese (Simplified)',
                          'zh-CN',
                          '🇨🇳',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Czech',
                          'cs',
                          '🇨🇿',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Danish',
                          'da',
                          '🇩🇰',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Dutch',
                          'nl',
                          '🇳🇱',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Finnish',
                          'fi',
                          '🇫🇮',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'French',
                          'fr',
                          '🇫🇷',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'German',
                          'de',
                          '🇩🇪',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Greek',
                          'el',
                          '🇬🇷',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Hebrew',
                          'he',
                          '🇮🇱',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Hindi',
                          'hi',
                          '🇮🇳',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Hungarian',
                          'hu',
                          '🇭🇺',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Indonesian',
                          'id',
                          '🇮🇩',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Italian',
                          'it',
                          '🇮🇹',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Japanese',
                          'ja',
                          '🇯🇵',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Korean',
                          'ko',
                          '🇰🇷',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Malay',
                          'ms',
                          '🇲🇾',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Malayalam',
                          'ml',
                          '🇮🇳',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Marathi',
                          'mr',
                          '🇮🇳',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Norwegian',
                          'no',
                          '🇳🇴',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Persian',
                          'fa',
                          '🇮🇷',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Polish',
                          'pl',
                          '🇵🇱',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Portuguese',
                          'pt',
                          '🇵🇹',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Romanian',
                          'ro',
                          '🇷🇴',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Russian',
                          'ru',
                          '🇷🇺',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Spanish',
                          'es',
                          '🇪🇸',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Swedish',
                          'sv',
                          '🇸🇪',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Tamil',
                          'ta',
                          '🇮🇳',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Telugu',
                          'te',
                          '🇮🇳',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Thai',
                          'th',
                          '🇹🇭',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Turkish',
                          'tr',
                          '🇹🇷',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Ukrainian',
                          'uk',
                          '🇺🇦',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Urdu',
                          'ur',
                          '🇵🇰',
                          colorScheme,
                        ),
                        _buildLanguageOption(
                          context,
                          'Vietnamese',
                          'vi',
                          '🇻🇳',
                          colorScheme,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String language,
    String code,
    String flag,
    ColorScheme colorScheme,
  ) {
    final isSelected = _currentLanguage == language;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          flag,
          style: const TextStyle(fontSize: 20),
        ),
      ),
      title: Text(
        language,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle_rounded,
              color: colorScheme.primary,
            )
          : null,
      onTap: () {
        Navigator.pop(context);
        _translateEntry(language);
      },
    );
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
                    final shareText = '''
${widget.entry.title}

${widget.entry.content}

${widget.entry.tags.isNotEmpty ? 'Tags: ${widget.entry.tags.map((tag) => '#$tag').join(' ')}\n' : ''}
Date: ${DateFormat('MMMM d, yyyy').format(widget.entry.date)}
''';
                    await Share.share(shareText, subject: widget.entry.title);
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
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showExportOptions() {
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
                'Export Entry',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Export as PDF'),
                subtitle: const Text('Save as PDF document'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await context.read<JournalProvider>().exportJournalEntry(
                          widget.entry,
                          'pdf',
                        );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Failed to export as PDF')),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('Export as JSON'),
                subtitle: const Text('Save as JSON data'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await context.read<JournalProvider>().exportJournalEntry(
                          widget.entry,
                          'json',
                        );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Failed to export as JSON')),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_snippet),
                title: const Text('Export as Text'),
                subtitle: const Text('Save as plain text'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await context.read<JournalProvider>().exportJournalEntry(
                          widget.entry,
                          'text',
                        );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Failed to export as text')),
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
          // Regular AppBar
          SliverAppBar(
            pinned: true,
            backgroundColor: colorScheme.surface,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(_currentEntry.date),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_currentEntry.lastEdited != null &&
                    _currentEntry.lastEdited != _currentEntry.date)
                  Text(
                    'Edited: ${DateFormat('MMM d • h:mm a').format(_currentEntry.lastEdited!)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
            centerTitle: false,
            titleSpacing: 16,
            elevation: 0,
            scrolledUnderElevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.translate),
                tooltip: 'Translate Entry',
                onPressed: _showTranslationOptions,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'More options',
                onSelected: (value) {
                  switch (value) {
                    case 'export':
                      _showExportOptions();
                      break;
                    case 'share':
                      _showShareOptions();
                      break;
                    case 'delete':
                      _confirmDeleteEntry(context);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(
                          Icons.download_rounded,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text('Export Entry'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(
                          Icons.share_rounded,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text('Share Entry'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Delete Entry',
                          style: TextStyle(
                            color: colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Main content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mood section
                  if (_currentEntry.mood != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _getMoodIcon(_currentEntry.mood!),
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
                    ),

                  const SizedBox(height: 16),

                  // Media preview grid
                  if (loadedMediaItems.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
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
                            itemCount: loadedMediaItems.length > 6
                                ? 6
                                : loadedMediaItems.length,
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
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image(
                                          image: AssetEntityImageProvider(
                                            asset,
                                            isOriginal: false,
                                            thumbnailSize:
                                                const ThumbnailSize(300, 300),
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      if (index == 5 &&
                                          loadedMediaItems.length > 6)
                                        GestureDetector(
                                          onTap: () => _showAllMedia(
                                              context, loadedMediaItems),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withOpacity(0.6),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '+${loadedMediaItems.length - 6}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
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
                                              color:
                                                  Colors.black.withOpacity(0.6),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  MediaUtils.getMediaTypeIcon(
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
                                                      MediaUtils.formatDuration(
                                                          duration),
                                                      style: const TextStyle(
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
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Content section
                  _buildContentSection(theme),

                  // Tags section
                  if (_currentEntry.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              TextButton.icon(
                                onPressed: () {
                                  // Show entries with similar tags
                                  _showSimilarEntries(context);
                                },
                                icon:
                                    const Icon(Icons.search_rounded, size: 18),
                                label: const Text('Find Similar'),
                                style: TextButton.styleFrom(
                                  foregroundColor: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _currentEntry.tags.map((tag) {
                              return GestureDetector(
                                onTap: () {
                                  // Show entries with this specific tag
                                  _showEntriesWithTag(context, tag);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        tag,
                                        style: TextStyle(
                                          color: colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 14,
                                        color: colorScheme.onPrimaryContainer
                                            .withOpacity(0.7),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
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

  void _showAllMedia(BuildContext context, List<AssetEntity> mediaItems) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(
              "Journal Gallery",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            centerTitle: false,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          body: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: mediaItems.length,
            itemBuilder: (context, index) {
              final asset = mediaItems[index];
              return GestureDetector(
                onTap: () => _showFullScreenImage(
                  context,
                  asset,
                  index,
                  mediaItems,
                ),
                child: Hero(
                  tag: 'journal_media_${_currentEntry.id}_$index',
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
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _confirmDeleteEntry(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Store entry data for potential undo
    final entryData = {
      'id': _currentEntry.id,
      'title': _currentEntry.title,
      'content': _currentEntry.content,
      'date': _currentEntry.date,
      'mediaIds': _currentEntry.mediaIds,
      'mood': _currentEntry.mood,
      'tags': _currentEntry.tags,
      'lastEdited': _currentEntry.lastEdited,
    };

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
            onPressed: () async {
              final journalProvider = context.read<JournalProvider>();
              final success =
                  await journalProvider.deleteEntry(_currentEntry.id);

              if (success && mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to journal list

                // Show snackbar with undo option
                SnackbarUtils.showJournalEntryDeleted(
                  context,
                  title: _currentEntry.title,
                  onUndo: () async {
                    // Restore the entry
                    final restoredEntry = JournalEntry(
                      id: entryData['id'] as String,
                      title: entryData['title'] as String,
                      content: entryData['content'] as String,
                      date: entryData['date'] as DateTime,
                      mediaIds:
                          List<String>.from(entryData['mediaIds'] as List),
                      mood: entryData['mood'] as String?,
                      tags: List<String>.from(entryData['tags'] as List),
                      lastEdited: entryData['lastEdited'] as DateTime,
                    );

                    await journalProvider.addEntry(restoredEntry);
                  },
                );
              } else if (mounted) {
                Navigator.pop(context); // Close dialog
                SnackbarUtils.showError(
                    context, 'Failed to delete journal entry');
              }
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
          initialId: _currentEntry.id,
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

  void _showSimilarEntries(BuildContext context) {
    final journalProvider = context.read<JournalProvider>();
    final similarEntries = journalProvider.entries
        .where((entry) =>
            entry.id != _currentEntry.id &&
            entry.tags.any((tag) => _currentEntry.tags.contains(tag)))
        .toList();

    if (similarEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No similar entries found')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
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
                    'Similar Entries',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: similarEntries.length,
                itemBuilder: (context, index) {
                  final entry = similarEntries[index];
                  return ListTile(
                    title: Text(entry.title),
                    subtitle: Text(
                      DateFormat('MMMM d, yyyy').format(entry.date),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              JournalDetailScreen(entry: entry),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEntriesWithTag(BuildContext context, String tag) {
    final journalProvider = context.read<JournalProvider>();
    final entriesWithTag = journalProvider.entries
        .where((entry) => entry.tags.contains(tag))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
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
                    'Entries with #$tag',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: entriesWithTag.length,
                itemBuilder: (context, index) {
                  final entry = entriesWithTag[index];
                  return ListTile(
                    title: Text(entry.title),
                    subtitle: Text(
                      DateFormat('MMMM d, yyyy').format(entry.date),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              JournalDetailScreen(entry: entry),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.book_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _translatedTitle ?? _currentEntry.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_currentLanguage != null)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_currentLanguage != null)
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            _getLanguageFlag(_currentLanguage!),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          CustomMarkdown(
            data: _translatedContent ?? _currentEntry.content,
            textColor: theme.colorScheme.onSurface,
            headingColor: theme.colorScheme.primary,
            fontSize: 16,
            headingFontSize: 20,
            lineSpacing: 1.7,
            paragraphSpacing: 16,
          ),
        ],
      ),
    );
  }

  String _getLanguageFlag(String language) {
    switch (language.toLowerCase()) {
      case 'arabic':
        return '🇸🇦';
      case 'bengali':
        return '🇧🇩';
      case 'chinese (simplified)':
        return '🇨🇳';
      case 'czech':
        return '🇨🇿';
      case 'danish':
        return '🇩🇰';
      case 'dutch':
        return '🇳🇱';
      case 'finnish':
        return '🇫🇮';
      case 'french':
        return '🇫🇷';
      case 'german':
        return '🇩🇪';
      case 'greek':
        return '🇬🇷';
      case 'hebrew':
        return '🇮🇱';
      case 'hindi':
        return '🇮🇳';
      case 'hungarian':
        return '🇭🇺';
      case 'indonesian':
        return '🇮🇩';
      case 'italian':
        return '🇮🇹';
      case 'japanese':
        return '🇯🇵';
      case 'korean':
        return '🇰🇷';
      case 'malay':
        return '🇲🇾';
      case 'malayalam':
        return '🇮🇳';
      case 'marathi':
        return '🇮🇳';
      case 'norwegian':
        return '🇳🇴';
      case 'persian':
        return '🇮🇷';
      case 'polish':
        return '🇵🇱';
      case 'portuguese':
        return '🇵🇹';
      case 'romanian':
        return '🇷🇴';
      case 'russian':
        return '🇷🇺';
      case 'spanish':
        return '🇪🇸';
      case 'swedish':
        return '🇸🇪';
      case 'tamil':
        return '🇮🇳';
      case 'telugu':
        return '🇮🇳';
      case 'thai':
        return '🇹🇭';
      case 'turkish':
        return '🇹🇷';
      case 'ukrainian':
        return '🇺🇦';
      case 'urdu':
        return '🇵🇰';
      case 'vietnamese':
        return '🇻🇳';
      default:
        return '';
    }
  }
}
