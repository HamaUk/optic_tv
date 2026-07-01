package com.kobani4k.app.tv.ui

import android.net.Uri
import android.view.KeyEvent
import android.widget.TextClock
import androidx.activity.compose.BackHandler
import androidx.annotation.OptIn as Media3OptIn
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.focusable
import androidx.compose.foundation.focusGroup
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.*
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.focusRestorer
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player as Media3Player
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.ui.PlayerView
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.kobani4k.app.tv.data.PocketBaseRepository
import com.kobani4k.app.tv.data.TvChannel
import com.kobani4k.app.tv.data.TvViewerService
import com.kobani4k.app.tv.ui.theme.UltraTokens
import com.kobani4k.app.tv.ui.theme.kobaniCardColors
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

// ─────────────────────────────────────────────────────────────
//  Key helpers — covers DPAD, Chinese remotes, Amazon sticks,
//  Roku sticks, generic TV boxes, and numeric remotes
// ─────────────────────────────────────────────────────────────

private fun isConfirm(keyCode: Int) = keyCode in setOf(
    KeyEvent.KEYCODE_DPAD_CENTER,
    KeyEvent.KEYCODE_ENTER,
    KeyEvent.KEYCODE_NUMPAD_ENTER,
    KeyEvent.KEYCODE_BUTTON_A,      // gamepad / Amazon Fire
    KeyEvent.KEYCODE_SPACE
)

private fun isBack(keyCode: Int) = keyCode in setOf(
    KeyEvent.KEYCODE_BACK,
    KeyEvent.KEYCODE_ESCAPE,
    KeyEvent.KEYCODE_MEDIA_CLOSE,
    KeyEvent.KEYCODE_BUTTON_B       // gamepad back
)

private fun isUp(keyCode: Int) = keyCode in setOf(
    KeyEvent.KEYCODE_DPAD_UP,
    KeyEvent.KEYCODE_CHANNEL_UP,
    KeyEvent.KEYCODE_PAGE_UP,
    KeyEvent.KEYCODE_NUMPAD_8
)

private fun isDown(keyCode: Int) = keyCode in setOf(
    KeyEvent.KEYCODE_DPAD_DOWN,
    KeyEvent.KEYCODE_CHANNEL_DOWN,
    KeyEvent.KEYCODE_PAGE_DOWN,
    KeyEvent.KEYCODE_NUMPAD_2
)

private fun isLeft(keyCode: Int) = keyCode in setOf(
    KeyEvent.KEYCODE_DPAD_LEFT,
    KeyEvent.KEYCODE_NUMPAD_4
)

private fun isRight(keyCode: Int) = keyCode in setOf(
    KeyEvent.KEYCODE_DPAD_RIGHT,
    KeyEvent.KEYCODE_NUMPAD_6
)

private fun isMenu(keyCode: Int) = keyCode in setOf(
    KeyEvent.KEYCODE_MENU,
    KeyEvent.KEYCODE_F1,            // some Chinese remotes send F1 for menu
    KeyEvent.KEYCODE_F2,
    KeyEvent.KEYCODE_F3,
    KeyEvent.KEYCODE_TV_INPUT,
    KeyEvent.KEYCODE_SETTINGS
)

// ─────────────────────────────────────────────────────────────
//  Active menus
// ─────────────────────────────────────────────────────────────

enum class ActiveMenu { NONE, QUALITY, AUDIO, SUBTITLES, SERVERS, SETTINGS }

// ─────────────────────────────────────────────────────────────
//  PLAYER SCREEN
// ─────────────────────────────────────────────────────────────

