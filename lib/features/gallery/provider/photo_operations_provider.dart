import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'media_provider.dart';
import '../../journal/models/journal_entry.dart';
import '../../journal/providers/journal_provider.dart';
import 'package:uuid/uuid.dart';

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

  Future<void> deleteSelectedItems(List<AssetEntity> assets) async {
    final selectedAssets =
        assets.where((asset) => _selectedItems.contains(asset.id)).toList();

    if (selectedAssets.isEmpty) return;

    final mediaProvider = MediaProvider();
    for (var asset in selectedAssets) {
      await mediaProvider.deleteMedia(asset);
    }

    _selectedItems.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  Future<void> toggleFavoriteSelected(List<AssetEntity> assets) async {
    final selectedAssets =
        assets.where((asset) => _selectedItems.contains(asset.id)).toList();

    if (selectedAssets.isEmpty) return;

    final mediaProvider = MediaProvider();
    for (var asset in selectedAssets) {
      await mediaProvider.toggleFavorite(asset);
    }

    _selectedItems.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  Future<void> addToJournalSelected(List<AssetEntity> assets) async {
    final selectedAssets =
        assets.where((asset) => _selectedItems.contains(asset.id)).toList();

    if (selectedAssets.isEmpty) return;

    final mediaIds = selectedAssets.map((asset) => asset.id).toList();

    // Ensure media is loaded in the provider
    final mediaProvider = MediaProvider();
    for (var asset in selectedAssets) {
      await mediaProvider.cacheAssetData(asset);
    }

    final entry = JournalEntry(
      id: const Uuid().v4(),
      title: 'New Journal Entry',
      content: '',
      mediaIds: mediaIds,
      mood: null,
      tags: [],
      date: DateTime.now(),
    );

    final journalProvider = JournalProvider();
    await journalProvider.addEntry(entry);

    _selectedItems.clear();
    _isSelectionMode = false;
    notifyListeners();
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

  Future<void> addToJournal(AssetEntity asset) async {
    final entry = JournalEntry(
      id: const Uuid().v4(),
      title: 'New Journal Entry',
      content: '',
      mediaIds: [asset.id],
      mood: null,
      tags: [],
      date: DateTime.now(),
    );

    final journalProvider = JournalProvider();
    await journalProvider.addEntry(entry);
    notifyListeners();
  }
}
