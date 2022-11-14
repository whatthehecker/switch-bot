import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Widget that displays an image from the given byte data or shows that no
/// image was given.
class ImageDisplayWidget extends StatelessWidget {
  final double aspectRatio;
  final Uint8List? imageBytes;

  const ImageDisplayWidget(
    this.imageBytes, {
    this.aspectRatio = 16.0 / 9.0,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageBytes == null) {
      return AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            border: Border.all(),
          ),
          child: const Center(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.video_camera_back_outlined),
                Text('No video connected.'),
              ],
            ),
          ),
        ),
      );
    }

    return Image.memory(
      imageBytes!,
      gaplessPlayback: true,
      isAntiAlias: false,
      filterQuality: FilterQuality.none,
    );
  }
}
