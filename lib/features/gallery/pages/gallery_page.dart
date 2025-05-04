import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/media_provider.dart';
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
  bool _isGridView = true;
  int _gridCrossAxisCount = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MediaProvider>().requestPermission();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Reverie',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          actions: [
            IconButton(
              icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
              tooltip: _isGridView ? 'List view' : 'Grid view',
            ),
            if (_isGridView)
              IconButton(
                icon: Icon(
                    _gridCrossAxisCount == 3 ? Icons.grid_4x4 : Icons.grid_3x3),
                onPressed: () {
                  setState(() {
                    _gridCrossAxisCount = _gridCrossAxisCount == 3 ? 4 : 3;
                  });
                },
                tooltip: 'Change grid size',
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Photos'),
              Tab(text: 'Albums'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            PhotosTab(
              isGridView: _isGridView,
              gridCrossAxisCount: _gridCrossAxisCount,
            ),
            AlbumsTab(
              isGridView: _isGridView,
              gridCrossAxisCount: _gridCrossAxisCount,
            ),
          ],
        ),
      ),
    );
  }
}
