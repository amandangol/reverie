import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class MediaProvider extends ChangeNotifier {
  List<AssetEntity> _mediaItems = [];
  List<AssetEntity> _videoItems = [];
  List<AssetPathEntity> _albums = [];
  List<AssetPathEntity> _videoAlbums = [];
  Map<DateTime, List<AssetEntity>> _groupedPhotos = {};
  final Map<String, Map<DateTime, List<AssetEntity>>> _albumGroupedPhotos = {};
  final Map<String, Map<DateTime, List<AssetEntity>>> _videoAlbumGroupedPhotos =
      {};
  final Map<String, List<AssetEntity>> _videoAlbumContents = {};
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMorePhotos = true;
  final String _currentAlbum = 'All Photos';
  final Map<String, File> _fileCache = {};
  final Map<String, File> _thumbnailCache = {};
  final Map<String, DateTime> _createDateCache = {};
  final Map<String, Size> _sizeCache = {};
  final Map<String, Duration> _durationCache = {};
  final Map<String, AssetEntity> _allMediaItems = {};
  final _uuid = const Uuid();
  String? _error;
  static const int _thumbnailSize = 300;
  final _preloadQueue = <AssetEntity>[];
  bool _isPreloading = false;
  int _currentPage = 0;
  static const int _pageSize = 100;
  bool _isInitialized = false;
  bool _mounted = true;

  // Favorites related variables
  static const String _favoritesKey = 'favorite_media_ids';
  Set<String> _favoriteIds = {};
  SharedPreferences? _prefs;
  bool _isFavoritesInitialized = false;

  List<AssetEntity> _allMediaList = [];
  List<AssetEntity> _currentAlbumItems = [];
  String? _currentAlbumId;
  bool _isFavoritesAlbum = false;
  bool _isVideosAlbum = false;

  final _imageLabeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.7),
  );
  Map<String, List<ImageLabel>> _labelCache = {};

  // Add these new properties
  Map<String, Set<String>> _categoryToAssetIds = {};
  final Map<String, Set<String>> _assetIdToCategories = {};
  bool _isCategorizing = false;

  // Add these constants for our specific categories
  static const List<String> _importantCategories = [
    'People',
    'Selfie',
    'Nature',
    'Food',
    'Screenshot'
  ];

  // Add mapping for related labels to our categories
  static const Map<String, List<String>> _labelToCategory = {
    'People': [
      'person',
      'people',
      'human',
      'man',
      'woman',
      'child',
      'boy',
      'girl'
    ],
    'Selfie': ['selfie', 'portrait', 'face'],
    'Nature': [
      'nature',
      'landscape',
      'mountain',
      'beach',
      'ocean',
      'sky',
      'tree',
      'flower',
      'plant',
      'forest',
      'grass'
    ],
    'Food': [
      'food',
      'meal',
      'dish',
      'restaurant',
      'fruit',
      'vegetable',
      'drink'
    ],
    'Screenshot': [
      'screenshot',
      'screen',
      'computer',
      'phone',
      'device',
      'app',
      'interface'
    ]
  };

  static const int _batchSize = 10; // Process 10 images at a time
  bool _isBackgroundProcessing = false;
  int _processedCount = 0;
  int _totalCount = 0;

  // Add getters for progress
  bool get isBackgroundProcessing => _isBackgroundProcessing;
  double get categorizationProgress =>
      _totalCount > 0 ? _processedCount / _totalCount : 0.0;

  static const String _labelsCacheKey = 'image_labels_cache';
  static const String _categoriesCacheKey = 'image_categories_cache';
  bool _isInitialCategorizationDone = false;

  // Add getter for initial categorization status
  bool get isInitialCategorizationDone => _isInitialCategorizationDone;

  @override
  void dispose() {
    _mounted = false;
    _imageLabeler.close();
    super.dispose();
  }

  MediaProvider() {
    _initSharedPreferences();
    _loadCachedLabels();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (_prefs == null) {
      await _initSharedPreferences();
    }

    final favoriteIds = _prefs?.getStringList(_favoritesKey) ?? [];
    _favoriteIds = Set<String>.from(favoriteIds);
    _isFavoritesInitialized = true;
    notifyListeners();
  }

  Future<void> _saveFavorites() async {
    if (_prefs == null) return;

    await _prefs?.setStringList(_favoritesKey, _favoriteIds.toList());
  }

  List<AssetEntity> get mediaItems =>
      _currentAlbumId == null ? _allMediaList : _currentAlbumItems;
  List<AssetEntity> get allMediaItems => _allMediaList;
  List<AssetEntity> get currentAlbumItems => _currentAlbumItems;
  List<AssetPathEntity> get albums => _albums;
  List<AssetPathEntity> get videoAlbums => _videoAlbums;
  Map<DateTime, List<AssetEntity>> get groupedPhotos => _groupedPhotos;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMorePhotos => _hasMorePhotos;
  String get currentAlbum => _currentAlbum;
  bool get isInitialized => _isInitialized;

  String? get error => _error;

  DateTime? getCreateDate(String assetId) => _createDateCache[assetId];
  Size? getSize(String assetId) => _sizeCache[assetId];
  Duration? getDuration(String assetId) => _durationCache[assetId];
  File? getCachedFile(String assetId) => _fileCache[assetId];
  File? getCachedThumbnail(String assetId) => _thumbnailCache[assetId];

  // Getters
  bool isFavorite(String assetId) {
    return _favoriteIds.contains(assetId);
  }

  List<AssetEntity> get favoriteItems {
    // Get all media items that are marked as favorites
    final allFavorites = _allMediaItems.values
        .where((asset) => _favoriteIds.contains(asset.id))
        .toList();

    // Sort by creation date
    allFavorites.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));

    return allFavorites;
  }

  Future<void> preloadMedia(AssetEntity asset) async {
    if (_fileCache.containsKey(asset.id)) return;
    _preloadQueue.add(asset);
    if (!_isPreloading) {
      _processPreloadQueue();
    }
  }

  Future<void> _processPreloadQueue() async {
    if (_preloadQueue.isEmpty) {
      _isPreloading = false;
      return;
    }

    _isPreloading = true;
    while (_preloadQueue.isNotEmpty) {
      final asset = _preloadQueue.removeAt(0);
      await getFileForAsset(asset);
      await cacheAssetData(asset);
    }
    _isPreloading = false;
  }

  Future<int?> getFileSize(String assetId) async {
    final asset = _mediaItems.firstWhere((item) => item.id == assetId);
    final file = await asset.file;
    if (file != null) {
      return await file.length();
    }
    return null;
  }

  Future<void> preloadAdjacentMedia(
      List<AssetEntity> assets, int currentIndex) async {
    // Preload current, previous, and next images
    if (currentIndex > 0) {
      await preloadMedia(assets[currentIndex - 1]);
    }
    await preloadMedia(assets[currentIndex]);
    if (currentIndex < assets.length - 1) {
      await preloadMedia(assets[currentIndex + 1]);
    }
  }

  Future<void> cacheAssetData(AssetEntity asset) async {
    if (!_mounted) return; // Stop if widget is disposed

    // Store asset in the all media items map
    _allMediaItems[asset.id] = asset;

    // Only cache if not already cached
    if (!_createDateCache.containsKey(asset.id)) {
      _createDateCache[asset.id] = asset.createDateTime;
    }
    if (!_sizeCache.containsKey(asset.id)) {
      final width = asset.width.toDouble();
      final height = asset.height.toDouble();
      _sizeCache[asset.id] = Size(width, height);
    }
    if (asset.type == AssetType.video &&
        !_durationCache.containsKey(asset.id)) {
      _durationCache[asset.id] = Duration(seconds: asset.duration);
    }
    notifyListeners();
  }

  Future<File?> getFileForAsset(AssetEntity asset) async {
    if (_fileCache.containsKey(asset.id)) {
      return _fileCache[asset.id];
    }

    try {
      final file = await asset.file;
      if (file != null) {
        _fileCache[asset.id] = file;
        notifyListeners();
        return file;
      }
    } catch (e) {
      debugPrint('Error loading file: $e');
    }
    return null;
  }

  Future<File?> getThumbnailForAsset(AssetEntity asset,
      {int? width, int? height}) async {
    final cacheKey =
        '${asset.id}_${width ?? _thumbnailSize}_${height ?? _thumbnailSize}';
    if (_thumbnailCache.containsKey(cacheKey)) {
      return _thumbnailCache[cacheKey];
    }

    try {
      final thumbnailData = await asset.thumbnailDataWithSize(
        ThumbnailSize(width ?? _thumbnailSize, height ?? _thumbnailSize),
        quality: 40, // Reduced quality for better performance
      );

      if (thumbnailData != null) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(path.join(tempDir.path, '${_uuid.v4()}.jpg'));
        await tempFile.writeAsBytes(thumbnailData);
        _thumbnailCache[cacheKey] = tempFile;
        return tempFile;
      }
    } catch (e) {
      debugPrint('Error loading thumbnail: $e');
    }
    return null;
  }

  Future<void> requestPermission() async {
    // Request both photo and video permissions
    final photosStatus = await Permission.photos.request();
    final videosStatus = await Permission.videos.request();

    debugPrint('Photos permission status: $photosStatus');
    debugPrint('Videos permission status: $videosStatus');

    if (photosStatus.isGranted || videosStatus.isGranted) {
      if (!_isInitialized) {
        await loadMedia();
      }
    } else {
      _error = 'Permission denied for photos and videos';
      notifyListeners();
    }
  }

  void groupPhotosByDate(List<AssetEntity> photos, {String? albumId}) {
    final targetMap =
        albumId != null ? _albumGroupedPhotos[albumId] ?? {} : _groupedPhotos;
    targetMap.clear();

    for (var photo in photos) {
      final date = photo.createDateTime;
      final dateKey = DateTime(date.year, date.month, date.day);

      if (!targetMap.containsKey(dateKey)) {
        targetMap[dateKey] = [];
      }
      targetMap[dateKey]!.add(photo);
    }

    // Sort each group by time
    for (var photos in targetMap.values) {
      photos.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
    }

    // Sort the dates in descending order
    final sortedMap = Map.fromEntries(
        targetMap.entries.toList()..sort((a, b) => b.key.compareTo(a.key)));

    if (albumId != null) {
      _albumGroupedPhotos[albumId] = sortedMap;
    } else {
      _groupedPhotos = sortedMap;
    }
  }

  Future<void> loadMedia() async {
    if (_isInitialized) return;

    _isLoading = true;
    _error = null;
    _currentPage = 0;
    _hasMorePhotos = true;
    _allMediaList.clear();
    _currentAlbumItems.clear();
    _currentAlbumId = null;
    _isFavoritesAlbum = false;
    _isVideosAlbum = false;
    notifyListeners();

    try {
      // Request permissions first
      final photosStatus = await Permission.photos.request();
      final videosStatus = await Permission.videos.request();

      if (!photosStatus.isGranted && !videosStatus.isGranted) {
        _error = 'Permission denied for photos and videos';
        notifyListeners();
        return;
      }

      await initializeFavorites();

      // Load albums with both photos and videos
      _albums = await PhotoManager.getAssetPathList(
        type: RequestType.all,
        filterOption: FilterOptionGroup(
          orders: [
            const OrderOption(type: OrderOptionType.createDate, asc: false),
          ],
          containsPathModified: true,
          createTimeCond: DateTimeCond(
            min: DateTime(1970),
            max: DateTime.now(),
          ),
        ),
      );

      if (_albums.isEmpty) {
        _error = 'No albums found';
        notifyListeners();
        return;
      }

      // Load video albums
      _videoAlbums = await PhotoManager.getAssetPathList(
        type: RequestType.video,
        filterOption: FilterOptionGroup(
          orders: [
            const OrderOption(type: OrderOptionType.createDate, asc: false),
          ],
          containsPathModified: true,
          createTimeCond: DateTimeCond(
            min: DateTime(1970),
            max: DateTime.now(),
          ),
        ),
      );

      final allPhotosAlbum = _albums.firstWhere(
        (album) => album.name == 'All Photos',
        orElse: () => _albums.first,
      );

      // Load first page immediately for quick initial display
      final firstPage = await allPhotosAlbum.getAssetListPaged(
        page: 0,
        size: _pageSize,
      );

      // Add first page to allMediaList
      _allMediaList.addAll(firstPage);

      // Store first page in the all media items map
      for (var asset in firstPage) {
        _allMediaItems[asset.id] = asset;
      }

      // Sort and group first page
      _allMediaList
          .sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
      groupPhotosByDate(_allMediaList);

      _isLoading = false;
      _isInitialized = true;
      notifyListeners();

      // Load remaining pages in background
      final totalCount = await allPhotosAlbum.assetCountAsync;
      final totalPages = (totalCount / _pageSize).ceil();

      if (totalPages > 1) {
        for (var page = 1; page < totalPages; page++) {
          if (!_mounted) break;

          final assets = await allPhotosAlbum.getAssetListPaged(
            page: page,
            size: _pageSize,
          );

          // Filter out duplicates
          final newAssets = assets
              .where((asset) => !_allMediaItems.containsKey(asset.id))
              .toList();

          // Add new assets to allMediaList
          _allMediaList.addAll(newAssets);

          // Store new assets in the all media items map
          for (var asset in newAssets) {
            _allMediaItems[asset.id] = asset;
          }

          // Sort and group all items
          _allMediaList
              .sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
          groupPhotosByDate(_allMediaList);

          notifyListeners();
        }
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadMorePhotos() async {
    if (_isLoadingMore || !_hasMorePhotos || _currentAlbumId == null) return;

    try {
      _isLoadingMore = true;
      notifyListeners();

      final currentAlbum = _albums.firstWhere(
        (album) => album.id == _currentAlbumId,
        orElse: () => _albums.first,
      );

      final assets = await currentAlbum.getAssetListPaged(
        page: _currentPage,
        size: _pageSize,
      );

      if (assets.isEmpty) {
        _hasMorePhotos = false;
        _isLoadingMore = false;
        notifyListeners();
        return;
      }

      // Filter out duplicates
      final newAssets = assets
          .where((asset) => !_allMediaItems.containsKey(asset.id))
          .toList();

      // Add new assets to currentAlbumItems
      _currentAlbumItems.addAll(newAssets);

      // Store new assets in the all media items map
      for (var asset in newAssets) {
        _allMediaItems[asset.id] = asset;
      }

      // Preload thumbnails for new assets
      for (var asset in newAssets) {
        if (!_mounted) break;
        await getThumbnailForAsset(asset, width: 300, height: 300);
      }

      _currentPage++;
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMore = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> _loadNextPage(AssetPathEntity album) async {
    final assets = await album.getAssetListPaged(
      page: _currentPage,
      size: _pageSize,
    );

    if (assets.isEmpty) {
      _hasMorePhotos = false;
      return;
    }

    // Filter out duplicates before adding to allMediaList
    final newAssets =
        assets.where((asset) => !_allMediaItems.containsKey(asset.id)).toList();

    // Add only new assets to allMediaList
    _allMediaList.addAll(newAssets);

    // Store all assets in the all media items map
    for (var asset in newAssets) {
      _allMediaItems[asset.id] = asset;
    }

    // Sort all media items by creation date in descending order
    _allMediaList.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));

    // Cache data for new assets only
    for (var asset in newAssets) {
      if (!_mounted) return;
      await cacheAssetData(asset);
    }

    // Group photos by date for display purposes
    groupPhotosByDate(_allMediaList);

    _currentPage++;
  }

  Future<void> loadAlbumContents(AssetPathEntity album,
      {bool isFavorites = false, bool isVideos = false}) async {
    try {
      _isLoading = true;
      _currentPage = 0;
      _hasMorePhotos = true;
      _currentAlbumItems.clear();
      _currentAlbumId = album.id;
      _isFavoritesAlbum = isFavorites;
      _isVideosAlbum = isVideos;
      notifyListeners();

      if (isFavorites) {
        _currentAlbumItems = favoriteItems;
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (isVideos) {
        _currentAlbumItems = await loadVideoAlbumContents(album);
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Load first page immediately
      final firstPage = await album.getAssetListPaged(
        page: 0,
        size: _pageSize,
      );

      // Filter out duplicates
      final newAssets = firstPage
          .where((asset) => !_allMediaItems.containsKey(asset.id))
          .toList();
      _currentAlbumItems.addAll(newAssets);

      // Store new assets in the all media items map
      for (var asset in newAssets) {
        _allMediaItems[asset.id] = asset;
      }

      // Update UI with first page
      _isLoading = false;
      notifyListeners();

      // Preload thumbnails for the first page
      for (var asset in newAssets) {
        if (!_mounted) break;
        await getThumbnailForAsset(asset, width: 300, height: 300);
      }

      // Load remaining pages in background
      final totalCount = await album.assetCountAsync;
      final totalPages = (totalCount / _pageSize).ceil();

      if (totalPages > 1) {
        for (var page = 1; page < totalPages; page++) {
          if (!_mounted) break;
          final assets = await album.getAssetListPaged(
            page: page,
            size: _pageSize,
          );

          // Filter out duplicates
          final newAssets = assets
              .where((asset) => !_allMediaItems.containsKey(asset.id))
              .toList();
          _currentAlbumItems.addAll(newAssets);

          // Store new assets in the all media items map
          for (var asset in newAssets) {
            _allMediaItems[asset.id] = asset;
          }

          // Preload thumbnails for the new page
          for (var asset in newAssets) {
            if (!_mounted) break;
            await getThumbnailForAsset(asset, width: 300, height: 300);
          }

          notifyListeners();
        }
      }

      // Sort assets by creation date
      _currentAlbumItems
          .sort((a, b) => b.createDateTime.compareTo(a.createDateTime));

      // Group assets by date
      groupPhotosByDate(_currentAlbumItems, albumId: album.id);
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<List<AssetEntity>> loadVideoAlbumContents(
      AssetPathEntity album) async {
    try {
      // Get total count of assets in the album
      final totalCount = await album.assetCountAsync;
      const pageSize = 100;
      final totalPages = (totalCount / pageSize).ceil();
      final List<AssetEntity> allVideos = [];

      // Load all pages
      for (var page = 0; page < totalPages; page++) {
        final assets = await album.getAssetListPaged(
          page: page,
          size: pageSize,
        );
        allVideos.addAll(assets);
      }

      // Sort videos by creation date
      allVideos.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));

      // Cache the contents
      _videoAlbumContents[album.id] = allVideos;

      // Group videos by date
      groupVideosByDate(allVideos, albumId: album.id);

      // Cache data for all videos
      for (var asset in allVideos) {
        await cacheAssetData(asset);
      }

      return allVideos;
    } catch (e) {
      debugPrint('Error loading video album contents: $e');
      return [];
    }
  }

  void groupVideosByDate(List<AssetEntity> videos, {String? albumId}) {
    final targetMap = albumId != null
        ? _videoAlbumGroupedPhotos[albumId] ?? {}
        : _groupedPhotos;
    targetMap.clear();

    for (var video in videos) {
      final date = video.createDateTime;
      final dateKey = DateTime(date.year, date.month, date.day);

      if (!targetMap.containsKey(dateKey)) {
        targetMap[dateKey] = [];
      }
      targetMap[dateKey]!.add(video);
    }

    // Sort each group by time
    for (var videos in targetMap.values) {
      videos.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
    }

    // Sort the dates in descending order
    final sortedMap = Map.fromEntries(
        targetMap.entries.toList()..sort((a, b) => b.key.compareTo(a.key)));

    if (albumId != null) {
      _videoAlbumGroupedPhotos[albumId] = sortedMap;
    } else {
      _groupedPhotos = sortedMap;
    }
  }

  Map<DateTime, List<AssetEntity>> getGroupedVideosForAlbum(String albumId) {
    return _videoAlbumGroupedPhotos[albumId] ?? {};
  }

  Future<void> shareMedia(AssetEntity asset) async {
    try {
      final file = await asset.file;
      if (file != null) {
        await Share.shareXFiles([XFile(file.path)]);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    try {
      await clearFileCache();
      _mediaItems.clear();
      _videoItems.clear();
      _albums.clear();
      _videoAlbums.clear();
      _allMediaItems.clear();
      _isInitialized = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing media: $e');
    }
  }

  Future<void> clearFileCache() async {
    _fileCache.clear();
    _thumbnailCache.clear();
    notifyListeners();
  }

  Future<void> clearMediaCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteMedia(AssetEntity asset) async {
    try {
      await PhotoManager.editor.deleteWithIds([asset.id]);
      _mediaItems.remove(asset);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  List<AssetEntity> getAssetsForAlbum(String albumId) {
    return _mediaItems.where((asset) => asset.id == albumId).toList();
  }

  Map<DateTime, List<AssetEntity>> getGroupedPhotosForAlbum(String albumId) {
    return _albumGroupedPhotos[albumId] ?? {};
  }

  Future<void> initializeFavorites() async {
    if (_isFavoritesInitialized) return;

    try {
      // Load favorites from shared preferences or other storage
      _favoriteIds.clear();
      _isFavoritesInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing favorites: $e');
    }
  }

  Future<void> toggleFavorite(AssetEntity asset) async {
    if (!_isFavoritesInitialized) {
      await _initSharedPreferences();
    }

    if (_favoriteIds.contains(asset.id)) {
      _favoriteIds.remove(asset.id);
    } else {
      _favoriteIds.add(asset.id);
    }
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> refreshMedia() async {
    _isInitialized = false;
    _mediaItems.clear();
    _videoItems.clear();
    _albums.clear();
    _videoAlbums.clear();
    _groupedPhotos.clear();
    _albumGroupedPhotos.clear();
    _videoAlbumGroupedPhotos.clear();
    _videoAlbumContents.clear();
    _fileCache.clear();
    _thumbnailCache.clear();
    _createDateCache.clear();
    _sizeCache.clear();
    _durationCache.clear();
    _allMediaItems.clear();
    _currentPage = 0;
    _hasMorePhotos = true;
    notifyListeners();
    await loadMedia();
  }

  void clearAlbumData(String albumId) {
    if (_currentAlbumId == albumId) {
      _currentAlbumItems.clear();
      _currentAlbumId = null;
      _isFavoritesAlbum = false;
      _isVideosAlbum = false;
      notifyListeners();
    }
  }

  void clearAllAlbumData() {
    _albumGroupedPhotos.clear();
    _videoAlbumGroupedPhotos.clear();
    _videoAlbumContents.clear();
    notifyListeners();
  }

  Future<void> clearCache() async {
    try {
      _fileCache.clear();
      _thumbnailCache.clear();
      _createDateCache.clear();
      _sizeCache.clear();
      _durationCache.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  Future<void> searchOnGoogle(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final url = Uri.parse('https://www.google.com/search?q=$encodedQuery');

    try {
      if (await launchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      // You might want to show a snackbar or dialog to inform the user
    }
  }

  Future<List<ImageLabel>> detectObjects(AssetEntity asset) async {
    if (_labelCache.containsKey(asset.id)) {
      return _labelCache[asset.id]!;
    }

    try {
      final file = await asset.file;
      if (file == null) return [];

      // Check if file exists and is readable
      if (!await file.exists()) return [];

      final inputImage = InputImage.fromFile(file);
      final labels = await _imageLabeler.processImage(inputImage);

      // Cache the results
      _labelCache[asset.id] = labels;
      _updateCategories(asset.id, labels);

      return labels;
    } catch (e) {
      debugPrint('Error detecting objects: $e');
      return [];
    }
  }

  // Add these getters
  bool get isCategorizing => _isCategorizing;
  Map<String, Set<String>> get categoryToAssetIds => _categoryToAssetIds;
  Set<String> getCategoriesForAsset(String assetId) =>
      _assetIdToCategories[assetId] ?? {};

  // Modify categorizeAllMedia to be more efficient
  Future<void> categorizeAllMedia() async {
    if (_isCategorizing) return;

    _isCategorizing = true;
    _isBackgroundProcessing = true;
    _processedCount = 0;
    _totalCount = _allMediaItems.length;
    notifyListeners();

    try {
      final assets = _allMediaItems.values.toList();

      // Process in smaller batches with lower priority
      for (var i = 0; i < assets.length; i += 5) {
        if (!_mounted) break;

        final end = (i + 5 < assets.length) ? i + 5 : assets.length;
        final batch = assets.sublist(i, end);

        // Process batch with lower priority
        await Future.wait(
          batch.map((asset) async {
            if (_labelCache.containsKey(asset.id)) {
              _processedCount++;
              notifyListeners();
              return;
            }

            try {
              final labels = await detectObjects(asset);
              _processedCount++;
              notifyListeners();

              // Save to cache every 50 images
              if (_processedCount % 50 == 0) {
                await _saveLabelsToCache();
              }
            } catch (e) {
              debugPrint('Error processing asset ${asset.id}: $e');
              _processedCount++;
              notifyListeners();
            }
          }),
        );

        // Longer delay between batches to reduce CPU usage
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // Final save to cache
      await _saveLabelsToCache();
      _isInitialCategorizationDone = true;
    } finally {
      _isCategorizing = false;
      _isBackgroundProcessing = false;
      notifyListeners();
    }
  }

  // Add method to start categorization manually
  Future<void> startCategorization() async {
    if (_isCategorizing) return;

    // Start from where we left off
    final unprocessedAssets = _allMediaItems.values
        .where((asset) => !_labelCache.containsKey(asset.id))
        .toList();

    if (unprocessedAssets.isEmpty) {
      _isInitialCategorizationDone = true;
      notifyListeners();
      return;
    }

    await categorizeAllMedia();
  }

  // Add method to clear categorization cache
  Future<void> clearCategorizationCache() async {
    _labelCache.clear();
    _categoryToAssetIds.clear();
    _assetIdToCategories.clear();
    _isInitialCategorizationDone = false;

    if (_prefs != null) {
      await _prefs?.remove(_labelsCacheKey);
      await _prefs?.remove(_categoriesCacheKey);
    }

    notifyListeners();
  }

  // Add method to process visible assets
  Future<void> processVisibleAssets(List<AssetEntity> visibleAssets) async {
    if (_isCategorizing) return;

    final unprocessedAssets = visibleAssets
        .where((asset) => !_labelCache.containsKey(asset.id))
        .toList();

    if (unprocessedAssets.isEmpty) return;

    // Process visible assets in smaller batches
    for (var i = 0; i < unprocessedAssets.length; i += 5) {
      if (!_mounted) break;

      final end =
          (i + 5 < unprocessedAssets.length) ? i + 5 : unprocessedAssets.length;
      final batch = unprocessedAssets.sublist(i, end);

      await Future.wait(
        batch.map((asset) => detectObjects(asset)),
      );

      // Small delay between batches
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  // Add method to clear label cache
  void clearLabelCache() {
    _labelCache.clear();
    _categoryToAssetIds.clear();
    _assetIdToCategories.clear();
    notifyListeners();
  }

  void _updateCategories(String assetId, List<ImageLabel> labels) {
    // Remove old categories for this asset
    final oldCategories = _assetIdToCategories[assetId] ?? {};
    for (var category in oldCategories) {
      _categoryToAssetIds[category]?.remove(assetId);
      if (_categoryToAssetIds[category]?.isEmpty ?? false) {
        _categoryToAssetIds.remove(category);
      }
    }

    // Map labels to our specific categories
    final Set<String> newCategories = {};
    for (var label in labels) {
      for (var entry in _labelToCategory.entries) {
        if (entry.value.any((keyword) =>
            label.label.toLowerCase().contains(keyword.toLowerCase()))) {
          newCategories.add(entry.key);
        }
      }
    }

    // Update the category mappings
    _assetIdToCategories[assetId] = newCategories;
    for (var category in newCategories) {
      _categoryToAssetIds.putIfAbsent(category, () => {}).add(assetId);
    }

    notifyListeners();
  }

  // Add method to get assets by category
  List<AssetEntity> getAssetsByCategory(String category) {
    final assetIds = _categoryToAssetIds[category] ?? {};
    return assetIds
        .map((id) => _allMediaItems[id])
        .where((asset) => asset != null)
        .cast<AssetEntity>()
        .toList();
  }

  // Add method to get all categories
  List<String> getAllCategories() {
    return _importantCategories
        .where((category) => _categoryToAssetIds.containsKey(category))
        .toList();
  }

  // Add method to get category icon
  IconData getCategoryIcon(String category) {
    switch (category) {
      case 'People':
        return Icons.people;
      case 'Selfie':
        return Icons.face;
      case 'Nature':
        return Icons.landscape;
      case 'Food':
        return Icons.restaurant;
      case 'Screenshot':
        return Icons.screenshot;
      default:
        return Icons.category;
    }
  }

  // Add method to load cached labels
  Future<void> _loadCachedLabels() async {
    if (_prefs == null) {
      await _initSharedPreferences();
    }

    try {
      final labelsJson = _prefs?.getString(_labelsCacheKey);
      final categoriesJson = _prefs?.getString(_categoriesCacheKey);

      if (labelsJson != null) {
        final Map<String, dynamic> labelsMap =
            Map<String, dynamic>.from(json.decode(labelsJson));
        _labelCache = labelsMap.map((key, value) => MapEntry(
              key,
              (value as List)
                  .map((e) => ImageLabel(
                        label: e['label'] as String,
                        confidence: e['confidence'] as double,
                        index: 0,
                      ))
                  .toList(),
            ));
      }

      if (categoriesJson != null) {
        final Map<String, dynamic> categoriesMap =
            Map<String, dynamic>.from(json.decode(categoriesJson));
        _categoryToAssetIds = categoriesMap.map((key, value) => MapEntry(
              key,
              Set<String>.from(value as List),
            ));
      }

      _isInitialCategorizationDone = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cached labels: $e');
    }
  }

  // Add method to save labels to cache
  Future<void> _saveLabelsToCache() async {
    if (_prefs == null) return;

    try {
      final labelsMap = _labelCache.map((key, value) => MapEntry(
            key,
            value
                .map((label) => {
                      'label': label.label,
                      'confidence': label.confidence,
                    })
                .toList(),
          ));

      final categoriesMap = _categoryToAssetIds.map((key, value) => MapEntry(
            key,
            value.toList(),
          ));

      await _prefs?.setString(_labelsCacheKey, json.encode(labelsMap));
      await _prefs?.setString(_categoriesCacheKey, json.encode(categoriesMap));
    } catch (e) {
      debugPrint('Error saving labels to cache: $e');
    }
  }
}
