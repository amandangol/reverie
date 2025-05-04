import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:provider/provider.dart';
import 'package:reverie/utils/media_utils.dart';
import 'package:shimmer/shimmer.dart';
import 'package:photo_manager/photo_manager.dart';
import '../journal_detail_screen.dart';
import '../providers/journal_provider.dart';
import '../models/journal_entry.dart';
import '../widgets/journal_entry_form.dart';
import '../../../utils/snackbar_utils.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:reverie/theme/app_theme.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showFab = true;
  Map<String, Widget> _entryWidgetCache = {};
  int _gridCrossAxisCount = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final journalProvider =
          Provider.of<JournalProvider>(context, listen: false);
      if (!journalProvider.isInitialized) {
        journalProvider.loadEntries();
      }
    });

    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_showFab) {
        setState(() {
          _showFab = false;
        });
      }
    }
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_showFab) {
        setState(() {
          _showFab = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _entryWidgetCache.clear();
    super.dispose();
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Journaling Tips',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTipItem(
                'Write Regularly',
                'Try to write in your journal daily. Even a few sentences can help you track your thoughts and feelings.',
                Icons.calendar_today_rounded,
              ),
              const SizedBox(height: 16),
              _buildTipItem(
                'Be Honest',
                'Your journal is a safe space. Write authentically about your feelings and experiences.',
                Icons.psychology_rounded,
              ),
              const SizedBox(height: 16),
              _buildTipItem(
                'Add Photos',
                'Enhance your entries with photos to capture moments and memories visually.',
                Icons.photo_library_rounded,
              ),
              const SizedBox(height: 16),
              _buildTipItem(
                'Use Tags',
                'Organize your entries with tags to easily find and group related content.',
                Icons.label_rounded,
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Got it',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    return Scaffold(
      extendBody: true,
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Reverie',
          style: journalTextTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.help_outline_rounded,
              color: colorScheme.primary,
            ),
            onPressed: _showHelpDialog,
            tooltip: 'Journaling Tips',
          ),
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
            return _buildShimmerLoading(theme);
          }
          if (journalProvider.entries.isEmpty) {
            return _buildEmptyState(journalProvider, theme);
          }
          return Stack(
            children: [
              // Background design
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colorScheme.surface,
                        colorScheme.background,
                      ],
                      stops: const [0.0, 0.3],
                    ),
                  ),
                ),
              ),

              // Main content
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: _buildHeader(journalProvider, theme),
                    ),
                  ),

                  // Stats section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: _buildJournalStats(journalProvider, theme),
                    ),
                  ),

                  // Recent entries section header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Your Entries',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onBackground,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              // Future implementation for filtering/sorting
                            },
                            icon: Icon(
                              Icons.sort_rounded,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            label: Text(
                              'Sort',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Grid of journal entries
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: _buildGridView(journalProvider, theme),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      floatingActionButton: _showFab
          ? FloatingActionButton.extended(
              heroTag: "journalFab",
              onPressed: () => _navigateToJournalEntryForm(context),
              label: const Text('New Entry'),
              icon: const Icon(Icons.edit_note_rounded),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 4,
            )
          : null,
    );
  }

  Widget _buildShimmerLoading(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surface,
      highlightColor: theme.colorScheme.surface.withOpacity(0.5),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header shimmer
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 200,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats card shimmer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Section title shimmer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 120,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Grid shimmer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _gridCrossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: _gridCrossAxisCount == 2 ? 0.85 : 0.75,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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

  Widget _buildEmptyState(JournalProvider journalProvider, ThemeData theme) {
    final journalTextTheme = AppTheme.journalTextTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your Journal is Empty',
            style: journalTextTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Start documenting your thoughts, feelings, and experiences. Your journal is a safe space to reflect and grow.',
              textAlign: TextAlign.center,
              style: journalTextTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _navigateToJournalEntryForm(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create First Entry'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 2,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _showHelpDialog,
            icon: Icon(
              Icons.help_outline_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            label: Text(
              'Learn more about journaling',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalStats(JournalProvider journalProvider, ThemeData theme) {
    final totalEntries = journalProvider.entries.length;

    // Calculate current streak
    int currentStreak = 0;
    int maxStreak = 0;
    int tempStreak = 0;

    if (journalProvider.entries.isNotEmpty) {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      // Sort entries by date in descending order
      final sortedEntries = List<JournalEntry>.from(journalProvider.entries)
        ..sort((a, b) => b.date.compareTo(a.date));

      // Calculate current streak
      DateTime currentDate = today;
      for (var entry in sortedEntries) {
        if (entry.date.year == currentDate.year &&
            entry.date.month == currentDate.month &&
            entry.date.day == currentDate.day) {
          // Entry exists for current date
          currentStreak++;
          currentDate = currentDate.subtract(const Duration(days: 1));
        } else if (entry.date.isBefore(currentDate)) {
          currentDate = entry.date;
          currentStreak++;
        } else {
          break;
        }
      }

      // Calculate max streak
      DateTime? lastEntryDate;
      for (var entry in sortedEntries) {
        if (lastEntryDate == null) {
          lastEntryDate = entry.date;
          tempStreak = 1;
          maxStreak = 1;
        } else {
          final difference = lastEntryDate.difference(entry.date).inDays;
          if (difference == 1) {
            tempStreak++;
            maxStreak = tempStreak > maxStreak ? tempStreak : maxStreak;
          } else {
            tempStreak = 1;
          }
          lastEntryDate = entry.date;
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                _buildStatItem(
                  theme,
                  totalEntries.toString(),
                  'Total Entries',
                  Icons.auto_stories_rounded,
                  colorOne: theme.colorScheme.primary,
                  colorTwo: theme.colorScheme.primaryContainer,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  theme,
                  currentStreak.toString(),
                  'Current Streak',
                  Icons.local_fire_department_rounded,
                  colorOne: Colors.orange,
                  colorTwo: Colors.orange.withOpacity(0.2),
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  theme,
                  maxStreak.toString(),
                  'Best Streak',
                  Icons.emoji_events_rounded,
                  colorOne: Colors.amber,
                  colorTwo: Colors.amber.withOpacity(0.2),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: currentStreak > 0
                        ? Colors.orange
                        : theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      currentStreak > 0
                          ? 'You\'re on a $currentStreak day streak! Keep it up!'
                          : 'Start your journaling streak today!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      ThemeData theme, String value, String label, IconData icon,
      {required Color colorOne, required Color colorTwo}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorTwo.withOpacity(0.2),
              colorTwo.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorOne.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: colorOne,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorOne,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(JournalProvider journalProvider, ThemeData theme) {
    final journalTextTheme = AppTheme.journalTextTheme;
    String greeting = _getGreeting();
    final entries = journalProvider.entries;
    final latestEntry = entries.isNotEmpty ? entries[0] : null;
    final lastEntryDate = latestEntry != null
        ? _formatTimeAgo(latestEntry.date)
        : 'No entries yet';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              greeting,
              style: journalTextTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              lastEntryDate,
              style: journalTextTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Your Journal',
          style: journalTextTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onBackground,
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _formatTimeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);

    if (difference.inDays > 7) {
      return 'Last entry: ${DateFormat('MMM d').format(date)}';
    } else if (difference.inDays > 1) {
      return 'Last entry: ${difference.inDays} days ago';
    } else if (difference.inDays == 1) {
      return 'Last entry: Yesterday';
    } else if (difference.inHours >= 1) {
      return 'Last entry: ${difference.inHours} hours ago';
    } else if (difference.inMinutes >= 1) {
      return 'Last entry: ${difference.inMinutes} minutes ago';
    } else {
      return 'Last entry: Just now';
    }
  }

  Widget _buildGridView(JournalProvider journalProvider, ThemeData theme) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridCrossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: _gridCrossAxisCount == 2 ? 0.85 : 0.75,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entry = journalProvider.entries[index];
          return _buildGridCard(entry, theme, index);
        },
        childCount: journalProvider.entries.length,
      ),
    );
  }

  Widget _buildGridCard(JournalEntry entry, ThemeData theme, int index) {
    if (_entryWidgetCache.containsKey(entry.id)) {
      return _entryWidgetCache[entry.id]!;
    }

    final card = Hero(
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => _navigateToJournalDetail(entry),
              splashColor: theme.colorScheme.primary.withOpacity(0.1),
              highlightColor: theme.colorScheme.primary.withOpacity(0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image section with overlay
                  Expanded(
                    flex: _gridCrossAxisCount == 2 ? 3 : 2,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildEntryImage(entry,
                            borderRadius: BorderRadius.zero),
                        // Gradient overlay
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
                        // Date chip
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 10,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  _formatDateFancy(entry.date),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Mood chip
                        if (entry.mood != null && entry.mood!.isNotEmpty)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    MediaUtils.getMoodIcon(entry.mood!),
                                    size: 10,
                                    color: _getMoodColor(entry.mood!),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    entry.mood!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Content section
                  Expanded(
                    flex: _gridCrossAxisCount == 2 ? 2 : 1,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Expanded(
                            child: Text(
                              entry.content,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                                height: 1.2,
                                fontSize: 11,
                              ),
                              maxLines: _gridCrossAxisCount == 2 ? 3 : 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (entry.tags.isNotEmpty) const SizedBox(height: 4),
                          _buildTagsRow(entry, theme),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    _entryWidgetCache[entry.id] = card;
    return card;
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

  String _formatDateFancy(DateTime date) {
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

  Widget _buildEntryImage(JournalEntry entry,
      {required BorderRadius borderRadius}) {
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
          borderRadius: borderRadius,
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

    return FutureBuilder<AssetEntity?>(
      future: AssetEntity.fromId(entry.mediaIds.first),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: borderRadius,
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
            child: ClipRRect(
              borderRadius: borderRadius,
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
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
              ),
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

  void _navigateToJournalDetail(JournalEntry entry) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            JournalDetailScreen(
          entry: entry,
        ),
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
      // Refresh widget cache
      setState(() {
        _entryWidgetCache.clear();
      });
    });
  }

  void _navigateToJournalEntryForm(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            JournalEntryForm(
          onSave: (title, content, mediaIds, mood, tags) async {
            final journalProvider = context.read<JournalProvider>();
            final newEntry = JournalEntry(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: title,
              content: content,
              date: DateTime.now(),
              mediaIds: mediaIds,
              mood: mood,
              tags: tags,
            );

            final success = await journalProvider.addEntry(newEntry);
            if (success) {
              if (!mounted) return;
              SnackbarUtils.showSuccess(
                context,
                'Journal entry added successfully',
              );
              // Clear cache on new entry
              setState(() {
                _entryWidgetCache.clear();
              });
            } else {
              if (!mounted) return;
              SnackbarUtils.showError(context, 'Failed to add journal entry');
            }
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 0.1);
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
    );
  }
}
