import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reverie/widgets/custom_app_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:reverie/widgets/google_drive_info_sheet.dart';
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
              title: const Text('Choose from Existing Media'),
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

  void _showGoogleDriveInfo(
      BuildContext context, BackupProvider backupProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => GoogleDriveInfoSheet(
        backupProvider: backupProvider,
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
          foregroundColor: colorScheme.onSurface,
          backgroundColor: colorScheme.background,
          elevation: 0,
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
}
