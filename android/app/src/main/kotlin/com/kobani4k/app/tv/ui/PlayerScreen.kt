package com.kobani4k.app.tv.ui

import android.net.Uri
import android.view.KeyEvent
import androidx.activity.compose.BackHandler
import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.focusable
import androidx.compose.foundation.focusGroup
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.focusRestorer
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
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
import com.kobani4k.app.tv.ui.theme.UltraTokens
import com.kobani4k.app.tv.ui.theme.ultraCardColors
import kotlinx.coroutines.delay

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
    var controlsTimeout by remember { mutableStateOf(0) }
    
    var channelsList by remember { mutableStateOf<List<TvChannel>>(emptyList()) }

    LaunchedEffect(Unit) {
        channelsList = repository.getChannels()
    }

    LaunchedEffect(showControls, controlsTimeout) {
        if (showControls) {
            delay(5000) // Auto-hide controls after 5 seconds
            showControls = false
        }
    }

    fun resetControlsTimeout() {
        controlsTimeout++
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

        val renderersFactory = DefaultRenderersFactory(context)
            .setEnableDecoderFallback(true)
            .setExtensionRendererMode(DefaultRenderersFactory.EXTENSION_RENDERER_MODE_PREFER)
            .forceEnableMediaCodecAsynchronousQueueing()

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
            
        player.trackSelectionParameters = player.trackSelectionParameters.buildUpon()
            .setMaxAudioChannelCount(2)
            .build()

        player.setWakeMode(androidx.media3.common.C.WAKE_MODE_NETWORK)
        player.videoScalingMode = androidx.media3.common.C.VIDEO_SCALING_MODE_SCALE_TO_FIT

        player
    }

    LaunchedEffect(currentStreamUrl) {
        isBuffering = true
        exoPlayer.stop()
        val mediaItem = MediaItem.fromUri(Uri.parse(currentStreamUrl))
        exoPlayer.setMediaItem(mediaItem)
        exoPlayer.prepare()
        exoPlayer.playWhenReady = true
        exoPlayer.play()
    }

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

    val focusRequester = remember { FocusRequester() }
    LaunchedEffect(showZapList, showControls) {
        if (!showZapList && !showControls) {
            focusRequester.requestFocus()
        }
    }

    BackHandler {
        if (showControls) {
            showControls = false
        } else if (showZapList) {
            showZapList = false
        } else {
            onBack()
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
            .focusRequester(focusRequester)
            .focusable()
            .onKeyEvent { keyEvent ->
                if (keyEvent.nativeKeyEvent.action == KeyEvent.ACTION_DOWN) {
                    resetControlsTimeout()
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
                        KeyEvent.KEYCODE_BACK -> {
                            if (showControls) {
                                showControls = false
                                true
                            } else if (showZapList) {
                                showZapList = false
                                true
                            } else {
                                onBack()
                                true
                            }
                        }
                        KeyEvent.KEYCODE_DPAD_UP -> {
                            if (!showZapList && channelsList.isNotEmpty()) {
                                val currentIndex = channelsList.indexOfFirst { it.url == currentStreamUrl }
                                if (currentIndex != -1) {
                                    val nextIndex = (currentIndex + 1) % channelsList.size
                                    val nextChannel = channelsList[nextIndex]
                                    currentStreamUrl = nextChannel.url
                                    currentChannelName = nextChannel.name
                                    currentLogoUrl = nextChannel.logo
                                    showControls = true
                                }
                                return@onKeyEvent true
                            }
                            false
                        }
                        KeyEvent.KEYCODE_DPAD_DOWN -> {
                            if (!showZapList && channelsList.isNotEmpty()) {
                                val currentIndex = channelsList.indexOfFirst { it.url == currentStreamUrl }
                                if (currentIndex != -1) {
                                    val prevIndex = if (currentIndex - 1 < 0) channelsList.size - 1 else currentIndex - 1
                                    val prevChannel = channelsList[prevIndex]
                                    currentStreamUrl = prevChannel.url
                                    currentChannelName = prevChannel.name
                                    currentLogoUrl = prevChannel.logo
                                    showControls = true
                                }
                                return@onKeyEvent true
                            }
                            false
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
        AndroidView(
            factory = { ctx ->
                PlayerView(ctx).apply {
                    player = exoPlayer
                    useController = false
                    resizeMode = androidx.media3.ui.AspectRatioFrameLayout.RESIZE_MODE_FIT
                    isFocusable = false
                    isFocusableInTouchMode = false
                    descendantFocusability = android.view.ViewGroup.FOCUS_BLOCK_DESCENDANTS
                }
            },
            modifier = Modifier.fillMaxSize()
        )

        if (isBuffering) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.4f)),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(
                    color = UltraTokens.Accent,
                    modifier = Modifier.size(56.dp)
                )
            }
        }

        // OSD Controls
        AnimatedVisibility(
            visible = showControls && !showZapList,
            enter = fadeIn(),
            exit = fadeOut()
        ) {
            Box(modifier = Modifier.fillMaxSize()) {
                // Top Bar
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(200.dp)
                        .background(
                            Brush.verticalGradient(
                                colors = listOf(Color.Black.copy(alpha = 0.95f), Color.Black.copy(alpha = 0.6f), Color.Transparent)
                            )
                        )
                        .padding(horizontal = 48.dp, vertical = 40.dp),
                    contentAlignment = Alignment.TopStart
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        if (!currentLogoUrl.isNullOrEmpty()) {
                            AsyncImage(
                                model = currentLogoUrl,
                                contentDescription = null,
                                modifier = Modifier.size(72.dp)
                            )
                            Spacer(Modifier.width(24.dp))
                        }
                        Text(
                            text = currentChannelName,
                            color = Color.White,
                            fontSize = 32.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }

                // Bottom Bar
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(260.dp)
                        .align(Alignment.BottomCenter)
                        .background(
                            Brush.verticalGradient(
                                colors = listOf(Color.Transparent, Color.Black.copy(alpha = 0.7f), Color.Black.copy(alpha = 0.98f))
                            )
                        )
                        .padding(horizontal = 48.dp, vertical = 40.dp),
                    contentAlignment = Alignment.BottomStart
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.Bottom
                    ) {
                        Column {
                            Text(
                                text = "NOW PLAYING",
                                color = UltraTokens.Accent,
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Bold,
                                letterSpacing = 2.sp
                            )
                            Spacer(Modifier.height(8.dp))
                            Text(
                                text = currentChannelName,
                                color = Color.White,
                                fontSize = 28.sp,
                                fontWeight = FontWeight.SemiBold
                            )
                        }

                        Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                            val interaction = remember { MutableInteractionSource() }
                            val focused by interaction.collectIsFocusedAsState()

                            Button(
                                onClick = { 
                                    resetControlsTimeout()
                                    if (isPlayingState) exoPlayer.pause() else exoPlayer.play() 
                                },
                                interactionSource = interaction,
                                shape = ButtonDefaults.shape(RoundedCornerShape(12.dp)),
                                colors = ButtonDefaults.colors(
                                    containerColor = if (focused) UltraTokens.Accent else Color.White.copy(alpha = 0.15f),
                                    contentColor = Color.White
                                ),
                                modifier = Modifier.size(64.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Default.PlayArrow,
                                    contentDescription = "Play/Pause",
                                    modifier = Modifier.size(36.dp)
                                )
                            }
                        }
                    }
                }
            }
        }

        // Zap List
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
