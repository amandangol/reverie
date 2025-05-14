import 'dart:ui';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: colorScheme.primary,
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      onTap: onTap,
    );
  }
}

class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 32);
  }
}

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onConfirm;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
          ),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class AppLogo extends StatefulWidget {
  const AppLogo({super.key});

  @override
  State<AppLogo> createState() => _AppLogoState();
}

class _AppLogoState extends State<AppLogo> with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Color?> _colorAnimation;

  final int _bounceTimes = 3;
  int _currentBounce = 0;
  bool _isAnimating = false;
  final double _logoSize = 70.0;

  // Animation effects tracking
  bool _enableRotation = false;
  bool _enableColorChange = false;
  int _clickCount = 0;
  final int _clicksToUnlockRotation = 2;
  final int _clicksToUnlockColor = 5;

  @override
  void initState() {
    super.initState();
    // Bounce animation setup
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -25.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -25.0, end: 0.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 75.0,
      ),
    ]).animate(_bounceController);

    // Pulse animation setup
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50.0,
      ),
    ]).animate(_pulseController);

    // Color animation setup
    _colorAnimation = ColorTween(
      begin: Colors.blue,
      end: Colors.purple,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Rotation animation setup
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(
      CurvedAnimation(
        parent: _rotationController,
        curve: Curves.easeInOutBack,
      ),
    );

    _bounceController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _currentBounce++;
        if (_currentBounce < _bounceTimes) {
          // Continue bouncing
          _bounceController.reset();
          _bounceController.forward();
        } else {
          // Reset bounce counter when done
          _currentBounce = 0;
          _isAnimating = false;
        }
      }
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _unlockFeatures() {
    _clickCount++;

    // Unlock rotation after 2 clicks
    if (_clickCount == _clicksToUnlockRotation) {
      setState(() {
        _enableRotation = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Spin animation unlocked!'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    // Unlock color changes after 5 clicks
    if (_clickCount == _clicksToUnlockColor) {
      setState(() {
        _enableColorChange = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Color effects unlocked!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _playAnimations() {
    if (_isAnimating) return;

    _isAnimating = true;
    _unlockFeatures();

    // Always play bounce animation
    _bounceController.reset();
    _bounceController.forward();

    // Always play pulse animation
    _pulseController.reset();
    _pulseController.forward();

    // Conditionally play rotation
    if (_enableRotation) {
      _rotationController.reset();
      _rotationController.forward();
    }

    // Add haptic feedback for a more tactile experience
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: _playAnimations,
      // Add double tap for an Easter egg
      onDoubleTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You found a secret! ✨'),
            duration: Duration(seconds: 1),
          ),
        );
        // Perform a quick 360 spin
        _rotationController.reset();
        _rotationController.forward();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge(
            [_bounceController, _pulseController, _rotationController]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _bounceAnimation.value),
            child: Transform.rotate(
              angle: _enableRotation ? _rotationAnimation.value : 0.0,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            ),
          );
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo with shadow for depth
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_logoSize / 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/icon/icon.png',
                  width: _logoSize,
                  height: _logoSize,
                ),
              ),
              const SizedBox(height: 12),
              // App title with gradients if color feature is unlocked
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        colors: _enableColorChange
                            ? [
                                _colorAnimation.value ?? colorScheme.primary,
                                colorScheme.primary,
                                _colorAnimation.value ?? colorScheme.primary,
                              ]
                            : [colorScheme.primary, colorScheme.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds);
                    },
                    child: Text(
                      'Reverie',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color:
                            Colors.white, // The ShaderMask will override this
                        fontSize: 24,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PermissionRequestDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRequestPermission;
  final VoidCallback onOpenSettings;

  const PermissionRequestDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onRequestPermission,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onRequestPermission();
          },
          child: const Text('Request Permission'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onOpenSettings();
          },
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
          ),
          child: const Text('Open Settings'),
        ),
      ],
    );
  }
}