@Media3OptIn(androidx.media3.common.util.UnstableApi::class)
@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun PlayerScreen(
    channelName: String,
    streamUrl: String,
    logoUrl: String?,
    onBack: () -> Unit
) {
    val context = LocalContext.current
    val repository = remember { PocketBaseRepository() }

    // ── Channel state ──
    var currentChannelName by remember { mutableStateOf(channelName) }
    var currentStreamUrl   by remember { mutableStateOf(streamUrl) }
    var currentLogoUrl     by remember { mutableStateOf(logoUrl) }

    var activeServerIndex  by remember { mutableStateOf(0) }

    // ── Player state ──
    var isBuffering    by remember { mutableStateOf(true) }
    var isPlayingState by remember { mutableStateOf(true) }
    var retryCount     by remember { mutableStateOf(0) }
    var streamFailed   by remember { mutableStateOf(false) }

    // ── UI visibility ──
    var showZapList  by remember { mutableStateOf(false) }
    var showControls by remember { mutableStateOf(false) }
    var activeMenu   by remember { mutableStateOf(ActiveMenu.NONE) }

    // Incrementing triggers for LaunchedEffect re-runs
    var controlsActivityTrigger by remember { mutableStateOf(0) }
    var zapBannerTrigger        by remember { mutableStateOf(0) }
    var showZapBanner           by remember { mutableStateOf(false) }

    var channelsList by remember { mutableStateOf<List<TvChannel>>(emptyList()) }

    val validServers = remember(currentStreamUrl, channelsList) {
        val ch = channelsList.firstOrNull { it.url == currentStreamUrl }
        val servers = mutableListOf<Pair<String, String>>()
        if (ch != null) {
            servers.add(Pair("SERVER 1", ch.url))
            if (!ch.url2.isNullOrEmpty()) {
                val n2 = if (!ch.url2Name.isNullOrEmpty()) ch.url2Name else "SERVER 2"
                servers.add(Pair(n2.uppercase(), ch.url2))
            }
            if (!ch.url3.isNullOrEmpty()) {
                val n3 = if (!ch.url3Name.isNullOrEmpty()) ch.url3Name else "SERVER 3"
                servers.add(Pair(n3.uppercase(), ch.url3))
            }
        } else {
            servers.add(Pair("SERVER 1", currentStreamUrl))
        }
        servers
    }

    LaunchedEffect(Unit) {
        channelsList = repository.getChannels()
    }

    // Auto-hide zap banner after 3 s
    LaunchedEffect(showZapBanner, zapBannerTrigger) {
        if (showZapBanner) {
            delay(3_000)
            showZapBanner = false
        }
    }

    // Auto-hide controls after 5 s of inactivity (or 15s if sub-menu is open)
    LaunchedEffect(showControls, controlsActivityTrigger, activeMenu) {
        if (showControls) {
            if (activeMenu == ActiveMenu.NONE) {
                delay(5_000)
                showControls = false
            } else {
                delay(15_000)
                activeMenu = ActiveMenu.NONE
                showControls = false
            }
        }
    }

    fun wakeUpControls() {
        controlsActivityTrigger++
        showControls = true
    }

    // ── ExoPlayer ──────────────────────────────────────────────
    // Built once, never recreated — avoids surface re-allocation lag
    val exoPlayer = remember {
        val loadControl = DefaultLoadControl.Builder()
            .setBufferDurationsMs(
                /* minBufferMs   */ 3_000,
                /* maxBufferMs   */ 15_000,
                /* bufferForPlayback */ 500,
                /* bufferForPlaybackAfterRebuffer */ 1_000
            )
            .setPrioritizeTimeOverSizeThresholds(true)
            .build()

        val httpFactory = DefaultHttpDataSource.Factory()
            .setUserAgent("SmartIPTV/1.0")
            .setAllowCrossProtocolRedirects(true)
            .setConnectTimeoutMs(10_000)
            .setReadTimeoutMs(15_000)

        // EXTENSION_RENDERER_MODE_PREFER — uses hardware decoder if available,
        // falls back to software. Works on Chinese boxes that only expose SW decoders.
        val renderersFactory = DefaultRenderersFactory(context)
            .setExtensionRendererMode(DefaultRenderersFactory.EXTENSION_RENDERER_MODE_PREFER)

        ExoPlayer.Builder(context)
            .setRenderersFactory(renderersFactory)
            .setLoadControl(loadControl)
            .setMediaSourceFactory(DefaultMediaSourceFactory(httpFactory))
            .build()
            .apply {
                setWakeMode(androidx.media3.common.C.WAKE_MODE_NETWORK)
                // SCALE_TO_FIT works on every TV regardless of resolution
                videoScalingMode = androidx.media3.common.C.VIDEO_SCALING_MODE_SCALE_TO_FIT
            }
    }

    // Load / switch stream — stops the old one cleanly before preparing new
    LaunchedEffect(currentStreamUrl, activeServerIndex) {
        if (validServers.isEmpty()) return@LaunchedEffect
        if (activeServerIndex >= validServers.size) activeServerIndex = 0
        val playUrl = validServers[activeServerIndex].second
        retryCount = 0
        streamFailed = false
        TvViewerService.joinChannel(playUrl)
        isBuffering = true
        exoPlayer.stop()
        exoPlayer.clearMediaItems()
        
        val ch = channelsList.firstOrNull { it.url == currentStreamUrl }
        var finalUrl = playUrl
        var finalDrmScheme = ch?.drmScheme
        var finalDrmLicense = ch?.drmLicense

        if (finalUrl.contains("|drmScheme=")) {
            val parts = finalUrl.split("|")
            finalUrl = parts[0]
            val params = parts[1].split("&")
            for (param in params) {
                if (param.startsWith("drmScheme=")) {
                    finalDrmScheme = param.substringAfter("drmScheme=")
                } else if (param.startsWith("drmLicense=")) {
                    finalDrmLicense = param.substringAfter("drmLicense=")
                }
            }
        }
        
        val builder = MediaItem.Builder().setUri(finalUrl)

        if (finalUrl.contains("m3u8", ignoreCase = true)) {
            builder.setMimeType(androidx.media3.common.MimeTypes.APPLICATION_M3U8)
        } else if (finalUrl.contains("mpd", ignoreCase = true)) {
            builder.setMimeType(androidx.media3.common.MimeTypes.APPLICATION_MPD)
        }

        if (!finalDrmScheme.isNullOrEmpty() && !finalDrmLicense.isNullOrEmpty()) {
            val schemeUuid = when (finalDrmScheme.lowercase()) {
                "widevine" -> androidx.media3.common.C.WIDEVINE_UUID
                "playready" -> androidx.media3.common.C.PLAYREADY_UUID
                "clearkey" -> androidx.media3.common.C.CLEARKEY_UUID
                else -> androidx.media3.common.C.WIDEVINE_UUID
            }
            val drmConfigBuilder = MediaItem.DrmConfiguration.Builder(schemeUuid)
            
            if (finalDrmScheme.lowercase() == "clearkey" && finalDrmLicense.contains(":") && !finalDrmLicense.startsWith("http")) {
                try {
                    val keys = finalDrmLicense.split(",")
                    val jsonKeys = keys.map { keyPair ->
                        val parts = keyPair.split(":")
                        if (parts.size == 2) {
                            val kidHex = parts[0].trim()
                            val keyHex = parts[1].trim()
                            val kidBytes = kidHex.chunked(2).map { it.toInt(16).toByte() }.toByteArray()
                            val keyBytes = keyHex.chunked(2).map { it.toInt(16).toByte() }.toByteArray()
                            val kidB64 = android.util.Base64.encodeToString(kidBytes, android.util.Base64.URL_SAFE or android.util.Base64.NO_PADDING or android.util.Base64.NO_WRAP)
                            val keyB64 = android.util.Base64.encodeToString(keyBytes, android.util.Base64.URL_SAFE or android.util.Base64.NO_PADDING or android.util.Base64.NO_WRAP)
                            "{\"kty\":\"oct\",\"k\":\"${keyB64}\",\"kid\":\"${kidB64}\"}"
                        } else ""
                    }.filter { it.isNotEmpty() }.joinToString(",")
                    
                    val json = "{\"keys\":[$jsonKeys],\"type\":\"temporary\"}"
                    val dataUri = "data:application/json;base64," + android.util.Base64.encodeToString(json.toByteArray(), android.util.Base64.NO_WRAP)
                    drmConfigBuilder.setLicenseUri(dataUri)
                } catch (e: Exception) {
                    drmConfigBuilder.setLicenseUri(finalDrmLicense)
                }
            } else {
                drmConfigBuilder.setLicenseUri(finalDrmLicense)
            }
            drmConfigBuilder.setForceDefaultLicenseUri(true)
            drmConfigBuilder.setForceSessionsForAudioAndVideoTracks(true)
            builder.setDrmConfiguration(drmConfigBuilder.build())
        }

        exoPlayer.setMediaItem(builder.build())
        exoPlayer.prepare()
        exoPlayer.playWhenReady = true
        exoPlayer.play()
    }

    DisposableEffect(Unit) {
        onDispose {
            TvViewerService.leaveChannel()
            exoPlayer.release()
        }
    }

    val scope = rememberCoroutineScope()

    // Player listener — stable reference, recreated only when exoPlayer changes
    val playerListener = remember(exoPlayer) {
        object : Media3Player.Listener {
            override fun onPlaybackStateChanged(state: Int) {
                isBuffering    = state == Media3Player.STATE_BUFFERING
                isPlayingState = exoPlayer.isPlaying
                if (state == Media3Player.STATE_READY) {
                    retryCount = 0
                    streamFailed = false
                }
                // Live stream ended (stream server restarted) → reconnect with backoff
                if (state == Media3Player.STATE_ENDED) {
                    if (retryCount < 3) {
                        retryCount++
                        scope.launch {
                            delay(2_000L * retryCount)
                            try {
                                exoPlayer.seekToDefaultPosition()
                                exoPlayer.prepare()
                                exoPlayer.play()
                            } catch (_: Exception) {}
                        }
                    } else {
                        if (activeServerIndex + 1 < validServers.size) {
                            activeServerIndex++
                        } else {
                            streamFailed = true
                        }
                    }
                }
            }
            override fun onPlayerError(error: PlaybackException) {
                isBuffering = false
                // Network / codec error → reconnect with backoff
                if (retryCount < 3) {
                    retryCount++
                    scope.launch {
                        delay(3_000L * retryCount)
                        try {
                            exoPlayer.seekToDefaultPosition()
                            exoPlayer.prepare()
                            exoPlayer.play()
                        } catch (_: Exception) {}
                    }
                } else {
                    if (activeServerIndex + 1 < validServers.size) {
                        activeServerIndex++
                    } else {
                        streamFailed = true
                    }
                }
            }
            override fun onIsPlayingChanged(isPlaying: Boolean) {
                isPlayingState = isPlaying
            }
        }
    }

    DisposableEffect(exoPlayer) {
        exoPlayer.addListener(playerListener)
        onDispose { exoPlayer.removeListener(playerListener) }
    }

    // ── Focus requesters ───────────────────────────────────────
    val mainFocusRequester     = remember { FocusRequester() }
    val controlsFocusRequester = remember { FocusRequester() }

    // Return focus to correct layer whenever visibility changes
    LaunchedEffect(showZapList, showControls, activeMenu) {
        when {
            !showZapList && !showControls && activeMenu == ActiveMenu.NONE -> {
                runCatching { mainFocusRequester.requestFocus() }
            }
            showControls && activeMenu == ActiveMenu.NONE -> {
                delay(80) // let animation start first
                runCatching { controlsFocusRequester.requestFocus() }
            }
        }
    }

    BackHandler {
        when {
            activeMenu != ActiveMenu.NONE -> activeMenu = ActiveMenu.NONE
            showControls                  -> showControls = false
            showZapList                   -> showZapList  = false
            else                          -> onBack()
        }
    }

    // ── Root Box — captures ALL key events before sub-composables ──
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
            .focusRequester(mainFocusRequester)
            .focusable()
            .onKeyEvent { keyEvent ->
                if (keyEvent.nativeKeyEvent.action != KeyEvent.ACTION_DOWN) return@onKeyEvent false
                val code = keyEvent.nativeKeyEvent.keyCode

                // ── Back ──
                // Handle back BEFORE waking up controls, otherwise waking controls 
                // intercepts the back press in an infinite loop!
                if (isBack(code)) {
                    return@onKeyEvent when {
                        activeMenu != ActiveMenu.NONE -> { activeMenu = ActiveMenu.NONE; true }
                        showControls                  -> { showControls = false; true }
                        showZapList                   -> { showZapList  = false; true }
                        else                          -> { onBack(); true }
                    }
                }

                // Every OTHER key wakes the controls HUD
                wakeUpControls()

                // ── Quick Zap (channel surf without opening OSD) ──
                if (!showControls && !showZapList && activeMenu == ActiveMenu.NONE) {
                    if (isUp(code) || isDown(code)) {
                        if (channelsList.isNotEmpty()) {
                            val idx = channelsList.indexOfFirst { it.url == currentStreamUrl }
                            if (idx != -1) {
                                val newIdx = if (isUp(code)) {
                                    (idx + 1) % channelsList.size
                                } else {
                                    if (idx - 1 < 0) channelsList.size - 1 else idx - 1
                                }
                                val ch = channelsList[newIdx]
                                activeServerIndex  = 0
                                currentStreamUrl   = ch.url
                                currentChannelName = ch.name
                                currentLogoUrl     = ch.logo
                                showControls  = false
                                showZapBanner = true
                                zapBannerTrigger++
                            }
                        }
                        return@onKeyEvent true
                    }
                }

                // ── Open channel drawer with LEFT or CENTER when idle ──
                if (!showZapList && !showControls && activeMenu == ActiveMenu.NONE) {
                    if (isLeft(code) || isConfirm(code)) {
                        showZapList = true
                        return@onKeyEvent true
                    }
                    // Menu key opens controls
                    if (isMenu(code)) {
                        showControls = true
                        return@onKeyEvent true
                    }
                }

                false
            }
    ) {

        // ── Video surface ──────────────────────────────────────
        // key() keeps the PlayerView alive across recompositions
        key(exoPlayer) {
            AndroidView(
                factory = { ctx ->
                    PlayerView(ctx).apply {
                        player        = exoPlayer
                        useController = false
                        resizeMode    = androidx.media3.ui.AspectRatioFrameLayout.RESIZE_MODE_FIT
                        isFocusable   = false
                        isFocusableInTouchMode = false
                    }
                },
                modifier = Modifier.fillMaxSize()
            )
        }

        // ── Buffering overlay ──────────────────────────────────
        if (isBuffering && !streamFailed) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.55f)),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    // Keep channel logo visible so user knows what's loading
                    if (!currentLogoUrl.isNullOrEmpty()) {
                        AsyncImage(
                            model = currentLogoUrl,
                            contentDescription = null,
                            modifier = Modifier
                                .size(64.dp)
                                .clip(RoundedCornerShape(12.dp))
                        )
                        Spacer(Modifier.height(20.dp))
                    }
                    CircularProgressIndicator(
                        color = UltraTokens.Blue,
                        modifier = Modifier.size(48.dp),
                        strokeWidth = 3.dp
                    )
                    Spacer(Modifier.height(14.dp))
                    Text(
                        currentChannelName,
                        color = Color.White,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                    Spacer(Modifier.height(4.dp))
                    Text(
                        "Loading stream…",
                        color = UltraTokens.TextSecondary,
                        fontSize = 12.sp
                    )
                }
            }
        }

        if (streamFailed) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.8f)),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(
                        imageVector = Icons.Rounded.ErrorOutline,
                        contentDescription = "Error",
                        tint = Color(0xFFFF4757),
                        modifier = Modifier.size(64.dp)
                    )
                    Spacer(Modifier.height(16.dp))
                    Text(
                        "Stream Offline",
                        color = Color.White,
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(Modifier.height(8.dp))
                    Text(
                        "Please try another channel.",
                        color = UltraTokens.TextSecondary,
                        fontSize = 14.sp
                    )
                }
            }
        }

        // ── Zap Banner ─────────────────────────────────────────
        AnimatedVisibility(
            visible = showZapBanner && !showControls && !showZapList,
            enter   = slideInVertically { it } + fadeIn(tween(220)),
            exit    = slideOutVertically { it } + fadeOut(tween(220)),
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(start = 48.dp, end = 48.dp, bottom = 48.dp)
        ) {
            ZapBanner(
                channelName = currentChannelName,
                logoUrl     = currentLogoUrl,
                channelIndex = channelsList.indexOfFirst { it.url == currentStreamUrl }
                    .takeIf { it >= 0 }?.plus(1)
            )
        }

        // ── OSD (top bar + bottom controls) ───────────────────
        AnimatedVisibility(
            visible = showControls && !showZapList,
            enter   = fadeIn(tween(250)),
            exit    = fadeOut(tween(250))
        ) {
            OsdOverlay(
                channelName    = currentChannelName,
                logoUrl        = currentLogoUrl,
                isPlaying      = isPlayingState,
                activeMenu     = activeMenu,
                validServers   = validServers,
                activeServerIndex = activeServerIndex,
                onSelectServer = { activeServerIndex = it },
                controlsFocusRequester = controlsFocusRequester,
                onTogglePlay   = {
                    wakeUpControls()
                    if (isPlayingState) exoPlayer.pause() else exoPlayer.play()
                },
                onOpenMenu     = { menu ->
                    activeMenu = menu
                    wakeUpControls()
                },
                onOpenChannels = {
                    showZapList  = true
                    showControls = false
                },
                onWake         = { wakeUpControls() }
            )
        }

        // ── Right side sub-menu (Quality / Audio / Subs / Settings) ──
        AnimatedVisibility(
            visible  = activeMenu != ActiveMenu.NONE,
            enter    = slideInHorizontally { it } + fadeIn(tween(220)),
            exit     = slideOutHorizontally { it } + fadeOut(tween(220)),
            modifier = Modifier.align(Alignment.CenterEnd)
        ) {
            SubMenuPanel(
                activeMenu = activeMenu,
                validServers = validServers,
                activeServerIndex = activeServerIndex,
                onSelectServer = { activeServerIndex = it },
                onDismiss  = { activeMenu = ActiveMenu.NONE }
            )
        }

        // ── Channel Drawer (left) ──────────────────────────────
        AnimatedVisibility(
            visible = showZapList,
            enter   = slideInHorizontally { -it } + fadeIn(tween(220)),
            exit    = slideOutHorizontally { -it } + fadeOut(tween(220))
        ) {
            ZapDrawer(
                channels       = channelsList,
                currentUrl     = currentStreamUrl,
                onPick         = { ch ->
                    activeServerIndex  = 0
                    currentStreamUrl   = ch.url
                    currentChannelName = ch.name
                    currentLogoUrl     = ch.logo
                    showZapList = false
                },
                onDismiss      = { showZapList = false }
            )
        }
    }
}

