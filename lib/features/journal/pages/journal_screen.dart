import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'journal_detail_screen.dart';
import '../providers/journal_provider.dart';
import '../models/journal_entry.dart';
import '../widgets/journal_entry_form.dart';
import '../../../utils/snackbar_utils.dart';
import 'package:intl/intl.dart';
import 'package:reverie/theme/app_theme.dart';
import '../widgets/journal_card.dart';
import '../widgets/journal_shimmer.dart';

import 'all_journals_screen.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showFab = true;
  Map<String, Widget> _entryWidgetCache = {};
  static const int _gridCrossAxisCount = 2;

  @override
  void initState() {
    super.initState();
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
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<JournalProvider>(
        builder: (context, journalProvider, child) {
          if (journalProvider.isLoading) {
            return _buildShimmerLoading(theme);
          }

          if (journalProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load journal entries',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    journalProvider.error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => journalProvider.initialize(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            );
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
            // Header section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 120,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 80,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 160,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),

            // Stats card
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildShimmerStatItem(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildShimmerStatItem(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildShimmerStatItem(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Section title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
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
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
            ),

            // Grid
            const JournalShimmer(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerStatItem() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 60,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
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
    final entriesThisMonth = journalProvider.getEntriesThisMonth();

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
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                theme,
                totalEntries.toString(),
                'Total Entries',
                Icons.auto_stories_rounded,
                colorOne: theme.colorScheme.primary,
                colorTwo: theme.colorScheme.primaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatItem(
                theme,
                entriesThisMonth.toString(),
                'This Month',
                Icons.calendar_month_rounded,
                colorOne: Colors.blue,
                colorTwo: Colors.blue.withOpacity(0.2),
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
    return Container(
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
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              lastEntryDate,
              style: journalTextTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
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
    final entries = journalProvider.entries;
    final displayEntries = entries.length > 4 ? entries.sublist(0, 4) : entries;
    final hasMoreEntries = entries.length > 4;

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridCrossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == displayEntries.length && hasMoreEntries) {
            return _buildShowAllButton(context, theme, entries.length);
          }
          final entry = displayEntries[index];
          return JournalCard(
            entry: entry,
            onTap: () => _navigateToJournalDetail(entry),
          );
        },
        childCount: displayEntries.length + (hasMoreEntries ? 1 : 0),
      ),
    );
  }

  Widget _buildShowAllButton(
      BuildContext context, ThemeData theme, int totalEntries) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToAllJournals(context),
        borderRadius: BorderRadius.circular(16),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_stories_rounded,
                size: 32,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'View All',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalEntries entries',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAllJournals(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AllJournalsScreen(),
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
      // Refresh entries when returning from all journals screen
      final journalProvider =
          Provider.of<JournalProvider>(context, listen: false);
      journalProvider.loadEntries();
      // Refresh widget cache
      setState(() {
        _entryWidgetCache.clear();
      });
    });
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
          onSave: (title, content, mediaIds, mood, tags,
              {DateTime? lastEdited}) async {
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
