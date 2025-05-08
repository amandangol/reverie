import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:intl/intl.dart';
import 'media_detail_view.dart';
import 'package:share_plus/share_plus.dart';

class FlashbackCard extends StatelessWidget {
  final AssetEntity asset;
  final List<AssetEntity> assetList;

  const FlashbackCard({
    super.key,
    required this.asset,
    required this.assetList,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openMediaDetail(context),
      child: SizedBox(
        width: 160,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Hero(
                        tag: 'flashback_${asset.id}',
                        child: AssetEntityImage(
                          asset,
                          isOriginal: false,
                          thumbnailSize: const ThumbnailSize(400, 400),
                          thumbnailFormat: ThumbnailFormat.jpeg,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Year badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          asset.createDateTime.year.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Image count indicator
                    if (assetList.length > 1)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.image,
                                  size: 14,
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  '${assetList.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )),
                      ),
                  ],
                ),
              ),
              // Bottom section
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('MMM d').format(asset.createDateTime),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, size: 18),
                      onPressed: () async {
                        try {
                          final file = await asset.file;
                          if (file != null) {
                            await Share.shareXFiles(
                              [XFile(file.path)],
                              text:
                                  'Memory from ${DateFormat('MMMM d, yyyy').format(asset.createDateTime)}',
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Failed to share: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Share',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openMediaDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaDetailView(
          asset: asset,
          assetList: assetList,
          heroTag: 'flashback_${asset.id}',
        ),
      ),
    );
  }
}
