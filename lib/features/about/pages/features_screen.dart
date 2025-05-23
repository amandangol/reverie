import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../settings/widgets/setting_widgets.dart';

class FeaturesScreen extends StatelessWidget {
  const FeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Features',
        showMenu: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Container(
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppLogo(),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      '~TAP ME~',
                      style: journalTextTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w100,
                        color: colorScheme.onBackground,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Discover Reverie',
                    style: journalTextTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your personal digital memory keeper, helping you preserve and relive your precious moments.',
                    style: journalTextTheme.bodyLarge?.copyWith(
                      color: colorScheme.onBackground.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Features Grid
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFeatureSection(
                    context,
                    'Gallery & Media',
                    Icons.photo_library_rounded,
                    const Color(0xFF4285F4),
                    [
                      'Beautiful gallery view of photos and videos',
                      'Smart organization with albums',
                      'Video library for easy access',
                      'Favorites collection',
                      'Built-in camera for photos and videos',
                      'Google Drive integration',
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildFeatureSection(
                    context,
                    'Journal & Memories',
                    Icons.auto_stories_rounded,
                    const Color(0xFF34A853),
                    [
                      'Rich journal entries with media',
                      'Mood tracking and emotional journey',
                      'Calendar view for date-based browsing',
                      'Tags and categories organization',
                      'AI-powered content generation',
                      'Multi-language support ',
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildFeatureSection(
                    context,
                    'Flashbacks & Calendar',
                    Icons.history_rounded,
                    const Color(0xFFFBBC05),
                    [
                      'Relive past memories',
                      'Time-based organization',
                      'Easy timeline navigation',
                      'Memory highlights',
                      'Anniversary reminders',
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildFeatureSection(
                    context,
                    'Recap & Memories',
                    Icons.auto_awesome_motion_rounded,
                    const Color(0xFF00BCD4),
                    [
                      'Monthly memory recaps',
                      'Beautiful timeline view',
                      'Smart date-based grouping',
                      'Quick month navigation',
                      'Memory count tracking',
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildFeatureSection(
                    context,
                    'AI-Powered Features',
                    Icons.auto_awesome_rounded,
                    const Color(0xFFEA4335),
                    [
                      'Smart image analysis',
                      'AI-assisted journal writing',
                      'Object labeling for images',
                      'Intelligent organization',
                      'Personalized suggestions',
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildFeatureSection(
                    context,
                    'Backup & Sync',
                    Icons.backup_rounded,
                    const Color(0xFF9C27B0),
                    [
                      'Secure Google Drive integration',
                      'Selective album backup',
                      'Progress tracking',
                      'Easy restoration process',
                      'Account-specific management',
                    ],
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  Text(
                    'Why Choose Reverie?',
                    style: journalTextTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildWhyChooseItem(
                    context,
                    'Beautiful Design',
                    'Modern, intuitive interface that makes memory-keeping a joy',
                    Icons.brush_rounded,
                  ),
                  _buildWhyChooseItem(
                    context,
                    'Privacy-Focused',
                    'Your memories stay on your device with optional cloud backup',
                    Icons.security_rounded,
                  ),
                  _buildWhyChooseItem(
                    context,
                    'AI-Enhanced',
                    'Smart features that make organizing memories easier',
                    Icons.psychology_rounded,
                  ),
                  _buildWhyChooseItem(
                    context,
                    'Cross-Platform',
                    'Seamless experience on both iOS and Android',
                    Icons.devices_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureSection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<String> features,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: journalTextTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onBackground,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature,
                      style: journalTextTheme.bodyMedium?.copyWith(
                        color: colorScheme.onBackground.withOpacity(0.7),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildWhyChooseItem(
    BuildContext context,
    String title,
    String description,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 20,
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
                    color: colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: journalTextTheme.bodyMedium?.copyWith(
                    color: colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
