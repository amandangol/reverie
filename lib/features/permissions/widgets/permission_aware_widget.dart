import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/permission_provider.dart';
import 'permission_dialog.dart';

class PermissionAwareWidget extends StatelessWidget {
  final Widget child;
  final Widget? loadingWidget;
  final Widget? deniedWidget;
  final VoidCallback? onPermissionGranted;

  const PermissionAwareWidget({
    super.key,
    required this.child,
    this.loadingWidget,
    this.deniedWidget,
    this.onPermissionGranted,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PermissionProvider>(
      builder: (context, permissionProvider, _) {
        if (permissionProvider.isRequestingPermission) {
          return loadingWidget ??
              const Center(child: CircularProgressIndicator());
        }

        if (!permissionProvider.hasMediaPermission) {
          return deniedWidget ??
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.no_photography,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      permissionProvider.isPermanentlyDenied()
                          ? 'Media access is permanently denied'
                          : 'Media access is required',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _showPermissionDialog(context),
                      child: Text(
                        permissionProvider.isPermanentlyDenied()
                            ? 'Open Settings'
                            : 'Grant Permission',
                      ),
                    ),
                  ],
                ),
              );
        }

        return child;
      },
    );
  }

  void _showPermissionDialog(BuildContext context) {
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
          if (granted && onPermissionGranted != null) {
            onPermissionGranted!();
          }
        },
        onOpenSettings: () {
          context.read<PermissionProvider>().openSettings();
        },
      ),
    );
  }
}
