import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'provider/ai_compilation_provider.dart';
import 'widgets/compilation_card.dart';
import 'widgets/compilation_form.dart';

class AICompilationPage extends StatelessWidget {
  const AICompilationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Compilations'),
      ),
      body: Consumer<AICompilationProvider>(
        builder: (context, aiProvider, child) {
          if (aiProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (aiProvider.compilations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No compilations yet',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showCreateCompilationDialog(context),
                    child: const Text('Create Compilation'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: aiProvider.compilations.length,
            itemBuilder: (context, index) {
              final compilation = aiProvider.compilations[index];
              return CompilationCard(
                compilation: compilation,
                onDelete: () => _deleteCompilation(context, compilation.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateCompilationDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateCompilationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CompilationForm(
        onSave: (title, theme, mediaPaths) {
          context.read<AICompilationProvider>().generateCompilation(
                title: title,
                theme: theme,
                mediaPaths: mediaPaths,
              );
          Navigator.pop(context);
        },
      ),
    );
  }

  void _deleteCompilation(BuildContext context, String id) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Compilation'),
        content:
            const Text('Are you sure you want to delete this compilation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AICompilationProvider>().deleteCompilation(id);
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
}
