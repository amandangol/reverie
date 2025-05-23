import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../provider/backup_provider.dart';
import '../../../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleDriveSection extends StatelessWidget {
  const GoogleDriveSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    return Card(
      color: colorScheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4285F4).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SvgPicture.asset(
                    'assets/svg/google_drive.svg',
                    width: 18,
                    height: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Google Drive',
                        style: journalTextTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Connect to save your memories securely',
                        style: journalTextTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Selector<BackupProvider, bool>(
              selector: (_, provider) => provider.isSignedIn,
              builder: (context, isSignedIn, _) {
                return Column(
                  children: [
                    if (isSignedIn) ...[
                      Selector<BackupProvider, Map<String, String?>>(
                        selector: (_, provider) => {
                          'email': provider.userEmail,
                          'name': provider.userName,
                          'photoUrl': provider.userPhotoUrl,
                        },
                        builder: (context, userInfo, _) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.surfaceVariant.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    if (userInfo['photoUrl'] != null &&
                                        userInfo['photoUrl']!.isNotEmpty)
                                      ClipOval(
                                        child: Image.network(
                                          userInfo['photoUrl']!,
                                          width: 32,
                                          height: 32,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return const CupertinoActivityIndicator();
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return CircleAvatar(
                                                radius: 16,
                                                backgroundColor:
                                                    const Color(0xFF4285F4),
                                                child: Text(
                                                  userInfo['name']?[0]
                                                          .toUpperCase() ??
                                                      userInfo['email']?[0]
                                                          .toUpperCase() ??
                                                      'G',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ));
                                          },
                                        ),
                                      )
                                    else
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor:
                                            const Color(0xFF4285F4),
                                        child: Text(
                                          userInfo['name']?[0].toUpperCase() ??
                                              userInfo['email']?[0]
                                                  .toUpperCase() ??
                                              'G',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userInfo['name'] ??
                                                userInfo['email'] ??
                                                'Google Account',
                                            style: journalTextTheme.bodySmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (userInfo['email'] != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              userInfo['email']!,
                                              style: journalTextTheme.bodySmall
                                                  ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Color(0xFF34A853),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Connected',
                                                style: journalTextTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      const Color(0xFF34A853),
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                    GoogleDriveButton(
                      isSignedIn: isSignedIn,
                      onPressed: () async {
                        final provider = context.read<BackupProvider>();
                        if (isSignedIn) {
                          await provider.signOutFromGoogleDrive();
                        } else {
                          await provider.signInToGoogleDrive();
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class GoogleDriveButton extends StatelessWidget {
  final bool isSignedIn;
  final Future<void> Function() onPressed;

  const GoogleDriveButton({
    super.key,
    required this.isSignedIn,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          try {
            await onPressed();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
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
        style: ElevatedButton.styleFrom(
          backgroundColor: isSignedIn
              ? Colors.white
              : const Color(0xFF4285F4).withOpacity(0.2),
          foregroundColor: isSignedIn ? const Color(0xFF4285F4) : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: isSignedIn
                ? const BorderSide(color: Color(0xFF4285F4), width: 1.5)
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isSignedIn) ...[
              SvgPicture.asset(
                'assets/svg/google-icon.svg',
                width: 18,
                height: 18,
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              isSignedIn ? Icons.logout_rounded : Icons.login_rounded,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              isSignedIn ? 'Sign Out' : 'Sign in with Google',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
