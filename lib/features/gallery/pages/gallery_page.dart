import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/gallery_preferences_provider.dart';
import '../../permissions/provider/permission_provider.dart';
import '../../permissions/widgets/permission_aware_widget.dart';
import '../provider/media_provider.dart';
import '../widgets/flashbacks_preview.dart';
import 'tabs/photos_tab.dart';
import 'tabs/albums_tab.dart';

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
}
