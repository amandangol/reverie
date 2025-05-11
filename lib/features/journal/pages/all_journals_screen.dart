import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/journal_provider.dart';
import '../models/journal_entry.dart';
import 'journal_detail_screen.dart';
import 'package:reverie/theme/app_theme.dart';
import '../widgets/journal_card.dart';
import '../widgets/journal_shimmer.dart';

class AllJournalsScreen extends StatefulWidget {
  const AllJournalsScreen({super.key});

  @override
  State<AllJournalsScreen> createState() => _AllJournalsScreenState();
}

class _AllJournalsScreenState extends State<AllJournalsScreen> {
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
              Icons.sort_rounded,
              color: colorScheme.primary,
            ),
            onPressed: _showSortMenu,
            tooltip: 'Sort entries',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<JournalProvider>(
        builder: (context, journalProvider, child) {
          if (journalProvider.isLoading) {
            return const JournalShimmer();
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
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return JournalCard(
                entry: entry,
                onTap: () => _navigateToJournalDetail(entry),
              );
            },
          );
        },
      ),
    );
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
