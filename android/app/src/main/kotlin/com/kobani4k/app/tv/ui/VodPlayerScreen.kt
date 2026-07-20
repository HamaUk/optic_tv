package com.kobani4k.app.tv.ui

import android.view.KeyEvent
import android.widget.TextClock
import androidx.activity.compose.BackHandler
import androidx.annotation.OptIn
import androidx.compose.animation.*
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import com.kobani4k.player.StreamResolver
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
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
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.ui.PlayerView
import androidx.media3.common.util.UnstableApi
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.kobani4k.app.tv.data.PocketBaseRepository
import com.kobani4k.app.tv.ui.theme.UltraTokens
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

private fun isConfirm(keyCode: Int) = keyCode in setOf(
    KeyEvent.KEYCODE_DPAD_CENTER,
    KeyEvent.KEYCODE_ENTER,
    KeyEvent.KEYCODE_NUMPAD_ENTER
)

private fun isBack(keyCode: Int) = keyCode in setOf(
    KeyEvent.KEYCODE_BACK,
    KeyEvent.KEYCODE_ESCAPE
)

private fun isMenu(keyCode: Int) = keyCode in setOf(
    KeyEvent.KEYCODE_MENU,
    KeyEvent.KEYCODE_SETTINGS
)

private fun isLeftRight(keyCode: Int) = keyCode in setOf(
    KeyEvent.KEYCODE_DPAD_LEFT,
    KeyEvent.KEYCODE_DPAD_RIGHT
)

