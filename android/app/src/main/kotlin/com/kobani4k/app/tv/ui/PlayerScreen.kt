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
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.scale
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.type
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
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
import com.kobani4k.app.R
import com.kobani4k.app.tv.data.PocketBaseRepository
import com.kobani4k.app.tv.data.TvChannel
import kotlinx.coroutines.delay

// Colors matching Premium TV theme
private val CanvasColor = Color(0xFF07111B)
private val SurfaceColor = Color(0xFF0F1B29)
private val SurfaceElevatedColor = Color(0xFF162338)
private val BrandGold = Color(0xFFFFC766)
private val FocusedOutlineColor = Color(0xFFF5F7FB)
private val TextPrimary = Color(0xFFF5F7FB)
private val TextSecondary = Color(0xFFBBC6D8)
private val OverlayBackground = Color(0xDD000000)
private val ZinaPanelBackground = Color(0xFF1E2738)

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
    
    var showControls by remember { mutableStateOf(false) }
    var controlHideTrigger by remember { mutableStateOf(0) }
    
    var channelNumberInput by remember { mutableStateOf("") }
    var showChannelInfoBanner by remember { mutableStateOf(true) }
    var infoBannerHideTrigger by remember { mutableStateOf(0) }
    
    var channelsList by remember { mutableStateOf<List<TvChannel>>(emptyList()) }

    LaunchedEffect(Unit) {
        channelsList = repository.getChannels()
    }

    LaunchedEffect(showControls, controlHideTrigger) {
        if (showControls) {
            delay(10000)
            showControls = false
        }
    }

    LaunchedEffect(showChannelInfoBanner, infoBannerHideTrigger) {
        if (showChannelInfoBanner && !showControls) {
            delay(4000)
            showChannelInfoBanner = false
        }
    }

    LaunchedEffect(channelNumberInput) {
        if (channelNumberInput.isNotEmpty()) {
            delay(2500)
            val index = channelNumberInput.toIntOrNull() ?: 0
            if (channelsList.isNotEmpty()) {
                val safeIndex = index.coerceIn(0, channelsList.size - 1)
                val ch = channelsList[safeIndex]
                currentStreamUrl = ch.url
                currentChannelName = ch.name
                currentLogoUrl = ch.logo
                
                showChannelInfoBanner = true
                infoBannerHideTrigger++
            }
            channelNumberInput = ""
        }
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
        showChannelInfoBanner = true
        infoBannerHideTrigger++
        
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
    LaunchedEffect(Unit) {
        focusRequester.requestFocus()
    }

    fun changeChannel(next: Boolean) {
        if (channelsList.isNotEmpty()) {
            val currentIndex = channelsList.indexOfFirst { it.url == currentStreamUrl }
            if (currentIndex != -1) {
                val newIndex = if (next) {
                    (currentIndex + 1) % channelsList.size
                } else {
                    if (currentIndex - 1 < 0) channelsList.size - 1 else currentIndex - 1
                }
                val ch = channelsList[newIndex]
                currentStreamUrl = ch.url
                currentChannelName = ch.name
                currentLogoUrl = ch.logo
                
                showChannelInfoBanner = true
                infoBannerHideTrigger++
            }
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
            .focusRequester(focusRequester)
            .focusable()
            .onKeyEvent { keyEvent ->
                if (keyEvent.type == androidx.compose.ui.input.key.KeyEventType.KeyDown) {
                    controlHideTrigger++ 
                    infoBannerHideTrigger++
                    
                    when (keyEvent.key) {
                        androidx.compose.ui.input.key.Key.Zero -> { if (channelNumberInput.length < 4) channelNumberInput += "0"; true }
                        androidx.compose.ui.input.key.Key.One -> { if (channelNumberInput.length < 4) channelNumberInput += "1"; true }
                        androidx.compose.ui.input.key.Key.Two -> { if (channelNumberInput.length < 4) channelNumberInput += "2"; true }
                        androidx.compose.ui.input.key.Key.Three -> { if (channelNumberInput.length < 4) channelNumberInput += "3"; true }
                        androidx.compose.ui.input.key.Key.Four -> { if (channelNumberInput.length < 4) channelNumberInput += "4"; true }
                        androidx.compose.ui.input.key.Key.Five -> { if (channelNumberInput.length < 4) channelNumberInput += "5"; true }
                        androidx.compose.ui.input.key.Key.Six -> { if (channelNumberInput.length < 4) channelNumberInput += "6"; true }
                        androidx.compose.ui.input.key.Key.Seven -> { if (channelNumberInput.length < 4) channelNumberInput += "7"; true }
                        androidx.compose.ui.input.key.Key.Eight -> { if (channelNumberInput.length < 4) channelNumberInput += "8"; true }
                        androidx.compose.ui.input.key.Key.Nine -> { if (channelNumberInput.length < 4) channelNumberInput += "9"; true }
                        androidx.compose.ui.input.key.Key.DirectionCenter,
                        androidx.compose.ui.input.key.Key.NumPadEnter,
                        androidx.compose.ui.input.key.Key.Enter -> {
                            showControls = !showControls
                            showChannelInfoBanner = false
                            true
                        }
                        androidx.compose.ui.input.key.Key.Back -> {
                            if (showControls) {
                                showControls = false
                                true
                            } else {
                                onBack()
                                true
                            }
                        }
                        KeyEvent.KEYCODE_DPAD_UP -> {
                            if (!showControls) {
                                changeChannel(next = true)
                                true
                            } else false
                        }
                        KeyEvent.KEYCODE_DPAD_DOWN -> {
                            if (!showControls) {
                                changeChannel(next = false)
                                true
                            } else false
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
                }
            },
            modifier = Modifier.fillMaxSize()
        )

        if (isBuffering && !showControls) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = BrandGold, modifier = Modifier.size(56.dp))
            }
        }

        AnimatedVisibility(
            visible = showControls,
            enter = fadeIn() + slideInHorizontally { -it },
            exit = fadeOut() + slideOutHorizontally { -it }
        ) {
            Box(modifier = Modifier.fillMaxSize()) {
                Row(modifier = Modifier.fillMaxSize()) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth(0.35f)
                            .fillMaxHeight()
                            .padding(16.dp)
                            .background(ZinaPanelBackground.copy(alpha = 0.95f), RoundedCornerShape(12.dp))
                    ) {
                        Column(modifier = Modifier.fillMaxSize()) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(8.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Icon(painter = painterResource(id = R.drawable.ic_back), contentDescription = null, tint = TextPrimary, modifier = Modifier.size(18.dp))
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text(text = "BACK", color = TextPrimary, fontFamily = PoppinsFamily, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                                }
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Icon(painter = painterResource(id = R.drawable.globe), contentDescription = null, tint = TextPrimary, modifier = Modifier.size(16.dp))
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text(text = "ALL", color = TextPrimary, fontFamily = PoppinsFamily, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                                }
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Icon(painter = painterResource(id = R.drawable.ic_live), contentDescription = null, tint = BrandGold, modifier = Modifier.size(12.dp))
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text(text = "${channelsList.size}", color = TextSecondary, fontFamily = PoppinsFamily, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                                }
                            }
                            
                            if (channelsList.isEmpty()) {
                                Box(modifier = Modifier.weight(1f), contentAlignment = Alignment.Center) {
                                    Text("No channels synced.", color = TextSecondary, fontFamily = PoppinsFamily)
                                }
                            } else {
                                LazyColumn(
                                    modifier = Modifier.fillMaxSize().padding(horizontal = 8.dp),
                                    verticalArrangement = Arrangement.spacedBy(4.dp)
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
                                                showControls = false
                                                showChannelInfoBanner = true
                                                infoBannerHideTrigger++
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }

                    Box(
                        modifier = Modifier
                            .fillMaxWidth(0.115f)
                            .fillMaxHeight()
                            .padding(vertical = 16.dp)
                            .padding(start = 8.dp)
                            .background(ZinaPanelBackground.copy(alpha = 0.95f), RoundedCornerShape(12.dp))
                    ) {
                        Column(
                            modifier = Modifier.fillMaxSize().padding(vertical = 16.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(28.dp)
                        ) {
                            Icon(painter = painterResource(id = R.drawable.ic_menu), contentDescription = null, tint = TextSecondary, modifier = Modifier.size(24.dp))
                            Spacer(modifier = Modifier.height(16.dp))
                            Icon(painter = painterResource(id = R.drawable.ic_search), contentDescription = null, tint = TextPrimary, modifier = Modifier.size(20.dp))
                            Icon(painter = painterResource(id = R.drawable.ic_favorite_filled), contentDescription = null, tint = TextPrimary, modifier = Modifier.size(20.dp))
                            Icon(painter = painterResource(id = R.drawable.ic_settings), contentDescription = null, tint = TextPrimary, modifier = Modifier.size(20.dp))
                        }
                    }
                }
            }
        }

        AnimatedVisibility(
            visible = showChannelInfoBanner && !showControls && channelNumberInput.isEmpty(),
            enter = fadeIn() + slideInVertically { it },
            exit = fadeOut() + slideOutVertically { it },
            modifier = Modifier.align(Alignment.BottomCenter)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .fillMaxHeight(0.2f)
                    .padding(64.dp)
                    .background(ZinaPanelBackground.copy(alpha = 0.9f), RoundedCornerShape(12.dp)),
                contentAlignment = Alignment.Center
            ) {
                Row(
                    modifier = Modifier.fillMaxSize().padding(horizontal = 32.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    val currentIndex = channelsList.indexOfFirst { it.url == currentStreamUrl }
                    val chNum = if (currentIndex != -1) (currentIndex + 1).toString() else "-"
                    Text(
                        text = chNum,
                        color = TextSecondary,
                        fontFamily = PoppinsFamily,
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold
                    )
                    
                    Text(
                        text = currentChannelName.uppercase(),
                        color = TextPrimary,
                        fontFamily = PoppinsFamily,
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f).padding(horizontal = 24.dp),
                        textAlign = TextAlign.Center
                    )
                    
                    Text(
                        text = "LIVE",
                        color = BrandGold,
                        fontFamily = PoppinsFamily,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }

        if (channelNumberInput.isNotEmpty() && !showControls) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color(0x88000000)),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth(0.35f)
                        .background(ZinaPanelBackground.copy(alpha = 0.95f), RoundedCornerShape(12.dp))
                        .padding(vertical = 32.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = channelNumberInput,
                        color = TextPrimary,
                        fontFamily = PoppinsFamily,
                        fontSize = 56.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 8.sp
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "PRESS OK TO CONTINUE",
                        color = TextSecondary,
                        fontFamily = PoppinsFamily,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Medium
                    )
                    Spacer(modifier = Modifier.height(32.dp))
                    LinearProgressIndicator(color = BrandGold, modifier = Modifier.fillMaxWidth(0.8f))
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
        shape = ClickableSurfaceDefaults.shape(shape = RoundedCornerShape(10.dp)),
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
                shape = RoundedCornerShape(10.dp)
            ),
            focusedBorder = Border(
                border = androidx.compose.foundation.BorderStroke(2.dp, FocusedOutlineColor),
                shape = RoundedCornerShape(10.dp)
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
                        fontFamily = PoppinsFamily,
                        fontSize = 10.sp,
                        color = BrandGold,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
            Spacer(modifier = Modifier.width(12.dp))
            Text(
                text = channel.name,
                fontFamily = PoppinsFamily,
                fontSize = 13.sp,
                fontWeight = FontWeight.Bold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}
