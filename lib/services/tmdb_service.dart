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
  Future<TmdbMovie?> findMovie(String title, {bool fast = true}) async {
    if (!isConfigured) return null;
    
    // Retry logic for rate limiting
    int retries = 0;
    while (retries < 3) {
      try {
        // 1. Extract year if it exists in format (2024) or [2024]
        String? year;
        final yearMatch = RegExp(r'(\d{4})').firstMatch(title);
        if (yearMatch != null) {
          year = yearMatch.group(1);
        }

        // 2. Clean title of technical tags, extensions, and trailing years
        String cleanTitle = title
            .replaceAll(RegExp(r'\.(mp4|mkv|avi|ts|mov|m3u8)$', caseSensitive: false), '')
            .replaceAll(RegExp(r'\[.*?\]'), '')
            .replaceAll(RegExp(r'\(.*?\)'), '')
            .replaceAll(RegExp(r'(1080p|720p|4k|uhd|bluray|h264|h265|web-dl|x264|x265)', caseSensitive: false), ' ')
            .replaceAll('_', ' ')
            .replaceAll('.', ' ');
        
        // Specifically remove " - 2026" or " 2026" from the query if we extracted a year
        if (year != null) {
          cleanTitle = cleanTitle.replaceAll(year, '').replaceAll(' - ', ' ');
        }
        
        cleanTitle = cleanTitle.replaceAll(RegExp(r'\s+'), ' ').trim();

        // 3. Search TMDB
        final res = await _dio.get('/search/movie', queryParameters: {
          'query': cleanTitle,
          if (year != null) 'primary_release_year': year,
        });

        final resultsList = res.data['results'] as List?;
        if (resultsList == null || resultsList.isEmpty) return null;

        // 4. Find the BEST match
        List<Map<String, dynamic>> candidates = resultsList.cast<Map<String, dynamic>>();
        candidates.sort((a, b) {
          final aTitle = (a['title'] as String? ?? '').toLowerCase();
          final bTitle = (b['title'] as String? ?? '').toLowerCase();
          final target = cleanTitle.toLowerCase();

          final aExact = aTitle == target ? 1 : 0;
          final bExact = bTitle == target ? 1 : 0;
          if (aExact != bExact) return bExact.compareTo(aExact);

          final aPop = (a['popularity'] as num? ?? 0.0).toDouble();
          final bPop = (b['popularity'] as num? ?? 0.0).toDouble();
          return bPop.compareTo(aPop);
        });

        final best = candidates.first;
        final movie = TmdbMovie.fromJson(best, _imageBaseUrl);
        
        // Only fetch IMDb ID if not in "fast" mode (bulk import uses fast mode)
        if (!fast) {
          final imdbId = await fetchImdbId(movie.id);
          return movie.copyWith(imdbId: imdbId);
        }
        
        return movie;
      } catch (e) {
        if (e is DioException && e.response?.statusCode == 429) {
          // Rate limited - wait and retry
          retries++;
          await Future.delayed(Duration(seconds: retries));
          continue;
        }
        return null;
      }
    }
    return null;
  }

  /// Get the IMDb ID for a given TMDB movie ID.
  Future<String?> fetchImdbId(int movieId) async {
    try {
      final res = await _dio.get('/movie/$movieId/external_ids');
      return res.data['imdb_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Get recommendations for a specific movie ID.
  Future<List<TmdbMovie>> getRecommendations(int movieId) async {
    if (!isConfigured) return [];
    try {
      final res = await _dio.get('/movie/$movieId/recommendations');
      final results = res.data['results'] as List?;
      if (results == null) return [];

      return results
          .map((m) => TmdbMovie.fromJson(m as Map<String, dynamic>, _imageBaseUrl))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Get cast and crew for a specific movie ID.
  Future<List<TmdbCast>> getCredits(int movieId) async {
    if (!isConfigured) return [];
    try {
      final res = await _dio.get('/movie/$movieId/credits');
      final cast = res.data['cast'] as List?;
      if (cast == null) return [];

      return cast
          .take(10) // Only top 10 cast members
          .map((c) => TmdbCast.fromJson(c as Map<String, dynamic>, _imageBaseUrl))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetch the official YouTube trailer key for a movie.
  /// Returns the YouTube video key (e.g. "dQw4w9WgXcQ") or null.
  Future<TmdbVideo?> fetchTrailer(int movieId) async {
    if (!isConfigured) return null;
    try {
      final res = await _dio.get('/movie/$movieId/videos');
      final results = res.data['results'] as List?;
      if (results == null || results.isEmpty) return null;

      // Prefer official trailers first, then teasers
      final videos = results.cast<Map<String, dynamic>>();
      final trailers = videos.where((v) =>
          v['site'] == 'YouTube' &&
          (v['type'] == 'Trailer' || v['type'] == 'Teaser') &&
          v['official'] == true,
      ).toList();

      // Fall back to any YouTube video if no official trailer
      final candidate = trailers.isNotEmpty
          ? trailers.first
          : videos.firstWhere(
              (v) => v['site'] == 'YouTube',
              orElse: () => {},
            );

      if (candidate.isEmpty) return null;
      return TmdbVideo.fromJson(candidate);
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
  final String? backdropUrl;
  final double rating;
  final String? releaseDate;
  final String? imdbId;

  TmdbMovie({
    required this.id,
    required this.title,
    required this.overview,
    this.posterUrl,
    this.backdropUrl,
    required this.rating,
    this.releaseDate,
    this.imdbId,
  });

  TmdbMovie copyWith({
    int? id,
    String? title,
    String? overview,
    String? posterUrl,
    String? backdropUrl,
    double? rating,
    String? releaseDate,
    String? imdbId,
  }) {
    return TmdbMovie(
      id: id ?? this.id,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      rating: rating ?? this.rating,
      releaseDate: releaseDate ?? this.releaseDate,
      imdbId: imdbId ?? this.imdbId,
    );
  }

  factory TmdbMovie.fromJson(Map<String, dynamic> json, String imageBase) {
    final posterPath = json['poster_path'] as String?;
    final backdropPath = json['backdrop_path'] as String?;
    return TmdbMovie(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      overview: json['overview'] as String? ?? 'No description available.',
      posterUrl: posterPath != null ? '$imageBase$posterPath' : null,
      backdropUrl: backdropPath != null ? '$imageBase$backdropPath' : null,
      rating: (json['vote_average'] as num? ?? 0.0).toDouble(),
      releaseDate: json['release_date'] as String?,
    );
  }
}

class TmdbCast {
  final String name;
  final String character;
  final String? profileUrl;

  TmdbCast({
    required this.name,
    required this.character,
    this.profileUrl,
  });

  factory TmdbCast.fromJson(Map<String, dynamic> json, String imageBase) {
    final path = json['profile_path'] as String?;
    return TmdbCast(
      name: json['name'] as String? ?? '',
      character: json['character'] as String? ?? '',
      profileUrl: path != null ? '$imageBase$path' : null,
    );
  }
}

/// Represents a YouTube video (trailer / teaser) linked to a TMDB movie.
class TmdbVideo {
  final String key;
  final String name;
  final String type;

  /// Full YouTube embed URL: https://www.youtube.com/embed/{key}
  String get youtubeUrl => 'https://www.youtube.com/embed/$key?autoplay=1&mute=1&loop=1&playlist=$key&controls=0&showinfo=0&rel=0&modestbranding=1';

  /// Thumbnail image URL for the video.
  String get thumbnailUrl => 'https://img.youtube.com/vi/$key/maxresdefault.jpg';

  const TmdbVideo({
    required this.key,
    required this.name,
    required this.type,
  });

  factory TmdbVideo.fromJson(Map<String, dynamic> json) {
    return TmdbVideo(
      key: json['key'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
    );
  }
}