// ─────────────────────────────────────────────────────────────
//  ZAP BANNER
// ─────────────────────────────────────────────────────────────

@Composable
private fun ZapBanner(
    channelName: String,
    logoUrl: String?,
    channelIndex: Int?
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(
                Brush.horizontalGradient(
                    colors = listOf(
                        UltraTokens.SurfaceHover,
                        UltraTokens.SurfaceHover.copy(alpha = 0.9f)
                    )
                )
            )
            .padding(horizontal = 24.dp, vertical = 18.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            // Logo
            Box(
                modifier = Modifier
                    .size(56.dp)
                    .clip(RoundedCornerShape(10.dp))
                    .background(Color.White.copy(0.05f)),
                contentAlignment = Alignment.Center
            ) {
                if (!logoUrl.isNullOrEmpty()) {
                    AsyncImage(
                        model = logoUrl,
                        contentDescription = null,
                        contentScale = ContentScale.Fit,
                        modifier = Modifier.fillMaxSize().padding(6.dp)
                    )
                } else {
                    Text(
                        channelName.take(2).uppercase(),
                        color = UltraTokens.TextSecondary,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
            Spacer(Modifier.width(16.dp))
            Column {
                if (channelIndex != null) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            modifier = Modifier
                                .size(7.dp)
                                .clip(CircleShape)
                                .background(UltraTokens.Live)
                        )
                        Spacer(Modifier.width(6.dp))
                        Text(
                            "LIVE  ·  CH $channelIndex",
                            color = UltraTokens.Blue,
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            letterSpacing = 1.sp
                        )
                    }
                    Spacer(Modifier.height(3.dp))
                }
                Text(
                    channelName,
                    color = Color.White,
                    fontSize = 22.sp,
                    fontWeight = FontWeight.Bold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
        // Clock
        AndroidView(
            factory = { ctx ->
                TextClock(ctx).apply {
                    format12Hour = "hh:mm a"
                    format24Hour = "HH:mm"
                    textSize = 18f
                    setTextColor(android.graphics.Color.WHITE)
                    typeface = android.graphics.Typeface.DEFAULT_BOLD
                }
            }
        )
    }
}

// ─────────────────────────────────────────────────────────────
//  OSD OVERLAY  (top info bar + bottom controls bar)
// ─────────────────────────────────────────────────────────────

@Composable
private fun OsdOverlay(
    channelName: String,
    logoUrl: String?,
    isPlaying: Boolean,
    activeMenu: ActiveMenu,
    validServers: List<Pair<String, String>>,
    activeServerIndex: Int,
    onSelectServer: (Int) -> Unit,
    controlsFocusRequester: FocusRequester,
    onTogglePlay: () -> Unit,
    onOpenMenu: (ActiveMenu) -> Unit,
    onOpenChannels: () -> Unit,
    onWake: () -> Unit
) {
    Box(modifier = Modifier.fillMaxSize()) {

        // ── TOP INFO BAR ──
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .align(Alignment.TopCenter)
                .background(
                    Brush.verticalGradient(
                        colors = listOf(
                            Color.Black.copy(0.85f),
                            Color.Black.copy(0.4f),
                            Color.Transparent
                        )
                    )
                )
                .padding(horizontal = 40.dp, vertical = 24.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Channel identity
            Row(verticalAlignment = Alignment.CenterVertically) {
                if (!logoUrl.isNullOrEmpty()) {
                    AsyncImage(
                        model = logoUrl,
                        contentDescription = null,
                        modifier = Modifier
                            .size(44.dp)
                            .clip(RoundedCornerShape(10.dp))
                    )
                    Spacer(Modifier.width(14.dp))
                }
                Column {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            modifier = Modifier
                                .size(6.dp)
                                .clip(CircleShape)
                                .background(UltraTokens.Live)
                        )
                        Spacer(Modifier.width(6.dp))
                        Text(
                            "LIVE",
                            color = UltraTokens.Blue,
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Bold,
                            letterSpacing = 2.sp
                        )
                    }
                    Spacer(Modifier.height(2.dp))
                    Text(
                        channelName,
                        color = Color.White,
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }
            // Clock
            AndroidView(
                factory = { ctx ->
                    TextClock(ctx).apply {
                        format12Hour = "hh:mm a"
                        format24Hour = "HH:mm"
                        textSize = 20f
                        setTextColor(android.graphics.Color.WHITE)
                        typeface = android.graphics.Typeface.DEFAULT_BOLD
                    }
                }
            )
        }

        // ── BOTTOM CONTROLS BAR ──
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .align(Alignment.BottomCenter)
                .background(
                    Brush.verticalGradient(
                        colors = listOf(
                            Color.Transparent,
                            Color.Black.copy(0.65f),
                            Color.Black.copy(0.95f)
                        )
                    )
                )
                .padding(horizontal = 40.dp, vertical = 24.dp)
        ) {
            // LIVE indicator bar
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.padding(bottom = 16.dp)
            ) {
                Box(
                    modifier = Modifier
                        .size(7.dp)
                        .clip(CircleShape)
                        .background(UltraTokens.Live)
                )
                Spacer(Modifier.width(8.dp))
                Text(
                    "LIVE",
                    color = Color.White,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 2.sp
                )
            }

            // Controls row
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                modifier = Modifier.focusGroup()
            ) {
                // ── Channels (first, accent tinted) ──
                OsdIconButton(
                    icon      = Icons.Rounded.List,
                    label     = "Channels",
                    accent    = true,
                    modifier  = Modifier.focusRequester(controlsFocusRequester),
                    onWake    = onWake,
                    onClick   = onOpenChannels
                )

                OsdDivider()

                // ── Quality ──
                OsdIconButton(
                    icon    = Icons.Rounded.HighQuality,
                    label   = "Quality",
                    onWake  = onWake,
                    onClick = { onOpenMenu(ActiveMenu.QUALITY) }
                )

                // ── Audio ──
                OsdIconButton(
                    icon    = Icons.Rounded.Audiotrack,
                    label   = "Audio",
                    onWake  = onWake,
                    onClick = { onOpenMenu(ActiveMenu.AUDIO) }
                )

                // ── Subtitles ──
                OsdIconButton(
                    icon    = Icons.Rounded.Subtitles,
                    label   = "Subtitles",
                    onWake  = onWake,
                    onClick = { onOpenMenu(ActiveMenu.SUBTITLES) }
                )

                // ── EPG / Guide ──
                OsdIconButton(
                    icon    = Icons.Rounded.DateRange,
                    label   = "Guide",
                    onWake  = onWake,
                    onClick = {}
                )

                // Push settings to the right
                Spacer(Modifier.weight(1f))

                // Channel chip (read-only info)
                ChannelChip(channelName = channelName, logoUrl = logoUrl)

                OsdDivider()

                // ── Settings ──
                OsdIconButton(
                    icon    = Icons.Rounded.Settings,
                    label   = "Settings",
                    onWake  = onWake,
                    onClick = { onOpenMenu(ActiveMenu.SETTINGS) }
                )
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────
//  OSD ICON BUTTON
//  • No border by default — clean modern look
//  • Indigo background only on focus
//  • Tooltip floats above on focus (TV-friendly)
//  • Handles all confirm keys via onKeyEvent
// ─────────────────────────────────────────────────────────────

@Composable
private fun OsdIconButton(
    icon: ImageVector,
    label: String,
    modifier: Modifier = Modifier,
    accent: Boolean = false,
    onWake: () -> Unit,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    // Smooth scale pop on focus — use spring so it feels physical
    val scale by animateFloatAsState(
        targetValue = if (isFocused) 1.12f else 1f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness    = Spring.StiffnessMediumLow
        ),
        label = "osd_scale"
    )

    val bgColor by animateColorAsState(
        targetValue = when {
            isFocused && accent -> UltraTokens.Blue
            isFocused           -> Color.White.copy(alpha = 0.18f)
            accent              -> UltraTokens.Blue.copy(alpha = 0.15f)
            else                -> Color.Transparent  // no background when idle
        },
        animationSpec = tween(180),
        label = "osd_bg"
    )

    val iconTint by animateColorAsState(
        targetValue = if (isFocused && accent) Color.White
                      else if (isFocused) Color.White
                      else if (accent) UltraTokens.Blue
                      else Color.White.copy(alpha = 0.75f),
        animationSpec = tween(180),
        label = "osd_tint"
    )

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = modifier
    ) {
        // Floating tooltip — only visible when focused
        AnimatedVisibility(
            visible = isFocused,
            enter   = fadeIn(tween(150)) + slideInVertically { it / 2 },
            exit    = fadeOut(tween(100))
        ) {
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(6.dp))
                    .background(Color.Black.copy(alpha = 0.75f))
                    .padding(horizontal = 8.dp, vertical = 4.dp)
            ) {
                Text(
                    label,
                    color = Color.White,
                    fontSize = 10.sp,
                    fontWeight = FontWeight.SemiBold
                )
            }
        }

        Spacer(Modifier.height(4.dp))

        Box(
            modifier = Modifier
                .size(48.dp)
                .scale(scale)
                .clip(RoundedCornerShape(12.dp))
                .background(bgColor)
                // No border — clean look requested
                .onFocusChanged {
                    isFocused = it.isFocused
                    if (it.isFocused) onWake()
                }
                .focusable()
                .onKeyEvent { ke ->
                    if (ke.nativeKeyEvent.action == KeyEvent.ACTION_DOWN &&
                        isConfirm(ke.nativeKeyEvent.keyCode)
                    ) {
                        onClick()
                        true
                    } else false
                },
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = label,
                tint = iconTint,
                modifier = Modifier.size(22.dp)
            )
        }
    }
}

