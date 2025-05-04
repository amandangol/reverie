import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/permission_provider.dart';

class PermissionDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRequestPermission;
  final VoidCallback? onOpenSettings;

  const PermissionDialog({
    super.key,
    required this.title,
    required this.message,
    this.onRequestPermission,
    this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final permissionProvider = context.watch<PermissionProvider>();

    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (permissionProvider.isRequestingPermission)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      actions: [
        if (permissionProvider.isPermanentlyDenied())
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onOpenSettings?.call();
            },
            child: const Text('Open Settings'),
          )
        else ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onRequestPermission?.call();
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ],
    );
  }
}
