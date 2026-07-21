package com.kobani4k.app.tv.ui

import android.net.Uri
import android.view.KeyEvent
import android.widget.TextClock
import androidx.activity.compose.BackHandler
import androidx.annotation.OptIn as Media3OptIn
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import com.kobani4k.app.tv.data.AppPreferences
import com.kobani4k.app.tv.data.MqttViewerService
import com.kobani4k.app.tv.data.PocketBaseRepository
import com.kobani4k.app.tv.data.TvChannel
import com.kobani4k.app.tv.ui.theme.UltraTokens
import com.kobani4k.app.tv.ui.theme.kobaniFocus
import androidx.compose.foundation.clickable
import com.kobani4k.app.tv.ui.theme.kobaniCardColors
import com.kobani4k.player.StreamResolver
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
    val mqttViewerService = remember { MqttViewerService() }

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

    var selectedAspect  by remember { mutableStateOf("Fit") }
    var selectedDecoder by remember { mutableStateOf("Auto") }

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
        channelsList = repository.getChannels() ?: emptyList()
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
    // Built once per decoder mode — released via DisposableEffect(exoPlayer)
    val exoPlayer = remember(selectedDecoder) {
        val loadControl = DefaultLoadControl.Builder()
            .setBufferDurationsMs(
                /* minBufferMs   */ 5_000,   // Start playing after 5s loaded
                /* maxBufferMs   */ 30_000,  // 30s runway handles weak/intermittent connections
                /* bufferForPlayback */ 2_000,
                /* bufferForPlaybackAfterRebuffer */ 5_000
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
        val renderersFactory = DefaultRenderersFactory(context).apply {
            when (selectedDecoder) {
                "Hardware (HW)" -> setEnableDecoderFallback(false)
                "Software (SW)" -> setExtensionRendererMode(DefaultRenderersFactory.EXTENSION_RENDERER_MODE_PREFER)
                else -> setExtensionRendererMode(DefaultRenderersFactory.EXTENSION_RENDERER_MODE_ON)
            }
        }

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

    // MQTT Viewer Tracking
    DisposableEffect(currentChannelName) {
        mqttViewerService.publishJoin(currentChannelName)
        onDispose {
            mqttViewerService.publishLeave(currentChannelName)
        }
    }

    DisposableEffect(Unit) {
        onDispose {
            mqttViewerService.disconnect()
        }
    }

    // Load / switch stream — stops the old one cleanly before preparing new
    LaunchedEffect(currentStreamUrl, activeServerIndex) {
        if (validServers.isEmpty()) return@LaunchedEffect
        if (activeServerIndex >= validServers.size) activeServerIndex = 0
        val playUrl = validServers[activeServerIndex].second
        retryCount = 0
        streamFailed = false
        isBuffering = true
        exoPlayer.stop()
        exoPlayer.clearMediaItems()
        
        if (playUrl.isBlank()) {
            isBuffering = false
            streamFailed = true
            return@LaunchedEffect
        }

        try {
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
        
        finalUrl = StreamResolver.resolveIfNeeded(finalUrl)

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

        val userAgent = ch?.userAgent ?: "SmartIPTV"
        val referer = ch?.referer
        
        val dynamicHttpFactory = DefaultHttpDataSource.Factory()
            .setUserAgent(userAgent)
            .setAllowCrossProtocolRedirects(true)
            .setConnectTimeoutMs(10_000)
            .setReadTimeoutMs(15_000)
            
        val requestProps = mutableMapOf<String, String>()
        requestProps["X-Optic-Security-Token"] = "k4k-secure-stream-99X"
        if (!referer.isNullOrEmpty()) {
            requestProps["Referer"] = referer
        }
        dynamicHttpFactory.setDefaultRequestProperties(requestProps)
        
        val mediaSource = DefaultMediaSourceFactory(dynamicHttpFactory).createMediaSource(builder.build())

        exoPlayer.setMediaSource(mediaSource)
        exoPlayer.prepare()
        exoPlayer.playWhenReady = true
        exoPlayer.play()
        } catch (e: Exception) {
            android.util.Log.e("PlayerScreen", "Stream error: ${e.message}", e)
            isBuffering = false
            streamFailed = true
        }
    }

    // Bug #2 fix: key on exoPlayer so when selectedDecoder changes and remember()
    // creates a NEW player, onDispose releases the OLD player before the new one starts.
    DisposableEffect(exoPlayer) {
        onDispose {
            exoPlayer.stop()
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

                // ── Quick Zap (channel surf without opening OSD) ──
                if (!showControls && !showZapList && activeMenu == ActiveMenu.NONE) {
                    if (isUp(code) || isDown(code)) {
                        if (channelsList.isNotEmpty()) {
                            // Bug #3 fix: match by name OR any server URL (url/url2/url3)
                            // so zapping still works when a backup server is active.
                            val currentCh = channelsList.firstOrNull { ch ->
                                ch.name == currentChannelName ||
                                ch.url == currentStreamUrl ||
                                ch.url2 == currentStreamUrl ||
                                ch.url3 == currentStreamUrl
                            }
                            if (currentCh != null) {
                                val groupChannels = channelsList.filter { it.group == currentCh.group }
                                val idx = groupChannels.indexOfFirst { it.name == currentCh.name }
                                if (idx != -1) {
                                    val newIdx = if (isUp(code)) {
                                        (idx + 1) % groupChannels.size
                                    } else {
                                        if (idx - 1 < 0) groupChannels.size - 1 else idx - 1
                                    }
                                    val ch = groupChannels[newIdx]
                                    activeServerIndex  = 0
                                    currentStreamUrl   = ch.url
                                    currentChannelName = ch.name
                                    currentLogoUrl     = ch.logo
                                    showControls  = false
                                    showZapBanner = true
                                    zapBannerTrigger++
                                }
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

                // Every OTHER key wakes the controls HUD
                wakeUpControls()

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
                update = { view ->
                    view.resizeMode = when (selectedAspect) {
                        "Fill" -> androidx.media3.ui.AspectRatioFrameLayout.RESIZE_MODE_FILL
                        "16:9" -> androidx.media3.ui.AspectRatioFrameLayout.RESIZE_MODE_FIXED_WIDTH
                        "4:3"  -> androidx.media3.ui.AspectRatioFrameLayout.RESIZE_MODE_FIXED_HEIGHT
                        "Stretch" -> androidx.media3.ui.AspectRatioFrameLayout.RESIZE_MODE_FILL
                        else -> androidx.media3.ui.AspectRatioFrameLayout.RESIZE_MODE_FIT
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
                        color = UltraTokens.Accent,
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
                exoPlayer = exoPlayer,
                activeMenu = activeMenu,
                validServers = validServers,
                activeServerIndex = activeServerIndex,
                onSelectServer = { activeServerIndex = it },
                selectedAspect = selectedAspect,
                onAspectSelected = { selectedAspect = it },
                selectedDecoder = selectedDecoder,
                onDecoderSelected = { selectedDecoder = it },
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
                channels       = remember(channelsList, currentStreamUrl) {
                    val currentGroup = channelsList.firstOrNull { it.url == currentStreamUrl }?.group
                    if (currentGroup != null) channelsList.filter { it.group == currentGroup } else channelsList
                },
                currentUrl     = currentStreamUrl,
                onPick         = { ch ->
                    activeServerIndex  = 0
                    currentStreamUrl   = ch.url
                    currentChannelName = ch.name
                    currentLogoUrl     = ch.logo
                    showZapList = false
                },
                onDismiss      = { showZapList = false },
                onBackToDashboard = { onBack() },
                onAspectClick = {
                    val aspects = listOf("Fit", "Fill", "16:9", "4:3", "Stretch")
                    selectedAspect = aspects[(aspects.indexOf(selectedAspect) + 1) % aspects.size]
                },
                onSettingsClick = {
                    showZapList = false
                    activeMenu = ActiveMenu.SETTINGS
                }
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
                            color = UltraTokens.Accent,
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
                            color = UltraTokens.Accent,
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

                if (validServers.size > 1) {
                    OsdIconButton(
                        icon    = Icons.Rounded.Dns,
                        label   = "Servers",
                        onWake  = onWake,
                        onClick = { onOpenMenu(ActiveMenu.SERVERS) }
                    )
                }

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
fun OsdIconButton(
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
        targetValue = if (isFocused) Color.White else Color.Transparent,
        animationSpec = tween(180),
        label = "osd_bg"
    )

    val iconTint by animateColorAsState(
        targetValue = if (isFocused) Color.Black else Color.White,
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
                    .background(Color.White)
                    .padding(horizontal = 8.dp, vertical = 4.dp)
            ) {
                Text(
                    label,
                    color = Color.Black,
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
                .border(1.dp, Color.White.copy(alpha = 0.3f), RoundedCornerShape(12.dp))
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
fun SubMenuPanel(
    exoPlayer: Media3Player,
    activeMenu: ActiveMenu,
    validServers: List<Pair<String, String>>,
    activeServerIndex: Int,
    onSelectServer: (Int) -> Unit,
    selectedAspect: String,
    onAspectSelected: (String) -> Unit,
    selectedDecoder: String,
    onDecoderSelected: (String) -> Unit,
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
                    selectedAspect = selectedAspect,
                    onAspectSelected = onAspectSelected,
                    selectedDecoder = selectedDecoder,
                    onDecoderSelected = onDecoderSelected,
                    onDismiss      = onDismiss
                )
            } else {
                var currentTracks by remember { mutableStateOf(exoPlayer.currentTracks) }
                DisposableEffect(exoPlayer) {
                    val listener = object : Media3Player.Listener {
                        override fun onTracksChanged(tracks: androidx.media3.common.Tracks) {
                            currentTracks = tracks
                        }
                    }
                    exoPlayer.addListener(listener)
                    onDispose { exoPlayer.removeListener(listener) }
                }

                val items = mutableListOf<String>()
                var selectedIndex = 0

                when (activeMenu) {
                    ActiveMenu.SERVERS -> {
                        items.addAll(validServers.map { it.first })
                        selectedIndex = activeServerIndex
                    }
                    ActiveMenu.QUALITY -> {
                        items.add("Auto")
                        val videoGroups = currentTracks.groups.filter { it.type == androidx.media3.common.C.TRACK_TYPE_VIDEO }
                        var idx = 1
                        for (g in videoGroups) {
                            for (i in 0 until g.length) {
                                val format = g.getTrackFormat(i)
                                val title = if (format.height > 0) "${format.height}p" else "Quality ${idx}"
                                items.add(title)
                                if (g.isTrackSelected(i)) selectedIndex = idx
                                idx++
                            }
                        }
                        if (items.size == 1) items[0] = "Default"
                    }
                    ActiveMenu.AUDIO -> {
                        val audioGroups = currentTracks.groups.filter { it.type == androidx.media3.common.C.TRACK_TYPE_AUDIO }
                        var idx = 0
                        for (g in audioGroups) {
                            for (i in 0 until g.length) {
                                val format = g.getTrackFormat(i)
                                val lang = format.language?.uppercase() ?: "Track ${idx + 1}"
                                items.add(lang)
                                if (g.isTrackSelected(i)) selectedIndex = idx
                                idx++
                            }
                        }
                        if (items.isEmpty()) items.add("Default Track")
                    }
                    ActiveMenu.SUBTITLES -> {
                        items.add("Off")
                        val subGroups = currentTracks.groups.filter { it.type == androidx.media3.common.C.TRACK_TYPE_TEXT }
                        var idx = 1
                        for (g in subGroups) {
                            for (i in 0 until g.length) {
                                val format = g.getTrackFormat(i)
                                val lang = format.language?.uppercase() ?: "Subtitle ${idx}"
                                items.add(lang)
                                if (g.isTrackSelected(i)) selectedIndex = idx
                                idx++
                            }
                        }
                    }
                    else -> {}
                }

                LazyColumn(
                    verticalArrangement = Arrangement.spacedBy(4.dp),
                    modifier = Modifier.focusRestorer()
                ) {
                    items(items.size) { i ->
                        TrackOption(
                            title      = items[i],
                            isSelected = i == selectedIndex,
                            modifier   = if (i == 0) Modifier.focusRequester(menuFocusRequester) else Modifier,
                            onClick    = { 
                                if (activeMenu == ActiveMenu.SERVERS) {
                                    onSelectServer(i)
                                } else if (activeMenu == ActiveMenu.QUALITY) {
                                    if (i == 0) {
                                        exoPlayer.trackSelectionParameters = exoPlayer.trackSelectionParameters
                                            .buildUpon()
                                            .clearOverridesOfType(androidx.media3.common.C.TRACK_TYPE_VIDEO)
                                            .build()
                                    } else {
                                        var current = 1
                                        val videoGroups = currentTracks.groups.filter { it.type == androidx.media3.common.C.TRACK_TYPE_VIDEO }
                                        for (g in videoGroups) {
                                            for (j in 0 until g.length) {
                                                if (current == i) {
                                                    exoPlayer.trackSelectionParameters = exoPlayer.trackSelectionParameters
                                                        .buildUpon()
                                                        .setOverrideForType(
                                                            androidx.media3.common.TrackSelectionOverride(g.mediaTrackGroup, listOf(j))
                                                        )
                                                        .build()
                                                    break
                                                }
                                                current++
                                            }
                                        }
                                    }
                                } else if (activeMenu == ActiveMenu.AUDIO) {
                                    if (items.size > 1) {
                                        var current = 0
                                        val audioGroups = currentTracks.groups.filter { it.type == androidx.media3.common.C.TRACK_TYPE_AUDIO }
                                        for (g in audioGroups) {
                                            for (j in 0 until g.length) {
                                                if (current == i) {
                                                    exoPlayer.trackSelectionParameters = exoPlayer.trackSelectionParameters
                                                        .buildUpon()
                                                        .setOverrideForType(
                                                            androidx.media3.common.TrackSelectionOverride(g.mediaTrackGroup, listOf(j))
                                                        )
                                                        .build()
                                                    break
                                                }
                                                current++
                                            }
                                        }
                                    }
                                } else if (activeMenu == ActiveMenu.SUBTITLES) {
                                    if (i == 0) {
                                        exoPlayer.trackSelectionParameters = exoPlayer.trackSelectionParameters
                                            .buildUpon()
                                            .clearOverridesOfType(androidx.media3.common.C.TRACK_TYPE_TEXT)
                                            .build()
                                    } else {
                                        var current = 1
                                        val textGroups = currentTracks.groups.filter { it.type == androidx.media3.common.C.TRACK_TYPE_TEXT }
                                        for (g in textGroups) {
                                            for (j in 0 until g.length) {
                                                if (current == i) {
                                                    exoPlayer.trackSelectionParameters = exoPlayer.trackSelectionParameters
                                                        .buildUpon()
                                                        .setOverrideForType(
                                                            androidx.media3.common.TrackSelectionOverride(g.mediaTrackGroup, listOf(j))
                                                        )
                                                        .build()
                                                    break
                                                }
                                                current++
                                            }
                                        }
                                    }
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

    val scale by animateFloatAsState(
        targetValue = if (isFocused || isSelected) 1.05f else 1f,
        animationSpec = androidx.compose.animation.core.spring(
            dampingRatio = 0.65f,
            stiffness = androidx.compose.animation.core.Spring.StiffnessLow
        ),
        label = "track_scale"
    )

    val bgColor by animateColorAsState(
        targetValue = when {
            isFocused || isSelected -> Color.White
            else -> Color.Transparent
        },
        animationSpec = tween(160),
        label = "track_bg"
    )

    Box(
        modifier = modifier
            .fillMaxWidth()
            .scale(scale)
            .clip(RoundedCornerShape(10.dp))
            .background(bgColor)
            .border(1.dp, Color.White.copy(alpha = 0.3f), RoundedCornerShape(10.dp))
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
                color      = if (isFocused || isSelected) Color.Black
                             else UltraTokens.TextSecondary,
                fontSize   = 14.sp,
                fontWeight = if (isSelected || isFocused) FontWeight.Bold else FontWeight.Medium
            )
            if (isSelected) {
                Icon(
                    Icons.Rounded.Check,
                    contentDescription = null,
                    tint     = Color.Black,
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
    selectedAspect: String,
    onAspectSelected: (String) -> Unit,
    selectedDecoder: String,
    onDecoderSelected: (String) -> Unit,
    onDismiss: () -> Unit
) {
    var selectedSleep   by remember { mutableStateOf("Off") }
    val context = LocalContext.current

    LaunchedEffect(selectedSleep) {
        if (selectedSleep != "Off") {
            val minutes = when (selectedSleep) {
                "15 min" -> 15L
                "30 min" -> 30L
                "1 hour" -> 60L
                "2 hours" -> 120L
                else -> 0L
            }
            if (minutes > 0) {
                kotlinx.coroutines.delay(minutes * 60 * 1000)
                (context as? android.app.Activity)?.finishAffinity()
            }
        }
    }

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
                onClick    = { onAspectSelected(aspects[i]) }
            )
        }

        item { Spacer(Modifier.height(10.dp)); SettingSectionLabel("DECODER") }
        val decoders = listOf("Auto", "Hardware (HW)", "Software (SW)")
        items(decoders.size) { i ->
            SettingRadioItem(
                title      = decoders[i],
                isSelected = selectedDecoder == decoders[i],
                onClick    = { onDecoderSelected(decoders[i]) }
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
        color         = UltraTokens.Accent,
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

    val scale by animateFloatAsState(
        targetValue = if (isFocused || isSelected) 1.05f else 1f,
        animationSpec = androidx.compose.animation.core.spring(
            dampingRatio = 0.65f,
            stiffness = androidx.compose.animation.core.Spring.StiffnessLow
        ),
        label = "setting_scale"
    )

    val bgColor by animateColorAsState(
        targetValue = when {
            isFocused || isSelected  -> Color.White
            else       -> Color.Transparent
        },
        animationSpec = tween(140),
        label = "setting_bg"
    )

    Row(
        modifier = modifier
            .fillMaxWidth()
            .scale(scale)
            .clip(RoundedCornerShape(8.dp))
            .background(bgColor)
            .border(1.dp, Color.White.copy(alpha = 0.3f), RoundedCornerShape(8.dp))
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
            color      = if (isFocused || isSelected) Color.Black
                         else UltraTokens.TextSecondary,
            fontSize   = 13.sp,
            fontWeight = if (isSelected || isFocused) FontWeight.Bold else FontWeight.Medium
        )
        // Radio circle
        Box(
            modifier = Modifier
                .size(17.dp)
                .clip(CircleShape)
                .background(Color.Transparent)
                .run {
                    val borderColor = if (isFocused || isSelected) Color.Black else UltraTokens.Divider
                    // draw border via padding trick — avoids extra composable
                    background(borderColor)
                        .padding(1.5.dp)
                        .clip(CircleShape)
                        .background(
                            if (isFocused || isSelected) Color.White
                            else UltraTokens.SurfaceHover
                        )
                        .padding(if (isSelected) 3.5.dp else 8.dp)
                        .clip(CircleShape)
                        .background(
                            if (isSelected) Color.Black else Color.Transparent
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
    onDismiss: () -> Unit,
    onBackToDashboard: () -> Unit,
    onAspectClick: () -> Unit,
    onSettingsClick: () -> Unit
) {
    BackHandler { onDismiss() }
    val context = LocalContext.current
    val prefs = remember { AppPreferences(context) }
    var favoriteChannels by remember { mutableStateOf(prefs.favoriteChannels) }
    val isFav = favoriteChannels.contains(currentUrl)

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
                .background(Color.Black.copy(alpha = 0.85f))
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
                DrawerSideIcon(androidx.compose.material.icons.Icons.Rounded.ArrowBack, "Back", onClick = onBackToDashboard)
                DrawerSideIcon(
                    if (isFav) Icons.Rounded.Favorite else Icons.Rounded.FavoriteBorder, 
                    "Favs", 
                    onClick = {
                        val newFavs = favoriteChannels.toMutableSet()
                        if (newFavs.contains(currentUrl)) newFavs.remove(currentUrl) else newFavs.add(currentUrl)
                        favoriteChannels = newFavs
                        prefs.favoriteChannels = newFavs
                    }
                )
                DrawerSideIcon(Icons.Rounded.AspectRatio, "Aspect", onClick = onAspectClick)
                DrawerSideIcon(Icons.Rounded.Settings, "Settings", onClick = onSettingsClick)
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

                        val scale by animateFloatAsState(
                            targetValue = if (focused) 1.05f else 1f,
                            animationSpec = androidx.compose.animation.core.spring(
                                dampingRatio = 0.65f,
                                stiffness = androidx.compose.animation.core.Spring.StiffnessLow
                            ),
                            label = "zapScale"
                        )

                        val bgColor by animateColorAsState(
                            targetValue = if (focused) Color.White else Color.Transparent,
                            animationSpec = tween(200)
                        )
                        
                        val textColor = if (focused) Color.Black else Color.White

                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 8.dp, vertical = 4.dp)
                                .scale(scale)
                                .clip(RoundedCornerShape(UltraTokens.CardRadius))
                                .background(bgColor)
                                .border(1.dp, Color.White.copy(alpha = 0.3f), RoundedCornerShape(UltraTokens.CardRadius))
                                .then(if (isCurrent) Modifier.focusRequester(currentFocus) else Modifier)
                                .onKeyEvent { keyEvent ->
                                    if (keyEvent.nativeKeyEvent.action == android.view.KeyEvent.ACTION_DOWN &&
                                        (keyEvent.nativeKeyEvent.keyCode == android.view.KeyEvent.KEYCODE_DPAD_CENTER ||
                                         keyEvent.nativeKeyEvent.keyCode == android.view.KeyEvent.KEYCODE_ENTER ||
                                         keyEvent.nativeKeyEvent.keyCode == android.view.KeyEvent.KEYCODE_NUMPAD_ENTER)
                                    ) {
                                        onPick(channel)
                                        true
                                    } else false
                                }
                                .clickable(
                                    interactionSource = interaction,
                                    indication = null
                                ) { onPick(channel) }
                                .padding(horizontal = 14.dp, vertical = 12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            // Channel number
                            Text(
                                (index + 1).toString(),
                                color = if (isCurrent && !focused) UltraTokens.Accent
                                        else if (focused) Color.Black
                                        else UltraTokens.Divider,
                                fontSize = 14.sp,
                                fontWeight = FontWeight.SemiBold,
                                modifier = Modifier.width(36.dp)
                            )
                            Spacer(Modifier.width(12.dp))

                            // Logo box
                            Box(
                                modifier = Modifier
                                    .size(54.dp)
                                    .clip(RoundedCornerShape(10.dp))
                                    .background(Color.White.copy(alpha = 0.05f)),
                                contentAlignment = Alignment.Center
                            ) {
                                if (!channel.logo.isNullOrEmpty()) {
                                    AsyncImage(
                                        model = channel.logo,
                                        contentDescription = null,
                                        contentScale = ContentScale.Fit,
                                        modifier = Modifier.fillMaxSize().padding(6.dp)
                                    )
                                } else {
                                    Text(
                                        channel.name.take(2).uppercase(),
                                        color = if (focused) Color.Black else UltraTokens.Accent,
                                        fontSize = 16.sp,
                                        fontWeight = FontWeight.Bold
                                    )
                                }
                            }
                            Spacer(Modifier.width(16.dp))

                            Text(
                                channel.name,
                                color = if (focused) Color.Black else if (isCurrent) Color.White else UltraTokens.Text,
                                fontSize = 16.sp,
                                fontWeight = if (focused || isCurrent) FontWeight.Bold else FontWeight.Medium,
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
                                            .background(UltraTokens.Accent)
                                    )
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
        targetValue = if (focused) UltraTokens.Accent else Color.Transparent,
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
            color = if (focused) UltraTokens.Accent else UltraTokens.Divider,
            fontSize = 9.sp,
            fontWeight = if (focused) FontWeight.Bold else FontWeight.Normal
        )
    }
}
