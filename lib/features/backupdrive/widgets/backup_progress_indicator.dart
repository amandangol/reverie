import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/backup_provider.dart';
import '../../../theme/app_theme.dart';

class BackupProgressIndicator extends StatelessWidget {
  final double progress;
  final bool isJournalBackup;

  const BackupProgressIndicator({
    super.key,
    required this.progress,
    this.isJournalBackup = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;
    final primaryColor =
        isJournalBackup ? const Color(0xFF4285F4) : const Color(0xFF34A853);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isJournalBackup
                      ? 'Backing up your journals...'
                      : 'Backing up your memories...',
                  style: journalTextTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  context.read<BackupProvider>().cancelBackup();
                },
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Cancel'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}% complete',
                style: journalTextTheme.bodyMedium?.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Please wait...',
                style: journalTextTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
