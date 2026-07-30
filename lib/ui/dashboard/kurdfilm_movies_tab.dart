import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/kurdfilm_service.dart';
import '../../core/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  KurdFilm Movies Tab  —  Flutter Phone/Tablet
//  Full flow:  Movie Grid → Detail Sheet → Ad-Blocking WebView Player
// ─────────────────────────────────────────────────────────────────────────────

class KurdfilmMoviesTab extends StatefulWidget {
  const KurdfilmMoviesTab({super.key});

  @override
  State<KurdfilmMoviesTab> createState() => _KurdfilmMoviesTabState();
}

class _KurdfilmMoviesTabState extends State<KurdfilmMoviesTab> {
  final _service = KurdfilmService();
  List<KurdfilmMovie> _movies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _service.getLatestMovies();
    if (mounted) setState(() { _movies = result; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentTeal),
      );
    }

    if (_movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie_outlined, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            Text(
              'Could not load movies',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.accentTeal),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.accentTeal,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentTeal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.accentTeal.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.movie_creation_rounded, size: 14, color: AppTheme.accentTeal),
                        const SizedBox(width: 6),
                        Text(
                          'KURDFILM',
                          style: TextStyle(
                            color: AppTheme.accentTeal,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_movies.length} movies',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // ── Grid ────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _KurdfilmMovieCard(
                  movie: _movies[index],
                  onTap: () => _openDetail(_movies[index]),
                ),
                childCount: _movies.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.62,
                crossAxisSpacing: 8,
                mainAxisSpacing: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(KurdfilmMovie movie) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _KurdfilmDetailSheet(movie: movie, service: _service),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  MOVIE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _KurdfilmMovieCard extends StatelessWidget {
  final KurdfilmMovie movie;
  final VoidCallback onTap;

  const _KurdfilmMovieCard({required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (movie.image.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: movie.image,
                      fit: BoxFit.cover,
                      errorWidget: (ctx, url, err) => Container(
                        color: Colors.white.withValues(alpha: 0.05),
                        child: const Center(
                          child: Icon(Icons.movie_outlined, color: Colors.white24),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: Colors.white.withValues(alpha: 0.05),
                      child: const Center(
                        child: Icon(Icons.movie_outlined, color: Colors.white24),
                      ),
                    ),
                  // Rating badge
                  if (movie.rating > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 10, color: Color(0xFFF7B955)),
                            const SizedBox(width: 2),
                            Text(
                              movie.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Play overlay on bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(6, 16, 6, 6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (movie.releaseDate.isNotEmpty)
            Text(
              movie.releaseDate.length >= 4 ? movie.releaseDate.substring(0, 4) : movie.releaseDate,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DETAIL BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _KurdfilmDetailSheet extends StatefulWidget {
  final KurdfilmMovie movie;
  final KurdfilmService service;

  const _KurdfilmDetailSheet({required this.movie, required this.service});

  @override
  State<_KurdfilmDetailSheet> createState() => _KurdfilmDetailSheetState();
}

class _KurdfilmDetailSheetState extends State<_KurdfilmDetailSheet> {
  KurdfilmDetail? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await widget.service.getMovieDetail(widget.movie.id);
    if (mounted) setState(() { _detail = d; _loading = false; });
  }

  void _openPlayer(String url) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _AdBlockingPlayerScreen(url: url, title: widget.movie.title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.movie;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D14),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster + info row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Poster
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: m.image.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: m.image,
                                      width: 110,
                                      height: 160,
                                      fit: BoxFit.cover,
                                      errorWidget: (ctx, url, err) => Container(
                                        width: 110, height: 160,
                                        color: Colors.white.withValues(alpha: 0.05),
                                        child: const Icon(Icons.movie_outlined, color: Colors.white24),
                                      ),
                                    )
                                  : Container(
                                      width: 110, height: 160,
                                      color: Colors.white.withValues(alpha: 0.05),
                                      child: const Icon(Icons.movie_outlined, color: Colors.white24),
                                    ),
                            ),
                            const SizedBox(width: 14),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    m.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      if (m.rating > 0) ...[
                                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF7B955)),
                                        const SizedBox(width: 4),
                                        Text(
                                          m.rating.toStringAsFixed(1),
                                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('•', style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
                                        const SizedBox(width: 8),
                                      ],
                                      if (m.releaseDate.isNotEmpty)
                                        Text(
                                          m.releaseDate.length >= 4 ? m.releaseDate.substring(0, 4) : m.releaseDate,
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                                        ),
                                    ],
                                  ),
                                  if (!_loading && _detail?.duration.isNotEmpty == true) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _detail!.duration,
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Description
                      if (!_loading && _detail?.description.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                          child: Text(
                            _detail!.description,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 13,
                              height: 1.55,
                            ),
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Server buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'CHOOSE SERVER',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator(color: AppTheme.accentTeal)),
                        )
                      else if (_detail == null || _detail!.servers.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No servers available for this movie.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _detail!.servers.map((server) {
                              return _ServerButton(
                                server: server,
                                onTap: () => _openPlayer(server.extractedUrl),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SERVER BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _ServerButton extends StatefulWidget {
  final KurdfilmServer server;
  final VoidCallback onTap;

  const _ServerButton({required this.server, required this.onTap});

  @override
  State<_ServerButton> createState() => _ServerButtonState();
}

class _ServerButtonState extends State<_ServerButton> {
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressing = true),
      onTapUp: (_) { setState(() => _pressing = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressing = false),
      child: AnimatedScale(
        scale: _pressing ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppTheme.accentTeal.withValues(alpha: 0.12),
            border: Border.all(color: AppTheme.accentTeal.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_circle_fill_rounded, size: 16, color: AppTheme.accentTeal),
              const SizedBox(width: 8),
              Text(
                widget.server.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  AD-BLOCKING WEBVIEW PLAYER  —  mirrors apk2url-main video_player_modal.dart
// ─────────────────────────────────────────────────────────────────────────────

class _AdBlockingPlayerScreen extends StatefulWidget {
  final String url;
  final String title;

  const _AdBlockingPlayerScreen({required this.url, required this.title});

  @override
  State<_AdBlockingPlayerScreen> createState() => _AdBlockingPlayerScreenState();
}

class _AdBlockingPlayerScreenState extends State<_AdBlockingPlayerScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) {
            setState(() => _loading = false);
            _injectAdBlocker();
          },
          onNavigationRequest: (request) {
            final targetUri = Uri.tryParse(request.url);
            final initialUri = Uri.tryParse(widget.url);
            
            // Block all main-frame navigations to 3rd party sites (these are usually redirect ads)
            if (targetUri != null && initialUri != null && request.isMainFrame) {
              if (targetUri.host != initialUri.host && !targetUri.host.endsWith(initialUri.host.replaceAll('www.', ''))) {
                return NavigationDecision.prevent;
              }
            }

            // Block known pop-up / redirect navigations to ad domains
            final url = request.url.toLowerCase();
            final adDomains = [
              'doubleclick.net', 'googlesyndication.com', 'adnxs.com',
              'popads.net', 'popcash.net', 'propellerads.com', 'clickadu.com',
              'trafficjunky.net', 'juicyads.com', 'exoclick.com', 'adskeeper.co.uk',
              'valueclick.com', 'hilltopads.net',
            ];
            final isAd = adDomains.any((d) => url.contains(d));
            if (isAd) return NavigationDecision.prevent;
            
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _injectAdBlocker() {
    // Combined CSS hide + JS popup kill — same logic as apk2url-main
    const js = r"""
      (function() {
        // ── CSS: hide all ad elements ────────────────────────────────────
        var style = document.createElement('style');
        style.innerHTML = `
          .ad, .ads, .adsbygoogle, .advertisement,
          [id*='google_ad'], [class*='google_ad'],
          [id*='banner'], [class*='banner'],
          [id*='popup'], [class*='popup'],
          [id*='overlay'], [class*='overlay'],
          iframe[src*='ads'], iframe[src*='doubleclick'],
          .vjs-vast-skip-button, .skip-ad, .skip-button,
          #ad_unit, #ads_unit, .ads-container,
          [class*='preroll'], [class*='midroll'],
          [data-ad], [data-ads],
          .jw-ad-container, .jw-overlays {
            display: none !important;
            visibility: hidden !important;
            opacity: 0 !important;
            pointer-events: none !important;
            height: 0 !important;
            width: 0 !important;
            overflow: hidden !important;
          }
        `;
        document.head.appendChild(style);

        // ── JS: kill pop-ups, new tabs, and redirect attempts ────────────
        window.open = function() { return null; };
        window.alert = function() {};
        window.confirm = function() { return true; };
        window.prompt = function() { return ''; };

        // Block _blank link taps aggressively
        document.addEventListener('click', function(e) {
          var t = e.target;
          while (t) {
            if (t.tagName === 'A') {
               // If it tries to open in a new tab, or goes to a different domain, kill the click!
               if (t.target === '_blank' || t.getAttribute('rel') === 'noopener' || (t.host && t.host !== window.location.host)) {
                  e.preventDefault();
                  e.stopImmediatePropagation();
                  return false;
               }
            }
            t = t.parentElement;
          }
        }, true);
        
        // Keep reapplying overrides just in case player scripts try to restore them
        setInterval(function() {
            window.open = function() { return null; };
            var badAds = document.querySelectorAll('.ad, .ads, [id*="popup"], [class*="popup"], iframe[src*="ads"]');
            badAds.forEach(function(el) { el.remove(); });
        }, 1000);

        // Override location hijacking attempts
        var _origAssign = window.location.assign;
        try {
          Object.defineProperty(window, 'location', {
            get: function() { return window._realLocation || location; },
            configurable: true
          });
        } catch(e) {}
      })();
    """;
    _controller.runJavaScript(js);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
              const Center(
                child: CircularProgressIndicator(color: AppTheme.accentTeal),
              ),
            // Close button
            Positioned(
              top: 8,
              left: 8,
              child: Material(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
            // Title bar at top
            Positioned(
              top: 8,
              left: 52,
              right: 52,
              child: Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
