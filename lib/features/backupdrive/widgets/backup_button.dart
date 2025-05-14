import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class BackupButton extends StatelessWidget {
  final Set<AssetPathEntity> selectedAlbums;
  final bool isBackingUp;
  final Future<void> Function() onBackupPressed;

  const BackupButton({
    super.key,
    required this.selectedAlbums,
    required this.isBackingUp,
    required this.onBackupPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            child: ElevatedButton.icon(
              onPressed: (selectedAlbums.isEmpty || isBackingUp)
                  ? null
                  : () async {
                      try {
                        await onBackupPressed();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.white),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(e.toString())),
                                ],
                              ),
                              backgroundColor: Colors.red.shade700,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              margin: const EdgeInsets.all(12),
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        }
                      }
                    },
              icon: Icon(
                isBackingUp
                    ? Icons.hourglass_empty_rounded
                    : Icons.backup_rounded,
                size: 20,
              ),
              label: Text(
                selectedAlbums.isEmpty
                    ? 'Select albums to backup'
                    : isBackingUp
                        ? 'Backing up...'
                        : 'Backup ${selectedAlbums.length} ${selectedAlbums.length == 1 ? 'album' : 'albums'}',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: colorScheme.surface,
                disabledForegroundColor: colorScheme.onSurfaceVariant,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
