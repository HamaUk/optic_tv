package com.kobani4k.app.tv.ui

import android.net.Uri
import android.view.KeyEvent
import androidx.compose.animation.*
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.scale
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
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
import kotlinx.coroutines.delay

// Colors matching StreamVault
private val CanvasColor = Color(0xFF07111B)
private val SurfaceColor = Color(0xFF0F1B29)
private val SurfaceElevatedColor = Color(0xFF162338)
private val BrandGold = Color(0xFFFFC766)
private val FocusedOutlineColor = Color(0xFFF5F7FB)
private val TextPrimary = Color(0xFFF5F7FB)
private val TextSecondary = Color(0xFFBBC6D8)

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

    // Dynamic states
    var currentChannelName by remember { mutableStateOf(channelName) }
    var currentStreamUrl by remember { mutableStateOf(streamUrl) }
    var currentLogoUrl by remember { mutableStateOf(logoUrl) }
    
    var isBuffering by remember { mutableStateOf(true) }
    var isPlayingState by remember { mutableStateOf(true) }
    var isMuted by remember { mutableStateOf(false) }
    
    var showControls by remember { mutableStateOf(true) }
    var controlHideTrigger by remember { mutableStateOf(0) }
    var showZapList by remember { mutableStateOf(false) }
    
    var channelsList by remember { mutableStateOf<List<TvChannel>>(emptyList()) }

    // Load channels list for zapping
    LaunchedEffect(Unit) {
        channelsList = repository.getChannels()
    }

    // Auto-hide controls timer
    LaunchedEffect(showControls, controlHideTrigger) {
        if (showControls && !showZapList) {
            delay(5000)
            showControls = false
        }
    }

    // 1. Configure ExoPlayer for Instant Playback & Low Latency
    val exoPlayer = remember {
        // Tuning default load control for rapid start
        val loadControl = DefaultLoadControl.Builder()
            .setBufferDurationsMs(
                5000,   // minBufferMs (minimum to load before buffer checks)
                15000,  // maxBufferMs (max memory footprint)
                500,    // bufferForPlaybackMs (Only needs 0.5s of buffer to start rendering!)
                1500    // bufferForPlaybackAfterRebufferMs (fast recovery)
            )
            .setPrioritizeTimeOverSizeThresholds(true)
            .build()

        // Tuning headers (User-Agent = SmartIPTV to bypass strict server filters)
        val httpDataSourceFactory = DefaultHttpDataSource.Factory()
            .setUserAgent("SmartIPTV")
            .setAllowCrossProtocolRedirects(true)
            .setConnectTimeoutMs(10000)
            .setReadTimeoutMs(15000)

        // Trick 1: PREFER Software Decoders (FFmpeg) over buggy hardware decoders
        val renderersFactory = DefaultRenderersFactory(context)
            .setEnableDecoderFallback(true)
            .setExtensionRendererMode(DefaultRenderersFactory.EXTENSION_RENDERER_MODE_PREFER)
            .forceEnableMediaCodecAsynchronousQueueing()

        // Trick 4: Explicit Movie Audio Attributes to bypass weird Android OS audio routing
        val audioAttributes = androidx.media3.common.AudioAttributes.Builder()
            .setUsage(androidx.media3.common.C.USAGE_MEDIA)
            .setContentType(androidx.media3.common.C.AUDIO_CONTENT_TYPE_MOVIE)
            .build()

        val player = ExoPlayer.Builder(context)
            .setRenderersFactory(renderersFactory)
            .setLoadControl(loadControl)
            .setMediaSourceFactory(DefaultMediaSourceFactory(httpDataSourceFactory))
            .setAudioAttributes(audioAttributes, true)
            .build()
            
        // Trick 3: Downmix to Stereo (2 channels) & Disable DSP Audio Offload
        // Also enable Audio Tunneling (trick from ultra-tv-main) to bypass the Android mixer
        // for better A/V sync on Android TV hardware decoders.
        player.trackSelectionParameters = player.trackSelectionParameters.buildUpon()
            .setMaxAudioChannelCount(2)
            .setTunnelingEnabled(true)
            .build()

        // Trick 5: Network Wake Mode to prevent cheap CPUs from putting audio/WiFi chips to sleep
        player.setWakeMode(androidx.media3.common.C.WAKE_MODE_NETWORK)

        // Trick from ultra-tv-main: Force video scaling mode to SCALE_TO_FIT.
        // On many cheap AMLogic/Realtek chipsets, the hardware decoder delivers frames but the 
        // surface isn't sized properly, leading to a "black screen with audio only" issue.
        player.videoScalingMode = androidx.media3.common.C.VIDEO_SCALING_MODE_SCALE_TO_FIT

        player
    }

    // Load initial item
    LaunchedEffect(currentStreamUrl) {
        isBuffering = true
        exoPlayer.stop()
        val mediaItem = MediaItem.fromUri(Uri.parse(currentStreamUrl))
        exoPlayer.setMediaItem(mediaItem)
        exoPlayer.prepare()
        exoPlayer.playWhenReady = true
        exoPlayer.play()
    }

    // Listener for buffering and state changes
    val playerListener = remember {
        object : Media3Player.Listener {
            override fun onPlaybackStateChanged(state: Int) {
                isBuffering = state == Media3Player.STATE_BUFFERING
                isPlayingState = exoPlayer.isPlaying
            }
            override fun onPlayerError(error: PlaybackException) {
                isBuffering = false
                error.printStackTrace()
            }
            override fun onIsPlayingChanged(isPlaying: Boolean) {
                isPlayingState = isPlaying
            }
        }
    }

    DisposableEffect(exoPlayer) {
        exoPlayer.addListener(playerListener)
        onDispose {
            exoPlayer.removeListener(playerListener)
            exoPlayer.release()
        }
    }

    // Focus Requester to capture D-pad key events
    val focusRequester = remember { FocusRequester() }
    LaunchedEffect(Unit) {
        focusRequester.requestFocus()
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
            .focusRequester(focusRequester)
            .focusable()
            .onKeyEvent { keyEvent ->
                if (keyEvent.nativeKeyEvent.action == KeyEvent.ACTION_DOWN) {
                    controlHideTrigger++ // Reset autohide timer
                    
                    when (keyEvent.nativeKeyEvent.keyCode) {
                        KeyEvent.KEYCODE_DPAD_CENTER,
                        KeyEvent.KEYCODE_ENTER -> {
                            if (!showZapList) {
                                showControls = !showControls
                            }
                            true
                        }
                        KeyEvent.KEYCODE_DPAD_LEFT -> {
                            if (!showZapList) {
                                showZapList = true
                                showControls = false
                            }
                            true
                        }
                        KeyEvent.KEYCODE_DPAD_RIGHT -> {
                            if (showZapList) {
                                showZapList = false
                                showControls = true
                            }
                            true
                        }
                        KeyEvent.KEYCODE_BACK -> {
                            if (showZapList) {
                                showZapList = false
                                true
                            } else if (showControls) {
                                showControls = false
                                true
                            } else {
                                onBack()
                                true
                            }
                        }
                        KeyEvent.KEYCODE_DPAD_UP -> {
                            if (!showZapList && channelsList.isNotEmpty()) {
                                // Zap Up
                                val currentIndex = channelsList.indexOfFirst { it.url == currentStreamUrl }
                                if (currentIndex != -1) {
                                    val nextIndex = (currentIndex + 1) % channelsList.size
                                    val nextChannel = channelsList[nextIndex]
                                    currentStreamUrl = nextChannel.url
                                    currentChannelName = nextChannel.name
                                    currentLogoUrl = nextChannel.logo
                                    showControls = true
                                }
                            }
                            false
                        }
                        KeyEvent.KEYCODE_DPAD_DOWN -> {
                            if (!showZapList && channelsList.isNotEmpty()) {
                                // Zap Down
                                val currentIndex = channelsList.indexOfFirst { it.url == currentStreamUrl }
                                if (currentIndex != -1) {
                                    val prevIndex = if (currentIndex - 1 < 0) channelsList.size - 1 else currentIndex - 1
                                    val prevChannel = channelsList[prevIndex]
                                    currentStreamUrl = prevChannel.url
                                    currentChannelName = prevChannel.name
                                    currentLogoUrl = prevChannel.logo
                                    showControls = true
                                }
                            }
                            false
                        }
                        else -> false
                    }
                } else {
                    false
                }
            }
    ) {
        // 1. NATIVE VIDEO SURFACE
        AndroidView(
            factory = { ctx ->
                PlayerView(ctx).apply {
                    player = exoPlayer
                    useController = false
                    resizeMode = androidx.media3.ui.AspectRatioFrameLayout.RESIZE_MODE_FIT
                }
            },
            modifier = Modifier.fillMaxSize()
        )

        // 2. BUFFERING OVERLAY
        if (isBuffering) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.4f)),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    CircularProgressIndicator(
                        color = BrandGold,
                        modifier = Modifier.size(56.dp)
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "CONNECTING STREAM...",
                        color = TextPrimary,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 2.sp
                    )
                }
            }
        }

        // 3. LEFT SIDEBAR ZAP LIST
        AnimatedVisibility(
            visible = showZapList,
            enter = slideInHorizontally { -it } + fadeIn(),
            exit = slideOutHorizontally { -it } + fadeOut()
        ) {
            Surface(
                shape = RoundedCornerShape(0.dp),
                colors = SurfaceDefaults.colors(
                    containerColor = SurfaceColor.copy(alpha = 0.95f)
                ),
                border = Border(
                    border = androidx.compose.foundation.BorderStroke(1.dp, SurfaceElevatedColor),
                    shape = RoundedCornerShape(0.dp)
                ),
                modifier = Modifier
                    .width(320.dp)
                    .fillMaxHeight()
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(vertical = 24.dp, horizontal = 16.dp)
                ) {
                    Text(
                        text = "QUICK ZAP LIST",
                        color = BrandGold,
                        fontWeight = FontWeight.Black,
                        fontSize = 18.sp,
                        letterSpacing = 2.sp,
                        modifier = Modifier.padding(bottom = 20.dp, start = 8.dp)
                    )
                    
                    if (channelsList.isEmpty()) {
                        Box(modifier = Modifier.weight(1f), contentAlignment = Alignment.Center) {
                            Text("No channels synced.", color = TextSecondary)
                        }
                    } else {
                        LazyColumn(
                            modifier = Modifier.weight(1f),
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            items(channelsList.size) { index ->
                                val ch = channelsList[index]
                                ZapItem(
                                    channel = ch,
                                    isSelected = ch.url == currentStreamUrl,
                                    onClick = {
                                        currentStreamUrl = ch.url
                                        currentChannelName = ch.name
                                        currentLogoUrl = ch.logo
                                        showZapList = false
                                        showControls = true
                                    }
                                )
                            }
                        }
                    }
                }
            }
        }

        // 4. PREMIUM HUD OVERLAY (TOP & BOTTOM OVERLAYS)
        AnimatedVisibility(
            visible = showControls,
            enter = fadeIn() + slideInVertically { it / 2 },
            exit = fadeOut() + slideOutVertically { it / 2 }
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        Brush.verticalGradient(
                            colors = listOf(
                                Color.Black.copy(alpha = 0.85f),
                                Color.Transparent,
                                Color.Transparent,
                                Color.Black.copy(alpha = 0.92f)
                            )
                        )
                    )
                    .padding(50.dp)
            ) {
                // TOP HUD: Channel Branding & Stream Status
                Row(
                    modifier = Modifier.align(Alignment.TopStart),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    if (!currentLogoUrl.isNullOrEmpty()) {
                        AsyncImage(
                            model = currentLogoUrl,
                            contentDescription = null,
                            modifier = Modifier
                                .size(72.dp)
                                .background(Color.White.copy(alpha = 0.1f), RoundedCornerShape(16.dp))
                                .padding(8.dp)
                        )
                    } else {
                        Box(
                            modifier = Modifier
                                .size(72.dp)
                                .background(SurfaceElevatedColor, RoundedCornerShape(16.dp)),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "TV",
                                color = BrandGold,
                                fontWeight = FontWeight.Bold,
                                fontSize = 20.sp
                            )
                        }
                    }
                    
                    Spacer(modifier = Modifier.width(24.dp))
                    
                    Column {
                        Text(
                            text = "NOW STREAMING LIVE",
                            color = BrandGold,
                            fontWeight = FontWeight.Black,
                            fontSize = 13.sp,
                            letterSpacing = 3.sp
                        )
                        Text(
                            text = currentChannelName.uppercase(),
                            color = TextPrimary,
                            fontSize = 32.sp,
                            fontWeight = FontWeight.Black
                        )
                    }
                }

                // BOTTOM HUD: Controls & Zap Hints
                Column(
                    modifier = Modifier.align(Alignment.BottomStart)
                ) {
                    // Sleek Gold Buffer Progress Indicator
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(4.dp)
                            .background(Color.White.copy(alpha = 0.15f), RoundedCornerShape(2.dp))
                    ) {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth(1.0f) // Represents continuous live feed
                                .height(4.dp)
                                .background(BrandGold, RoundedCornerShape(2.dp))
                        )
                    }

                    Spacer(modifier = Modifier.height(24.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Quick Action Buttons
                        Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                            HudActionButton(
                                label = if (isPlayingState) "PAUSE" else "PLAY",
                                iconText = if (isPlayingState) "||" else ">"
                            ) {
                                if (isPlayingState) exoPlayer.pause() else exoPlayer.play()
                            }
                            
                            HudActionButton(
                                label = if (isMuted) "UNMUTE" else "MUTE",
                                iconText = "VOL"
                            ) {
                                isMuted = !isMuted
                                exoPlayer.volume = if (isMuted) 0.0f else 1.0f
                            }
                            
                            HudActionButton(
                                label = "ZAP LIST",
                                iconText = "<-"
                            ) {
                                showControls = false
                                showZapList = true
                            }
                            
                            HudActionButton(
                                label = "RETURN",
                                iconText = "ESC"
                            ) {
                                onBack()
                            }
                        }

                        // Navigation Hints
                        Row(horizontalArrangement = Arrangement.spacedBy(28.dp)) {
                            Text(
                                text = "← ZAP LIST",
                                color = TextSecondary,
                                fontWeight = FontWeight.Bold,
                                fontSize = 12.sp,
                                letterSpacing = 1.sp
                            )
                            Text(
                                text = "↑↓ NEXT/PREV CH",
                                color = TextSecondary,
                                fontWeight = FontWeight.Bold,
                                fontSize = 12.sp,
                                letterSpacing = 1.sp
                            )
                            Text(
                                text = "OK INFO",
                                color = TextSecondary,
                                fontWeight = FontWeight.Bold,
                                fontSize = 12.sp,
                                letterSpacing = 1.sp
                            )
                        }
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun ZapItem(
    channel: TvChannel,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(targetValue = if (isFocused) 1.03f else 1.0f)

    Surface(
        onClick = onClick,
        shape = ClickableSurfaceDefaults.shape(shape = RoundedCornerShape(12.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = if (isSelected) SurfaceElevatedColor else Color.Transparent,
            focusedContainerColor = TextPrimary,
            contentColor = if (isSelected) BrandGold else TextSecondary,
            focusedContentColor = CanvasColor
        ),
        border = ClickableSurfaceDefaults.border(
            border = Border(
                border = androidx.compose.foundation.BorderStroke(
                    width = if (isSelected) 1.5.dp else 0.dp,
                    color = if (isSelected) BrandGold else Color.Transparent
                ),
                shape = RoundedCornerShape(12.dp)
            ),
            focusedBorder = Border(
                border = androidx.compose.foundation.BorderStroke(2.dp, FocusedOutlineColor),
                shape = RoundedCornerShape(12.dp)
            )
        ),
        modifier = Modifier
            .fillMaxWidth()
            .height(52.dp)
            .scale(scale)
            .onFocusChanged { isFocused = it.isFocused }
    ) {
        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (!channel.logo.isNullOrEmpty()) {
                AsyncImage(
                    model = channel.logo,
                    contentDescription = null,
                    modifier = Modifier
                        .size(32.dp)
                        .background(Color.White.copy(alpha = 0.1f), RoundedCornerShape(8.dp))
                        .padding(4.dp)
                )
            } else {
                Box(
                    modifier = Modifier
                        .size(32.dp)
                        .background(SurfaceElevatedColor, RoundedCornerShape(8.dp)),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "TV",
                        fontSize = 10.sp,
                        color = BrandGold,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
            Spacer(modifier = Modifier.width(12.dp))
            Text(
                text = channel.name,
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold,
                maxLines = 1
            )
        }
    }
}

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun HudActionButton(
    label: String,
    iconText: String,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(targetValue = if (isFocused) 1.04f else 1.0f)

    Button(
        onClick = onClick,
        shape = ButtonDefaults.shape(shape = RoundedCornerShape(12.dp)),
        colors = ButtonDefaults.colors(
            containerColor = SurfaceElevatedColor.copy(alpha = 0.6f),
            focusedContainerColor = TextPrimary,
            contentColor = TextPrimary,
            focusedContentColor = CanvasColor
        ),
        border = ButtonDefaults.border(
            border = Border(
                border = androidx.compose.foundation.BorderStroke(1.dp, SurfaceElevatedColor),
                shape = RoundedCornerShape(12.dp)
            ),
            focusedBorder = Border(
                border = androidx.compose.foundation.BorderStroke(2.dp, BrandGold),
                shape = RoundedCornerShape(12.dp)
            )
        ),
        modifier = Modifier
            .height(44.dp)
            .scale(scale)
            .onFocusChanged { isFocused = it.isFocused }
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(24.dp)
                    .background(
                        if (isFocused) CanvasColor.copy(alpha = 0.15f) else SurfaceElevatedColor,
                        RoundedCornerShape(6.dp)
                    ),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = iconText,
                    fontSize = 9.sp,
                    fontWeight = FontWeight.Black,
                    color = if (isFocused) CanvasColor else BrandGold
                )
            }
            Text(
                text = label,
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold
            )
        }
    }
}
