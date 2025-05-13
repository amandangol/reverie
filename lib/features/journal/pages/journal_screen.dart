import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'journal_detail_screen.dart';
import 'calendar_screen.dart';
import '../providers/journal_provider.dart';
import '../models/journal_entry.dart';
import '../widgets/journal_entry_form.dart';
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
                child: SingleChildScrollView(
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
                            'Journal Guide',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildTipSection(
                        'Creating Entries',
                        [
                          _buildTipItem(
                            'New Entry',
                            'Tap the "New Entry" button to start writing. Add a title, content, mood, and tags.',
                            Icons.edit_note_rounded,
                          ),
                          _buildTipItem(
                            'AI Assistant',
                            'Use the AI Assistant to generate content based on your mood, tags, and photos.',
                            Icons.auto_awesome_rounded,
                          ),
                          _buildTipItem(
                            'Media & Photos',
                            'Add photos and videos to your entries. You can select multiple items.',
                            Icons.photo_library_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildTipSection(
                        'Organizing Content',
                        [
                          _buildTipItem(
                            'Tags & Keywords',
                            'Use tags to organize entries. Try suggested keywords or create your own.',
                            Icons.label_rounded,
                          ),
                          _buildTipItem(
                            'Mood Tracking',
                            'Select your mood for each entry to track emotional patterns.',
                            Icons.mood_rounded,
                          ),
                          _buildTipItem(
                            'Calendar View',
                            'View your entries by date in the calendar. Tap any date to see entries.',
                            Icons.calendar_month_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildTipSection(
                        'Tracking Progress',
                        [
                          _buildTipItem(
                            'Streaks',
                            'Maintain your journaling streak by writing daily. View your current and best streaks.',
                            Icons.local_fire_department_rounded,
                          ),
                          _buildTipItem(
                            'Monthly Stats',
                            'Track your monthly progress and total entries in the insights section.',
                            Icons.insights_rounded,
                          ),
                          _buildTipItem(
                            'Entry History',
                            'View all your entries sorted by date, title, or mood.',
                            Icons.history_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildTipSection(
                        'Managing Entries',
                        [
                          _buildTipItem(
                            'Edit & Delete',
                            'Edit or delete entries anytime. Changes are saved automatically.',
                            Icons.edit_rounded,
                          ),
                          _buildTipItem(
                            'Share Entries',
                            'Share your entries with others, including photos and videos.',
                            Icons.share_rounded,
                          ),
                          _buildTipItem(
                            'Search & Filter',
                            'Find entries using tags, dates, or keywords.',
                            Icons.search_rounded,
                          ),
                        ],
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
            ));
  }

  Widget _buildTipSection(String title, List<Widget> tips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 16),
        ...tips,
      ],
    );
  }

  Widget _buildTipItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.3),
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
      ),
    );
  }

  void _showSortMenu() {
    final journalProvider = context.read<JournalProvider>();
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Sort By',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.calendar_today_rounded,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Date (Newest First)'),
              trailing: journalProvider.currentSort == SortOption.dateDesc
                  ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
                  : null,
              onTap: () {
                journalProvider.setSortOption(SortOption.dateDesc);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.calendar_today_rounded,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Date (Oldest First)'),
              trailing: journalProvider.currentSort == SortOption.dateAsc
                  ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
                  : null,
              onTap: () {
                journalProvider.setSortOption(SortOption.dateAsc);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.sort_by_alpha_rounded,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Title (A-Z)'),
              trailing: journalProvider.currentSort == SortOption.titleAsc
                  ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
                  : null,
              onTap: () {
                journalProvider.setSortOption(SortOption.titleAsc);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.sort_by_alpha_rounded,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Title (Z-A)'),
              trailing: journalProvider.currentSort == SortOption.titleDesc
                  ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
                  : null,
              onTap: () {
                journalProvider.setSortOption(SortOption.titleDesc);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.mood_rounded,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Mood (A-Z)'),
              trailing: journalProvider.currentSort == SortOption.moodAsc
                  ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
                  : null,
              onTap: () {
                journalProvider.setSortOption(SortOption.moodAsc);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.mood_rounded,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Mood (Z-A)'),
              trailing: journalProvider.currentSort == SortOption.moodDesc
                  ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
                  : null,
              onTap: () {
                journalProvider.setSortOption(SortOption.moodDesc);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarSection(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CalendarScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withOpacity(0.1),
                colorScheme.primary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Journal Calendar',
                          style: journalTextTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Visualize your journaling patterns',
                          style: journalTextTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      tooltip: 'Open full calendar',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CalendarScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Simple mini calendar preview
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final day =
                      DateTime.now().subtract(Duration(days: 6 - index));
                  final isToday = index == 6;
                  final hasEntry =
                      _hasEntryForDay(day); // You would implement this method

                  return Column(
                    children: [
                      Text(
                        DateFormat('E').format(day).substring(0, 1),
                        style: journalTextTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isToday
                              ? colorScheme.primary
                              : hasEntry
                                  ? colorScheme.primaryContainer
                                      .withOpacity(0.3)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: isToday
                              ? null
                              : Border.all(
                                  color: hasEntry
                                      ? colorScheme.primary.withOpacity(0.2)
                                      : colorScheme.onSurface.withOpacity(0.1),
                                  width: 1.5,
                                ),
                        ),
                        child: Center(
                          child: Text(
                            day.day.toString(),
                            style: journalTextTheme.bodyMedium?.copyWith(
                              color: isToday
                                  ? colorScheme.onPrimary
                                  : hasEntry
                                      ? colorScheme.primary
                                      : colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: isToday || hasEntry
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to check if a day has journal entries
  bool _hasEntryForDay(DateTime day) {
    // Implement this method based on your JournalProvider
    final provider = Provider.of<JournalProvider>(context, listen: false);
    return provider.getEntriesForDate(day).isNotEmpty;
  }

  Widget _buildHeader(JournalProvider journalProvider, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;
    String greeting = _getGreeting();

    // Get current date
    final now = DateTime.now();
    final dateString = DateFormat('EEEE, MMMM d').format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upper section with greeting and streak
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wb_sunny_rounded,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    greeting,
                    style: journalTextTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // const Spacer(),
            // if (latestEntry != null)
            //   Container(
            //     padding:
            //         const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            //     decoration: BoxDecoration(
            //       color: colorScheme.secondaryContainer.withOpacity(0.3),
            //       borderRadius: BorderRadius.circular(20),
            //     ),
            //     child: Row(
            //       mainAxisSize: MainAxisSize.min,
            //       children: [
            //         Icon(
            //           Icons.access_time_rounded,
            //           size: 14,
            //           color: colorScheme.secondary,
            //         ),
            // const SizedBox(width: 4),
            // Text(
            //   lastEntryDate,
            //   style: journalTextTheme.labelSmall?.copyWith(
            //     color: colorScheme.secondary,
            //     fontWeight: FontWeight.w500,
            //   ),
            // ),
            //     ],
            //   ),
            // ),
          ],
        ),
        const SizedBox(height: 16),

        // Main header with title and date
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Journal',
                    style: journalTextTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onBackground,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dateString,
                    style: journalTextTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                // Navigate to profile or settings
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.asset(
                    'assets/icon/icon.png',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
            ),
          ],
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
      return '${difference.inDays} days ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildJournalStats(JournalProvider journalProvider, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;
    final totalEntries = journalProvider.entries.length;
    final entriesThisMonth = journalProvider.getEntriesThisMonth();
    final currentStreak = journalProvider.getCurrentStreak();
    final longestStreak = journalProvider.getLongestStreak();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Journal Insights',
                style: journalTextTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              IconButton(
                onPressed: () =>
                    _showDetailedStatsDialog(context, journalProvider),
                icon: Icon(
                  Icons.insights_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                tooltip: 'View detailed stats',
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            _showDetailedStatsDialog(context, journalProvider);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatIcon(
                context,
                totalEntries.toString(),
                'Entries',
                Icons.auto_stories_rounded,
                colorScheme.primary,
              ),
              _buildStatIcon(
                context,
                entriesThisMonth.toString(),
                'This Month',
                Icons.calendar_view_month_rounded,
                Colors.blue,
              ),
              _buildStatIcon(
                context,
                currentStreak.toString(),
                'Streak',
                Icons.local_fire_department_rounded,
                Colors.orange,
              ),
              _buildStatIcon(
                context,
                longestStreak.toString(),
                'Best',
                Icons.emoji_events_rounded,
                Colors.amber,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatIcon(BuildContext context, String value, String label,
      IconData icon, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
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
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  void _showDetailedStatsDialog(
      BuildContext context, JournalProvider journalProvider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    final totalEntries = journalProvider.entries.length;
    final entriesThisMonth = journalProvider.getEntriesThisMonth();
    final currentStreak = journalProvider.getCurrentStreak();
    final longestStreak = journalProvider.getLongestStreak();
    final averageEntryLength =
        journalProvider.getAverageEntryLength().toStringAsFixed(1);

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
                    Icons.insights_rounded,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Journal Insights',
                    style: journalTextTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailedStatItem(
                context,
                'Total Entries',
                totalEntries.toString(),
                'Total number of journal entries',
                Icons.auto_stories_rounded,
                colorScheme.primary,
              ),
              const SizedBox(height: 16),
              _buildDetailedStatItem(
                context,
                'Entries This Month',
                entriesThisMonth.toString(),
                'Number of entries in the current month',
                Icons.calendar_view_month_rounded,
                Colors.blue,
              ),
              const SizedBox(height: 16),
              _buildDetailedStatItem(
                context,
                'Current Streak',
                '$currentStreak days',
                'Consecutive days of journaling',
                Icons.local_fire_department_rounded,
                Colors.orange,
              ),
              const SizedBox(height: 16),
              _buildDetailedStatItem(
                context,
                'Longest Streak',
                '$longestStreak days',
                'Best consecutive days of journaling',
                Icons.emoji_events_rounded,
                Colors.amber,
              ),
              const SizedBox(height: 16),
              _buildDetailedStatItem(
                context,
                'Average Entry Length',
                '$averageEntryLength words',
                'Average number of words per entry',
                Icons.text_fields_rounded,
                Colors.green,
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: colorScheme.primary,
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

  Widget _buildDetailedStatItem(
    BuildContext context,
    String title,
    String value,
    String description,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: journalTextTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: journalTextTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: journalTextTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
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

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text(
          'Reverie',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 17,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.background,
        actions: [
          IconButton(
            icon: Icon(
              Icons.help_outline_rounded,
              color: colorScheme.primary,
            ),
            onPressed: _showHelpDialog,
            tooltip: 'Journaling Guide',
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
                        colorScheme.background,
                        colorScheme.surface,
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

                  // Calendar section
                  SliverToBoxAdapter(
                    child: _buildCalendarSection(theme),
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
                              color: colorScheme.onSurface,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _showSortMenu,
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
            // The entry creation is now handled entirely in the JournalEntryForm
            // We just need to refresh the entries list when returning
            if (mounted) {
              final journalProvider = context.read<JournalProvider>();
              await journalProvider.loadEntries();
              // Clear cache on new entry
              setState(() {
                _entryWidgetCache.clear();
              });
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
    ).then((_) {
      // Refresh entries when returning from form
      final journalProvider =
          Provider.of<JournalProvider>(context, listen: false);
      journalProvider.loadEntries();
    });
  }
}
