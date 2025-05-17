import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'media_provider.dart';
import '../../journal/providers/journal_provider.dart';

class PhotoOperationsProvider extends ChangeNotifier {
  bool _isSelectionMode = false;
  final Set<String> _selectedItems = {};

  bool get isSelectionMode => _isSelectionMode;
  Set<String> get selectedItems => _selectedItems;
  int get selectedCount => _selectedItems.length;

  void toggleSelectionMode() {
    HapticFeedback.selectionClick();
    _isSelectionMode = !_isSelectionMode;
    if (!_isSelectionMode) {
      _selectedItems.clear();
    }
    notifyListeners();
  }

  void toggleItemSelection(String itemId) {
    if (_selectedItems.contains(itemId)) {
      _selectedItems.remove(itemId);
    } else {
      _selectedItems.add(itemId);
      HapticFeedback.lightImpact();
    }
    if (_selectedItems.isEmpty) {
      _isSelectionMode = false;
    }
    notifyListeners();
  }

  Future<void> shareSelectedItems(List<AssetEntity> assets) async {
    final selectedAssets =
        assets.where((asset) => _selectedItems.contains(asset.id)).toList();

    if (selectedAssets.isEmpty) return;

    final files = await Future.wait(
      selectedAssets.map((asset) => asset.file),
    );
    final validFiles = files.where((file) => file != null).cast<File>();

    if (validFiles.isNotEmpty) {
      await Share.shareXFiles(
        validFiles.map((file) => XFile(file.path)).toList(),
        text: 'Check out these photos!',
      );
    }
  }

  Future<void> deleteSelectedItems(
      List<AssetEntity> assets, MediaProvider mediaProvider) async {
    final selectedAssets =
        assets.where((asset) => _selectedItems.contains(asset.id)).toList();

    if (selectedAssets.isEmpty) return;

    try {
      // Delete each asset
      for (var asset in selectedAssets) {
        await mediaProvider.deleteMedia(asset);
      }

      // Clear selection mode and selected items
      _selectedItems.clear();
      _isSelectionMode = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting items: $e');
      rethrow;
    }
  }

  Future<int> toggleFavoriteSelected(List<AssetEntity> assets) async {
    final selectedAssets =
        assets.where((asset) => _selectedItems.contains(asset.id)).toList();

    if (selectedAssets.isEmpty) return 0;

    final mediaProvider = MediaProvider();
    int successCount = 0;

    for (var asset in selectedAssets) {
      try {
        await mediaProvider.toggleFavorite(asset);
        successCount++;
      } catch (e) {
        debugPrint('Error toggling favorite for asset ${asset.id}: $e');
      }
    }

    _selectedItems.clear();
    _isSelectionMode = false;
    notifyListeners();

    return successCount;
  }

  Future<List<String>> addToJournalSelected(List<AssetEntity> assets) async {
    final selectedAssets =
        assets.where((asset) => _selectedItems.contains(asset.id)).toList();

    if (selectedAssets.isEmpty) return [];

    try {
      // Check if any of the selected assets are already in journal entries
      final journalProvider = JournalProvider();
      final existingEntries = journalProvider.entries
          .where((entry) => entry.mediaIds
              .any((id) => selectedAssets.any((asset) => asset.id == id)))
          .toList();

      // If any assets are already in journal entries, filter them out
      final mediaIds = selectedAssets
          .where((asset) => !existingEntries
              .any((entry) => entry.mediaIds.contains(asset.id)))
          .map((asset) => asset.id)
          .toList();

      // Clear selection mode and selected items before returning
      _selectedItems.clear();
      _isSelectionMode = false;
      notifyListeners();

      return mediaIds;
    } catch (e) {
      debugPrint('Error checking journal entries: $e');
      return [];
    }
  }

  Future<void> shareMedia(AssetEntity asset) async {
    try {
      final file = await asset.file;
      if (file != null) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text:
              'Check out this ${asset.type == AssetType.video ? 'video' : 'photo'}!',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleFavorite(AssetEntity asset) async {
    final mediaProvider = MediaProvider();
    await mediaProvider.toggleFavorite(asset);
    notifyListeners();
  }

  Future<List<String>> addToJournal(AssetEntity asset) async {
    try {
      // Check if the asset is already in a journal entry
      final journalProvider = JournalProvider();
      final entries = journalProvider.entries
          .where((entry) => entry.mediaIds.contains(asset.id))
          .toList();

      // If the asset is already in a journal entry, return empty list
      if (entries.isNotEmpty) {
        return [];
      }

      // Return a list with single media ID
      return [asset.id];
    } catch (e) {
      debugPrint('Error checking journal entries: $e');
      return [];
    }
  }
}
