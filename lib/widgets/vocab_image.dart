import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'vocab_image_local.dart'
    if (dart.library.io) 'vocab_image_local_io.dart' as local_image;

class VocabImage extends StatelessWidget {
  const VocabImage({
    required this.fallback,
    super.key,
    this.localImagePath,
    this.imageUrl,
    this.memoryBytes,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
  });

  final String? localImagePath;
  final String? imageUrl;
  final Uint8List? memoryBytes;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget fallback;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final child = _buildChild();
    if (borderRadius == null) {
      return child;
    }
    return ClipRRect(
      borderRadius: borderRadius!,
      child: child,
    );
  }

  Widget _buildChild() {
    if (memoryBytes != null && memoryBytes!.isNotEmpty) {
      return Image.memory(
        memoryBytes!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    final localPath = localImagePath?.trim();
    if (localPath != null && localPath.isNotEmpty) {
      return local_image.buildLocalVocabImage(
        path: localPath,
        width: width,
        height: height,
        fit: fit,
        fallback: fallback,
      );
    }

    final remoteUrl = imageUrl?.trim();
    if (remoteUrl != null && remoteUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: remoteUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => placeholder ?? fallback,
        errorWidget: (context, url, error) => fallback,
      );
    }

    return fallback;
  }
}
