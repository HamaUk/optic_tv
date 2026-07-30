package com.kobani4k.app.tv.ui

import android.annotation.SuppressLint
import android.webkit.WebChromeClient
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Movie
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.tv.material3.Text
import coil.compose.AsyncImage
import com.kobani4k.app.tv.data.KurdfilmApiService
import com.kobani4k.app.tv.data.KurdfilmDetail
import com.kobani4k.app.tv.data.KurdfilmMovie
import com.kobani4k.app.tv.ui.theme.UltraTokens
import kotlinx.coroutines.delay

// ═══════════════════════════════════════════════════════════════════════════
//  KURDFILM MOVIES SCREEN — Replaces TMDB/PocketBase movie browsing
// ═══════════════════════════════════════════════════════════════════════════

@Composable
fun KurdfilmMoviesScreen() {
    val api = remember { KurdfilmApiService() }
    var movies by remember { mutableStateOf<List<KurdfilmMovie>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    var selectedMovie by remember { mutableStateOf<KurdfilmMovie?>(null) }

    LaunchedEffect(Unit) {
        isLoading = true
        movies = api.getLatestMovies(page = 1)
        isLoading = false
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(UltraTokens.Background)
    ) {
        if (isLoading) {
            CircularProgressIndicator(
                color = UltraTokens.Accent,
                modifier = Modifier.align(Alignment.Center),
                strokeWidth = 3.dp
            )
        } else {
            KurdfilmMoviesContent(
                movies = movies,
                onMovieClick = { selectedMovie = it }
            )
        }
    }

    // Detail Overlay
    val selected = selectedMovie
    if (selected != null) {
        KurdfilmDetailScreen(
            movie = selected,
            onBack = { selectedMovie = null }
        )
    }
}

@Composable
private fun KurdfilmMoviesContent(
    movies: List<KurdfilmMovie>,
    onMovieClick: (KurdfilmMovie) -> Unit
) {
    var focusedMovie by remember { mutableStateOf(movies.firstOrNull()) }

    Box(modifier = Modifier.fillMaxSize()) {
        // Hero section background
        val heroImage = focusedMovie?.image
        if (!heroImage.isNullOrEmpty()) {
            AsyncImage(
                model = heroImage,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(350.dp)
                    .blur(16.dp)
            )
        }

        // Bottom gradient
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(350.dp)
                .background(
                    Brush.verticalGradient(
                        colors = listOf(Color.Transparent, UltraTokens.Background)
                    )
                )
        )

        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(top = 180.dp, bottom = 48.dp)
        ) {
            // Hero info
            item {
                focusedMovie?.let { movie ->
                    Column(modifier = Modifier.padding(horizontal = 24.dp)) {
                        Text(
                            text = movie.title,
                            fontSize = 28.sp,
                            fontWeight = FontWeight.Bold,
                            color = UltraTokens.Text,
                            maxLines = 2,
                            overflow = TextOverflow.Ellipsis
                        )
                        Spacer(Modifier.height(6.dp))
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            if (movie.rating > 0) {
                                Icon(Icons.Default.Star, null, tint = UltraTokens.Movie, modifier = Modifier.size(14.dp))
                                Text(String.format("%.1f", movie.rating), color = UltraTokens.Text, fontSize = 13.sp)
                                Text("•", color = UltraTokens.TextSecondary, fontSize = 13.sp)
                            }
                            if (movie.releaseDate.isNotEmpty()) {
                                Text(movie.releaseDate.take(4), color = UltraTokens.TextSecondary, fontSize = 13.sp)
                            }
                        }
                        Spacer(Modifier.height(20.dp))
                    }
                }
            }

            // Row: Latest Movies
            item {
                KurdfilmMovieRow(
                    title = "Latest Movies",
                    movies = movies,
                    onFocus = { focusedMovie = it },
                    onClick = onMovieClick
                )
            }
        }
    }
}

