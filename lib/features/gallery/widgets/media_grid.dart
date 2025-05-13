import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:reverie/features/gallery/widgets/asset_thumbnail.dart';

class MediaGrid extends StatelessWidget {
  final List<AssetEntity> assets;
  final Function(int) onMediaTap;

  const MediaGrid({
    super.key,
    required this.assets,
    required this.onMediaTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2.0,
        mainAxisSpacing: 2.0,
      ),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];
        return AssetThumbnail(
          asset: asset,
          heroTag: 'flashback_${asset.id}',
          onTap: () => onMediaTap(index),
        );
      },
    );
  }
}
