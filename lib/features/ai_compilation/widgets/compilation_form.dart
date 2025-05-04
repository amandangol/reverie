import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../gallery/provider/media_provider.dart';
import 'package:photo_manager/photo_manager.dart';

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
  final _titleController = TextEditingController();
  final _themeController = TextEditingController();
  final List<AssetEntity> _selectedMedia = [];
  final Map<String, File?> _mediaFiles = {};

  @override
  void dispose() {
    _titleController.dispose();
    _themeController.dispose();
    super.dispose();
  }

  Future<void> _loadMediaFile(AssetEntity asset) async {
    if (!_mediaFiles.containsKey(asset.id)) {
      final file = await context.read<MediaProvider>().getFileForAsset(asset);
      if (mounted) {
        setState(() {
          _mediaFiles[asset.id] = file;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Compilation'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _themeController,
              decoration: const InputDecoration(
                labelText: 'Theme',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Select Media:'),
            const SizedBox(height: 8),
            Consumer<MediaProvider>(
              builder: (context, mediaProvider, child) {
                return SizedBox(
                  height: 200,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4.0,
                      mainAxisSpacing: 4.0,
                    ),
                    itemCount: mediaProvider.mediaItems.length,
                    itemBuilder: (context, index) {
                      final asset = mediaProvider.mediaItems[index];
                      final isSelected = _selectedMedia.contains(asset);

                      if (!_mediaFiles.containsKey(asset.id)) {
                        _loadMediaFile(asset);
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }

                      final file = _mediaFiles[asset.id];
                      if (file == null) {
                        return const Center(child: Text('Error'));
                      }

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedMedia.remove(asset);
                            } else {
                              _selectedMedia.add(asset);
                            }
                          });
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              file,
                              fit: BoxFit.cover,
                            ),
                            if (isSelected)
                              Container(
                                color: Colors.black.withOpacity(0.5),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final title = _titleController.text.trim();
            final theme = _themeController.text.trim();
            if (title.isNotEmpty &&
                theme.isNotEmpty &&
                _selectedMedia.isNotEmpty) {
              final mediaPaths = _selectedMedia
                  .map((asset) => _mediaFiles[asset.id]?.path ?? '')
                  .where((path) => path.isNotEmpty)
                  .toList();
              widget.onSave(title, theme, mediaPaths);
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
