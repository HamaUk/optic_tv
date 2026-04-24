import 'dart:async';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

/// Extracted palette from an image URL.
class ImagePalette {
  final Color dominant;
  final Color vibrant;
  final Color muted;
  final Color darkVibrant;

  const ImagePalette({
    required this.dominant,
    required this.vibrant,
    required this.muted,
    required this.darkVibrant,
  });

  /// Fallback static palette when no image is available.
  static const ImagePalette fallback = ImagePalette(
    dominant: Color(0xFFD32F2F),
    vibrant: Color(0xFFEF5350),
    muted: Color(0xFF8B0000),
    darkVibrant: Color(0xFF7F0000),
  );

  /// Best "accent" color to use for borders / highlights.
  Color get accent => vibrant != Colors.transparent ? vibrant : dominant;

  /// A subtle glow for box-shadows.
  Color get glow => accent.withOpacity(0.45);
}

/// A lightweight, self-caching service for extracting colour palettes from
/// remote image URLs.  Wrap it in a [Provider] or use it as a singleton.
class PaletteService {
  PaletteService._();
  static final PaletteService instance = PaletteService._();

  final Map<String, ImagePalette> _cache = {};
  final Map<String, Future<ImagePalette>> _inFlight = {};

  /// Returns the cached palette immediately, or starts extraction in the
  /// background.  Call [generate] on your widget's [initState] and then
  /// rebuild when the future completes.
  Future<ImagePalette> generate(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return ImagePalette.fallback;

    if (_cache.containsKey(imageUrl)) return _cache[imageUrl]!;
    if (_inFlight.containsKey(imageUrl)) return _inFlight[imageUrl]!;

    final completer = Completer<ImagePalette>();
    _inFlight[imageUrl] = completer.future;

    try {
      final generator = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        size: const Size(100, 100), // Down-sample for speed
        maximumColorCount: 16,
        timeout: const Duration(seconds: 6),
      );

      Color resolve(Color? c) => c ?? Colors.transparent;

      final palette = ImagePalette(
        dominant: resolve(generator.dominantColor?.color),
        vibrant: resolve(generator.vibrantColor?.color ?? generator.dominantColor?.color),
        muted: resolve(generator.mutedColor?.color ?? generator.darkVibrantColor?.color),
        darkVibrant: resolve(generator.darkVibrantColor?.color ?? generator.dominantColor?.color),
      );

      _cache[imageUrl] = palette;
      completer.complete(palette);
      _inFlight.remove(imageUrl);
      return palette;
    } catch (_) {
      _cache[imageUrl] = ImagePalette.fallback;
      completer.complete(ImagePalette.fallback);
      _inFlight.remove(imageUrl);
      return ImagePalette.fallback;
    }
  }

  /// Synchronously return cached palette if available, else [null].
  ImagePalette? getCached(String? imageUrl) {
    if (imageUrl == null) return null;
    return _cache[imageUrl];
  }

  void clearCache() => _cache.clear();
}
