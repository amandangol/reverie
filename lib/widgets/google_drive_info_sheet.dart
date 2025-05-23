import 'package:flutter/material.dart';
import '../features/backupdrive/pages/backup_screen.dart';
import '../features/backupdrive/provider/backup_provider.dart';

class GoogleDriveInfoSheet extends StatelessWidget {
  final BackupProvider backupProvider;

  const GoogleDriveInfoSheet({
    super.key,
    required this.backupProvider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (backupProvider.isSignedIn) ...[
            if (backupProvider.userPhotoUrl != null)
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(backupProvider.userPhotoUrl!),
              )
            else
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF4285F4),
                child: Text(
                  backupProvider.userName?[0].toUpperCase() ??
                      backupProvider.userEmail?[0].toUpperCase() ??
                      'G',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              backupProvider.userName ??
                  backupProvider.userEmail ??
                  'Google Account',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (backupProvider.userEmail != null) ...[
              const SizedBox(height: 4),
              Text(
                backupProvider.userEmail!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF34A853),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Connected to Google Drive',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF34A853),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BackupScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.backup_rounded),
                label: const Text('Manage Backup'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF34A853),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await backupProvider.signOutFromGoogleDrive();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign Out'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF4285F4),
                  side: const BorderSide(color: Color(0xFF4285F4), width: 1.5),
                ),
              ),
            ),
          ] else ...[
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Color(0xFF4285F4),
            ),
            const SizedBox(height: 16),
            Text(
              'Not Connected to Google Drive',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect your Google account to backup your memories',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await backupProvider.signInToGoogleDrive();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.red.shade700,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.login_rounded),
                label: const Text('Sign in with Google'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4285F4),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
