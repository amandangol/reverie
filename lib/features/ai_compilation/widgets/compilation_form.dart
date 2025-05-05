import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../gallery/provider/media_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class CompilationForm extends StatefulWidget {
  final Function(String title, String theme, List<String> mediaPaths) onSave;

  const CompilationForm({
    super.key,
    required this.onSave,
  });

  @override
  State<CompilationForm> createState() => _CompilationFormState();
}

class _CompilationFormState extends State<CompilationForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _themeController = TextEditingController();
  List<String> _selectedMediaPaths = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _themeController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    try {
      final permitted = await PhotoManager.requestPermissionExtend();
      if (!permitted.isAuth) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission denied')),
          );
        }
        return;
      }

      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.all,
      );

      if (albums.isEmpty) return;

      final List<AssetEntity> assets = await albums[0].getAssetListPaged(
        page: 0,
        size: 80,
      );

      if (!mounted) return;

      final selectedAssets = await Navigator.push<List<AssetEntity>>(
        context,
        MaterialPageRoute(
          builder: (context) => MediaPickerPage(assets: assets),
        ),
      );

      if (selectedAssets != null) {
        setState(() {
          _selectedMediaPaths =
              selectedAssets.map((asset) => asset.id).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking media: $e')),
        );
      }
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMediaPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one media item')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      widget.onSave(
        _titleController.text,
        _themeController.text,
        _selectedMediaPaths,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating compilation: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Compilation'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _submit,
              child: const Text('Create'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter a title for your compilation',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _themeController,
              decoration: const InputDecoration(
                labelText: 'Theme',
                hintText: 'Enter a theme for your compilation',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a theme';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'Selected Media',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${_selectedMediaPaths.length} selected',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedMediaPaths.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 48,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No media selected',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedMediaPaths.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: AssetEntityImage(
                              AssetEntity(
                                id: _selectedMediaPaths[index],
                                typeInt: 1,
                                width: 0,
                                height: 0,
                              ),
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _selectedMediaPaths.removeAt(index);
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickMedia,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Select Media'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MediaPickerPage extends StatefulWidget {
  final List<AssetEntity> assets;

  const MediaPickerPage({
    super.key,
    required this.assets,
  });

  @override
  State<MediaPickerPage> createState() => _MediaPickerPageState();
}

class _MediaPickerPageState extends State<MediaPickerPage> {
  final Set<AssetEntity> _selectedAssets = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Media'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _selectedAssets.toList());
            },
            child: const Text('Done'),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: widget.assets.length,
        itemBuilder: (context, index) {
          final asset = widget.assets[index];
          final isSelected = _selectedAssets.contains(asset);

          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedAssets.remove(asset);
                } else {
                  _selectedAssets.add(asset);
                }
              });
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                AssetEntityImage(
                  asset,
                  fit: BoxFit.cover,
                ),
                if (isSelected)
                  Container(
                    color: Colors.black26,
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
