import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reverie/widgets/custom_app_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../providers/gallery_preferences_provider.dart';
import '../../backupdrive/pages/backup_screen.dart';
import '../../permissions/provider/permission_provider.dart';
import '../../permissions/widgets/permission_aware_widget.dart';
import '../provider/media_provider.dart';
import '../widgets/flashbacks_preview.dart';
import '../widgets/gallery_search_delegate.dart';
import 'tabs/photos_tab.dart';
import 'tabs/albums_tab.dart';
import '../../backupdrive/provider/backup_provider.dart';

class GalleryPage extends StatefulWidget {
  final VoidCallback? onMenuPressed;

  const GalleryPage({
    super.key,
    this.onMenuPressed,
  });

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (image != null) {
        final File imageFile = File(image.path);

        // Save the image to gallery
        final result = await PhotoManager.editor.saveImageWithPath(
          imageFile.path,
          title: 'Gallery_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (result != null) {
          if (mounted) {
            await context.read<MediaProvider>().addNewMedia(result);
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo captured and saved to gallery'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing photo: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 10),
      );

      if (video != null) {
        final File videoFile = File(video.path);

        // Save the video to gallery
        final result = await PhotoManager.editor.saveVideo(
          videoFile,
          title: 'Gallery_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (result != null) {
          if (mounted) {
            await context.read<MediaProvider>().addNewMedia(result);
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video captured and saved to gallery'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing video: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showCameraOptions() {
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
            Text(
              'Add Media',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: const Text('Take Photo'),
              subtitle: const Text('Capture a new photo with camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.videocam_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: const Text('Record Video'),
              subtitle: const Text('Record a new video with camera'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.photo_library_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select an existing photo or video'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<GalleryPreferencesProvider>();
    final mediaProvider = context.watch<MediaProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Gallery',
          onMenuPressed: widget.onMenuPressed,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.search_rounded,
              ),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: GallerySearchDelegate(mediaProvider),
                );
              },
              tooltip: 'Search media',
            ),
            Consumer<BackupProvider>(
              builder: (context, backupProvider, _) {
                return IconButton(
                  icon: Icon(
                    Icons.cloud_rounded,
                    color: backupProvider.isSignedIn
                        ? const Color(0xFF34A853)
                        : colorScheme.onSurfaceVariant,
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
          ],
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
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Photos'),
                      Tab(text: 'Albums'),
                    ],
                  ),
                ),
                pinned: true,
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
        floatingActionButton: Consumer<PermissionProvider>(
          builder: (context, permissionProvider, _) {
            if (!permissionProvider.hasMediaPermission) {
              return const SizedBox.shrink();
            }

            return FloatingActionButton(
              onPressed: _showCameraOptions,
              tooltip: 'Add Photo',
              child: const Icon(Icons.add_a_photo_rounded),
            );
          },
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
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BackupScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.backup_rounded),
                  label: const Text('Manage Backup'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF34A853),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