// ─────────────────────────────────────────────────────────────
//  OSD DIVIDER
// ─────────────────────────────────────────────────────────────

@Composable
private fun OsdDivider() {
    Box(
        modifier = Modifier
            .padding(horizontal = 4.dp)
            .width(1.dp)
            .height(28.dp)
            .background(Color.White.copy(alpha = 0.1f))
    )
}

// ─────────────────────────────────────────────────────────────
//  CHANNEL CHIP (read-only info pill in OSD)
// ─────────────────────────────────────────────────────────────

@Composable
private fun ChannelChip(channelName: String, logoUrl: String?) {
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(10.dp))
            .background(Color.White.copy(alpha = 0.07f))
            .padding(horizontal = 12.dp, vertical = 0.dp)
            .height(48.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Box(
            modifier = Modifier
                .size(26.dp)
                .clip(RoundedCornerShape(5.dp))
                .background(Color.White.copy(0.08f)),
            contentAlignment = Alignment.Center
        ) {
            if (!logoUrl.isNullOrEmpty()) {
                AsyncImage(
                    model = logoUrl,
                    contentDescription = null,
                    contentScale = ContentScale.Fit,
                    modifier = Modifier.fillMaxSize().padding(3.dp)
                )
            } else {
                Text(
                    channelName.take(2).uppercase(),
                    color = UltraTokens.TextSecondary,
                    fontSize = 8.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }
        Text(
            channelName,
            color = Color.White.copy(alpha = 0.7f),
            fontSize = 12.sp,
            fontWeight = FontWeight.SemiBold,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
    }
}

// ─────────────────────────────────────────────────────────────
//  SUB-MENU PANEL  (Quality / Audio / Subtitles / Settings)
// ─────────────────────────────────────────────────────────────

@Composable
private fun SubMenuPanel(
    activeMenu: ActiveMenu,
    validServers: List<Pair<String, String>>,
    activeServerIndex: Int,
    onSelectServer: (Int) -> Unit,
    onDismiss: () -> Unit
) {
    val menuFocusRequester = remember { FocusRequester() }

    LaunchedEffect(activeMenu) {
        if (activeMenu != ActiveMenu.NONE) {
            delay(80)
            runCatching { menuFocusRequester.requestFocus() }
        }
    }

    Box(
        modifier = Modifier
            .fillMaxHeight()
            .width(340.dp)
            .background(UltraTokens.SurfaceHover)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(24.dp)
        ) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = when (activeMenu) {
                        ActiveMenu.SERVERS   -> "SERVERS"
                        ActiveMenu.QUALITY   -> "VIDEO QUALITY"
                        ActiveMenu.AUDIO     -> "AUDIO TRACKS"
                        ActiveMenu.SUBTITLES -> "SUBTITLES"
                        ActiveMenu.SETTINGS  -> "QUICK SETTINGS"
                        else                 -> ""
                    },
                    color = Color.White,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 1.sp
                )
                Text(
                    "← Back",
                    color = UltraTokens.Divider,
                    fontSize = 11.sp
                )
            }

            Spacer(Modifier.height(4.dp))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(Color.White.copy(alpha = 0.07f))
            )
            Spacer(Modifier.height(16.dp))

            if (activeMenu == ActiveMenu.SETTINGS) {
                SettingsPanel(
                    focusRequester = menuFocusRequester,
                    onDismiss      = onDismiss
                )
            } else {
                val items = when (activeMenu) {
                    ActiveMenu.SERVERS   -> validServers.map { it.first }
                    ActiveMenu.QUALITY   -> listOf("Auto", "1080p HD", "720p", "480p", "360p")
                    ActiveMenu.AUDIO     -> listOf("Track 1 (Default)", "Track 2", "Track 3")
                    ActiveMenu.SUBTITLES -> listOf("Off", "English", "Arabic", "French", "Spanish")
                    else                 -> emptyList()
                }
                LazyColumn(
                    verticalArrangement = Arrangement.spacedBy(4.dp),
                    modifier = Modifier.focusRestorer()
                ) {
                    items(items.size) { i ->
                        val isSel = if (activeMenu == ActiveMenu.SERVERS) i == activeServerIndex else i == 0
                        TrackOption(
                            title      = items[i],
                            isSelected = isSel,
                            modifier   = if (i == 0) Modifier.focusRequester(menuFocusRequester) else Modifier,
                            onClick    = { 
                                if (activeMenu == ActiveMenu.SERVERS) {
                                    onSelectServer(i)
                                }
                                onDismiss() 
                            }
                        )
                    }
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────
//  TRACK OPTION
// ─────────────────────────────────────────────────────────────

@Composable
private fun TrackOption(
    title: String,
    isSelected: Boolean,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    val bgColor by animateColorAsState(
        targetValue = when {
            isFocused  -> UltraTokens.Blue
            isSelected -> UltraTokens.SurfaceSelected
            else       -> Color.Transparent
        },
        animationSpec = tween(160),
        label = "track_bg"
    )

    Box(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(10.dp))
            .background(bgColor)
            .onFocusChanged { isFocused = it.isFocused }
            .focusable()
            .onKeyEvent { ke ->
                if (ke.nativeKeyEvent.action == KeyEvent.ACTION_DOWN &&
                    isConfirm(ke.nativeKeyEvent.keyCode)
                ) { onClick(); true } else false
            }
            .padding(horizontal = 16.dp, vertical = 14.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text       = title,
                color      = if (isFocused) Color.White
                             else if (isSelected) UltraTokens.Blue
                             else UltraTokens.TextSecondary,
                fontSize   = 14.sp,
                fontWeight = if (isSelected || isFocused) FontWeight.Bold else FontWeight.Normal
            )
            if (isSelected) {
                Icon(
                    Icons.Rounded.Check,
                    contentDescription = null,
                    tint     = if (isFocused) Color.White else UltraTokens.Blue,
                    modifier = Modifier.size(18.dp)
                )
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────
//  SETTINGS PANEL
// ─────────────────────────────────────────────────────────────

@Composable
private fun SettingsPanel(
    focusRequester: FocusRequester,
    onDismiss: () -> Unit
) {
    var selectedAspect  by remember { mutableStateOf("Fit") }
    var selectedDecoder by remember { mutableStateOf("Auto") }
    var selectedSleep   by remember { mutableStateOf("Off") }

    LazyColumn(
        verticalArrangement = Arrangement.spacedBy(3.dp),
        modifier = Modifier.fillMaxSize().focusRestorer()
    ) {
        item { SettingSectionLabel("ASPECT RATIO") }
        val aspects = listOf("Fit", "Fill", "16:9", "4:3", "Stretch")
        items(aspects.size) { i ->
            SettingRadioItem(
                title      = aspects[i],
                isSelected = selectedAspect == aspects[i],
                modifier   = if (i == 0) Modifier.focusRequester(focusRequester) else Modifier,
                onClick    = { selectedAspect = aspects[i] }
            )
        }

        item { Spacer(Modifier.height(10.dp)); SettingSectionLabel("DECODER") }
        val decoders = listOf("Auto", "Hardware (HW)", "Software (SW)")
        items(decoders.size) { i ->
            SettingRadioItem(
                title      = decoders[i],
                isSelected = selectedDecoder == decoders[i],
                onClick    = { selectedDecoder = decoders[i] }
            )
        }

        item { Spacer(Modifier.height(10.dp)); SettingSectionLabel("SLEEP TIMER") }
        val sleeps = listOf("Off", "15 min", "30 min", "1 hour", "2 hours")
        items(sleeps.size) { i ->
            SettingRadioItem(
                title      = sleeps[i],
                isSelected = selectedSleep == sleeps[i],
                onClick    = { selectedSleep = sleeps[i] }
            )
        }
    }
}

@Composable
private fun SettingSectionLabel(title: String) {
    Text(
        text          = title,
        color         = UltraTokens.Blue,
        fontSize      = 10.sp,
        fontWeight    = FontWeight.Bold,
        letterSpacing = 2.sp,
        modifier      = Modifier.padding(vertical = 8.dp, horizontal = 4.dp)
    )
}

@Composable
private fun SettingRadioItem(
    title: String,
    isSelected: Boolean,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    val bgColor by animateColorAsState(
        targetValue = when {
            isFocused  -> UltraTokens.Blue
            isSelected -> UltraTokens.SurfaceSelected
            else       -> Color.Transparent
        },
        animationSpec = tween(140),
        label = "setting_bg"
    )

    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp))
            .background(bgColor)
            .onFocusChanged { isFocused = it.isFocused }
            .focusable()
            .onKeyEvent { ke ->
                if (ke.nativeKeyEvent.action == KeyEvent.ACTION_DOWN &&
                    isConfirm(ke.nativeKeyEvent.keyCode)
                ) { onClick(); true } else false
            }
            .padding(horizontal = 14.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text       = title,
            color      = if (isFocused) Color.White
                         else if (isSelected) UltraTokens.Blue
                         else UltraTokens.TextSecondary,
            fontSize   = 13.sp,
            fontWeight = if (isSelected || isFocused) FontWeight.SemiBold else FontWeight.Normal
        )
        // Radio circle
        Box(
            modifier = Modifier
                .size(17.dp)
                .clip(CircleShape)
                .background(Color.Transparent)
                .run {
                    val borderColor = if (isFocused) Color.White
                                      else if (isSelected) UltraTokens.Blue
                                      else UltraTokens.Divider
                    // draw border via padding trick — avoids extra composable
                    background(borderColor)
                        .padding(1.5.dp)
                        .clip(CircleShape)
                        .background(
                            if (isFocused) UltraTokens.Blue
                            else UltraTokens.SurfaceHover
                        )
                        .padding(if (isSelected) 3.5.dp else 8.dp)
                        .clip(CircleShape)
                        .background(
                            if (isSelected)
                                if (isFocused) Color.White else UltraTokens.Blue
                            else Color.Transparent
                        )
                }
        ) {}
    }
}

// ─────────────────────────────────────────────────────────────
//  ZAP DRAWER  (left-side channel list)
// ─────────────────────────────────────────────────────────────

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
private fun ZapDrawer(
    channels: List<TvChannel>,
    currentUrl: String,
    onPick: (TvChannel) -> Unit,
    onDismiss: () -> Unit
) {
    BackHandler { onDismiss() }

    val listState    = rememberLazyListState()
    val initialIdx   = remember(channels) {
        channels.indexOfFirst { it.url == currentUrl }.coerceAtLeast(0)
    }
    val currentFocus = remember { FocusRequester() }
    var focusSet     by remember { mutableStateOf(false) }

    LaunchedEffect(channels) {
        if (!focusSet && channels.isNotEmpty()) {
            if (initialIdx > 0) listState.scrollToItem(initialIdx)
            delay(50)
            runCatching { currentFocus.requestFocus() }
            focusSet = true
        }
    }

    Row(Modifier.fillMaxSize()) {
        // ── Panel ──
        Row(
            modifier = Modifier
                .fillMaxHeight()
                .background(UltraTokens.SurfaceHover)
        ) {
            // Icon sidebar
            Column(
                modifier = Modifier
                    .width(60.dp)
                    .fillMaxHeight()
                    .background(UltraTokens.Background)
                    .padding(vertical = 20.dp)
                    .focusGroup()
                    .focusRestorer()
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                DrawerSideIcon(Icons.Rounded.List, "All", onClick = {})
                DrawerSideIcon(Icons.Rounded.Search, "Search", onClick = {})
                DrawerSideIcon(Icons.Rounded.Favorite, "Favs", onClick = {})
                DrawerSideIcon(Icons.Rounded.DateRange, "EPG", onClick = {})
                DrawerSideIcon(Icons.Rounded.AspectRatio, "Aspect", onClick = {})
                DrawerSideIcon(Icons.Rounded.Settings, "Settings", onClick = {})
            }

            // Channel list
            Column(
                modifier = Modifier
                    .fillMaxHeight()
                    .width(360.dp)
                    .padding(horizontal = 14.dp, vertical = 18.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        "All Channels",
                        color = Color.White,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        "${channels.size}",
                        color = UltraTokens.Divider,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
                Spacer(Modifier.height(4.dp))
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(1.dp)
                        .background(Color.White.copy(alpha = 0.06f))
                )
                Spacer(Modifier.height(10.dp))

                LazyColumn(
                    state = listState,
                    verticalArrangement = Arrangement.spacedBy(2.dp),
                    modifier = Modifier
                        .fillMaxSize()
                        .focusRestorer()
                ) {
                    items(channels.size) { index ->
                        val channel   = channels[index]
                        val isCurrent = channel.url == currentUrl
                        val interaction = remember { MutableInteractionSource() }
                        val focused by interaction.collectIsFocusedAsState()

                        Card(
                            onClick = { onPick(channel) },
                            modifier = if (isCurrent) Modifier.focusRequester(currentFocus) else Modifier,
                            interactionSource = interaction,
                            shape = CardDefaults.shape(RoundedCornerShape(8.dp)),
                            colors = CardDefaults.colors(
                                containerColor        = Color.Transparent,
                                focusedContainerColor = UltraTokens.Blue,
                                focusedContentColor   = Color.White
                            )
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(horizontal = 10.dp, vertical = 9.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                // Channel number
                                Text(
                                    (index + 1).toString(),
                                    color = if (isCurrent && !focused) UltraTokens.Blue
                                            else if (focused) Color.White
                                            else UltraTokens.Divider,
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    modifier = Modifier.width(30.dp)
                                )
                                Spacer(Modifier.width(8.dp))

                                // Logo box
                                Box(
                                    modifier = Modifier
                                        .size(34.dp)
                                        .clip(RoundedCornerShape(6.dp))
                                        .background(
                                            if (focused) Color.White.copy(alpha = 0.15f)
                                            else UltraTokens.SurfaceHover
                                        ),
                                    contentAlignment = Alignment.Center
                                ) {
                                    if (!channel.logo.isNullOrEmpty()) {
                                        AsyncImage(
                                            model = channel.logo,
                                            contentDescription = null,
                                            contentScale = ContentScale.Fit,
                                            modifier = Modifier.fillMaxSize().padding(4.dp)
                                        )
                                    } else {
                                        Text(
                                            channel.name.take(2).uppercase(),
                                            color = if (focused) Color.White else UltraTokens.Divider,
                                            fontSize = 9.sp,
                                            fontWeight = FontWeight.Bold
                                        )
                                    }
                                }

                                Spacer(Modifier.width(10.dp))

                                Text(
                                    channel.name,
                                    color = if (isCurrent && !focused) UltraTokens.Blue
                                            else Color.White,
                                    fontSize = 13.sp,
                                    fontWeight = if (isCurrent || focused) FontWeight.Bold else FontWeight.Medium,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis,
                                    modifier = Modifier.weight(1f)
                                )

                                // Playing dot
                                if (isCurrent && !focused) {
                                    Box(
                                        modifier = Modifier
                                            .size(5.dp)
                                            .clip(CircleShape)
                                            .background(UltraTokens.Blue)
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }

        // Dim overlay to dismiss
        Box(
            modifier = Modifier
                .weight(1f)
                .fillMaxHeight()
                .background(Color.Black.copy(alpha = 0.35f))
        )
    }
}

// ─────────────────────────────────────────────────────────────
//  DRAWER SIDE ICON
//  No border — clean look, tooltip on focus
// ─────────────────────────────────────────────────────────────

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
private fun DrawerSideIcon(
    icon: ImageVector,
    label: String,
    onClick: () -> Unit,
    tint: Color = Color.White
) {
    val interaction = remember { MutableInteractionSource() }
    val focused by interaction.collectIsFocusedAsState()

    val bgColor by animateColorAsState(
        targetValue = if (focused) UltraTokens.Blue else Color.Transparent,
        animationSpec = tween(160),
        label = "drawer_icon_bg"
    )

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(3.dp)
    ) {
        IconButton(
            onClick = onClick,
            interactionSource = interaction,
            modifier = Modifier
                .size(40.dp)
                .clip(RoundedCornerShape(10.dp))
                .background(bgColor)
            // No border — clean modern look
        ) {
            Icon(
                imageVector = icon,
                contentDescription = label,
                tint = if (focused) Color.White else tint.copy(alpha = 0.5f),
                modifier = Modifier.size(20.dp)
            )
        }
        // Small label always visible for TV discoverability
        Text(
            label,
            color = if (focused) UltraTokens.Blue else UltraTokens.Divider,
            fontSize = 9.sp,
            fontWeight = if (focused) FontWeight.Bold else FontWeight.Normal
        )
    }
}
