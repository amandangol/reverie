// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:photo_manager/photo_manager.dart';
// import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
// import 'package:reverie/features/gallery/provider/media_provider.dart';
// import 'package:reverie/features/gallery/pages/media_detail_view.dart';
// import 'package:reverie/utils/media_utils.dart';

// class SmartSearchScreen extends StatefulWidget {
//   const SmartSearchScreen({super.key});

//   @override
//   State<SmartSearchScreen> createState() => _SmartSearchScreenState();
// }

// class _SmartSearchScreenState extends State<SmartSearchScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   bool _isInitialized = false;

//   @override
//   void initState() {
//     super.initState();
//     _searchController.addListener(_onSearchChanged);
//     _initializeSmartSearch();
//   }

//   @override
//   void dispose() {
//     _searchController.removeListener(_onSearchChanged);
//     _searchController.dispose();
//     super.dispose();
//   }

//   Future<void> _initializeSmartSearch() async {
//     final mediaProvider = context.read<MediaProvider>();
//     // Start analysis in background
//     mediaProvider.analyzeAllMedia();
//     // Mark as initialized immediately to show UI
//     if (mounted) {
//       setState(() {
//         _isInitialized = true;
//       });
//     }
//   }

//   void _onSearchChanged() {
//     if (_searchController.text.isEmpty) {
//       context.read<MediaProvider>().clearSearch();
//     } else {
//       context.read<MediaProvider>().searchMedia(_searchController.text);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//     final mediaProvider = context.watch<MediaProvider>();

//     return Scaffold(
//       backgroundColor: colorScheme.background,
//       body: CustomScrollView(
//         slivers: [
//           // Custom App Bar
//           SliverAppBar(
//             pinned: true,
//             backgroundColor: colorScheme.surface,
//             title: Text(
//               'Smart Search',
//               style: theme.textTheme.titleLarge?.copyWith(
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             centerTitle: false,
//             elevation: 0,
//             scrolledUnderElevation: 0,
//           ),

