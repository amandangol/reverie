import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reverie/theme/app_theme.dart';
import 'package:reverie/features/onboarding/provider/onboarding_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Wait for both animation and onboarding status check
    Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      _checkOnboardingStatus(),
    ]).then((_) {
      if (!mounted) return;
      _navigateToNextScreen();
    });
  }

  Future<void> _checkOnboardingStatus() async {
    final onboardingProvider =
        Provider.of<OnboardingProvider>(context, listen: false);
    await onboardingProvider.loadOnboardingStatus();
  }

  void _navigateToNextScreen() {
    final onboardingProvider =
        Provider.of<OnboardingProvider>(context, listen: false);
    if (!onboardingProvider.hasCompletedOnboarding) {
      Navigator.of(context).pushReplacementNamed('/onboarding');
    } else {
      Navigator.of(context).pushReplacementNamed('/main');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final splashTextTheme = AppTheme.splashTextTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      "assets/icon/icon.png",
                      height: 80,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Reverie',
                      style: splashTextTheme.displayLarge?.copyWith(
                        color: colorScheme.onBackground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Capture Your Moments',
                      style: splashTextTheme.titleMedium?.copyWith(
                        color: colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
