import 'package:dio/dio.dart';

/// The Movie Database (TMDB) API Service.
/// Get your free API key at: https://www.themoviedb.org/documentation/api
class TmdbService {
  /// ⚠️ TMDB API Key (v3)
  static const String _apiKey = '80ab7e17810930a03bcaeba6c98aa656';
  /// 🔑 TMDB Read Access Token (v4)
  static const String _readAccessToken = 'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI4MGFiN2UxNzgxMDkzMGEwM2JjYWViYTZjOThhYTY1NiIsIm5iZiI6MTc3NTkzNTI1NS42ODksInN1YiI6IjY5ZGE5ZjE3OTA4MTdjYjk3MzAyNmRjNSIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.DEgqhdxcwvDTo_a0gL6514ZdZX7Rt_3rB7zbRHDsiQM';
  
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    headers: {
      'Authorization': 'Bearer $_readAccessToken',
      'accept': 'application/json',
    },
  ));

  bool get isConfigured => _apiKey != 'API_KEY_HERE' && _apiKey.isNotEmpty;

  /// Search for a movie by name and return details of the best match.
  Future<TmdbMovie?> findMovie(String title) async {
    if (!isConfigured) return null;
    try {
      // Clean title: remove year in brackets or common IPTV tags
      final cleanTitle = title
          .replaceAll(RegExp(r'\[.*?\]'), '')
          .replaceAll(RegExp(r'\(.*?\)'), '')
          .trim();

      final res = await _dio.get('/search/movie', queryParameters: {
        'query': cleanTitle,
      });

      final results = res.data['results'] as List?;
      if (results == null || results.isEmpty) return null;

      final first = results.first as Map<String, dynamic>;
      return TmdbMovie.fromJson(first, _imageBaseUrl);
    } catch (_) {
      return null;
    }
  }
}

class TmdbMovie {
  final int id;
  final String title;
  final String overview;
  final String? posterUrl;
  final double rating;
  final String? releaseDate;

  TmdbMovie({
    required this.id,
    required this.title,
    required this.overview,
    this.posterUrl,
    required this.rating,
    this.releaseDate,
  });

  factory TmdbMovie.fromJson(Map<String, dynamic> json, String imageBase) {
    final posterPath = json['poster_path'] as String?;
    return TmdbMovie(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      overview: json['overview'] as String? ?? 'No description available.',
      posterUrl: posterPath != null ? '$imageBase$posterPath' : null,
      rating: (json['vote_average'] as num? ?? 0.0).toDouble(),
      releaseDate: json['release_date'] as String?,
    );
  }
}
