import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'dart:ui' show ImageFilter;
import '../../core/theme.dart';
import '../../services/playlist_service.dart';
import '../player/player_screen.dart';
import '../player/movie_player_page.dart';
import '../../providers/app_locale_provider.dart';
import '../../l10n/app_strings.dart';

class MovieDetailsScreen extends ConsumerStatefulWidget {
  final List<Channel> allChannels;
  final Channel channel;
  final TmdbMovie? initialMovie;

  const MovieDetailsScreen({
    super.key,
    required this.allChannels,
    required this.channel,
    this.initialMovie,
  });

  @override
  ConsumerState<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends ConsumerState<MovieDetailsScreen> {
  late TmdbMovie? _movie;
  List<TmdbCast> _cast = [];
  List<TmdbMovie> _recommendations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _movie = widget.initialMovie;
    _initData();
  }

  Future<void> _initData() async {
    final tmdb = TmdbService();
    
    // If no initial movie, try to finding it
    if (_movie == null) {
      _movie = await tmdb.findMovie(widget.channel.name);
    }

    if (_movie != null) {
      final results = await Future.wait([
        tmdb.getCredits(_movie!.id),
        tmdb.getRecommendations(_movie!.id),
      ]);
      if (mounted) {
        setState(() {
          _cast = results[0] as List<TmdbCast>;
          _recommendations = results[1] as List<TmdbMovie>;
          _loading = false;
        });
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _play() {
    final uiLocale = ref.read(appLocaleProvider);
    final s = AppStrings(uiLocale);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          final p = Player(configuration: const PlayerConfiguration(title: 'Optic TV Movie'));
          final vc = VideoController(p, configuration: const VideoControllerConfiguration(enableHardwareAcceleration: true));
          p.open(Media(widget.channel.url));
          
          return MoviePlayerPage(
            player: p,
            controller: vc,
            channel: widget.channel,
            uiLocale: uiLocale,
            strings: s,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = ref.watch(favoritesProvider.notifier).isFavorite(widget.channel);
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: Stack(
        children: [
          // Backdrop
          if (_movie?.backdropUrl != null)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: _movie!.backdropUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const SizedBox(),
              ),
            ),
          
          // Gradient Overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                    AppTheme.backgroundBlack,
                    AppTheme.backgroundBlack,
                  ],
                  stops: const [0, 0.4, 0.7, 1],
                ),
              ),
            ),
          ),

          // Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header Space
              SliverToBoxAdapter(child: SizedBox(height: size.height * 0.35)),
              
              // Info Section
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _movie?.title ?? widget.channel.name,
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
                      ),
                      const SizedBox(height: 12),
                      _buildMetaRow(),
                      const SizedBox(height: 24),
                      _buildMainActions(isFavorite),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Overview'),
                      const SizedBox(height: 12),
                      Text(
                        _movie?.overview ?? 'No description available for this content.',
                        style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 15, height: 1.5),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Cast Section
              if (_cast.isNotEmpty) ...[
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildSectionTitle('Top Cast'),
                )),
                SliverToBoxAdapter(child: _buildCastList()),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],

              // Recommendations Section
              if (_recommendations.isNotEmpty) ...[
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildSectionTitle('You Might Also Like'),
                )),
                SliverToBoxAdapter(child: _buildRecommendationsList()),
                const SliverToBoxAdapter(child: SizedBox(height: 60)),
              ],
            ],
          ),

          // Back Button
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            left: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow() {
    return Row(
      children: [
        if (_movie != null) ...[
          const Icon(Icons.star_rounded, color: AppTheme.primaryGold, size: 20),
          const SizedBox(width: 4),
          Text(
            _movie!.rating.toStringAsFixed(1),
            style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
        ],
        if (_movie?.releaseDate != null) ...[
          Text(
            _movie!.releaseDate!.split('-').first,
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
          const SizedBox(width: 16),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text('4K', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildMainActions(bool isFavorite) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _play,
            icon: const Icon(Icons.play_arrow_rounded, size: 28),
            label: const Text('Watch Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFavorite ? Colors.redAccent : Colors.white,
            ),
            onPressed: () {
              ref.read(favoritesProvider.notifier).toggle(widget.channel);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2),
    );
  }

  Widget _buildCastList() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _cast.length,
        itemBuilder: (ctx, i) {
          final c = _cast[i];
          return Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white10,
                  backgroundImage: c.profileUrl != null ? CachedNetworkImageProvider(c.profileUrl!) : null,
                  child: c.profileUrl == null ? const Icon(Icons.person, color: Colors.white24) : null,
                ),
                const SizedBox(height: 8),
                Text(c.name, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                Text(c.character, style: TextStyle(color: Colors.white38, fontSize: 10), textAlign: TextAlign.center),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendationsList() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _recommendations.length,
        itemBuilder: (ctx, i) {
          final m = _recommendations[i];
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 0.68,
                child: CachedNetworkImage(
                  imageUrl: m.posterUrl ?? '',
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: Colors.white10, child: const Icon(Icons.movie, color: Colors.white24)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