//           // Search Bar
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Search Bar
//                   Container(
//                     decoration: BoxDecoration(
//                       color: colorScheme.surfaceVariant.withOpacity(0.5),
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: TextField(
//                       controller: _searchController,
//                       decoration: InputDecoration(
//                         hintText: 'Search for objects in your photos...',
//                         prefixIcon: Icon(
//                           Icons.search_rounded,
//                           color: colorScheme.primary,
//                         ),
//                         suffixIcon: _searchController.text.isNotEmpty
//                             ? IconButton(
//                                 icon: const Icon(Icons.clear_rounded),
//                                 onPressed: () {
//                                   _searchController.clear();
//                                   mediaProvider.clearSearch();
//                                 },
//                               )
//                             : null,
//                         border: InputBorder.none,
//                         contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 16,
//                           vertical: 14,
//                         ),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 16),

//                   // Analysis Status
//                   if (mediaProvider.isAnalyzing)
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: colorScheme.primaryContainer.withOpacity(0.5),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Row(
//                         children: [
//                           SizedBox(
//                             width: 20,
//                             height: 20,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               valueColor: AlwaysStoppedAnimation<Color>(
//                                 colorScheme.primary,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Text(
//                               'Analyzing photos in background...',
//                               style: theme.textTheme.bodyMedium?.copyWith(
//                                 color: colorScheme.onPrimaryContainer,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ),

//           // Search Results
//           if (mediaProvider.isSearching)
//             const SliverFillRemaining(
//               child: Center(
//                 child: CircularProgressIndicator(),
//               ),
//             )
//           else if (mediaProvider.searchQuery.isEmpty)
//             SliverFillRemaining(
//               child: Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.search_rounded,
//                       size: 64,
//                       color: colorScheme.primary.withOpacity(0.5),
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       'Search your photos',
//                       style: theme.textTheme.titleMedium?.copyWith(
//                         color: colorScheme.onSurface.withOpacity(0.7),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Try searching for objects like "dog", "beach", or "car"',
//                       style: theme.textTheme.bodyMedium?.copyWith(
//                         color: colorScheme.onSurface.withOpacity(0.5),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             )
//           else if (mediaProvider.searchResults.isEmpty)
//             SliverFillRemaining(
//               child: Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.search_off_rounded,
//                       size: 64,
//                       color: colorScheme.error.withOpacity(0.5),
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       'No matching objects found',
//                       style: theme.textTheme.titleMedium?.copyWith(
//                         color: colorScheme.onSurface.withOpacity(0.7),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Try different object names',
//                       style: theme.textTheme.bodyMedium?.copyWith(
//                         color: colorScheme.onSurface.withOpacity(0.5),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             )
//           else
//             SliverPadding(
//               padding: const EdgeInsets.all(16),
//               sliver: SliverGrid(
//                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 3,
//                   mainAxisSpacing: 8,
//                   crossAxisSpacing: 8,
//                   childAspectRatio: 1,
//                 ),
//                 delegate: SliverChildBuilderDelegate(
//                   (context, index) {
//                     final asset = mediaProvider.searchResults[index];
//                     return _buildSearchResultItem(context, asset, index);
//                   },
//                   childCount: mediaProvider.searchResults.length,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSearchResultItem(
//       BuildContext context, AssetEntity asset, int index) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//     final mediaProvider = context.read<MediaProvider>();
//     final detectedObjects = mediaProvider.getDetectedObjects(asset.id);

//     return GestureDetector(
//       onTap: () => _showFullScreenImage(context, asset, index),
//       child: Hero(
//         tag: 'search_result_$index',
//         child: Stack(
//           fit: StackFit.expand,
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(12),
//               child: Image(
//                 image: AssetEntityImageProvider(
//                   asset,
//                   isOriginal: false,
//                   thumbnailSize: const ThumbnailSize(300, 300),
//                 ),
//                 fit: BoxFit.cover,
//               ),
//             ),
//             // Detected Objects Overlay
//             if (detectedObjects.isNotEmpty)
//               Positioned(
//                 bottom: 0,
//                 left: 0,
//                 right: 0,
//                 child: Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       begin: Alignment.bottomCenter,
//                       end: Alignment.topCenter,
//                       colors: [
//                         Colors.black.withOpacity(0.8),
//                         Colors.transparent,
//                       ],
//                     ),
//                     borderRadius: const BorderRadius.vertical(
//                       bottom: Radius.circular(12),
//                     ),
//                   ),
//                   child: Wrap(
//                     spacing: 4,
//                     runSpacing: 4,
//                     children: detectedObjects
//                         .take(3)
//                         .map((label) => Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 6,
//                                 vertical: 2,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: colorScheme.primary.withOpacity(0.8),
//                                 borderRadius: BorderRadius.circular(4),
//                               ),
//                               child: Text(
//                                 label.label,
//                                 style: theme.textTheme.labelSmall?.copyWith(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ))
//                         .toList(),
//                   ),
//                 ),
//               ),
//             if (asset.type == AssetType.video)
//               Positioned(
//                 bottom: 8,
//                 right: 8,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 8,
//                     vertical: 4,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.6),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(
//                         MediaUtils.getMediaTypeIcon(asset.type),
//                         color: Colors.white,
//                         size: 16,
//                       ),
//                       const SizedBox(width: 4),
//                       Consumer<MediaProvider>(
//                         builder: (context, mediaProvider, _) {
//                           final duration = mediaProvider.getDuration(asset.id);
//                           if (duration == null) {
//                             return const SizedBox();
//                           }
//                           return Text(
//                             MediaUtils.formatDuration(duration),
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 12,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showFullScreenImage(
//       BuildContext context, AssetEntity asset, int initialIndex) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (context) => MediaDetailView(
//           asset: asset,
//           assetList: context.read<MediaProvider>().searchResults,
//           heroTag: 'search_result_$initialIndex',
//         ),
//       ),
//     );
//   }
// }
