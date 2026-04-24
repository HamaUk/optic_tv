import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../services/palette_service.dart';
import '../../services/playlist_service.dart';
import '../../services/tmdb_service.dart';
import '../../providers/channel_library_provider.dart';
import '../../providers/app_locale_provider.dart';
import '../../l10n/app_strings.dart';
import '../player/movie_player_page.dart';

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

class _MovieDetailsScreenState extends ConsumerState<MovieDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TmdbMovie? _movie;
  List<TmdbCast> _cast = [];
  List<TmdbMovie> _recommendations = [];
  TmdbVideo? _trailer;
  bool _loading = true;

  // Dynamic palette state
  ImagePalette _palette = ImagePalette.fallback;

  // Shimmer animation for the glassmorphic trailer card
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnim;

  // Trailer card state
  bool _trailerHovered = false;

  @override
  void initState() {
    super.initState();
    _movie = widget.initialMovie;

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _shimmerAnim = CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut);

    _initData();
  }

  Future<void> _initData() async {
    final tmdb = TmdbService();

    // Find movie if not provided
    if (_movie == null) {
      _movie = await tmdb.findMovie(widget.channel.name);
    }

    // Extract palette from poster/backdrop immediately when we have a URL
    final imageUrl = _movie?.posterUrl ?? widget.channel.logo;
    if (imageUrl != null) {
      final palette = await PaletteService.instance.generate(imageUrl);
      if (mounted) setState(() => _palette = palette);
    }

    if (_movie != null) {
      // Fetch all enrichment data in parallel
      final results = await Future.wait([
        tmdb.getCredits(_movie!.id),
        tmdb.getRecommendations(_movie!.id),
        tmdb.fetchTrailer(_movie!.id),
      ]);
      if (mounted) {
        setState(() {
          _cast = results[0] as List<TmdbCast>;
          _recommendations = results[1] as List<TmdbMovie>;
          _trailer = results[2] as TmdbVideo?;
          _loading = false;
        });
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _play() {
    HapticFeedback.mediumImpact();
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

  Future<void> _openTrailer() async {
    HapticFeedback.lightImpact();
    final trailer = _trailer;
    if (trailer == null) return;
    final url = Uri.parse('https://www.youtube.com/watch?v=${trailer.key}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = ref.watch(favoritesProvider.notifier).isFavorite(widget.channel);
    final size = MediaQuery.sizeOf(context);
    final accent = _palette.accent;
    final glowColor = accent.withOpacity(0.5);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: Stack(
        children: [
          // ── Backdrop image ─────────────────────────────────────────────────
          if (_movie?.backdropUrl != null || widget.channel.backdrop != null)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: _movie?.backdropUrl ?? widget.channel.backdrop!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const SizedBox(),
              ),
            ),

          // ── Dynamic palette ambient glow (top) ────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeInOutCubic,
              height: size.height * 0.55,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.1,
                  colors: [
                    glowColor.withOpacity(0.25),
                    glowColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // ── Main gradient overlay ──────────────────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.25),
                    Colors.black.withOpacity(0.65),
                    AppTheme.backgroundBlack,
                    AppTheme.backgroundBlack,
                  ],
                  stops: const [0, 0.4, 0.68, 1],
                ),
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────────
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Space for backdrop
              SliverToBoxAdapter(child: SizedBox(height: size.height * 0.32)),

              // ── Trailer card (Netflix style) ─────────────────────────────
              if (_trailer != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildTrailerCard(accent),
                  ),
                ),
              if (_trailer != null)
                const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── Movie info ───────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        (_movie?.title ?? widget.channel.name).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildNetflixMetaRow(accent),
                      const SizedBox(height: 28),
                      _buildNetflixPlayButton(isFavorite, accent),
                      const SizedBox(height: 36),
                      _buildSectionTitle('Overview', accent),
                      const SizedBox(height: 12),
                      Text(
                        _movie?.overview ??
                            widget.channel.description ??
                            'Cinematic details for this title are being retrieved. Enjoy the high-quality stream.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                          height: 1.6,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // ── Cast ─────────────────────────────────────────────────────
              if (_cast.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildSectionTitle('Top Cast', accent),
                  ),
                ),
                SliverToBoxAdapter(child: _buildCastList()),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],

              // ── Recommendations ──────────────────────────────────────────
              if (_recommendations.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildSectionTitle('You Might Also Like', accent),
                  ),
                ),
                SliverToBoxAdapter(child: _buildRecommendationsList()),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ] else
                const SliverToBoxAdapter(child: SizedBox(height: 60)),
            ],
          ),

          // ── Back button ────────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            left: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: Colors.black.withOpacity(0.35),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Trailer card with Netflix‐style thumbnail + play overlay ─────────────

  Widget _buildTrailerCard(Color accent) {
    final trailer = _trailer!;
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (context, _) {
        return MouseRegion(
          onEnter: (_) => setState(() => _trailerHovered = true),
          onExit: (_) => setState(() => _trailerHovered = false),
          child: GestureDetector(
            onTap: _openTrailer,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              transform: Matrix4.identity()
                ..scale(_trailerHovered ? 1.025 : 1.0),
              transformAlignment: Alignment.center,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(_trailerHovered ? 0.5 : 0.25),
                    blurRadius: _trailerHovered ? 32 : 16,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // ── Trailer thumbnail ──────────────────────────────────
                    CachedNetworkImage(
                      imageUrl: trailer.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.black,
                        child: Center(
                          child: Icon(Icons.movie_outlined, color: accent.withOpacity(0.3), size: 48),
                        ),
                      ),
                    ),

                    // ── Frosty glassmorphic overlay ────────────────────────
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: _trailerHovered ? 0 : 1.5,
                          sigmaY: _trailerHovered ? 0 : 1.5,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.black.withOpacity(0.25),
                                Colors.black.withOpacity(0.60),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Shimmer sweep (frosty effect) ──────────────────────
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.08 + (_shimmerAnim.value * 0.06),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(
                                -1.5 + (_shimmerAnim.value * 3.0),
                                -1.5,
                              ),
                              end: Alignment(
                                -1.5 + (_shimmerAnim.value * 3.0) + 0.6,
                                1.5,
                              ),
                              colors: [
                                Colors.white.withOpacity(0),
                                Colors.white.withOpacity(0.7),
                                Colors.white.withOpacity(0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── TRAILER badge (top-left) ───────────────────────────
                    Positioned(
                      top: 14,
                      left: 14,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: accent.withOpacity(0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.smart_display_rounded, color: accent, size: 14),
                                const SizedBox(width: 5),
                                Text(
                                  'OFFICIAL TRAILER',
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Play button (center) ───────────────────────────────
                    Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: _trailerHovered ? 72 : 64,
                        height: _trailerHovered ? 72 : 64,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.6),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacity(0.4),
                              blurRadius: 24,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),

                    // ── Trailer name (bottom) ──────────────────────────────
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                          ),
                        ),
                        child: Text(
                          trailer.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNetflixMetaRow(Color accent) {
    return Row(
      children: [
        if (_movie != null) ...[
          Text(
            '${(_movie!.rating * 10).toInt()}% Match',
            style: const TextStyle(
              color: Color(0xFF46D369),
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 14),
          if (_movie!.releaseDate != null)
            Text(
              _movie!.releaseDate!.split('-').first,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(width: 14),
        ],
        _buildQualityBadge('4K', accent),
        const SizedBox(width: 8),
        _buildQualityBadge('HDR', accent),
        const SizedBox(width: 14),
        const Icon(Icons.info_outline, color: Colors.white38, size: 18),
      ],
    );
  }

  Widget _buildQualityBadge(String text, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: accent.withOpacity(0.6), width: 1),
        borderRadius: BorderRadius.circular(4),
        color: accent.withOpacity(0.08),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: accent.withOpacity(0.9),
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildNetflixPlayButton(bool isFavorite, Color accent) {
    return Row(
      children: [
        // Primary play button — uses palette accent color
        Expanded(
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: _play,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 52,
                alignment: Alignment.center,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded, color: Colors.black, size: 32),
                    SizedBox(width: 4),
                    Text(
                      'Play',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Trailer shortcut button
        if (_trailer != null)
          _buildCircularAction(
            Icons.smart_display_rounded,
            _openTrailer,
            'Trailer',
            accent,
          ),
        const SizedBox(width: 10),
        // Favorites button
        _buildCircularAction(
          isFavorite ? Icons.check_rounded : Icons.add_rounded,
          () {
            HapticFeedback.lightImpact();
            ref.read(favoritesProvider.notifier).toggle(widget.channel);
          },
          isFavorite ? 'My List' : 'Add',
          accent,
        ),
      ],
    );
  }

  Widget _buildCircularAction(IconData icon, VoidCallback onTap, String label, Color accent) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white38, width: 1.5),
            color: Colors.white.withOpacity(0.05),
          ),
          child: IconButton(
            onPressed: onTap,
            icon: Icon(icon, color: Colors.white, size: 26),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, Color accent) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [BoxShadow(color: accent.withOpacity(0.5), blurRadius: 8)],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ],
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
                  backgroundColor: _palette.muted.withOpacity(0.3),
                  backgroundImage: c.profileUrl != null
                      ? CachedNetworkImageProvider(c.profileUrl!)
                      : null,
                  child: c.profileUrl == null
                      ? const Icon(Icons.person, color: Colors.white24)
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  c.name,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  c.character,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
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
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 0.68,
                  child: CachedNetworkImage(
                    imageUrl: m.posterUrl ?? '',
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.white10,
                      child: const Icon(Icons.movie, color: Colors.white24),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
