import 'package:dio/dio.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  KurdFilm API Service — mirrors apk2url-main/lib/services/api_service.dart
//  Base: https://app.kurdfilm.krd/api
// ─────────────────────────────────────────────────────────────────────────────

class KurdfilmMovie {
  final int id;
  final String title;
  final String image;
  final double rating;
  final String releaseDate;
  final String type;

  const KurdfilmMovie({
    required this.id,
    required this.title,
    required this.image,
    required this.rating,
    required this.releaseDate,
    required this.type,
  });

  factory KurdfilmMovie.fromJson(Map<String, dynamic> json) {
    return KurdfilmMovie(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      image: json['image'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      releaseDate: json['releasedate'] as String? ?? '',
      type: json['type'] as String? ?? '',
    );
  }
}

class KurdfilmServer {
  final String name;
  final String url;

  const KurdfilmServer({required this.name, required this.url});

  factory KurdfilmServer.fromJson(Map<String, dynamic> json) {
    return KurdfilmServer(
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  /// Extract the real video URL from kurdfilm proxy links
  String get extractedUrl {
    if (url.contains('kurdfilm.krd/play-kf')) {
      try {
        final uri = Uri.parse(url);
        final urlParam = uri.queryParameters['url'];
        if (urlParam != null) return Uri.decodeComponent(urlParam);
      } catch (_) {}
    }
    return url;
  }
}

class KurdfilmDetail {
  final int id;
  final String title;
  final String description;
  final String director;
  final List<String> cast;
  final String duration;
  final double rating;
  final String releaseDate;
  final List<KurdfilmServer> servers;
  final String? embedUrl;

  const KurdfilmDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.director,
    required this.cast,
    required this.duration,
    required this.rating,
    required this.releaseDate,
    required this.servers,
    this.embedUrl,
  });

  factory KurdfilmDetail.fromJson(Map<String, dynamic> json) {
    final castRaw = json['cast'];
    final castList = castRaw is List
        ? castRaw.map((e) => e.toString()).toList()
        : <String>[];

    final serversRaw = json['servers'];
    final serversList = serversRaw is List
        ? serversRaw
            .map((s) => KurdfilmServer.fromJson(s as Map<String, dynamic>))
            .toList()
        : <KurdfilmServer>[];

    return KurdfilmDetail(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      director: json['director'] as String? ?? '',
      cast: castList,
      duration: json['duration'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      releaseDate: json['releasedate'] as String? ?? '',
      servers: serversList,
      embedUrl: json['embed_url'] as String? ?? json['video_url'] as String?,
    );
  }
}

class KurdfilmService {
  static const _baseUrl = 'https://app.kurdfilm.krd/api';
  final _dio = Dio(BaseOptions(
    connectTimeout: Duration(seconds: 15),
    receiveTimeout: Duration(seconds: 15),
    headers: {'Accept': 'application/json'},
  ));

  Future<List<KurdfilmMovie>> getLatestMovies({int page = 1}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/titles',
        queryParameters: {'kind': 'movie', 'sort': 'newest', 'per_page': 21, 'page': page},
      );
      if (response.statusCode != 200 || response.data == null) return [];
      final data = response.data!['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => KurdfilmMovie.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<KurdfilmDetail?> getMovieDetail(int movieId) async {
    final endpoints = [
      '$_baseUrl/movies/$movieId',
      '$_baseUrl/titles/$movieId',
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await _dio.get<Map<String, dynamic>>(endpoint);
        if (response.statusCode == 200 && response.data != null) {
          final json = response.data!;
          final data = json['data'] as Map<String, dynamic>? ?? json;
          return KurdfilmDetail.fromJson(data);
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }
}
