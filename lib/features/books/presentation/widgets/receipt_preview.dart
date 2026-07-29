import 'dart:convert';

import 'package:flutter/material.dart';

class ReceiptPreview extends StatelessWidget {
  const ReceiptPreview({
    super.key,
    this.base64Data,
    this.fit = BoxFit.cover,
  });

  final String? base64Data;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final fallback = _FallbackPreview(theme: Theme.of(context));

    if (base64Data == null || base64Data!.isEmpty) {
      return fallback;
    }

    final data = base64Data!;

    try {
      final trimmed = data.contains(',') ? data.split(',').last : data;
      final bytes = base64Decode(trimmed);
      // Downsample: decode the bitmap at (roughly) the size it's displayed at
      // instead of full resolution, to save memory and improve performance.
      return LayoutBuilder(
        builder: (context, constraints) {
          final dpr = MediaQuery.of(context).devicePixelRatio;
          final cacheWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
              ? (constraints.maxWidth * dpr).round()
              : null;
          return Image.memory(
            bytes,
            fit: fit,
            cacheWidth: cacheWidth,
            filterQuality: FilterQuality.low,
            errorBuilder: (_, __, ___) => fallback,
          );
        },
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to decode receipt image: $error\n$stackTrace');

      if (data.startsWith('http')) {
        return Image.network(
          data,
          fit: fit,
          errorBuilder: (_, __, ___) => fallback,
        );
      }

      return fallback;
    }
  }
}

class _FallbackPreview extends StatelessWidget {
  const _FallbackPreview({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.colorScheme.surfaceVariant,
      alignment: Alignment.center,
      child: Icon(
        Icons.broken_image_outlined,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
