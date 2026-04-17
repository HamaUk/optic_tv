import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class SubtitleResult {
  final String id;
  final String language;
  final String fileName;
  final String? downloadUrl;

  SubtitleResult({
    required this.id,
    required this.language,
    required this.fileName,
    this.downloadUrl,
  });
}

class SubtitleService {
  /// TODO: Replace with your actual OpenSubtitles.com API Key
  static const String _apiKey = 'API_KEY_HERE';
  static const String _baseUrl = 'https://api.opensubtitles.com/api/v1';
  
  /// Mandatory User-Agent as per documentation
  static const String _userAgent = 'OpticTV v1.0';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    headers: {
      'Api-Key': _apiKey,
      'Content-Type': 'application/json',
      'User-Agent': _userAgent,
    },
  ));

  String? _token;

  bool get hasApiKey => _apiKey != 'API_KEY_HERE' && _apiKey.isNotEmpty;

  /// Authenticate with OpenSubtitles to increase download limits.
  /// If credentials are null, we continue as a guest (5 downloads/day limit).
  Future<bool> login({String? username, String? password}) async {
    if (!hasApiKey) return false;
    if (username == null || password == null) return true; // Guest mode

    try {
      final res = await _dio.post('/login', data: {
        'username': username,
        'password': password,
      });
      _token = res.data['token'] as String?;
      if (_token != null) {
        _dio.options.headers['Authorization'] = 'Bearer $_token';
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Subtitle login error: $e');
      return false;
    }
  }

  /// Search for subtitles using IMDb ID or raw title.
  Future<List<SubtitleResult>> search({String? imdbId, String? query}) async {
    if (!hasApiKey) return [];

    try {
      final queryParams = <String, dynamic>{
        'languages': 'en,ku', // English and Kurdish
      };

      if (imdbId != null) {
        // Strip 'tt' prefix if present
        queryParams['imdb_id'] = imdbId.replaceAll('tt', '');
      } else if (query != null) {
        queryParams['query'] = query;
      } else {
        return [];
      }

      final res = await _dio.get('/subtitles', queryParameters: queryParams);
      final data = res.data['data'] as List?;
      if (data == null) return [];

      return data.map((item) {
        final attr = item['attributes'];
        return SubtitleResult(
          id: item['id'].toString(),
          language: attr['language'] ?? 'unknown',
          fileName: attr['release'] ?? 'Subtitle',
        );
      }).toList();
    } catch (e) {
      debugPrint('Subtitle search error: $e');
      return [];
    }
  }

  /// Get the actual download URL for a subtitle file.
  Future<String?> getDownloadUrl(String subtitleId) async {
    if (!hasApiKey) return null;

    try {
      final res = await _dio.post('/download', data: {
        'file_id': int.tryParse(subtitleId),
        'sub_format': 'srt',
      });
      return res.data['link'] as String?;
    } catch (e) {
      debugPrint('Subtitle download error: $e');
      return null;
    }
  }
}
