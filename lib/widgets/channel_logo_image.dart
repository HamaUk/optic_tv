import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Renders [logo] from a network URL or a `data:image/...;base64,...` data URI.
class ChannelLogoImage extends StatelessWidget {
  const ChannelLogoImage({
    super.key,
    required this.logo,
    this.channelName,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.fallback,
    this.httpHeaders,
  });

  final String? logo;
  final String? channelName;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? fallback;
  final Map<String, String>? httpHeaders;

  @override
  Widget build(BuildContext context) {
    final w = width ?? 24;
    final h = height ?? 24;
    final defaultSize = w < h ? w : h;
    final Widget fb = fallback ??
        (channelName != null && channelName!.trim().isNotEmpty
            ? ChannelLogoPlaceholder(name: channelName!, size: defaultSize)
            : Container(
                width: w,
                height: h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.12),
                      Colors.white.withOpacity(0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Icon(
                  Icons.tv_rounded,
                  color: Colors.white24,
                  size: defaultSize * 0.5,
                ),
              ));

    if (logo == null || logo!.isEmpty) {
      return _wrap(fb, w, h);
    }

    var s = logo!.trim();
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
      return _wrap(fb, w, h);
    }

    // Auto-fix relative and missing protocol URLs
    if (s.startsWith('//')) {
      s = 'https:$s';
    } else if (s.startsWith('www.')) {
      s = 'https://$s';
    }

    if (!s.startsWith('http://') && !s.startsWith('https://')) {
      return _wrap(fb, w, h);
    }

    // URL encoding for spaces and special characters
    try {
      Uri.parse(s);
    } catch (_) {
      try {
        s = Uri.encodeFull(s);
      } catch (_) {
        return _wrap(fb, w, h);
      }
    }

    final Map<String, String> headers = httpHeaders ?? {'User-Agent': 'SmartIPTV'};
    final net = CachedNetworkImage(
      imageUrl: s,
      width: w,
      height: h,
      fit: fit,
      placeholder: (_, __) => fb,
      errorWidget: (_, __, ___) => Image.network(
        s,
        width: w,
        height: h,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => fb,
      ),
      httpHeaders: headers,
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

/// A gorgeous, colored gradient avatar placeholder for channels without a logo.
class ChannelLogoPlaceholder extends StatelessWidget {
  final String name;
  final double size;

  const ChannelLogoPlaceholder({
    super.key,
    required this.name,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final int hash = name.hashCode;
    
    // Premium HSL color palettes (complementary premium gradients)
    final List<List<Color>> gradients = [
      [const Color(0xFFFF8C00), const Color(0xFFFF3030)], // Warm Gold/Red
      [const Color(0xFF00C6FF), const Color(0xFF0072FF)], // Electric Blue
      [const Color(0xFF7F00FF), const Color(0xFFE100FF)], // Deep Purple
      [const Color(0xFF00FF87), const Color(0xFF60EFFF)], // Neon Mint/Teal
      [const Color(0xFFF24E1E), const Color(0xFFFF7262)], // Coral/Sunset
      [const Color(0xFF8A2387), const Color(0xFFE94057), const Color(0xFFF27121)], // Cosmic
      [const Color(0xFF11998e), const Color(0xFF38ef7d)], // Emerald
      [const Color(0xFF1f4068), const Color(0xFF162447)], // Deep Slate
    ];
    
    final gradient = gradients[hash.abs() % gradients.length];
    
    // Get initials (up to 2 characters)
    String initials = "";
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isNotEmpty) {
      if (words.length == 1) {
        if (words[0].length >= 2) {
          initials = words[0].substring(0, 2).toUpperCase();
        } else if (words[0].isNotEmpty) {
          initials = words[0].substring(0, 1).toUpperCase();
        }
      } else {
        final first = words[0].isNotEmpty ? words[0].substring(0, 1) : "";
        final second = words[words.length - 1].isNotEmpty ? words[words.length - 1].substring(0, 1) : "";
        initials = (first + second).toUpperCase();
      }
    }
    
    if (initials.isEmpty) initials = "?";

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.38,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(1, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
