import 'package:flutter/material.dart';
import 'package:reverie/features/about/pages/features_screen.dart';
import 'package:reverie/features/gallery/pages/flashbacks/flashbacks_screen.dart';
import 'package:reverie/features/gallery/pages/recap/recap_screen.dart';
import 'package:reverie/features/gallery/pages/smart_search_screen.dart';
import 'package:reverie/features/quickaccess/pages/quickaccess_screen.dart';
import 'package:reverie/features/settings/pages/settings_page.dart';
import 'package:url_launcher/url_launcher.dart';

class AppDrawer extends StatelessWidget {
  final Function(Widget) onNavigation;

  const AppDrawer({
    super.key,
    required this.onNavigation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: Column(
        children: [
          // Drawer Header with Gallery Theme
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withOpacity(0.9),
                  colorScheme.onPrimary.withOpacity(0.7),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Image Grid Background Effect
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.2,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      itemCount: 16,
                      itemBuilder: (context, index) {
                        return Container(
                          color: index % 2 == 0
                              ? Colors.white.withOpacity(0.3)
                              : Colors.white.withOpacity(0.1),
                        );
                      },
                    ),
                  ),
                ),

                // App Logo and Title
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reverie',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                            shadows: [
                              Shadow(
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your Digital Memory Keeper',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontStyle: FontStyle.italic,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Floating polaroid frame effect
                Positioned(
                  top: 20,
                  right: 20,
                  child: Transform.rotate(
                    angle: 0.1,
                    child: Container(
                      width: 70,
                      height: 80,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(1),
                              child: Image.asset(
                                'assets/icon/icon.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Drawer Items - with improved styling
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Quick Access Item
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard_rounded,
                  title: 'Quick Glance',
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const QuickAccessScreen()),
                    );
                  },
                ),

                // Memories Item
                _buildDrawerItem(
                  context,
                  icon: Icons.history_rounded,
                  title: 'Memories',
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const FlashbacksScreen()),
                    );
                  },
                ),

                // Monthly Recap Item
                _buildDrawerItem(
                  context,
                  icon: Icons.calendar_month_rounded,
                  title: 'Monthly Recap',
                  badge: 'New',
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RecapScreen()),
                    );
                  },
                ),

                // Settings Item
                _buildDrawerItem(
                  context,
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsPage()),
                    );
                  },
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Divider(color: colorScheme.onSurface.withOpacity(0.2)),
                ),

                // Features Item
                _buildDrawerItem(
                  context,
                  icon: Icons.info_outline_rounded,
                  title: 'Features',
                  onTap: () => onNavigation(const FeaturesScreen()),
                ),

                // About Item
                _buildDrawerItem(
                  context,
                  icon: Icons.help_outline_rounded,
                  title: 'About',
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),
          ),

          // Footer with app version
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.5),
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Version 1.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                  ),
                  child: Text(
                    '2025',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                'assets/icon/icon.png',
                height: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Reverie',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.0',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Reverie is your personal digital memory keeper, helping you preserve and relive your precious moments through photos and journals.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(
                  context,
                  icon: Icons.history_edu_rounded,
                  onTap: () {
                    Navigator.pop(context);
                    launchUrl(
                      Uri.parse(
                          'https://github.com/amandangol/reverie/blob/main/README.md'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  tooltip: 'Documentation',
                ),
                const SizedBox(width: 24),
                _buildSocialButton(
                  context,
                  icon: Icons.code_rounded,
                  onTap: () {
                    Navigator.pop(context);
                    launchUrl(
                      Uri.parse('https://github.com/amandangol/reverie'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  tooltip: 'Source Code',
                ),
                const SizedBox(width: 24),
                _buildSocialButton(
                  context,
                  icon: Icons.bug_report_rounded,
                  onTap: () {
                    Navigator.pop(context);
                    launchUrl(
                      Uri.parse('https://github.com/amandangol/reverie/issues'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  tooltip: 'Report Issues',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(icon),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? badge,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          splashColor: colorScheme.primary.withOpacity(0.1),
          highlightColor: colorScheme.primary.withOpacity(0.05),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: colorScheme.surfaceVariant.withOpacity(0.5),
                  ),
                  child: Icon(
                    icon,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurface.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
