import 'dart:ui';

import 'package:flutter/material.dart';

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

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        children: [
          Image.asset(
            'assets/icon/icon.png',
            width: 100,
            height: 100,
          ),
          const SizedBox(height: 8),
          Text(
            'Reverie',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.primary,
              fontSize: 24,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
