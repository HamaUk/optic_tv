import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../services/playlist_service.dart';

/// A utility to automatically scrape and resolve live stream tokens
/// from web player pages.
class StreamResolver {
  /// Checks if a URL needs to be resolved (ends with |scrape=true or %7Cscrape=true)
  /// and returns the raw stream URL. Otherwise, returns the original URL.
  static Future<String> resolveIfNeeded(String url, {String? userAgent}) async {
    // 1. Check for stalker portal MAC URLs
    if (url.contains('mac=') && url.contains('live.php')) {
      try {
        var currentUrl = url;
        var redirects = 0;
        final client = http.Client();
        while (redirects < 5) {
          final request = http.Request('GET', Uri.parse(currentUrl))..followRedirects = false;
          request.headers['User-Agent'] = userAgent ?? 'SmartIPTV';
          final response = await client.send(request);
          if (response.statusCode >= 300 && response.statusCode < 400) {
            final location = response.headers['location'];
            if (location != null) {
              if (location.startsWith('http')) {
                currentUrl = location;
              } else if (location.startsWith('//')) {
                currentUrl = 'http:$location';
              } else if (location.startsWith('/')) {
                final uri = Uri.parse(currentUrl);
                currentUrl = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}$location';
              } else {
                 final uri = Uri.parse(currentUrl);
                 final path = uri.path.substring(0, uri.path.lastIndexOf('/') + 1);
                 currentUrl = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}$path$location';
              }
              redirects++;
              response.stream.drain();
            } else {
              response.stream.drain();
              break;
            }
          } else {
            response.stream.drain();
            break;
          }
        }
        client.close();
        if (currentUrl != url) {
          if (url.contains('extension=m3u8') && !currentUrl.contains('m3u8')) {
            return '$currentUrl#.m3u8';
          }
          return currentUrl;
        }
      } catch (e) {
        print('StreamResolver Stalker Error: $e');
      }
    }

    if (!url.endsWith('|scrape=true') && !url.endsWith('%7Cscrape=true')) {
      return url;
    }

    final decryptedUrl = Channel.decrypt(url);
    final targetUrl = decryptedUrl.replaceAll('|scrape=true', '').replaceAll('%7Cscrape=true', '');
    try {
      final res = await http.get(
        Uri.parse(targetUrl),
        headers: {
          'User-Agent': userAgent ?? 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
        },
      );

      if (res.statusCode != 200) {
        return targetUrl; // Fallback
      }

      final body = res.body;

      // 1. Check for standard m3u8/mpd links in plain text
      final directMatch = RegExp(r'''(https?://[^\s'"]+\.(?:m3u8|mpd)[^\s'"]*)''').firstMatch(body);
      if (directMatch != null) {
        return directMatch.group(1)!;
      }

      // 2. Check for base64 encoded strings (like atob("..."))
      final atobRegExp = RegExp(r'''atob\(['"]([^'"]+)['"]\)''');
      final matches = atobRegExp.allMatches(body);
      for (final match in matches) {
        try {
          final b64 = match.group(1)!;
          final decoded = utf8.decode(base64.decode(b64));
          final streamMatch = RegExp(r'''(https?://[^\s'"]+\.(?:m3u8|mpd)[^\s'"]*)''').firstMatch(decoded);
          if (streamMatch != null) {
            return streamMatch.group(1)!;
          }
        } catch (_) {
          // Ignore decoding errors
        }
      }

      // 3. Check for iframe embeds
      final iframeRegExp = RegExp(r'''<iframe[^>]+src=['"]([^'"]+)['"]''', caseSensitive: false);
      final iframeMatch = iframeRegExp.firstMatch(body);
      if (iframeMatch != null) {
        var iframeSrc = iframeMatch.group(1)!;
        if (iframeSrc.startsWith('//')) {
          iframeSrc = 'https:$iframeSrc';
        } else if (iframeSrc.startsWith('/')) {
          final uri = Uri.parse(targetUrl);
          iframeSrc = '${uri.scheme}://${uri.host}$iframeSrc';
        }
        
        // Recursively scrape the iframe
        final iframeRes = await http.get(
          Uri.parse(iframeSrc),
          headers: {
            'User-Agent': userAgent ?? 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': targetUrl,
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
          },
        );
        if (iframeRes.statusCode == 200) {
          final iframeBody = iframeRes.body;
          
          final iframeDirectMatch = RegExp(r'''(https?://[^\s'"]+\.(?:m3u8|mpd)[^\s'"]*)''').firstMatch(iframeBody);
          if (iframeDirectMatch != null) return iframeDirectMatch.group(1)!;
          
          final iframeMatches = atobRegExp.allMatches(iframeBody);
          for (final match in iframeMatches) {
            try {
              final b64 = match.group(1)!;
              final decoded = utf8.decode(base64.decode(b64));
              final streamMatch = RegExp(r'''(https?://[^\s'"]+\.(?:m3u8|mpd)[^\s'"]*)''').firstMatch(decoded);
              if (streamMatch != null) return streamMatch.group(1)!;
            } catch (e) { debugPrint('Caught error in stream_resolver.dart: $e'); }
          }
        }
      }

      // 4. Just general base64 matching (a bit risky, so restricted to typical lengths)
      // Usually not needed if atob or plain text works.

    } catch (e) {
      print('StreamResolver Error: $e');
    }

    return targetUrl; // Fallback to original
  }
}
