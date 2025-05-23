import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import '../../../../../utils/media_utils.dart';
import '../../../provider/media_provider.dart';

class InfoPanel extends StatelessWidget {
  final AssetEntity asset;
  final VoidCallback onClose;

  const InfoPanel({
    required this.asset,
    required this.onClose,
  });

  Future<Map<String, dynamic>> _getMediaDetails(
      MediaProvider mediaProvider) async {
    final details = <String, dynamic>{};

    // Get creation date
    details['date'] = mediaProvider.getCreateDate(asset.id);

    // Get dimensions
    details['size'] = mediaProvider.getSize(asset.id);

    // Get file size
    try {
      final file = await asset.file;
      if (file != null) {
        details['filePath'] = file.path;
        // Try to get file size
        try {
          final fileSize = await file.length();
          details['fileSize'] = fileSize;
        } catch (e) {}
      }
    } catch (e) {}

    // Get duration for videos
    if (asset.type == AssetType.video) {
      details['duration'] = mediaProvider.getDuration(asset.id);
    }

    // Get device info
    if (asset.title != null) {
      details['device'] = asset.title;
    }

    // Get modified date
    if (asset.modifiedDateTime != null) {
      details['modifiedDate'] = asset.modifiedDateTime;
    }

    // Get EXIF data
    final exifData = await mediaProvider.getExifData(asset);
    if (exifData != null) {
      details['exif'] = exifData;
    }

    return details;
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExifSection(Map<String, dynamic> exifData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Camera Information',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (exifData['camera'] != null || exifData['model'] != null)
          _buildInfoRow(
            'Camera',
            [exifData['camera'], exifData['model']]
                .where((s) => s != null)
                .join(' '),
          ),
        if (exifData['dateTime'] != null)
          _buildInfoRow('Date Taken', exifData['dateTime']),
        const SizedBox(height: 16),
        const Text(
          'Exposure Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (exifData['exposureTime'] != null)
          _buildInfoRow('Exposure', exifData['exposureTime']),
        if (exifData['fNumber'] != null)
          _buildInfoRow('Aperture', 'f/${exifData['fNumber']}'),
        if (exifData['iso'] != null) _buildInfoRow('ISO', exifData['iso']),
        if (exifData['focalLength'] != null)
          _buildInfoRow(
            'Focal Length',
            exifData['focalLength35mm'] != null
                ? '${exifData['focalLength']}mm (${exifData['focalLength35mm']}mm eq.)'
                : '${exifData['focalLength']}mm',
          ),
        const SizedBox(height: 16),
        const Text(
          'Other Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (exifData['flash'] != null)
          _buildInfoRow('Flash', exifData['flash']),
        if (exifData['whiteBalance'] != null)
          _buildInfoRow('White Balance', exifData['whiteBalance']),
        if (exifData['exposureProgram'] != null)
          _buildInfoRow('Exposure Program', exifData['exposureProgram']),
        if (exifData['meteringMode'] != null)
          _buildInfoRow('Metering Mode', exifData['meteringMode']),
        if (exifData['sceneCaptureType'] != null)
          _buildInfoRow('Scene Type', exifData['sceneCaptureType']),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Media Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: onClose,
              ),
            ],
          ),
          const Divider(color: Colors.white30),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, dynamic>>(
            future: _getMediaDetails(context.read<MediaProvider>()),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading details: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              final details = snapshot.data ?? {};
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Type',
                        asset.type == AssetType.video ? 'Video' : 'Image'),
                    const SizedBox(height: 12),
                    if (details['date'] != null)
                      _buildInfoRow(
                          'Date', MediaUtils.formatDate(details['date'])),
                    const SizedBox(height: 12),
                    if (details['size'] != null)
                      _buildInfoRow('Dimensions',
                          MediaUtils.formatDimensions(details['size'])),
                    const SizedBox(height: 12),
                    if (details['fileSize'] != null)
                      _buildInfoRow('File Size',
                          MediaUtils.formatFileSize(details['fileSize'])),
                    const SizedBox(height: 12),
                    if (details['filePath'] != null)
                      _buildInfoRow('File Path', details['filePath']),
                    const SizedBox(height: 12),
                    if (asset.type == AssetType.video &&
                        details['duration'] != null)
                      _buildInfoRow('Duration',
                          MediaUtils.formatDuration(details['duration'])),
                    const SizedBox(height: 12),
                    if (details['device'] != null)
                      _buildInfoRow('Device', details['device']),
                    const SizedBox(height: 12),
                    if (details['modifiedDate'] != null)
                      _buildInfoRow('Modified',
                          MediaUtils.formatDate(details['modifiedDate'])),
                    const SizedBox(height: 16),
                    if (details['exif'] != null) ...[
                      const Divider(color: Colors.white30),
                      const SizedBox(height: 16),
                      _buildExifSection(details['exif']),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
