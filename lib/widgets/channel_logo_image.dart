import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Renders [logo] from a network URL or a `data:image/...;base64,...` data URI.
class ChannelLogoImage extends StatelessWidget {
  const ChannelLogoImage({
    super.key,
    required this.logo,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallback,
  });

  final String? logo;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final w = width ?? 24;
    final h = height ?? 24;
    final fb = fallback ??
        Icon(
          Icons.tv_rounded,
          color: Colors.white24,
          size: (w < h ? w : h),
        );

    if (logo == null || logo!.isEmpty) {
      return _wrap(fb, w, h);
    }

    final s = logo!.trim();
    if (s.startsWith('data:image')) {
      final comma = s.indexOf(',');
      if (comma > 0) {
        try {
          final bytes = base64Decode(s.substring(comma + 1).trim());
          final img = Image.memory(
            bytes,
            width: w,
            height: h,
            fit: fit,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => fb,
          );
          return _wrap(img, w, h);
        } catch (_) {
          return _wrap(fb, w, h);
        }
      }
    }

    final net = CachedNetworkImage(
      imageUrl: s,
      width: w,
      height: h,
      fit: fit,
      placeholder: (_, __) => fb,
      errorWidget: (_, __, ___) => fb,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
    );
    return _wrap(net, w, h);
  }

  Widget _wrap(Widget child, double w, double h) {
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: SizedBox(width: w, height: h, child: child),
      );
    }
    return SizedBox(width: w, height: h, child: child);
  }
}
