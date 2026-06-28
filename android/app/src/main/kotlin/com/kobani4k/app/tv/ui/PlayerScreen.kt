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
import androidx.compose.material.icons.filled.*
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
import com.kobani4k.app.tv.ui.theme.ultraCardColors
import kotlinx.coroutines.delay

// ═══════════════════════════════════════════════════
//  Active Menus
// ═══════════════════════════════════════════════════
enum class ActiveMenu { NONE, QUALITY, AUDIO, SUBTITLES, SETTINGS }

// ═══════════════════════════════════════════════════
//  PLAYER SCREEN — Premium OSD with Quick Zap
// ═══════════════════════════════════════════════════

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

    var currentChannelName by remember { mutableStateOf(channelName) }
    var currentStreamUrl by remember { mutableStateOf(streamUrl) }
    var currentLogoUrl by remember { mutableStateOf(logoUrl) }

    var isBuffering by remember { mutableStateOf(true) }
    var isPlayingState by remember { mutableStateOf(true) }

    var showZapList by remember { mutableStateOf(false) }
    var showControls by remember { mutableStateOf(false) }
    var activeMenu by remember { mutableStateOf(ActiveMenu.NONE) }
    var controlsActivityTrigger by remember { mutableStateOf(0) }

    var showZapBanner by remember { mutableStateOf(false) }
    var zapBannerTrigger by remember { mutableStateOf(0) }

    var channelsList by remember { mutableStateOf<List<TvChannel>>(emptyList()) }

    LaunchedEffect(Unit) {
        channelsList = repository.getChannels()
    }

    // Auto-hide Zap banner after 3s
    LaunchedEffect(showZapBanner, zapBannerTrigger) {
        if (showZapBanner) {
            delay(3000)
            showZapBanner = false
        }
    }

    // Auto-hide controls after 5s of inactivity
    LaunchedEffect(showControls, controlsActivityTrigger, activeMenu) {
        if (showControls && activeMenu == ActiveMenu.NONE) {
            delay(5000)
            showControls = false
        }
    }

    fun wakeUpControls() {
        controlsActivityTrigger++
        showControls = true
    }

    // ═══ ExoPlayer Engine (UNCHANGED) ═══
    val exoPlayer = remember {
        val loadControl = DefaultLoadControl.Builder()
            .setBufferDurationsMs(5000, 15000, 500, 1500)
            .setPrioritizeTimeOverSizeThresholds(true)
            .build()

        val httpDataSourceFactory = DefaultHttpDataSource.Factory()
            .setUserAgent("SmartIPTV")
            .setAllowCrossProtocolRedirects(true)
            .setConnectTimeoutMs(10000)
            .setReadTimeoutMs(15000)

        val player = ExoPlayer.Builder(context)
            .setRenderersFactory(DefaultRenderersFactory(context).setExtensionRendererMode(DefaultRenderersFactory.EXTENSION_RENDERER_MODE_PREFER))
            .setLoadControl(loadControl)
            .setMediaSourceFactory(DefaultMediaSourceFactory(httpDataSourceFactory))
            .build()

        player.setWakeMode(androidx.media3.common.C.WAKE_MODE_NETWORK)
        player.videoScalingMode = androidx.media3.common.C.VIDEO_SCALING_MODE_SCALE_TO_FIT
        player
    }

    LaunchedEffect(currentStreamUrl) {
        TvViewerService.joinChannel(currentStreamUrl)
        isBuffering = true
        exoPlayer.stop()
        exoPlayer.clearMediaItems()
        exoPlayer.setMediaItem(MediaItem.fromUri(Uri.parse(currentStreamUrl)))
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

    val playerListener = remember {
        object : Media3Player.Listener {
            override fun onPlaybackStateChanged(state: Int) {
                isBuffering = state == Media3Player.STATE_BUFFERING
                isPlayingState = exoPlayer.isPlaying
            }
            override fun onPlayerError(error: PlaybackException) {
                isBuffering = false
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

    val mainFocusRequester = remember { FocusRequester() }
    val controlsFocusRequester = remember { FocusRequester() }

    LaunchedEffect(showZapList, showControls, activeMenu) {
        if (!showZapList && !showControls && activeMenu == ActiveMenu.NONE) {
            mainFocusRequester.requestFocus()
        } else if (showControls && activeMenu == ActiveMenu.NONE) {
            delay(100)
            runCatching { controlsFocusRequester.requestFocus() }
        }
    }

    BackHandler {
        when {
            activeMenu != ActiveMenu.NONE -> activeMenu = ActiveMenu.NONE
            showControls -> showControls = false
            showZapList -> showZapList = false
            else -> onBack()
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
            .focusRequester(mainFocusRequester)
            .focusable()
            .onKeyEvent { keyEvent ->
                if (keyEvent.nativeKeyEvent.action == KeyEvent.ACTION_DOWN) {
                    wakeUpControls()

                    val isUp = keyEvent.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_DPAD_UP ||
                            keyEvent.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_CHANNEL_UP
                    val isDown = keyEvent.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_DPAD_DOWN ||
                            keyEvent.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_CHANNEL_DOWN

                    // Quick Zap when controls are hidden
                    if (!showControls && !showZapList && activeMenu == ActiveMenu.NONE) {
                        if (isUp || isDown) {
                            if (channelsList.isNotEmpty()) {
                                val currentIndex = channelsList.indexOfFirst { it.url == currentStreamUrl }
                                if (currentIndex != -1) {
                                    val newIndex = if (isUp) {
                                        (currentIndex + 1) % channelsList.size
                                    } else {
                                        if (currentIndex - 1 < 0) channelsList.size - 1 else currentIndex - 1
                                    }
                                    val ch = channelsList[newIndex]
                                    currentStreamUrl = ch.url
                                    currentChannelName = ch.name
                                    currentLogoUrl = ch.logo

                                    showControls = false
                                    showZapBanner = true
                                    zapBannerTrigger++
                                }
                            }
                            return@onKeyEvent true
                        }
                    }

                    when (keyEvent.nativeKeyEvent.keyCode) {
                        KeyEvent.KEYCODE_DPAD_CENTER, KeyEvent.KEYCODE_ENTER -> {
                            if (!showZapList && !showControls) {
                                showZapList = true
                                return@onKeyEvent true
                            }
                            false
                        }
                        KeyEvent.KEYCODE_DPAD_DOWN -> {
                            if (!showZapList && !showControls) {
                                showControls = true
                                return@onKeyEvent true
                            }
                            false
                        }
                        KeyEvent.KEYCODE_DPAD_LEFT -> {
                            if (!showZapList && !showControls) {
                                showZapList = true
                                return@onKeyEvent true
                            }
                            false
                        }
                        KeyEvent.KEYCODE_BACK -> {
                            when {
                                activeMenu != ActiveMenu.NONE -> { activeMenu = ActiveMenu.NONE; true }
                                showControls -> { showControls = false; true }
                                showZapList -> { showZapList = false; true }
                                else -> { onBack(); true }
                            }
                        }
                        KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE -> {
                            if (isPlayingState) exoPlayer.pause() else exoPlayer.play()
                            true
                        }
                        else -> false
                    }
                } else {
                    false
                }
            }
    ) {
        // ═══ VIDEO PLAYER ═══
        AndroidView(
            factory = { ctx ->
                PlayerView(ctx).apply {
                    player = exoPlayer
                    useController = false
                    resizeMode = androidx.media3.ui.AspectRatioFrameLayout.RESIZE_MODE_FIT
                    isFocusable = false
                }
            },
            modifier = Modifier.fillMaxSize()
        )

        // Buffering indicator
        if (isBuffering) {
            Box(
                Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.5f)),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    CircularProgressIndicator(
                        color = UltraTokens.Accent,
                        modifier = Modifier.size(56.dp),
                        strokeWidth = 3.dp
                    )
                    Spacer(Modifier.height(16.dp))
                    Text(
                        "Loading stream...",
                        color = UltraTokens.Fg3,
                        fontSize = 14.sp
                    )
                }
            }
        }

        // ═══════════════════════════════════════════
        //  QUICK ZAP BANNER (Bottom, auto-hide)
        // ═══════════════════════════════════════════
        AnimatedVisibility(
            visible = showZapBanner && !showControls && !showZapList,
            enter = slideInVertically { it } + fadeIn(tween(300)),
            exit = slideOutVertically { it } + fadeOut(tween(300)),
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(start = 48.dp, end = 48.dp, bottom = 48.dp)
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(20.dp))
                    .background(
                        Brush.horizontalGradient(
                            colors = listOf(
                                UltraTokens.SurfacePanel,
                                UltraTokens.SurfacePanel.copy(alpha = 0.9f)
                            )
                        )
                    )
                    .border(
                        1.dp,
                        Color.White.copy(alpha = 0.06f),
                        RoundedCornerShape(20.dp)
                    )
                    .padding(horizontal = 32.dp, vertical = 24.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    // Channel Logo
                    if (!currentLogoUrl.isNullOrEmpty()) {
                        Box(
                            modifier = Modifier
                                .size(72.dp)
                                .clip(RoundedCornerShape(12.dp))
                                .background(Color.White.copy(0.05f))
                                .padding(8.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            AsyncImage(
                                model = currentLogoUrl,
                                contentDescription = null,
                                modifier = Modifier.fillMaxSize()
                            )
                        }
                        Spacer(Modifier.width(20.dp))
                    }

                    Column {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Box(
                                modifier = Modifier
                                    .size(8.dp)
                                    .clip(CircleShape)
                                    .background(UltraTokens.Live)
                            )
                            Spacer(Modifier.width(8.dp))
                            Text(
                                "LIVE NOW",
                                color = UltraTokens.Accent,
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                letterSpacing = 2.sp
                            )
                        }
                        Spacer(Modifier.height(4.dp))
                        Text(
                            text = currentChannelName,
                            color = Color.White,
                            fontSize = 32.sp,
                            fontWeight = FontWeight.Bold,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                }

                // Clock + Hint
                Column(horizontalAlignment = Alignment.End) {
                    AndroidView(
                        factory = { ctx ->
                            TextClock(ctx).apply {
                                format12Hour = "hh:mm a"
                                format24Hour = "HH:mm"
                                textSize = 22f
                                setTextColor(android.graphics.Color.WHITE)
                                typeface = android.graphics.Typeface.DEFAULT_BOLD
                            }
                        }
                    )
                    Spacer(Modifier.height(8.dp))
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("Press ", color = UltraTokens.Fg4, fontSize = 13.sp)
                        Icon(
                            Icons.Rounded.RadioButtonChecked,
                            contentDescription = null,
                            tint = UltraTokens.Fg2,
                            modifier = Modifier.size(14.dp)
                        )
                        Text(" for controls", color = UltraTokens.Fg4, fontSize = 13.sp)
                    }
                }
            }
        }

        // ═══════════════════════════════════════════
        //  OSD CONTROLS (Center/Enter to show)
        // ═══════════════════════════════════════════
        AnimatedVisibility(
            visible = showControls && !showZapList,
            enter = fadeIn(tween(300)),
            exit = fadeOut(tween(300))
        ) {
            Box(modifier = Modifier.fillMaxSize()) {

                // TOP BAR
                AnimatedVisibility(
                    visible = showControls,
                    enter = slideInVertically { -it },
                    exit = slideOutVertically { -it },
                    modifier = Modifier.align(Alignment.TopCenter)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(
                                Brush.verticalGradient(
                                    colors = listOf(
                                        Color.Black.copy(0.9f),
                                        Color.Black.copy(0.5f),
                                        Color.Transparent
                                    )
                                )
                            )
                            .padding(horizontal = 48.dp, vertical = 28.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.Top
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            if (!currentLogoUrl.isNullOrEmpty()) {
                                AsyncImage(
                                    model = currentLogoUrl,
                                    contentDescription = null,
                                    modifier = Modifier
                                        .size(56.dp)
                                        .clip(RoundedCornerShape(10.dp))
                                )
                                Spacer(Modifier.width(16.dp))
                            }
                            Column {
                                Text(
                                    "NOW PLAYING",
                                    color = UltraTokens.Accent,
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Bold,
                                    letterSpacing = 2.sp
                                )
                                Spacer(Modifier.height(2.dp))
                                Text(
                                    currentChannelName,
                                    color = Color.White,
                                    fontSize = 24.sp,
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
                }

                // BOTTOM CONTROLS BAR
                AnimatedVisibility(
                    visible = showControls,
                    enter = slideInVertically { it },
                    exit = slideOutVertically { it },
                    modifier = Modifier.align(Alignment.BottomCenter)
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(
                                Brush.verticalGradient(
                                    colors = listOf(
                                        Color.Transparent,
                                        Color.Black.copy(0.7f),
                                        Color.Black.copy(0.95f)
                                    )
                                )
                            )
                            .padding(horizontal = 48.dp, vertical = 28.dp)
                    ) {
                        // LIVE indicator
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Box(
                                modifier = Modifier
                                    .size(8.dp)
                                    .clip(CircleShape)
                                    .background(UltraTokens.Live)
                            )
                            Spacer(Modifier.width(8.dp))
                            Text(
                                "LIVE",
                                color = Color.White,
                                fontSize = 13.sp,
                                fontWeight = FontWeight.Bold,
                                letterSpacing = 1.sp
                            )
                        }

                        Spacer(Modifier.height(20.dp))

                        // Control buttons
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(14.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.focusGroup()
                        ) {
                            // Play / Pause
                            OsdButton(
                                icon = if (isPlayingState) Icons.Rounded.Pause else Icons.Rounded.PlayArrow,
                                label = if (isPlayingState) "Pause" else "Play",
                                modifier = Modifier.focusRequester(controlsFocusRequester),
                                onClick = {
                                    wakeUpControls()
                                    if (isPlayingState) exoPlayer.pause() else exoPlayer.play()
                                }
                            )

                            Spacer(Modifier.width(8.dp))

                            // Quality
                            OsdButton(
                                icon = Icons.Rounded.HighQuality,
                                label = "Quality",
                                onClick = { activeMenu = ActiveMenu.QUALITY; wakeUpControls() }
                            )

                            // Audio
                            OsdButton(
                                icon = Icons.Rounded.Audiotrack,
                                label = "Audio",
                                onClick = { activeMenu = ActiveMenu.AUDIO; wakeUpControls() }
                            )

                            // Subtitles
                            OsdButton(
                                icon = Icons.Rounded.Subtitles,
                                label = "Subtitles",
                                onClick = { activeMenu = ActiveMenu.SUBTITLES; wakeUpControls() }
                            )

                            Spacer(Modifier.weight(1f))

                            // Settings (opens in-player settings panel)
                            OsdButton(
                                icon = Icons.Rounded.Settings,
                                label = "Settings",
                                onClick = { activeMenu = ActiveMenu.SETTINGS; wakeUpControls() }
                            )
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════
        //  RIGHT SIDE MENU (Quality / Audio / Subs / Settings)
        // ═══════════════════════════════════════════
        AnimatedVisibility(
            visible = activeMenu != ActiveMenu.NONE,
            enter = slideInHorizontally { it } + fadeIn(),
            exit = slideOutHorizontally { it } + fadeOut(),
            modifier = Modifier.align(Alignment.CenterEnd)
        ) {
            val menuFocusRequester = remember { FocusRequester() }

            LaunchedEffect(activeMenu) {
                if (activeMenu != ActiveMenu.NONE) {
                    delay(100)
                    runCatching { menuFocusRequester.requestFocus() }
                }
            }

            Box(
                modifier = Modifier
                    .fillMaxHeight()
                    .width(360.dp)
                    .background(
                        Brush.horizontalGradient(
                            colors = listOf(
                                Color.Transparent,
                                UltraTokens.SurfacePanel
                            ),
                            startX = 0f,
                            endX = 80f
                        )
                    )
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(UltraTokens.SurfacePanel)
                        .padding(24.dp)
                ) {
                    // Menu Header
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = when (activeMenu) {
                                ActiveMenu.QUALITY -> "VIDEO QUALITY"
                                ActiveMenu.AUDIO -> "AUDIO TRACKS"
                                ActiveMenu.SUBTITLES -> "SUBTITLES"
                                ActiveMenu.SETTINGS -> "QUICK SETTINGS"
                                else -> ""
                            },
                            color = Color.White,
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Bold,
                            letterSpacing = 1.sp
                        )
                        Text(
                            "← Back",
                            color = UltraTokens.Fg4,
                            fontSize = 12.sp
                        )
                    }

                    Spacer(Modifier.height(4.dp))

                    // Subtle separator
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(1.dp)
                            .background(Color.White.copy(alpha = 0.08f))
                    )

                    Spacer(Modifier.height(16.dp))

                    if (activeMenu == ActiveMenu.SETTINGS) {
                        // ═══ SETTINGS PANEL ═══
                        SettingsPanel(
                            focusRequester = menuFocusRequester,
                            onDismiss = { activeMenu = ActiveMenu.NONE }
                        )
                    } else {
                        // ═══ TRACK SELECTION LIST ═══
                        val items = when (activeMenu) {
                            ActiveMenu.QUALITY -> listOf("Auto", "1080p (HD)", "720p", "480p", "360p")
                            ActiveMenu.AUDIO -> listOf("Track 1 (Default)", "Track 2", "Track 3")
                            ActiveMenu.SUBTITLES -> listOf("Off", "English", "Spanish", "Arabic", "French")
                            else -> emptyList()
                        }

                        LazyColumn(
                            verticalArrangement = Arrangement.spacedBy(6.dp),
                            modifier = Modifier.focusRestorer()
                        ) {
                            items(items.size) { index ->
                                TrackOption(
                                    title = items[index],
                                    isSelected = index == 0,
                                    modifier = if (index == 0) Modifier.focusRequester(menuFocusRequester) else Modifier,
                                    onClick = { activeMenu = ActiveMenu.NONE }
                                )
                            }
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════
        //  ZAP DRAWER (Left side channel list)
        // ═══════════════════════════════════════════
        AnimatedVisibility(
            visible = showZapList,
            enter = slideInHorizontally { -it } + fadeIn(),
            exit = slideOutHorizontally { -it } + fadeOut()
        ) {
            ZapDrawer(
                channels = channelsList,
                currentUrl = currentStreamUrl,
                onPick = { ch ->
                    currentStreamUrl = ch.url
                    currentChannelName = ch.name
                    currentLogoUrl = ch.logo
                    showZapList = false
                },
                onDismiss = { showZapList = false }
            )
        }
    }
}

// ═══════════════════════════════════════════════════
//  OSD ICON BUTTON
// ═══════════════════════════════════════════════════

@Composable
private fun OsdButton(
    icon: ImageVector,
    label: String,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(if (isFocused) 1.15f else 1f, tween(200), label = "osdScale")
    val bgColor by animateColorAsState(
        if (isFocused) UltraTokens.Accent else Color.White.copy(alpha = 0.12f),
        tween(200),
        label = "osdBg"
    )
    val borderColor by animateColorAsState(
        if (isFocused) UltraTokens.Accent.copy(alpha = 0.6f) else Color.Transparent,
        tween(200),
        label = "osdBorder"
    )

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = modifier.width(72.dp)
    ) {
        Box(
            modifier = Modifier
                .size(52.dp)
                .scale(scale)
                .clip(CircleShape)
                .background(bgColor)
                .border(2.dp, borderColor, CircleShape)
                .onFocusChanged { isFocused = it.isFocused }
                .focusable()
                .onKeyEvent {
                    if (it.nativeKeyEvent.action == KeyEvent.ACTION_DOWN &&
                        (it.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_DPAD_CENTER ||
                                it.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_ENTER)
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
                tint = Color.White,
                modifier = Modifier.size(24.dp)
            )
        }

        Spacer(Modifier.height(8.dp))

        AnimatedVisibility(visible = isFocused, enter = fadeIn(), exit = fadeOut()) {
            Text(
                text = label,
                color = Color.White,
                fontSize = 11.sp,
                fontWeight = FontWeight.Medium,
                maxLines = 1
            )
        }
    }
}

// ═══════════════════════════════════════════════════
//  TRACK OPTION ITEM (for Quality / Audio / Subs)
// ═══════════════════════════════════════════════════

@Composable
private fun TrackOption(
    title: String,
    isSelected: Boolean,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    val bgColor by animateColorAsState(
        when {
            isFocused -> UltraTokens.Accent
            isSelected -> UltraTokens.AccentTint
            else -> Color.Transparent
        },
        tween(200),
        label = "trackBg"
    )

    Box(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(10.dp))
            .background(bgColor)
            .onFocusChanged { isFocused = it.isFocused }
            .focusable()
            .onKeyEvent {
                if (it.nativeKeyEvent.action == KeyEvent.ACTION_DOWN &&
                    (it.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_DPAD_CENTER ||
                            it.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_ENTER)
                ) {
                    onClick()
                    true
                } else false
            }
            .padding(horizontal = 16.dp, vertical = 14.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = title,
                color = if (isFocused) Color.White else if (isSelected) UltraTokens.Accent else UltraTokens.Fg2,
                fontSize = 15.sp,
                fontWeight = if (isSelected || isFocused) FontWeight.Bold else FontWeight.Normal
            )
            if (isSelected) {
                Icon(
                    Icons.Rounded.Check,
                    contentDescription = null,
                    tint = if (isFocused) Color.White else UltraTokens.Accent,
                    modifier = Modifier.size(18.dp)
                )
            }
        }
    }
}

// ═══════════════════════════════════════════════════
//  SETTINGS PANEL (In-Player Quick Settings)
// ═══════════════════════════════════════════════════

@Composable
private fun SettingsPanel(
    focusRequester: FocusRequester,
    onDismiss: () -> Unit
) {
    // Settings state
    var selectedAspect by remember { mutableStateOf("Fit") }
    var selectedDecoder by remember { mutableStateOf("Auto") }
    var selectedSleep by remember { mutableStateOf("Off") }

    LazyColumn(
        verticalArrangement = Arrangement.spacedBy(4.dp),
        modifier = Modifier.fillMaxSize().focusRestorer()
    ) {
        // ── Aspect Ratio ──
        item {
            SettingSectionHeader("ASPECT RATIO")
        }
        val aspectOptions = listOf("Fit", "Fill", "16:9", "4:3", "Stretch")
        items(aspectOptions.size) { index ->
            SettingRadioItem(
                title = aspectOptions[index],
                isSelected = selectedAspect == aspectOptions[index],
                modifier = if (index == 0) Modifier.focusRequester(focusRequester) else Modifier,
                onClick = { selectedAspect = aspectOptions[index] }
            )
        }

        // ── Decoder ──
        item {
            Spacer(Modifier.height(12.dp))
            SettingSectionHeader("DECODER")
        }
        val decoderOptions = listOf("Auto", "Hardware (HW)", "Software (SW)")
        items(decoderOptions.size) { index ->
            SettingRadioItem(
                title = decoderOptions[index],
                isSelected = selectedDecoder == decoderOptions[index],
                onClick = { selectedDecoder = decoderOptions[index] }
            )
        }

        // ── Sleep Timer ──
        item {
            Spacer(Modifier.height(12.dp))
            SettingSectionHeader("SLEEP TIMER")
        }
        val sleepOptions = listOf("Off", "15 min", "30 min", "1 hour", "2 hours")
        items(sleepOptions.size) { index ->
            SettingRadioItem(
                title = sleepOptions[index],
                isSelected = selectedSleep == sleepOptions[index],
                onClick = { selectedSleep = sleepOptions[index] }
            )
        }
    }
}

@Composable
private fun SettingSectionHeader(title: String) {
    Text(
        text = title,
        color = UltraTokens.Accent,
        fontSize = 11.sp,
        fontWeight = FontWeight.Bold,
        letterSpacing = 2.sp,
        modifier = Modifier.padding(vertical = 8.dp, horizontal = 4.dp)
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
        when {
            isFocused -> UltraTokens.Accent
            isSelected -> UltraTokens.AccentTint
            else -> Color.Transparent
        },
        tween(150),
        label = "settingBg"
    )

    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp))
            .background(bgColor)
            .onFocusChanged { isFocused = it.isFocused }
            .focusable()
            .onKeyEvent {
                if (it.nativeKeyEvent.action == KeyEvent.ACTION_DOWN &&
                    (it.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_DPAD_CENTER ||
                            it.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_ENTER)
                ) {
                    onClick()
                    true
                } else false
            }
            .padding(horizontal = 14.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = title,
            color = if (isFocused) Color.White else if (isSelected) UltraTokens.Accent else UltraTokens.Fg2,
            fontSize = 14.sp,
            fontWeight = if (isSelected || isFocused) FontWeight.SemiBold else FontWeight.Normal
        )

        // Radio indicator
        Box(
            modifier = Modifier
                .size(18.dp)
                .clip(CircleShape)
                .border(
                    2.dp,
                    if (isFocused) Color.White
                    else if (isSelected) UltraTokens.Accent
                    else UltraTokens.Fg4,
                    CircleShape
                ),
            contentAlignment = Alignment.Center
        ) {
            if (isSelected) {
                Box(
                    modifier = Modifier
                        .size(10.dp)
                        .clip(CircleShape)
                        .background(if (isFocused) Color.White else UltraTokens.Accent)
                )
            }
        }
    }
}

// ═══════════════════════════════════════════════════
//  ZAP DRAWER (Left side channel list)
// ═══════════════════════════════════════════════════

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
private fun ZapDrawer(
    channels: List<TvChannel>,
    currentUrl: String,
    onPick: (TvChannel) -> Unit,
    onDismiss: () -> Unit
) {
    BackHandler { onDismiss() }

    val listState = rememberLazyListState()
    val initialIdx = remember(channels) {
        channels.indexOfFirst { it.url == currentUrl }.coerceAtLeast(0)
    }
    val currentFocus = remember { FocusRequester() }
    var focusSet by remember { mutableStateOf(false) }

    LaunchedEffect(channels) {
        if (!focusSet && channels.isNotEmpty()) {
            if (initialIdx > 0) {
                listState.scrollToItem(initialIdx)
            }
            delay(50)
            runCatching { currentFocus.requestFocus() }
            focusSet = true
        }
    }

    Row(Modifier.fillMaxSize()) {
        Row(
            modifier = Modifier
                .fillMaxHeight()
                .background(UltraTokens.SurfacePanel)
        ) {
            // Icon Sidebar
            Column(
                modifier = Modifier
                    .width(64.dp)
                    .fillMaxHeight()
                    .background(UltraTokens.BgDeep)
                    .padding(vertical = 20.dp)
                    .focusGroup()
                    .focusRestorer()
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                DrawerIcon(Icons.Default.Search, "Search", onClick = {})
                DrawerIcon(Icons.Default.List, "EPG", onClick = {})
                DrawerIcon(Icons.Default.Favorite, "Favorites", onClick = {})
                DrawerIcon(Icons.Default.PlayArrow, "Tracks", onClick = {})
                DrawerIcon(Icons.Default.AspectRatio, "Aspect", onClick = {})
                DrawerIcon(Icons.Default.Settings, "Settings", onClick = {})
            }

            // Channel List
            Column(
                modifier = Modifier
                    .fillMaxHeight()
                    .width(360.dp)
                    .padding(horizontal = 16.dp, vertical = 20.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        "All Channels",
                        color = Color.White,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        "${channels.size}",
                        color = UltraTokens.Fg4,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold
                    )
                }

                Spacer(Modifier.height(4.dp))

                // Separator
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(1.dp)
                        .background(Color.White.copy(alpha = 0.06f))
                )

                Spacer(Modifier.height(12.dp))

                LazyColumn(
                    state = listState,
                    verticalArrangement = Arrangement.spacedBy(2.dp),
                    modifier = Modifier
                        .fillMaxSize()
                        .focusRestorer()
                ) {
                    items(channels.size) { index ->
                        val channel = channels[index]
                        val isCurrent = channel.url == currentUrl
                        val interaction = remember { MutableInteractionSource() }
                        val focused by interaction.collectIsFocusedAsState()

                        Card(
                            onClick = { onPick(channel) },
                            modifier = if (isCurrent) Modifier.focusRequester(currentFocus) else Modifier,
                            interactionSource = interaction,
                            shape = CardDefaults.shape(RoundedCornerShape(8.dp)),
                            colors = ultraCardColors(
                                containerColor = Color.Transparent,
                                focusedContainerColor = UltraTokens.Accent,
                                focusedContentColor = Color.White,
                            ),
                        ) {
                            Row(
                                Modifier
                                    .fillMaxWidth()
                                    .padding(horizontal = 12.dp, vertical = 10.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                // Channel number
                                Text(
                                    (index + 1).toString(),
                                    color = if (isCurrent && !focused) UltraTokens.Accent
                                    else if (focused) Color.White
                                    else UltraTokens.Fg4,
                                    fontSize = 13.sp,
                                    fontWeight = FontWeight.Bold,
                                    modifier = Modifier.width(32.dp)
                                )
                                Spacer(Modifier.width(8.dp))

                                // Channel logo
                                Box(
                                    modifier = Modifier
                                        .size(36.dp)
                                        .clip(RoundedCornerShape(6.dp))
                                        .background(
                                            if (focused) Color.White.copy(alpha = 0.15f)
                                            else UltraTokens.Surface3
                                        ),
                                    contentAlignment = Alignment.Center
                                ) {
                                    if (!channel.logo.isNullOrEmpty()) {
                                        AsyncImage(
                                            model = channel.logo,
                                            contentDescription = null,
                                            contentScale = ContentScale.Fit,
                                            modifier = Modifier
                                                .fillMaxSize()
                                                .padding(4.dp)
                                        )
                                    } else {
                                        Text(
                                            channel.name.take(2).uppercase(),
                                            color = if (focused) Color.White else UltraTokens.Fg4,
                                            fontSize = 10.sp,
                                            fontWeight = FontWeight.Bold
                                        )
                                    }
                                }

                                Spacer(Modifier.width(10.dp))

                                Column(Modifier.weight(1f)) {
                                    Text(
                                        channel.name,
                                        color = if (isCurrent && !focused) UltraTokens.Accent
                                        else Color.White,
                                        fontSize = 14.sp,
                                        fontWeight = if (isCurrent || focused) FontWeight.Bold else FontWeight.Medium,
                                        maxLines = 1,
                                        overflow = TextOverflow.Ellipsis
                                    )
                                }

                                // Current indicator
                                if (isCurrent && !focused) {
                                    Box(
                                        modifier = Modifier
                                            .size(6.dp)
                                            .clip(CircleShape)
                                            .background(UltraTokens.Accent)
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }

        // Transparent overlay to dismiss
        Box(
            Modifier
                .weight(1f)
                .fillMaxHeight()
                .background(Color.Black.copy(alpha = 0.3f))
        )
    }
}

// ═══════════════════════════════════════════════════
//  DRAWER ICON BUTTON
// ═══════════════════════════════════════════════════

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
private fun DrawerIcon(
    icon: ImageVector,
    label: String,
    onClick: () -> Unit,
    tint: Color = Color.White,
) {
    val interaction = remember { MutableInteractionSource() }
    val focused by interaction.collectIsFocusedAsState()

    IconButton(
        onClick = onClick,
        interactionSource = interaction,
        modifier = Modifier.size(44.dp),
    ) {
        Icon(
            icon,
            contentDescription = label,
            tint = if (focused) Color.Black else tint,
            modifier = Modifier.size(22.dp),
        )
    }
}
