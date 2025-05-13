import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reverie/theme/app_theme.dart';
import 'package:reverie/features/onboarding/provider/onboarding_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to Reverie',
      description: 'Your personal space for memories, reflection, and growth.',
      imagePath: 'assets/icon/icon.png',
      color: Colors.amber,
      icon: Icons.auto_stories_rounded,
    ),
    OnboardingPage(
      title: 'Gallery & Media',
      description:
          'Browse and organize your photos and videos in a beautiful gallery view.',
      icon: Icons.photo_library_rounded,
      color: Colors.blue,
    ),
    OnboardingPage(
      title: 'Journal & Memories',
      description:
          'Write journal entries, add media, and track your emotional journey.',
      icon: Icons.auto_stories_rounded,
      color: Colors.purple,
    ),
    OnboardingPage(
      title: 'Flashbacks & Calendar',
      description:
          'Relive past memories and view your journal entries organized by date.',
      icon: Icons.history_rounded,
      color: Colors.orange,
    ),
    OnboardingPage(
      title: 'Favorites & Videos',
      description:
          'Keep your favorite memories close and enjoy your video collection.',
      icon: Icons.favorite_rounded,
      color: Colors.red,
    ),
    OnboardingPage(
      title: 'AI-Powered Features',
      description:
          'Let our AI assistant help you organize memories and generate content.',
      icon: Icons.auto_awesome_rounded,
      color: Colors.green,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _completeOnboarding() async {
    final onboardingProvider =
        Provider.of<OnboardingProvider>(context, listen: false);
    await onboardingProvider.completeOnboarding();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final journalTextTheme = AppTheme.journalTextTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _buildPage(page, theme);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? colorScheme.primary
                              : colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _currentPage == _pages.length - 1
                        ? _completeOnboarding
                        : () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? 'Get Started'
                          : 'Next',
                      style: journalTextTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_currentPage < _pages.length - 1) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (page.imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Image.asset(
                page.imagePath!,
                height: 200,
                width: 200,
                fit: BoxFit.contain,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: page.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                page.icon,
                size: 80,
                color: page.color,
              ),
            ),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String? imagePath;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.imagePath,
  });
}