@Composable
private fun KurdfilmMovieRow(
    title: String,
    movies: List<KurdfilmMovie>,
    onFocus: (KurdfilmMovie) -> Unit,
    onClick: (KurdfilmMovie) -> Unit
) {
    Column(modifier = Modifier.fillMaxWidth().padding(vertical = 12.dp)) {
        Text(
            text = title,
            fontSize = 20.sp,
            fontWeight = FontWeight.Bold,
            color = UltraTokens.Text,
            modifier = Modifier.padding(horizontal = 24.dp)
        )
        Spacer(Modifier.height(12.dp))
        LazyRow(
            contentPadding = PaddingValues(horizontal = 24.dp),
            horizontalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            items(movies) { movie ->
                KurdfilmMovieCard(movie = movie, onFocus = { onFocus(movie) }, onClick = { onClick(movie) })
            }
        }
    }
}

@Composable
private fun KurdfilmMovieCard(
    movie: KurdfilmMovie,
    onFocus: () -> Unit,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(
        targetValue = if (isFocused) 1.07f else 1f,
        animationSpec = tween(100),
        label = "card_scale"
    )

    Box(
        modifier = Modifier
            .width(120.dp)
            .height(180.dp)
            .scale(scale)
            .then(
                if (isFocused) Modifier.border(3.dp, UltraTokens.Accent, RoundedCornerShape(8.dp))
                else Modifier
            )
            .clip(RoundedCornerShape(8.dp))
            .background(UltraTokens.Surface)
            .onFocusChanged {
                isFocused = it.isFocused
                if (it.isFocused) onFocus()
            }
            .clickable { onClick() }
            .focusable()
    ) {
        if (movie.image.isNotEmpty()) {
            AsyncImage(
                model = movie.image,
                contentDescription = movie.title,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize()
            )
        } else {
            Icon(
                Icons.Default.Movie, null,
                tint = UltraTokens.TextSecondary,
                modifier = Modifier.align(Alignment.Center).size(32.dp)
            )
        }

        // Title overlay at bottom
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .align(Alignment.BottomCenter)
                .background(
                    Brush.verticalGradient(listOf(Color.Transparent, Color.Black.copy(0.85f)))
                )
                .padding(horizontal = 6.dp, vertical = 6.dp)
        ) {
            Text(
                text = movie.title,
                color = Color.White,
                fontSize = 11.sp,
                fontWeight = FontWeight.SemiBold,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth()
            )
        }

        // Rating badge
        if (movie.rating > 0) {
            Box(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(5.dp)
                    .background(Color.Black.copy(0.7f), RoundedCornerShape(4.dp))
                    .padding(horizontal = 5.dp, vertical = 2.dp)
            ) {
                Text(String.format("%.1f", movie.rating), fontSize = 11.sp, fontWeight = FontWeight.Bold, color = UltraTokens.Text)
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//  KURDFILM DETAIL SCREEN — Shows servers + ad-blocking WebView player
// ═══════════════════════════════════════════════════════════════════════════

@Composable
fun KurdfilmDetailScreen(
    movie: KurdfilmMovie,
    onBack: () -> Unit
) {
    val api = remember { KurdfilmApiService() }
    var detail by remember { mutableStateOf<KurdfilmDetail?>(null) }
    var isLoading by remember { mutableStateOf(true) }
    var selectedServerUrl by remember { mutableStateOf<String?>(null) }
    val firstButtonFocus = remember { FocusRequester() }

    LaunchedEffect(movie.id) {
        isLoading = true
        detail = api.getMovieDetails(movie.id)
        isLoading = false
        delay(100)
        runCatching { firstButtonFocus.requestFocus() }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(UltraTokens.Background)
    ) {
        // Blurred backdrop
        if (movie.image.isNotEmpty()) {
            AsyncImage(
                model = movie.image,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize().blur(20.dp)
            )
        }
        // Dark overlay
        Box(
            modifier = Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.75f))
        )

        if (isLoading) {
            CircularProgressIndicator(
                color = UltraTokens.Accent,
                modifier = Modifier.align(Alignment.Center),
                strokeWidth = 3.dp
            )
        } else {
            val d = detail
            Row(
                modifier = Modifier.fillMaxSize().padding(48.dp),
                verticalAlignment = Alignment.Bottom
            ) {
                // Poster
                if (movie.image.isNotEmpty()) {
                    AsyncImage(
                        model = movie.image,
                        contentDescription = null,
                        contentScale = ContentScale.Crop,
                        modifier = Modifier
                            .width(200.dp)
                            .height(300.dp)
                            .clip(RoundedCornerShape(12.dp))
                            .border(1.dp, UltraTokens.Divider, RoundedCornerShape(12.dp))
                    )
                    Spacer(Modifier.width(40.dp))
                }

                Column(modifier = Modifier.weight(1f)) {
                    Text(movie.title, fontSize = 42.sp, fontWeight = FontWeight.Bold, color = UltraTokens.Text, maxLines = 2, overflow = TextOverflow.Ellipsis)
                    Spacer(Modifier.height(12.dp))

                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                        if (movie.rating > 0) {
                            Icon(Icons.Default.Star, null, tint = UltraTokens.Movie, modifier = Modifier.size(18.dp))
                            Text(String.format("%.1f", movie.rating), color = UltraTokens.Text, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
                            Text("•", color = UltraTokens.TextSecondary, fontSize = 16.sp)
                        }
                        if (movie.releaseDate.isNotEmpty()) {
                            Text(movie.releaseDate.take(4), color = UltraTokens.TextSecondary, fontSize = 16.sp)
                        }
                        if (d?.duration?.isNotEmpty() == true) {
                            Text("•", color = UltraTokens.TextSecondary, fontSize = 16.sp)
                            Text(d.duration, color = UltraTokens.TextSecondary, fontSize = 16.sp)
                        }
                    }

                    Spacer(Modifier.height(16.dp))

                    if (d?.description?.isNotEmpty() == true) {
                        Text(
                            text = d.description,
                            color = UltraTokens.TextSecondary,
                            fontSize = 15.sp,
                            lineHeight = 22.sp,
                            maxLines = 4,
                            overflow = TextOverflow.Ellipsis,
                            modifier = Modifier.fillMaxWidth(0.85f)
                        )
                        Spacer(Modifier.height(24.dp))
                    }

                    // Server buttons
                    Text("Choose Server:", color = UltraTokens.TextFaint, fontSize = 12.sp, letterSpacing = 1.sp)
                    Spacer(Modifier.height(10.dp))

                    val servers = d?.servers ?: emptyList()
                    if (servers.isEmpty()) {
                        Text("No servers available.", color = UltraTokens.TextSecondary, fontSize = 14.sp)
                    } else {
                        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                            servers.forEachIndexed { index, server ->
                                var btnFocused by remember { mutableStateOf(false) }
                                val btnScale by animateFloatAsState(if (btnFocused) 1.06f else 1f, tween(80), label = "btn_scale")
                                Box(
                                    modifier = Modifier
                                        .scale(btnScale)
                                        .then(if (index == 0) Modifier.focusRequester(firstButtonFocus) else Modifier)
                                        .onFocusChanged { btnFocused = it.isFocused }
                                        .clip(RoundedCornerShape(8.dp))
                                        .background(if (btnFocused) UltraTokens.Accent else Color.White.copy(0.1f))
                                        .border(1.dp, if (btnFocused) UltraTokens.Accent else Color.White.copy(0.3f), RoundedCornerShape(8.dp))
                                        .clickable { selectedServerUrl = api.extractVideoUrl(server.url) }
                                        .focusable()
                                        .padding(horizontal = 20.dp, vertical = 12.dp),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Icon(Icons.Default.PlayArrow, null, tint = Color.White, modifier = Modifier.size(16.dp))
                                        Spacer(Modifier.width(6.dp))
                                        Text(server.name, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = Color.White)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Back button
        IconButton(
            onClick = onBack,
            modifier = Modifier.padding(24.dp).align(Alignment.TopStart)
                .background(Color.Black.copy(0.5f), RoundedCornerShape(50))
        ) {
            Icon(Icons.AutoMirrored.Filled.ArrowBack, "Back", tint = UltraTokens.Text, modifier = Modifier.size(26.dp))
        }
    }

    // Ad-blocking WebView player dialog
    val playUrl = selectedServerUrl
    if (playUrl != null) {
        AdBlockingPlayerDialog(url = playUrl, onDismiss = { selectedServerUrl = null })
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//  AD-BLOCKING WEBVIEW PLAYER
//  Injects CSS to hide banners + JS to kill pop-ups / redirects
// ═══════════════════════════════════════════════════════════════════════════

@SuppressLint("SetJavaScriptEnabled")
@Composable
fun AdBlockingPlayerDialog(url: String, onDismiss: () -> Unit) {
    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.Black)
        ) {
            AndroidView(
                factory = { context ->
                    WebView(context).apply {
                        settings.apply {
                            javaScriptEnabled = true
                            domStorageEnabled = true
                            mediaPlaybackRequiresUserGesture = false
                            loadWithOverviewMode = true
                            useWideViewPort = true
                            builtInZoomControls = false
                            displayZoomControls = false
                            mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
                            userAgentString = "Mozilla/5.0 (Linux; Android 14; TV) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36"
                        }

                        webChromeClient = WebChromeClient()

                        webViewClient = object : WebViewClient() {
                            override fun shouldOverrideUrlLoading(view: WebView?, request: android.webkit.WebResourceRequest?): Boolean {
                                val targetUrl = request?.url?.toString() ?: return false
                                val targetUri = android.net.Uri.parse(targetUrl)
                                val initialUri = android.net.Uri.parse(url)
                                
                                // Block if navigating to completely different host
                                if (request.isForMainFrame) {
                                    val tHost = targetUri.host ?: ""
                                    val iHost = initialUri.host?.replace("www.", "") ?: ""
                                    if (tHost != initialUri.host && !tHost.endsWith(iHost)) {
                                        return true // block it
                                    }
                                }
                                
                                val adDomains = listOf("doubleclick.net", "googlesyndication.com", "adnxs.com", "popads.net", "popcash.net", "propellerads.com", "clickadu.com", "trafficjunky.net", "juicyads.com", "exoclick.com", "adskeeper.co.uk", "valueclick.com", "hilltopads.net")
                                if (adDomains.any { targetUrl.contains(it) }) return true
                                
                                return false
                            }

                            override fun onPageFinished(view: WebView?, loadedUrl: String?) {
                                // Inject CSS to hide common ad elements
                                val cssHide = """
                                    (function() {
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
                                            }
                                        `;
                                        document.head.appendChild(style);
                                        
                                        // Kill pop-ups and new tab redirects
                                        window.open = function() { return null; };
                                        window.alert = function() {};
                                        window.confirm = function() { return true; };
                                        
                                        // Block clicks that open new windows
                                        document.addEventListener('click', function(e) {
                                            var target = e.target;
                                            while (target) {
                                                if (target.tagName === 'A') {
                                                    if (target.target === '_blank' || target.getAttribute('rel') === 'noopener' || (target.host && target.host !== window.location.host)) {
                                                        e.preventDefault();
                                                        e.stopPropagation();
                                                        return false;
                                                    }
                                                }
                                                target = target.parentElement;
                                            }
                                        }, true);
                                        
                                        setInterval(function() {
                                            window.open = function() { return null; };
                                            var badAds = document.querySelectorAll('.ad, .ads, [id*="popup"], [class*="popup"], iframe[src*="ads"]');
                                            badAds.forEach(function(el) { el.remove(); });
                                        }, 1000);
                                    })();
                                """.trimIndent()
                                view?.evaluateJavascript(cssHide, null)
                            }
                        }

                        loadUrl(url)
                    }
                },
                modifier = Modifier.fillMaxSize()
            )

            // Close button
            IconButton(
                onClick = onDismiss,
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(12.dp)
                    .background(Color.Black.copy(0.6f), RoundedCornerShape(50))
            ) {
                Icon(
                    Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = "Close",
                    tint = Color.White,
                    modifier = Modifier.size(24.dp)
                )
            }
        }
    }
}
