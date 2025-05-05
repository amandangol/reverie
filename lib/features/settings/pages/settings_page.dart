import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reverie/features/journal/providers/journal_provider.dart';
import '../../gallery/provider/media_provider.dart';
import '../../ai_compilation/provider/ai_compilation_provider.dart';
import '../../permissions/provider/permission_provider.dart';
import '../../permissions/widgets/permission_dialog.dart';
import '../widgets/setting_widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _version = '1.0.0';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Data Management Section
          SettingsSection(
            title: 'Data Management',
            children: [
              SettingsTile(
                icon: Icons.photo_library,
                title: 'Clear Media Cache',
                subtitle: 'Remove temporary media files',
                onTap: () => _showConfirmationDialog(
                  context,
                  title: 'Clear Media Cache',
                  content: 'Are you sure you want to clear the media cache?',
                  onConfirm: () {
                    context.read<MediaProvider>().clearMediaCache();
                    _showSnackBar(context, 'Media cache cleared');
                  },
                ),
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: Icons.book,
                title: 'Clear Journal Data',
                subtitle: 'Delete all journal entries',
                onTap: () => _showConfirmationDialog(
                  context,
                  title: 'Clear Journal Data',
                  content:
                      'Are you sure you want to delete all journal entries?',
                  onConfirm: () {
                    context.read<JournalProvider>().clearAll();
                    _showSnackBar(context, 'Journal data cleared');
                  },
                ),
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: Icons.auto_awesome,
                title: 'Clear AI Compilations',
                subtitle: 'Delete all AI-generated compilations',
                onTap: () => _showConfirmationDialog(
                  context,
                  title: 'Clear AI Compilations',
                  content:
                      'Are you sure you want to delete all AI compilations?',
                  onConfirm: () {
                    context.read<AICompilationProvider>().clearAll();
                    _showSnackBar(context, 'AI compilations cleared');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Permissions Section
          SettingsSection(
            title: 'Permissions',
            children: [
              SettingsTile(
                icon: Icons.photo,
                title: 'Media Access',
                subtitle: 'Manage photo and video access',
                onTap: () => _requestMediaPermission(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // About Section
          SettingsSection(
            title: 'About',
            children: [
              SettingsTile(
                icon: Icons.info,
                title: 'App Version',
                subtitle: _version,
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),

          // Logo at the bottom
          const SizedBox(height: 40),
          const AppLogo(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        content: content,
        onConfirm: onConfirm,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Reverie',
      applicationVersion: _version,
      applicationIcon: Image.asset(
        'assets/icon/icon.png',
        width: 40,
        height: 40,
      ),
      children: [
        const Text('Thank you for using Reverie!'),
      ],
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _requestMediaPermission(BuildContext context) {
    final permissionProvider = context.read<PermissionProvider>();

    showDialog(
      context: context,
      builder: (context) => PermissionDialog(
          title: 'Media Access Required',
          message: permissionProvider.isPermanentlyDenied()
              ? 'Media access is required to view and manage your photos and videos. Please enable it in your device settings.'
              : 'Media access is required to view and manage your photos and videos.',
          onRequestPermission: () async {
            final granted = await permissionProvider.requestMediaPermission();
            if (granted) {
              context.read<MediaProvider>().requestPermission();
              _showSnackBar(context, 'Media access granted');
            }
          },
          onOpenSettings: () =>
              context.read<PermissionProvider>().openSettings()),
    );
  }
}
