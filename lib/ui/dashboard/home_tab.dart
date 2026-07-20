import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../services/playlist_service.dart';
import '../../providers/channel_library_provider.dart';
import '../../providers/app_locale_provider.dart';
import '../../l10n/app_strings.dart';
import '../../services/world_cup_service.dart';
import '../player/movie_player_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeTabScreen extends ConsumerStatefulWidget {
  final List<Channel> allChannels;
  final Function(List<Channel>, Channel) onOpenPlayer;

  const HomeTabScreen({
    Key? key,
    required this.allChannels,
    required this.onOpenPlayer,
  }) : super(key: key);

  @override
  ConsumerState<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends ConsumerState<HomeTabScreen> {
  List<dynamic> _news = [];
  bool _isLoadingNews = true;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    final news = await WorldCupService.fetchNews();
    if (mounted) {
      setState(() {
        _news = news;
        _isLoadingNews = false;
      });
    }
  }

  bool _isMovieChannel(Channel c) {
    if (c.type == 'movie') return true;
    final g = c.group.toLowerCase();
    if (g.contains('vod') || g.contains('movie') || g.contains('series')) return true;
    return false;
  }

  bool _isSportChannel(Channel c) {
    if (c.type == 'sport') return true;
    final g = c.group.toLowerCase();
    if (g.contains('sport') || g.contains('bein')) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings(ref.watch(appLocaleProvider));

    // Prepare data
    final movies = widget.allChannels.where(_isMovieChannel).toList();
    final liveTv = widget.allChannels.where((c) => !_isMovieChannel(c) && !_isSportChannel(c)).toList();
    final sports = widget.allChannels.where(_isSportChannel).toList();

    // Select Hero Items
    final heroMovies = movies.take(5).toList();
    final heroLive = liveTv.take(5).toList();
    final heroSports = sports.take(5).toList();

    return Container(
      color: Colors.transparent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120), // Padding for bottom nav
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HERO FEATURED MOVIE CAROUSEL
            if (heroMovies.isNotEmpty) _HeroCarousel(channels: heroMovies, allChannels: widget.allChannels, onOpenPlayer: widget.onOpenPlayer, isMovie: true),
            if (heroMovies.isNotEmpty) const SizedBox(height: 24),

            // 2. MOVIES
            if (movies.length > 5) ...[
              _buildSectionHeader(s.navMovies),
              _buildMoviesScroll(movies.skip(5).take(12).toList()), // Skip hero carousel movies
              const SizedBox(height: 32),
            ],

            // 3. LIVE TV CAROUSEL + LIST
            if (heroLive.isNotEmpty) ...[
              _buildSectionHeader('Live TV', showPulse: true),
              _HeroCarousel(channels: heroLive, allChannels: widget.allChannels, onOpenPlayer: widget.onOpenPlayer, isMovie: false),
              const SizedBox(height: 16),
            ],
            if (liveTv.length > 5) ...[
              _buildLiveTvScroll(liveTv.skip(5).take(12).toList(), isSport: false),
              const SizedBox(height: 32),
            ],

            // 4. SPORTS CAROUSEL + LIST
            if (heroSports.isNotEmpty) ...[
              _buildSectionHeader(s.navSport, showPulse: true),
              _HeroCarousel(channels: heroSports, allChannels: widget.allChannels, onOpenPlayer: widget.onOpenPlayer, isMovie: false),
              const SizedBox(height: 16),
            ],
            if (sports.length > 5) ...[
              _buildLiveTvScroll(sports.skip(5).take(12).toList(), isSport: true),
              const SizedBox(height: 32),
            ],

            // 5. LATEST NEWS
            if (_isLoadingNews)
              const Center(child: CircularProgressIndicator(color: Color(0xFF5B6F99)))
            else if (_news.isNotEmpty) ...[
              _buildSectionHeader(s.wcTabNews),
              _buildNewsScroll(_news.take(6).toList()),
            ],
          ],
        ),
      ),
    );
  }

  // _buildHeroCard removed, replaced by _HeroCarousel

  Widget _buildSectionHeader(String title, {bool showPulse = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF314066).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFEDF1FF).withValues(alpha: 0.9),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          if (showPulse)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF141E32).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B6F99).withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('On air', style: TextStyle(color: Color(0xFF7A8BB8), fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLiveTvScroll(List<Channel> channels, {bool isSport = false}) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: channels.length,
        itemBuilder: (context, index) {
          final c = channels[index];
          return StatefulBuilder(
            builder: (context, setState) {
              bool focused = false;
              return GestureDetector(
                onTap: () => widget.onOpenPlayer(widget.allChannels, c),
                child: Focus(
                  onFocusChange: (f) {
                    if (mounted) setState(() => focused = f);
                  },
                  child: AnimatedScale(
                    scale: focused ? 1.20 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      width: 138,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.fromLTRB(10, 22, 10, 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141A22).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: focused ? Theme.of(context).primaryColor.withValues(alpha: 1.0) : Colors.white.withValues(alpha: 0.05),
                          width: focused ? 4.0 : 1.0,
                        ),
                        boxShadow: focused ? [
                          BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 1),
                        ] : [],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: CachedNetworkImage(
                                  imageUrl: c.logo ?? '',
                                  fit: BoxFit.contain,
                                  errorWidget: (_, __, ___) => const Icon(Icons.tv, color: Colors.white24),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                c.name,
                                style: TextStyle(
                                  color: focused ? Colors.white : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: focused ? FontWeight.w900 : FontWeight.w600,
                                  letterSpacing: -0.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                                decoration: BoxDecoration(
                                  color: focused ? Theme.of(context).primaryColor.withValues(alpha: 0.2) : Colors.black26,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: focused ? Theme.of(context).primaryColor : Colors.white12),
                                ),
                                child: Text(
                                  isSport ? 'SPORT' : 'LIVE',
                                  style: TextStyle(
                                    color: focused ? Colors.white : Colors.white60,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMoviesScroll(List<Channel> movies) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final m = movies[index];
          return StatefulBuilder(
            builder: (context, setState) {
              bool focused = false;
              return GestureDetector(
                onTap: () => widget.onOpenPlayer(widget.allChannels, m),
                child: Focus(
                  onFocusChange: (f) {
                    if (mounted) setState(() => focused = f);
                  },
                  child: AnimatedScale(
                    scale: focused ? 1.20 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      width: 108,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141A22).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: focused ? Theme.of(context).primaryColor.withValues(alpha: 1.0) : Colors.white.withValues(alpha: 0.05),
                          width: focused ? 4.0 : 1.0,
                        ),
                        boxShadow: focused ? [
                          BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 1),
                        ] : [],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColorFiltered(
                            colorFilter: const ColorFilter.mode(Colors.black12, BlendMode.darken),
                            child: CachedNetworkImage(
                              imageUrl: m.logo ?? '',
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(color: const Color(0xFF101A2E)),
                            ),
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.8),
                                  ],
                                  stops: const [0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                m.name,
                                style: TextStyle(
                                  color: focused ? Colors.white : Colors.white70,
                                  fontSize: 11,
                                  fontWeight: focused ? FontWeight.w800 : FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
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
        },
      ),
    );
  }

  Widget _buildNewsScroll(List<dynamic> newsItems) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: newsItems.length,
        itemBuilder: (context, index) {
          final item = newsItems[index];
          final headline = item['headline'] ?? 'News Update';
          final img = (item['images'] != null && item['images'].isNotEmpty) ? item['images'][0]['url'] : '';

          return StatefulBuilder(
            builder: (context, setState) {
              bool focused = false;
              return Focus(
                onFocusChange: (f) {
                  if (mounted) setState(() => focused = f);
                },
                child: AnimatedScale(
                  scale: focused ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    width: 240,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141A22).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: focused ? Theme.of(context).primaryColor.withValues(alpha: 1.0) : Colors.white.withValues(alpha: 0.05),
                        width: focused ? 4.0 : 1.0,
                      ),
                      boxShadow: focused ? [
                        BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 1),
                      ] : [],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: CachedNetworkImage(
                            imageUrl: img,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(color: const Color(0xFF101A2E)),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            color: Colors.transparent,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  headline,
                                  style: TextStyle(
                                    color: focused ? Colors.white : Colors.white70,
                                    fontSize: 13,
                                    fontWeight: focused ? FontWeight.bold : FontWeight.w600,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HeroCarousel extends StatefulWidget {
  final List<Channel> channels;
  final List<Channel> allChannels;
  final bool isMovie;
  final Function(List<Channel>, Channel) onOpenPlayer;

  const _HeroCarousel({
    Key? key,
    required this.channels,
    this.isMovie = true,
    required this.allChannels,
    required this.onOpenPlayer,
  }) : super(key: key);

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88, initialPage: 0);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _currentPage + 1;
        if (nextPage >= widget.channels.length) {
          nextPage = 0;
          _pageController.animateToPage(nextPage, duration: const Duration(milliseconds: 1200), curve: Curves.fastOutSlowIn);
        } else {
          _pageController.nextPage(duration: const Duration(milliseconds: 800), curve: Curves.fastOutSlowIn);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.channels.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: SizedBox(
        height: 380,
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemCount: widget.channels.length,
          itemBuilder: (context, index) {
            final channel = widget.channels[index];
            return AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) {
                double value = 1.0;
                if (_pageController.position.haveDimensions) {
                  value = _pageController.page! - index;
                  value = (1 - (value.abs() * 0.12)).clamp(0.88, 1.0);
                }
                final opacity = value.clamp(0.4, 1.0);
                return Center(
                  child: Opacity(
                    opacity: opacity,
                    child: SizedBox(
                      height: Curves.easeOut.transform(value) * 360,
                      width: Curves.easeOut.transform(value) * MediaQuery.of(context).size.width,
                      child: child,
                    ),
                  ),
                );
              },
              child: _buildHeroCard(channel),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroCard(Channel channel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: const Color(0xFF0A101E),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 35,
            spreadRadius: -10,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                1.05, 0, 0, 0, 0,
                0, 1.05, 0, 0, 0,
                0, 0, 1.05, 0, 0,
                0, 0, 0, 0.45, 0, // Brightness 0.45
              ]),
              child: CachedNetworkImage(
                imageUrl: channel.logo ?? '',
                fit: BoxFit.cover,
                errorWidget: (c, u, e) => Container(color: const Color(0xFF0A101E)),
              ),
            ),
          ),
          // Gradient
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 280,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color(0xF8040914), // rgba(4, 9, 20, 0.97)
                    Color(0x8C040914), // rgba(4, 9, 20, 0.55)
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Genre Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F192D).withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            channel.group.isNotEmpty ? channel.group : (widget.isMovie ? 'Movie' : 'Live'),
                            style: const TextStyle(
                              color: Color(0xFFBCC8E6),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Title
                Text(
                  channel.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF2F5FF),
                    letterSpacing: -0.5,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 4))],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Meta
                Row(
                  children: [
                    if (widget.isMovie) ...[
                      const Icon(Icons.star_rounded, color: Color(0xFFB8A86A), size: 14),
                      const SizedBox(width: 4),
                      const Text('8.5', style: TextStyle(color: Color(0xFFC8BFA0), fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 18),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(4)),
                        child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Text('HD', style: TextStyle(color: Color(0xFFAAB8D6), fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 16),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      flex: 11,
                      child: GestureDetector(
                        onTap: () => widget.onOpenPlayer(widget.allChannels, channel),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C2840).withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.play_arrow_rounded, color: Color(0xFFCBD3F0), size: 18),
                                  SizedBox(width: 6),
                                  Text('Watch', style: TextStyle(color: Color(0xFFE8EDFF), fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 9,
                      child: GestureDetector(
                        onTap: () => widget.onOpenPlayer(widget.allChannels, channel),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C1426).withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.info_outline_rounded, color: Color(0xFFCBD3F0), size: 16),
                                  SizedBox(width: 6),
                                  Text('Details', style: TextStyle(color: Color(0xFFD4DDF8), fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
