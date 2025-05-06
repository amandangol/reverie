import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/gallery/pages/album_page.dart';
import '../features/gallery/provider/media_provider.dart';
import '../features/journal/pages/journal_screen.dart';

class SnackbarUtils {
  static void showSuccess(BuildContext context, String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: theme.colorScheme.onPrimary),
            const SizedBox(width: 12),
            Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showInfo(BuildContext context, String message,
      {bool isSuccess = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: theme.colorScheme.onPrimary),
            const SizedBox(width: 12),
            Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: isSuccess ? theme.colorScheme.primary : Colors.grey,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showWithAction(
    BuildContext context, {
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    IconData? icon,
    Color? backgroundColor,
    bool isError = false,
  }) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: theme.colorScheme.onPrimary),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ??
            (isError ? Colors.red.shade700 : theme.colorScheme.primary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: actionLabel,
          textColor: theme.colorScheme.onPrimary,
          onPressed: onAction,
        ),
      ),
    );
  }

  static void showJournalEntryCreated(
    BuildContext context, {
    required String title,
    required VoidCallback onView,
  }) {
    showWithAction(
      context,
      message: 'Journal entry "$title" created successfully',
      actionLabel: 'View',
      onAction: () {
        // Navigate to the journal screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const JournalScreen(),
          ),
        );
      },
      icon: Icons.book,
      isError: false,
    );
  }

  static void showMediaAddedToFavorites(
    BuildContext context, {
    required int count,
    required VoidCallback onView,
  }) {
    showWithAction(
      context,
      message:
          count == 1 ? 'Added to favorites' : '$count items added to favorites',
      actionLabel: 'View Favorites',
      onAction: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlbumPage(
              album: context.read<MediaProvider>().albums.first,
              isGridView: true,
              gridCrossAxisCount: 3,
              isFavoritesAlbum: true,
            ),
          ),
        );
      },
      icon: Icons.favorite,
      isError: false,
    );
  }

  static void showMediaRemovedFromFavorites(
    BuildContext context, {
    required int count,
  }) {
    showSuccess(
      context,
      count == 1
          ? 'Removed from favorites'
          : '$count items removed from favorites',
    );
  }

  static void showMediaDeleted(
    BuildContext context, {
    required int count,
  }) {
    showInfo(
      context,
      '$count item${count == 1 ? '' : 's'} deleted successfully',
      isSuccess: true,
    );
  }
}