@OptIn(UnstableApi::class, ExperimentalTvMaterial3Api::class)
@Composable
fun VodPlayerScreen(
    channelName: String,
    streamUrl: String,
    logoUrl: String?,
    onBack: () -> Unit
) {
    val context = LocalContext.current
    val repository = remember { PocketBaseRepository() }

    // â”€â”€ Player state â”€â”€
    var isBuffering    by remember { mutableStateOf(true) }
    var isPlayingState by remember { mutableStateOf(true) }
    var streamFailed   by remember { mutableStateOf(false) }
    
    var currentPosition by remember { mutableStateOf(0L) }
    var duration        by remember { mutableStateOf(0L) }

    // â”€â”€ UI visibility â”€â”€
    var showControls by remember { mutableStateOf(false) }
    var activeMenu   by remember { mutableStateOf(ActiveMenu.NONE) }
    var controlsActivityTrigger by remember { mutableStateOf(0) }

    var selectedAspect  by remember { mutableStateOf("Fit") }
    var selectedDecoder by remember { mutableStateOf("Auto") }

    // Auto-hide controls after 5 s of inactivity
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

    // â”€â”€ ExoPlayer â”€â”€
    val exoPlayer = remember(selectedDecoder) {
        val loadControl = DefaultLoadControl.Builder()
            .setBufferDurationsMs(60_000, 120_000, 2_500, 5_000)
            .setPrioritizeTimeOverSizeThresholds(true)
            .build()

        val httpFactory = DefaultHttpDataSource.Factory()
            .setUserAgent("SmartIPTV/1.0")
            .setAllowCrossProtocolRedirects(true)
            .setConnectTimeoutMs(10_000)
            .setReadTimeoutMs(15_000)

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
                videoScalingMode = androidx.media3.common.C.VIDEO_SCALING_MODE_SCALE_TO_FIT
            }
    }

    // Load stream
    LaunchedEffect(streamUrl) {
        streamFailed = false
        isBuffering = true
        exoPlayer.stop()
        exoPlayer.clearMediaItems()
        
        val finalUrl = StreamResolver.resolveIfNeeded(streamUrl)
        
        val builder = MediaItem.Builder().setUri(finalUrl)

        if (finalUrl.contains("m3u8", ignoreCase = true)) {
            builder.setMimeType(androidx.media3.common.MimeTypes.APPLICATION_M3U8)
        } else if (finalUrl.contains("mpd", ignoreCase = true)) {
            builder.setMimeType(androidx.media3.common.MimeTypes.APPLICATION_MPD)
        }

        exoPlayer.setMediaItem(builder.build())
        exoPlayer.prepare()
        exoPlayer.playWhenReady = true
        exoPlayer.play()
    }

    DisposableEffect(Unit) {
        onDispose {
            exoPlayer.release()
        }
    }

    val scope = rememberCoroutineScope()

    // Player listener & Progress Tracker
    val playerListener = remember(exoPlayer) {
        object : Media3Player.Listener {
            override fun onPlaybackStateChanged(state: Int) {
                isBuffering    = state == Media3Player.STATE_BUFFERING
                isPlayingState = exoPlayer.isPlaying
                if (state == Media3Player.STATE_READY) {
                    streamFailed = false
                    duration = exoPlayer.duration.coerceAtLeast(0L)
                }
                if (state == Media3Player.STATE_ENDED) {
                    isPlayingState = false
                    showControls = true
                }
            }
            override fun onPlayerError(error: PlaybackException) {
                isBuffering = false
                streamFailed = true
                showControls = true
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

    // Update progress bar
    LaunchedEffect(exoPlayer) {
        while (true) {
            if (exoPlayer.isPlaying) {
                currentPosition = exoPlayer.currentPosition.coerceAtLeast(0L)
            }
            delay(1000)
        }
    }

    val mainFocusRequester     = remember { FocusRequester() }
    val controlsFocusRequester = remember { FocusRequester() }

    LaunchedEffect(showControls, activeMenu) {
        when {
            !showControls && activeMenu == ActiveMenu.NONE -> runCatching { mainFocusRequester.requestFocus() }
            showControls && activeMenu == ActiveMenu.NONE -> {
                delay(80) 
                runCatching { controlsFocusRequester.requestFocus() }
            }
        }
    }

    BackHandler {
        when {
            activeMenu != ActiveMenu.NONE -> activeMenu = ActiveMenu.NONE
            showControls                  -> showControls = false
            else                          -> onBack()
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
            .focusRequester(mainFocusRequester)
            .focusable()
            .onKeyEvent { keyEvent ->
                if (keyEvent.nativeKeyEvent.action != KeyEvent.ACTION_DOWN) return@onKeyEvent false
                val code = keyEvent.nativeKeyEvent.keyCode

                if (isBack(code)) {
                    return@onKeyEvent when {
                        activeMenu != ActiveMenu.NONE -> { activeMenu = ActiveMenu.NONE; true }
                        showControls                  -> { showControls = false; true }
                        else                          -> { onBack(); true }
                    }
                }
                
                // Seek +/- 10s if controls are hidden, otherwise rely on controls HUD
                if (!showControls && activeMenu == ActiveMenu.NONE && isLeftRight(code)) {
                    val jumpMs = if (code == KeyEvent.KEYCODE_DPAD_LEFT) -15000L else 15000L
                    val newPos = (exoPlayer.currentPosition + jumpMs).coerceIn(0, exoPlayer.duration)
                    exoPlayer.seekTo(newPos)
                    currentPosition = newPos
                    wakeUpControls()
                    return@onKeyEvent true
                }

                if (isMenu(code)) {
                    showControls = true
                    return@onKeyEvent true
                }

                wakeUpControls()
                false
            }
    ) {
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

        if (isBuffering && !streamFailed) {
            Box(Modifier.fillMaxSize().background(Color.Black.copy(0.4f)), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = UltraTokens.Accent, modifier = Modifier.size(64.dp), strokeWidth = 4.dp)
            }
        }

        if (streamFailed) {
            Box(Modifier.fillMaxSize().background(Color.Black.copy(0.8f)), contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(Icons.Rounded.ErrorOutline, null, tint = Color(0xFFFF4757), modifier = Modifier.size(64.dp))
                    Spacer(Modifier.height(16.dp))
                    Text("Video Offline", color = Color.White, fontSize = 24.sp, fontWeight = FontWeight.Bold)
                    Spacer(Modifier.height(8.dp))
                    Text("Could not load the movie stream.", color = UltraTokens.TextSecondary, fontSize = 14.sp)
                }
            }
        }

        AnimatedVisibility(
            visible = showControls,
            enter   = fadeIn(tween(250)),
            exit    = fadeOut(tween(250))
        ) {
            VodOsdOverlay(
                channelName    = channelName,
                isPlaying      = isPlayingState,
                duration       = duration,
                currentPos     = currentPosition,
                controlsFocusRequester = controlsFocusRequester,
                onTogglePlay   = {
                    wakeUpControls()
                    if (isPlayingState) exoPlayer.pause() else exoPlayer.play()
                },
                onSeek = { ms ->
                    val newPos = (exoPlayer.currentPosition + ms).coerceIn(0, exoPlayer.duration)
                    exoPlayer.seekTo(newPos)
                    currentPosition = newPos
                    wakeUpControls()
                },
                onOpenMenu     = { menu ->
                    activeMenu = menu
                    wakeUpControls()
                },
                onBack = onBack,
                onWake         = { wakeUpControls() }
            )
        }

        AnimatedVisibility(
            visible  = activeMenu != ActiveMenu.NONE,
            enter    = slideInHorizontally { it } + fadeIn(tween(220)),
            exit     = slideOutHorizontally { it } + fadeOut(tween(220)),
            modifier = Modifier.align(Alignment.CenterEnd)
        ) {
            SubMenuPanel(
                exoPlayer = exoPlayer,
                activeMenu = activeMenu,
                validServers = emptyList(), // No multi-server support natively configured here yet
                activeServerIndex = 0,
                onSelectServer = { },
                selectedAspect = selectedAspect,
                onAspectSelected = { selectedAspect = it },
                selectedDecoder = selectedDecoder,
                onDecoderSelected = { selectedDecoder = it },
                onDismiss  = { activeMenu = ActiveMenu.NONE }
            )
        }
    }
}

@Composable
private fun VodOsdOverlay(
    channelName: String,
    isPlaying: Boolean,
    duration: Long,
    currentPos: Long,
    controlsFocusRequester: FocusRequester,
    onTogglePlay: () -> Unit,
    onSeek: (Long) -> Unit,
    onOpenMenu: (ActiveMenu) -> Unit,
    onBack: () -> Unit,
    onWake: () -> Unit
) {
    Box(modifier = Modifier.fillMaxSize()) {
        // Top Bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .align(Alignment.TopCenter)
                .background(Brush.verticalGradient(listOf(Color.Black.copy(0.85f), Color.Transparent)))
                .padding(horizontal = 48.dp, vertical = 32.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconButton(onClick = onBack, modifier = Modifier.size(48.dp)) {
                    Icon(Icons.Rounded.ArrowBack, null, tint = Color.White)
                }
                Spacer(Modifier.width(24.dp))
                Text(
                    channelName,
                    color = Color.White,
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Bold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }

        // Bottom Bar (Timeline & Controls)
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .align(Alignment.BottomCenter)
                .background(Brush.verticalGradient(listOf(Color.Transparent, Color.Black.copy(0.9f))))
                .padding(horizontal = 48.dp, vertical = 32.dp)
        ) {
            // Timeline
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    formatTime(currentPos),
                    color = Color.White,
                    fontSize = 14.sp,
                    modifier = Modifier.width(60.dp)
                )
                Spacer(Modifier.width(16.dp))
                // Progress Bar
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .height(6.dp)
                        .clip(CircleShape)
                        .background(Color.White.copy(0.3f))
                ) {
                    val progress = if (duration > 0) (currentPos.toFloat() / duration.toFloat()) else 0f
                    Box(
                        modifier = Modifier
                            .fillMaxHeight()
                            .fillMaxWidth(progress)
                            .background(UltraTokens.Accent)
                    )
                }
                Spacer(Modifier.width(16.dp))
                Text(
                    formatTime(duration),
                    color = UltraTokens.TextSecondary,
                    fontSize = 14.sp,
                    modifier = Modifier.width(60.dp)
                )
            }
            
            Spacer(Modifier.height(24.dp))

            // Controls
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                OsdIconButton(
                    icon = Icons.Rounded.Subtitles,
                    label = "Audio / Sub",
                    onClick = { onOpenMenu(ActiveMenu.SUBTITLES) },
                    onWake = onWake
                )
                Spacer(Modifier.width(32.dp))
                OsdIconButton(
                    icon = Icons.Rounded.Replay10,
                    label = "-15s",
                    onClick = { onSeek(-15000L) },
                    onWake = onWake
                )
                Spacer(Modifier.width(24.dp))
                OsdIconButton(
                    icon = if (isPlaying) Icons.Rounded.Pause else Icons.Rounded.PlayArrow,
                    label = if (isPlaying) "Pause" else "Play",
                    onClick = onTogglePlay,
                    onWake = onWake,
                    modifier = Modifier.focusRequester(controlsFocusRequester)
                )
                Spacer(Modifier.width(24.dp))
                OsdIconButton(
                    icon = Icons.Rounded.Forward10,
                    label = "+15s",
                    onClick = { onSeek(15000L) },
                    onWake = onWake
                )
                Spacer(Modifier.width(32.dp))
                OsdIconButton(
                    icon = Icons.Rounded.Settings,
                    label = "Settings",
                    onClick = { onOpenMenu(ActiveMenu.SETTINGS) },
                    onWake = onWake
                )
            }
        }
    }
}

private fun formatTime(ms: Long): String {
    val totalSeconds = ms / 1000
    val seconds = totalSeconds % 60
    val minutes = (totalSeconds / 60) % 60
    val hours = totalSeconds / 3600
    return if (hours > 0) {
        String.format("%d:%02d:%02d", hours, minutes, seconds)
    } else {
        String.format("%02d:%02d", minutes, seconds)
    }
}

