package com.kobani4k.app.tv.ui

import android.net.Uri
import android.view.KeyEvent
import android.widget.TextClock
import androidx.activity.compose.BackHandler
import androidx.annotation.OptIn as Media3OptIn
import androidx.compose.animation.*
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
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
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.rounded.*
import androidx.compose.material3.CircularProgressIndicator
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

// Enum to handle right-side menus
enum class ActiveMenu { NONE, QUALITY, AUDIO, SUBTITLES, SETTINGS }

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

    var channelsList by remember { mutableStateOf<List<TvChannel>>(emptyList()) }

    LaunchedEffect(Unit) {
        channelsList = repository.getChannels()
    }

    // Auto-hide controls after 5 seconds of inactivity
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
            // Give time for UI to compose before focusing controls
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
                    
                    val isUp = keyEvent.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_DPAD_UP || keyEvent.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_CHANNEL_UP
                    val isDown = keyEvent.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_DPAD_DOWN || keyEvent.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_CHANNEL_DOWN
                    
                    // If controls are hidden, allow Quick Zap!
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
                                    showControls = true
                                }
                            }
                            return@onKeyEvent true
                        }
                    }

                    // Standard Key bindings
                    when (keyEvent.nativeKeyEvent.keyCode) {
                        KeyEvent.KEYCODE_DPAD_CENTER, KeyEvent.KEYCODE_ENTER -> {
                            if (!showZapList && !showControls) {
                                showControls = true
                                return@onKeyEvent true
                            }
                            false // Let Compose handle button clicks
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
        // VIDEO PLAYER
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

        if (isBuffering) {
            Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.4f)), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = UltraTokens.Accent, modifier = Modifier.size(64.dp))
            }
        }

        // PROFESSIONAL OSD CONTROLS
        AnimatedVisibility(
            visible = showControls && !showZapList,
            enter = fadeIn(tween(300)),
            exit = fadeOut(tween(300))
        ) {
            Box(modifier = Modifier.fillMaxSize()) {
                
                // TOP BAR (Channel Info & Clock)
                AnimatedVisibility(
                    visible = showControls,
                    enter = slideInVertically { -it },
                    exit = slideOutVertically { -it },
                    modifier = Modifier.align(Alignment.TopCenter)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(Brush.verticalGradient(listOf(Color.Black.copy(0.9f), Color.Transparent)))
                            .padding(horizontal = 48.dp, vertical = 32.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.Top
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            if (!currentLogoUrl.isNullOrEmpty()) {
                                AsyncImage(
                                    model = currentLogoUrl,
                                    contentDescription = null,
                                    modifier = Modifier.size(64.dp).clip(RoundedCornerShape(8.dp))
                                )
                                Spacer(Modifier.width(20.dp))
                            }
                            Column {
                                Text(text = "NOW PLAYING", color = UltraTokens.Accent, fontSize = 12.sp, fontWeight = FontWeight.Bold, letterSpacing = 2.sp)
                                Text(text = currentChannelName, color = Color.White, fontSize = 28.sp, fontWeight = FontWeight.Bold)
                            }
                        }
                        
                        // TV Clock
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
                    }
                }

                // BOTTOM BAR (Controls)
                AnimatedVisibility(
                    visible = showControls,
                    enter = slideInVertically { it },
                    exit = slideOutVertically { it },
                    modifier = Modifier.align(Alignment.BottomCenter)
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(Brush.verticalGradient(listOf(Color.Transparent, Color.Black.copy(0.8f), Color.Black)))
                            .padding(horizontal = 48.dp, vertical = 32.dp)
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Box(modifier = Modifier.size(10.dp).clip(CircleShape).background(Color.Red))
                            Spacer(Modifier.width(8.dp))
                            Text("LIVE", color = Color.White, fontSize = 14.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.sp)
                        }
                        Spacer(Modifier.height(24.dp))
                        
                        // Control Buttons Row
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(16.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.focusGroup()
                        ) {
                            // Play/Pause
                            OsdIconButton(
                                icon = if (isPlayingState) Icons.Rounded.Pause else Icons.Rounded.PlayArrow,
                                label = if (isPlayingState) "Pause" else "Play",
                                modifier = Modifier.focusRequester(controlsFocusRequester),
                                onClick = {
                                    wakeUpControls()
                                    if (isPlayingState) exoPlayer.pause() else exoPlayer.play()
                                }
                            )

                            Spacer(Modifier.width(16.dp))

                            // Quality
                            OsdIconButton(
                                icon = Icons.Rounded.HighQuality,
                                label = "Quality",
                                onClick = { activeMenu = ActiveMenu.QUALITY; wakeUpControls() }
                            )

                            // Audio
                            OsdIconButton(
                                icon = Icons.Rounded.Audiotrack,
                                label = "Audio Tracks",
                                onClick = { activeMenu = ActiveMenu.AUDIO; wakeUpControls() }
                            )
                            
                            // Subtitles
                            OsdIconButton(
                                icon = Icons.Rounded.Subtitles,
                                label = "Subtitles",
                                onClick = { activeMenu = ActiveMenu.SUBTITLES; wakeUpControls() }
                            )

                            Spacer(Modifier.weight(1f))

                            // Settings
                            OsdIconButton(
                                icon = Icons.Rounded.Settings,
                                label = "Settings",
                                onClick = { activeMenu = ActiveMenu.SETTINGS; wakeUpControls() }
                            )
                        }
                    }
                }
            }
        }

        // RIGHT SIDE MENU (Quality, Audio, etc)
        AnimatedVisibility(
            visible = activeMenu != ActiveMenu.NONE,
            enter = slideInHorizontally { it } + fadeIn(),
            exit = slideOutHorizontally { it } + fadeOut(),
            modifier = Modifier.align(Alignment.CenterEnd)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxHeight()
                    .width(340.dp)
                    .background(Color(0xE60A0A0F)) // Translucent dark
                    .padding(24.dp)
            ) {
                Column(Modifier.fillMaxSize()) {
                    Text(
                        text = activeMenu.name,
                        color = Color.White,
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.padding(bottom = 24.dp)
                    )
                    
                    // Mocked List - You will wire this to ExoPlayer TrackSelection parameters later
                    LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        val items = when (activeMenu) {
                            ActiveMenu.QUALITY -> listOf("Auto", "1080p (HD)", "720p", "480p")
                            ActiveMenu.AUDIO -> listOf("Track 1 (Default)", "Track 2")
                            ActiveMenu.SUBTITLES -> listOf("Off", "English", "Spanish")
                            else -> listOf("Aspect Ratio", "Decoder", "Sleep Timer")
                        }
                        
                        items(items.size) { index ->
                            TrackMenuItem(
                                title = items[index],
                                isSelected = index == 0, // Mock selection
                                onClick = { activeMenu = ActiveMenu.NONE }
                            )
                        }
                    }
                }
            }
        }

        // ZAP LIST
        AnimatedVisibility(
            visible = showZapList,
            enter = slideInHorizontally { -it } + fadeIn(),
            exit = slideOutHorizontally { -it } + fadeOut()
        ) {
            LiveDrawer(
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

@Composable
fun OsdIconButton(
    icon: ImageVector,
    label: String,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(if (isFocused) 1.15f else 1f, tween(200))
    val bgAlpha by animateFloatAsState(if (isFocused) 1f else 0.2f, tween(200))

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = modifier.width(80.dp)
    ) {
        Box(
            modifier = Modifier
                .size(56.dp)
                .scale(scale)
                .clip(CircleShape)
                .background(if (isFocused) UltraTokens.Accent else Color.White.copy(alpha = bgAlpha))
                .focusable()
                .onFocusChanged { isFocused = it.isFocused }
                .onKeyEvent {
                    if (it.nativeKeyEvent.action == KeyEvent.ACTION_DOWN && it.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_DPAD_CENTER) {
                        onClick()
                        true
                    } else false
                },
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = label,
                tint = if (isFocused) Color.White else Color.White.copy(alpha = 0.9f),
                modifier = Modifier.size(28.dp)
            )
        }
        
        Spacer(Modifier.height(12.dp))
        
        // Tooltip label appears when focused
        AnimatedVisibility(visible = isFocused, enter = fadeIn(), exit = fadeOut()) {
            Text(
                text = label,
                color = Color.White,
                fontSize = 12.sp,
                fontWeight = FontWeight.Medium,
                maxLines = 1
            )
        }
    }
}

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun TrackMenuItem(
    title: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp))
            .background(if (isFocused) UltraTokens.Accent else if (isSelected) Color.White.copy(0.1f) else Color.Transparent)
            .focusable()
            .onFocusChanged { isFocused = it.isFocused }
            .onKeyEvent {
                if (it.nativeKeyEvent.action == KeyEvent.ACTION_DOWN && it.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_DPAD_CENTER) {
                    onClick()
                    true
                } else false
            }
            .padding(16.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = title,
                color = if (isFocused) Color.White else Color.LightGray,
                fontSize = 16.sp,
                fontWeight = if (isSelected || isFocused) FontWeight.Bold else FontWeight.Normal
            )
            if (isSelected) {
                Icon(
                    imageVector = Icons.Rounded.Check,
                    contentDescription = null,
                    tint = if (isFocused) Color.White else UltraTokens.Accent,
                    modifier = Modifier.size(20.dp)
                )
            }
        }
    }
}

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
internal fun LiveDrawer(
    channels: List<TvChannel>,
    currentUrl: String,
    onPick: (TvChannel) -> Unit,
    onDismiss: () -> Unit
) {
    BackHandler { onDismiss() }

    val listState = rememberLazyListState()
    val initialIdx = remember(channels) { channels.indexOfFirst { it.url == currentUrl }.coerceAtLeast(0) }
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
                .background(Color(0xFA09090C)) // Highly opaque glass look
        ) {
            // Icon Menu
            Column(
                modifier = Modifier
                    .width(72.dp)
                    .fillMaxHeight()
                    .background(Color(0xFF0B0A12))
                    .padding(vertical = 24.dp)
                    .focusGroup()
                    .focusRestorer()
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(20.dp),
            ) {
                DrawerIconButton(Icons.Default.Search, "Search", onClick = {})
                DrawerIconButton(Icons.Default.List, "EPG", onClick = {})
                DrawerIconButton(Icons.Default.Favorite, "Add to Fav", onClick = {})
                DrawerIconButton(Icons.Default.PlayArrow, "Tracks", onClick = {})
                DrawerIconButton(Icons.Default.Info, "Aspect", onClick = {})
                DrawerIconButton(Icons.Default.Settings, "Settings", onClick = {})
            }

            // Channel List
            Column(
                modifier = Modifier
                    .fillMaxHeight()
                    .width(360.dp)
                    .padding(horizontal = 16.dp, vertical = 24.dp),
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        "All Channels",
                        color = Color.White,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
                Spacer(Modifier.height(16.dp))
                LazyColumn(
                    state = listState,
                    verticalArrangement = Arrangement.spacedBy(4.dp),
                    modifier = Modifier.fillMaxSize().focusRestorer()
                ) {
                    items(channels.size) { index ->
                        val e = channels[index]
                        val isCurrent = e.url == currentUrl
                        val interaction = remember { MutableInteractionSource() }
                        val focused by interaction.collectIsFocusedAsState()
                        val highlight = isCurrent || focused

                        Card(
                            onClick = { onPick(e) },
                            modifier = if (isCurrent) Modifier.focusRequester(currentFocus) else Modifier,
                            interactionSource = interaction,
                            shape = CardDefaults.shape(RoundedCornerShape(4.dp)),
                            colors = ultraCardColors(
                                containerColor = Color.Transparent,
                                focusedContainerColor = UltraTokens.Accent,
                                focusedContentColor = Color.White,
                            ),
                        ) {
                            Row(
                                Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 12.dp),
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                Text(
                                    (index + 1).toString(),
                                    color = if (isCurrent) UltraTokens.Accent else Color.White.copy(alpha = 0.5f),
                                    fontSize = 14.sp,
                                    fontWeight = FontWeight.Bold,
                                    modifier = Modifier.width(32.dp),
                                )
                                Spacer(Modifier.width(8.dp))
                                Column(Modifier.weight(1f)) {
                                    Text(
                                        e.name,
                                        color = if (isCurrent && !highlight) UltraTokens.Accent else Color.White,
                                        fontSize = 15.sp,
                                        fontWeight = if (isCurrent) FontWeight.Bold else FontWeight.Medium,
                                        maxLines = 1,
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }

        Box(
            Modifier
                .weight(1f)
                .fillMaxHeight()
                .background(Color(0x33000000))
        )
    }
}

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
private fun DrawerIconButton(
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
        modifier = Modifier.size(48.dp),
    ) {
        Icon(
            icon,
            contentDescription = label,
            tint = if (focused) Color.Black else tint,
            modifier = Modifier.size(24.dp),
        )
    }
}
