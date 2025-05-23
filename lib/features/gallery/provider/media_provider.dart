import 'dart:typed_data';
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
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:exif/exif.dart' as exif;
import '../../../services/connectivity_service.dart';

enum AlbumSortOption { nameAsc, nameDesc, countAsc, countDesc }

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

  final ConnectivityService _connectivityService = ConnectivityService();

  final _imageLabeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.7),
  );
  final Map<String, List<ImageLabel>> _labelCache = {};

  final _model = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: 'AIzaSyCyCzEzKjHpkacME7Y8wj1u2E787Q-NAu4',
  );

  final Map<String, Map<String, dynamic>> _analysisCache = {};
  final Map<String, bool> _analysisInProgress = {};

  final Map<String, String> _captionCache = {};

  final Map<String, Map<String, dynamic>> _memoryAnalysisCache = {};
  final Map<String, bool> _memoryAnalysisInProgress = {};

  AlbumSortOption _currentSortOption = AlbumSortOption.nameAsc;
  AlbumSortOption get currentSortOption => _currentSortOption;

  final _textRecognizer = TextRecognizer();
  final Map<String, RecognizedText> _textRecognitionCache = {};
  final Map<String, bool> _textRecognitionInProgress = {};

  String _searchQuery = '';
  List<AssetEntity> _searchResults = [];
  bool _isSearching = false;

  MediaProvider() {
    _initSharedPreferences();
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
    try {
      final asset = _allMediaItems[assetId];
      if (asset == null) {
        debugPrint('Asset not found for ID: $assetId');
        return null;
      }

      // First try to get the file
      final file = await asset.file;
      if (file == null) {
        debugPrint('File not found for asset: $assetId');
        return null;
      }

      // Check if file exists
      if (!await file.exists()) {
        debugPrint('File does not exist: ${file.path}');
        return null;
      }

      // Get file size in bytes
      final fileSize = await file.length();
      debugPrint('File size for $assetId: $fileSize bytes (${file.path})');
      return fileSize;
    } catch (e) {
      debugPrint('Error getting file size for $assetId: $e');
      return null;
    }
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

      // Remove from all relevant lists and caches
      _mediaItems.remove(asset);
      _videoItems.remove(asset);
      _allMediaList.remove(asset);
      _currentAlbumItems.remove(asset);
      _allMediaItems.remove(asset.id);
      _fileCache.remove(asset.id);
      _thumbnailCache.remove(asset.id);
      _createDateCache.remove(asset.id);
      _sizeCache.remove(asset.id);
      _durationCache.remove(asset.id);
      _labelCache.remove(asset.id);
      _analysisCache.remove(asset.id);
      _captionCache.remove(asset.id);

      // Update grouped photos
      for (var date in _groupedPhotos.keys.toList()) {
        _groupedPhotos[date]?.remove(asset);
        if (_groupedPhotos[date]?.isEmpty ?? false) {
          _groupedPhotos.remove(date);
        }
      }

      // Update album grouped photos
      for (var albumId in _albumGroupedPhotos.keys) {
        for (var date in _albumGroupedPhotos[albumId]!.keys.toList()) {
          _albumGroupedPhotos[albumId]![date]?.remove(asset);
          if (_albumGroupedPhotos[albumId]![date]?.isEmpty ?? false) {
            _albumGroupedPhotos[albumId]!.remove(date);
          }
        }
      }

      // Update video album grouped photos
      for (var albumId in _videoAlbumGroupedPhotos.keys) {
        for (var date in _videoAlbumGroupedPhotos[albumId]!.keys.toList()) {
          _videoAlbumGroupedPhotos[albumId]![date]?.remove(asset);
          if (_videoAlbumGroupedPhotos[albumId]![date]?.isEmpty ?? false) {
            _videoAlbumGroupedPhotos[albumId]!.remove(date);
          }
        }
      }

      // Update video album contents
      for (var albumId in _videoAlbumContents.keys) {
        _videoAlbumContents[albumId]?.remove(asset);
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
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

    // Update the UI immediately
    notifyListeners();

    // Ensure the asset is in the allMediaItems map
    if (!_allMediaItems.containsKey(asset.id)) {
      _allMediaItems[asset.id] = asset;
    }
  }

  @override
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
    }
  }

  Future<List<ImageLabel>> detectObjects(AssetEntity asset) async {
    if (_labelCache.containsKey(asset.id)) {
      return _labelCache[asset.id]!;
    }

    try {
      final file = await asset.file;
      if (file == null) return [];

      final inputImage = InputImage.fromFile(file);
      final labels = await _imageLabeler.processImage(inputImage);

      _labelCache[asset.id] = labels;
      notifyListeners();
      return labels;
    } catch (e) {
      debugPrint('Error detecting objects: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> analyzeImage(AssetEntity asset) async {
    // Check if analysis is already in progress
    if (_analysisInProgress[asset.id] == true) {
      throw Exception('Analysis already in progress');
    }
    if (!await _connectivityService.checkConnection()) {
      throw NoInternetException();
    }

    // Check cache first
    if (_analysisCache.containsKey(asset.id)) {
      debugPrint('Using cached analysis for ${asset.id}');
      return _analysisCache[asset.id]!;
    }

    try {
      // Set analysis in progress
      _analysisInProgress[asset.id] = true;
      notifyListeners();

      final file = await asset.file;
      if (file == null) throw Exception('Could not load image file');

      final bytes = await file.readAsBytes();

      final prompt = '''
You are an AI visual analyst. Analyze the following gallery image and provide a structured, concise analysis under these headings:

1. **Main Subject**: What is the central object, person, or scene in the image? Be specific.
2. **Visual Composition**:
   - Dominant colors
   - Lighting type (e.g., natural, artificial, low-light, overexposed)
   - Framing or perspective (e.g., wide shot, close-up, top-down)
3. **Scene Context**:
   - Likely setting (e.g., indoor, outdoor, event, nature, city)
   - Time of day if possible
   - Any activity or action happening
4. **Notable Features**:
   - Unusual objects, fashion, facial expressions, landmarks, or text in the image
   - Any emotional cues or symbolic elements
5. **Style & Mood**:
   - Artistic style or filter (e.g., candid, posed, edited, vintage)
   - Mood conveyed (e.g., joyful, eerie, serene, chaotic)
6. **Tags (comma-separated)**:
   Generate 5–10 concise keywords or tags relevant for search or categorization.

Avoid repetition. Use clear and simple language. Return only the structured output. Do not describe the image as an AI; focus on insights as if summarizing for a user-facing gallery.

''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', bytes),
        ])
      ];

      final response = await _model.generateContent(content);
      final text = response.text;

      // Create analysis result
      final analysis = {
        'rawResponse': text,
        'timestamp': DateTime.now().toIso8601String(),
        'assetId': asset.id,
      };

      // Cache the result
      _analysisCache[asset.id] = analysis;
      debugPrint('Cached analysis for ${asset.id}');

      return analysis;
    } catch (e) {
      debugPrint('Error analyzing image: $e');
      rethrow;
    } finally {
      // Clear analysis in progress state
      _analysisInProgress[asset.id] = false;
      notifyListeners();
    }
  }

  // Add method to check if analysis is in progress
  bool isAnalysisInProgress(String assetId) {
    return _analysisInProgress[assetId] ?? false;
  }

  // Modify clearAnalysisCache to also clear progress state
  void clearAnalysisCache() {
    _analysisCache.clear();
    _analysisInProgress.clear();
    notifyListeners();
  }

  // Add method to generate caption
  Future<String> generateCaption(AssetEntity asset) async {
    // Check cache first
    if (_captionCache.containsKey(asset.id)) {
      return _captionCache[asset.id]!;
    }

    try {
      final file = await asset.file;
      if (file == null) throw Exception('Could not load image file');

      final bytes = await file.readAsBytes();

      const prompt = '''
You are a memory caption generator. Create a short, engaging caption (max 2 sentences) for this photo that captures the essence of the moment. Focus on:
- The main subject or scene
- The mood or feeling
- Any notable details that make this moment special

Keep it personal and nostalgic, as if reminiscing about a past memory. Be concise but evocative.
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', bytes),
        ])
      ];

      final response = await _model.generateContent(content);
      final caption = response.text;

      // Cache the caption
      _captionCache[asset.id] = caption!;
      notifyListeners();

      return caption;
    } catch (e) {
      debugPrint('Error generating caption: $e');
      return 'Unable to generate caption';
    }
  }

  // Add method to get caption
  String? getCaption(String assetId) {
    return _captionCache[assetId];
  }

  // Add method to clear caption cache
  void clearCaptionCache() {
    _captionCache.clear();
    notifyListeners();
  }

  // Keep memory analysis related methods
  Future<Map<String, dynamic>> analyzeMemory(AssetEntity asset) async {
    if (_memoryAnalysisInProgress[asset.id] == true) {
      throw Exception('Memory analysis already in progress');
    }

    if (_memoryAnalysisCache.containsKey(asset.id)) {
      return _memoryAnalysisCache[asset.id]!;
    }

    try {
      _memoryAnalysisInProgress[asset.id] = true;
      notifyListeners();

      final file = await asset.file;
      if (file == null) throw Exception('Could not load image file');

      final bytes = await file.readAsBytes();

      const prompt = '''
You are a memory analyst. Analyze this photo and provide insights about the memory it captures:

1. **Memory Context**:
   - What kind of moment or event is captured?
   - What emotions or feelings does it evoke?
   - What makes this memory special or significant?

2. **Memory Details**:
   - Key people, places, or objects in the memory
   - Notable activities or events happening
   - Any unique or memorable elements

3. **Memory Impact**:
   - Why might this memory be important to the person?
   - What story or narrative does it tell?
   - How might it connect to other memories?

4. **Memory Tags**:
   Generate 5-10 emotional or thematic tags that capture the essence of this memory.

Keep the analysis personal and nostalgic, focusing on the emotional and narrative aspects of the memory.
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', bytes),
        ])
      ];

      final response = await _model.generateContent(content);
      final text = response.text;

      final analysis = {
        'rawResponse': text,
        'timestamp': DateTime.now().toIso8601String(),
        'assetId': asset.id,
      };

      _memoryAnalysisCache[asset.id] = analysis;
      return analysis;
    } catch (e) {
      debugPrint('Error analyzing memory: $e');
      rethrow;
    } finally {
      _memoryAnalysisInProgress[asset.id] = false;
      notifyListeners();
    }
  }

  bool isMemoryAnalysisInProgress(String assetId) {
    return _memoryAnalysisInProgress[assetId] ?? false;
  }

  void clearMemoryAnalysisCache() {
    _memoryAnalysisCache.clear();
    _memoryAnalysisInProgress.clear();
    notifyListeners();
  }

  Map<String, dynamic>? getMemoryAnalysis(String assetId) {
    return _memoryAnalysisCache[assetId];
  }

  List<AssetEntity> getSimilarMemories(AssetEntity asset, {int limit = 5}) {
    final analysis = _memoryAnalysisCache[asset.id];
    if (analysis == null) return [];

    final memoriesWithAnalysis = _allMediaItems.values
        .where((a) => _memoryAnalysisCache.containsKey(a.id))
        .toList();

    memoriesWithAnalysis.sort((a, b) {
      final aAnalysis = _memoryAnalysisCache[a.id]!;
      final bAnalysis = _memoryAnalysisCache[b.id]!;
      return bAnalysis['timestamp'].compareTo(aAnalysis['timestamp']);
    });

    return memoriesWithAnalysis.take(limit).toList();
  }

  List<AssetEntity> getMemoryTimeline({int limit = 10}) {
    final memoriesWithAnalysis = _allMediaItems.values
        .where((a) => _memoryAnalysisCache.containsKey(a.id))
        .toList();

    memoriesWithAnalysis
        .sort((a, b) => b.createDateTime.compareTo(a.createDateTime));

    return memoriesWithAnalysis.take(limit).toList();
  }

  // Keep text recognition related methods
  Map<String, RecognizedText> get textRecognitionCache => _textRecognitionCache;

  Future<RecognizedText?> recognizeText(AssetEntity asset) async {
    if (_textRecognitionCache.containsKey(asset.id)) {
      return _textRecognitionCache[asset.id];
    }

    if (_textRecognitionInProgress[asset.id] == true) {
      return null;
    }

    try {
      _textRecognitionInProgress[asset.id] = true;
      notifyListeners();

      final file = await asset.file;
      if (file == null) return null;

      final inputImage = InputImage.fromFile(file);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      _textRecognitionCache[asset.id] = recognizedText;
      _textRecognitionInProgress[asset.id] = false;
      notifyListeners();
      return recognizedText;
    } catch (e) {
      debugPrint('Error recognizing text: $e');
      _textRecognitionInProgress[asset.id] = false;
      notifyListeners();
      return null;
    }
  }

  void clearTextRecognitionCache() {
    _textRecognitionCache.clear();
    _textRecognitionInProgress.clear();
    notifyListeners();
  }

  // Add getter for sorted albums
  Future<List<AssetPathEntity>> getSortedAlbums() async {
    final albums = List<AssetPathEntity>.from(_albums);

    if (_currentSortOption == AlbumSortOption.nameAsc) {
      albums.sort((a, b) => a.name.compareTo(b.name));
      return albums;
    } else if (_currentSortOption == AlbumSortOption.nameDesc) {
      albums.sort((a, b) => b.name.compareTo(a.name));
      return albums;
    } else {
      // For count-based sorting, we need to get the counts first
      final albumCounts = await Future.wait(
        albums.map((album) =>
            album.assetCountAsync.then((count) => MapEntry(album, count))),
      );

      final countMap = Map.fromEntries(albumCounts);

      if (_currentSortOption == AlbumSortOption.countAsc) {
        albums.sort((a, b) => countMap[a]!.compareTo(countMap[b]!));
      } else {
        albums.sort((a, b) => countMap[b]!.compareTo(countMap[a]!));
      }

      return albums;
    }
  }

  // Add method to change sort option
  Future<void> changeSortOption(AlbumSortOption option) async {
    if (_currentSortOption == option) return;
    _currentSortOption = option;
    notifyListeners();
  }

  // Add these getters
  String get searchQuery => _searchQuery;
  List<AssetEntity> get searchResults => _searchResults;
  bool get isSearching => _isSearching;

  // Add this method to search media
  Future<void> searchMedia(String query) async {
    if (query.isEmpty) {
      _searchQuery = '';
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _searchQuery = query;
    _isSearching = true;
    notifyListeners();

    try {
      // Search through all media items
      final results = _allMediaItems.values.where((asset) {
        // Search in file name
        final fileName = asset.title?.toLowerCase() ?? '';
        if (fileName.contains(query.toLowerCase())) {
          return true;
        }

        // Search in labels if available
        final labels = _labelCache[asset.id];
        if (labels != null) {
          return labels.any((label) =>
              label.label.toLowerCase().contains(query.toLowerCase()));
        }

        // Search in captions if available
        final caption = _captionCache[asset.id];
        if (caption != null) {
          return caption.toLowerCase().contains(query.toLowerCase());
        }

        // Search in memory analysis if available
        final memoryAnalysis = _memoryAnalysisCache[asset.id];
        if (memoryAnalysis != null) {
          final analysis = memoryAnalysis['rawResponse'] as String;
          return analysis.toLowerCase().contains(query.toLowerCase());
        }

        return false;
      }).toList();

      _searchResults = results;
    } catch (e) {
      debugPrint('Error searching media: $e');
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  // Add method to clear search
  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }

  // Replace the getLocation method with getExifData
  Future<Map<String, dynamic>?> getExifData(AssetEntity asset) async {
    debugPrint('Getting EXIF data for asset: ${asset.id}');

    try {
      final file = await asset.file;
      if (file == null) {
        debugPrint('No file found for asset ${asset.id}');
        return null;
      }

      final bytes = await file.readAsBytes();
      final exifData = await exif.readExifFromBytes(bytes);

      if (exifData.isEmpty) {
        debugPrint('No EXIF data found');
        return null;
      }

      // Extract relevant EXIF data
      final exifInfo = <String, dynamic>{};

      // Camera info
      exifInfo['camera'] = exifData['Image Make']?.printable ??
          exifData['EXIF Tag 0x9A00']?.printable;
      exifInfo['model'] = exifData['Image Model']?.printable;

      // Date and time
      exifInfo['dateTime'] = exifData['EXIF DateTimeOriginal']?.printable ??
          exifData['Image DateTime']?.printable;

      // Exposure settings
      if (exifData['EXIF ExposureTime'] != null) {
        exifInfo['exposureTime'] = exifData['EXIF ExposureTime']?.printable;
      }
      if (exifData['EXIF FNumber'] != null) {
        exifInfo['fNumber'] = exifData['EXIF FNumber']?.printable;
      }
      if (exifData['EXIF ISOSpeedRatings'] != null) {
        exifInfo['iso'] = exifData['EXIF ISOSpeedRatings']?.printable;
      }
      if (exifData['EXIF FocalLength'] != null) {
        exifInfo['focalLength'] = exifData['EXIF FocalLength']?.printable;
      }
      if (exifData['EXIF FocalLengthIn35mmFilm'] != null) {
        exifInfo['focalLength35mm'] =
            exifData['EXIF FocalLengthIn35mmFilm']?.printable;
      }

      // Other settings
      exifInfo['flash'] = exifData['EXIF Flash']?.printable;
      exifInfo['whiteBalance'] = exifData['EXIF WhiteBalance']?.printable;
      exifInfo['exposureProgram'] = exifData['EXIF ExposureProgram']?.printable;
      exifInfo['meteringMode'] = exifData['EXIF MeteringMode']?.printable;
      exifInfo['sceneCaptureType'] =
          exifData['EXIF SceneCaptureType']?.printable;

      // Additional camera info
      if (exifData['EXIF Tag 0x9999'] != null) {
        try {
          final cameraSettings = exifData['EXIF Tag 0x9999']?.printable;
          if (cameraSettings != null) {
            exifInfo['cameraSettings'] = cameraSettings;
          }
        } catch (e) {
          debugPrint('Error parsing camera settings: $e');
        }
      }

      return exifInfo;
    } catch (e) {
      debugPrint('Error getting EXIF data: $e');
      return null;
    }
  }

  // Remove the location cache and related methods
  @override
  void dispose() {
    _mounted = false;
    _imageLabeler.close();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> saveEditedImage(
      Uint8List editedImage, AssetEntity originalAsset) async {
    try {
      // Get the app's temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'edited_${originalAsset.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${tempDir.path}/$fileName');

      // Write the edited image to the file
      await file.writeAsBytes(editedImage);

      // Save the edited image to the gallery
      final result = await PhotoManager.editor.saveImageWithPath(
        file.path,
        title: 'Edited ${originalAsset.title ?? 'Image'}',
      );

      if (result != null) {
        // Clear the cache for the original asset
        _fileCache.remove(originalAsset.id);
        _thumbnailCache.remove(originalAsset.id);
        _sizeCache.remove(originalAsset.id);
        _createDateCache.remove(originalAsset.id);

        // Reload media to update the UI
        await loadMedia();
      }
    } catch (e) {
      debugPrint('Error saving edited image: $e');
      rethrow;
    }
  }

  Future<void> addNewMedia(AssetEntity newAsset) async {
    try {
      // Add to all media items map
      _allMediaItems[newAsset.id] = newAsset;

      // Add to all media list
      _allMediaList.insert(
          0, newAsset); // Insert at beginning since it's newest

      // Add to current album items if we're in the main gallery
      if (_currentAlbumId == null) {
        _currentAlbumItems.insert(0, newAsset);
      }

      // Update grouped photos
      final date = newAsset.createDateTime;
      final dateKey = DateTime(date.year, date.month, date.day);

      // Update main grouped photos
      if (!_groupedPhotos.containsKey(dateKey)) {
        _groupedPhotos[dateKey] = [];
      }
      _groupedPhotos[dateKey]!.insert(0, newAsset);

      // Update album grouped photos if we're in an album
      if (_currentAlbumId != null) {
        if (!_albumGroupedPhotos.containsKey(_currentAlbumId)) {
          _albumGroupedPhotos[_currentAlbumId!] = {};
        }
        if (!_albumGroupedPhotos[_currentAlbumId]!.containsKey(dateKey)) {
          _albumGroupedPhotos[_currentAlbumId]![dateKey] = [];
        }
        _albumGroupedPhotos[_currentAlbumId]![dateKey]!.insert(0, newAsset);
      }

      // Cache the asset data
      await cacheAssetData(newAsset);

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding new media: $e');
      rethrow;
    }
  }
}
