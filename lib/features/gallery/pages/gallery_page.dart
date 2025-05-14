import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/gallery_preferences_provider.dart';
import '../../permissions/provider/permission_provider.dart';
import '../../permissions/widgets/permission_aware_widget.dart';
import '../provider/media_provider.dart';
import '../widgets/flashbacks_preview.dart';
import 'tabs/photos_tab.dart';
import 'tabs/albums_tab.dart';
import '../../backupdrive/provider/backup_provider.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final permissionProvider = context.read<PermissionProvider>();
      final mediaProvider = context.read<MediaProvider>();

      await permissionProvider.checkMediaPermission();
      if (permissionProvider.hasMediaPermission) {
        if (!mediaProvider.isInitialized) {
          await mediaProvider.loadMedia();
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<GalleryPreferencesProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Reverie',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              fontSize: 17,
            ),
          ),
          backgroundColor: colorScheme.background,
          actions: [
            Consumer<BackupProvider>(
              builder: (context, backupProvider, _) {
                return IconButton(
                  icon: Icon(
                    Icons.cloud_rounded,
                    color: backupProvider.isSignedIn
                        ? const Color(0xFF34A853) // Google green when connected
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () =>
                      _showGoogleDriveInfo(context, backupProvider),
                  tooltip: backupProvider.isSignedIn
                      ? 'Connected to Google Drive'
                      : 'Connect to Google Drive',
                );
              },
            ),
            IconButton(
              icon: Icon(
                preferences.isGridView
                    ? Icons.grid_view_rounded
                    : Icons.list_rounded,
              ),
              onPressed: () => preferences.toggleViewMode(),
              tooltip: preferences.isGridView ? 'List view' : 'Grid view',
            ),
            if (preferences.isGridView)
              IconButton(
                icon: Icon(preferences.gridCrossAxisCount == 3
                    ? Icons.grid_4x4
                    : Icons.grid_3x3),
                onPressed: () => preferences.setGridCrossAxisCount(
                    preferences.gridCrossAxisCount == 3 ? 4 : 3),
                tooltip: 'Change grid size',
              ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Photos'),
              Tab(text: 'Albums'),
            ],
          ),
        ),
        body: PermissionAwareWidget(
          onPermissionGranted: () {
            context.read<MediaProvider>().requestPermission();
          },
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Consumer<MediaProvider>(
                  builder: (context, mediaProvider, _) {
                    if (mediaProvider.isLoading) {
                      return const SizedBox.shrink();
                    }
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: FlashbacksPreview(),
                    );
                  },
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                PhotosTab(
                  isGridView: preferences.isGridView,
                  gridCrossAxisCount: preferences.gridCrossAxisCount,
                ),
                AlbumsTab(
                  isGridView: preferences.isGridView,
                  gridCrossAxisCount: preferences.gridCrossAxisCount,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGoogleDriveInfo(
      BuildContext context, BackupProvider backupProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (backupProvider.isSignedIn) ...[
              if (backupProvider.userPhotoUrl != null)
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(backupProvider.userPhotoUrl!),
                )
              else
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF4285F4),
                  child: Text(
                    backupProvider.userName?[0].toUpperCase() ??
                        backupProvider.userEmail?[0].toUpperCase() ??
                        'G',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                backupProvider.userName ??
                    backupProvider.userEmail ??
                    'Google Account',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (backupProvider.userEmail != null) ...[
                const SizedBox(height: 4),
                Text(
                  backupProvider.userEmail!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF34A853),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Connected to Google Drive',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF34A853),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await backupProvider.signOutFromGoogleDrive();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4285F4),
                    side:
                        const BorderSide(color: Color(0xFF4285F4), width: 1.5),
                  ),
                ),
              ),
            ] else ...[
              const Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: Color(0xFF4285F4),
              ),
              const SizedBox(height: 16),
              Text(
                'Not Connected to Google Drive',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Connect your Google account to backup your memories',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await backupProvider.signInToGoogleDrive();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: Colors.red.shade700,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Sign in with Google'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4285F4),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
