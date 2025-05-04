import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reverie/features/journal/providers/journal_provider.dart';
import '../gallery/provider/media_provider.dart';
import '../ai_compilation/provider/ai_compilation_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Data Management',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Clear Media Cache'),
            subtitle: const Text('Remove temporary media files'),
            onTap: () => _clearMediaCache(context),
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('Clear Journal Data'),
            subtitle: const Text('Delete all journal entries'),
            onTap: () => _clearJournalData(context),
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text('Clear AI Compilations'),
            subtitle: const Text('Delete all AI-generated compilations'),
            onTap: () => _clearAICompilations(context),
          ),
          const Divider(),
          Text(
            'Permissions',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text('Media Access'),
            subtitle: const Text('Manage photo and video access'),
            onTap: () => _requestMediaPermission(context),
          ),
        ],
      ),
    );
  }

  void _clearMediaCache(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Media Cache'),
        content: const Text('Are you sure you want to clear the media cache?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement media cache clearing
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _clearJournalData(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Journal Data'),
        content:
            const Text('Are you sure you want to delete all journal entries?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // context.read<JournalProvider>().clearAll();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _clearAICompilations(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear AI Compilations'),
        content:
            const Text('Are you sure you want to delete all AI compilations?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AICompilationProvider>().clearAll();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _requestMediaPermission(BuildContext context) {
    context.read<MediaProvider>().requestPermission();
  }
}
