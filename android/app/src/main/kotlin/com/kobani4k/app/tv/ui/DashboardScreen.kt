package com.kobani4k.app.tv.ui

import android.content.Context
import android.net.Uri
import androidx.compose.animation.*
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.kobani4k.app.tv.data.PocketBaseRepository
import com.kobani4k.app.tv.data.TvChannel
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player as Media3Player
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView
import kotlinx.coroutines.delay

// Premium TV Palette
private val CanvasColor = Color(0xFF060B11)      // Deep charcoal/navy canvas
private val SurfaceColor = Color(0xFF0C131D)     // Card/Sidebar panel background
private val SurfaceElevatedColor = Color(0xFF131D2D) // Focused element container
private val BrandGold = Color(0xFFFFD700)        // Gold/Amber highlight
private val FocusedOutlineColor = Color(0xFFFFFFFF) // White focus boundary
private val TextPrimary = Color(0xFFF5F7FB)      // Bright primary text
private val TextSecondary = Color(0xFF8C9BAE)    // Muted grey secondary text

enum class TvMenu { LIVE_TV, MOVIES, SPORTS, FAVORITES, SETTINGS }

data class TvSettingsItem(
    val title: String,
    val description: String,
    val iconText: String,
    val value: String,
    val isAction: Boolean = false,
    val action: () -> Unit = {}
)

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun DashboardScreen(
    onChannelSelected: (TvChannel) -> Unit,
    onLogout: () -> Unit
) {
    val context = LocalContext.current
    val repository = remember { PocketBaseRepository() }
    
    // Playlists and settings
    var allChannels by remember { mutableStateOf<List<TvChannel>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    
    // Favorites states
    val sharedPrefs = remember(context) { context.getSharedPreferences("TvFavorites", Context.MODE_PRIVATE) }
    var favoritesSet by remember { mutableStateOf(sharedPrefs.getStringSet("urls", emptySet()) ?: emptySet()) }

    fun toggleFavorite(url: String) {
        val newSet = if (favoritesSet.contains(url)) favoritesSet - url else favoritesSet + url
        favoritesSet = newSet
        sharedPrefs.edit().putStringSet("urls", newSet).apply()
    }

    // Active Navigation items
    var selectedMenu by remember { mutableStateOf(TvMenu.LIVE_TV) }
    var activeCategory by remember { mutableStateOf("") }
    var focusedChannel by remember { mutableStateOf<TvChannel?>(null) }
    
    // Settings categories and items
    val settingsCategories = listOf("PREFERENCES", "SYSTEM DIAGNOSTICS")
    var activeSettingsCategory by remember { mutableStateOf("PREFERENCES") }
    var focusedSettingItem by remember { mutableStateOf<TvSettingsItem?>(null) }

    // Fetch channels on start
    LaunchedEffect(Unit) {
        allChannels = repository.getChannels()
        isLoading = false
    }

    // Computed categories based on selection
    val categories = remember(allChannels, selectedMenu, favoritesSet) {
        when (selectedMenu) {
            TvMenu.LIVE_TV -> {
                allChannels.filter { it.type == "live" && !it.group.contains("sport", ignoreCase = true) }
                    .map { it.group.trim().ifEmpty { "General" } }
                    .distinct()
                    .sorted()
            }
            TvMenu.MOVIES -> {
                allChannels.filter { it.type == "movie" }
                    .map { it.group.trim().ifEmpty { "General" } }
                    .distinct()
                    .sorted()
            }
            TvMenu.SPORTS -> {
                allChannels.filter { it.group.contains("sport", ignoreCase = true) || it.type == "sports" }
                    .map { it.group.trim().ifEmpty { "Sports" } }
                    .distinct()
                    .sorted()
            }
            TvMenu.FAVORITES -> {
                listOf("FAVORITE CHANNELS")
            }
            TvMenu.SETTINGS -> {
                settingsCategories
            }
        }
    }

    // Automatically select first category when navigation category list changes
    LaunchedEffect(categories) {
        activeCategory = categories.firstOrNull() ?: ""
    }

    // Computed channels list for middle pane
    val filteredChannels = remember(allChannels, selectedMenu, activeCategory, favoritesSet) {
        if (activeCategory.isEmpty()) return@remember emptyList<TvChannel>()
        when (selectedMenu) {
            TvMenu.LIVE_TV -> {
                allChannels.filter { 
                    it.type == "live" && 
                    !it.group.contains("sport", ignoreCase = true) &&
                    (it.group.trim().ifEmpty { "General" } == activeCategory)
                }
            }
            TvMenu.MOVIES -> {
                allChannels.filter { 
                    it.type == "movie" && 
                    (it.group.trim().ifEmpty { "General" } == activeCategory)
                }
            }
            TvMenu.SPORTS -> {
                allChannels.filter { 
                    (it.group.contains("sport", ignoreCase = true) || it.type == "sports") &&
                    (it.group.trim().ifEmpty { "Sports" } == activeCategory)
                }
            }
            TvMenu.FAVORITES -> {
                allChannels.filter { favoritesSet.contains(it.url) }
            }
            TvMenu.SETTINGS -> {
                emptyList()
            }
        }
    }

    // Computed settings options list for middle pane
    val settingsItems = remember(activeCategory, allChannels, onLogout) {
        when (activeCategory) {
            "PREFERENCES" -> listOf(
                TvSettingsItem("LOW LATENCY MODE", "Start streams with a tight 500ms buffer", "LATENCY", "ENABLED (Optimized)"),
                TvSettingsItem("HARDWARE ACCELERATION", "Use GPU-driven hardware codecs", "HW CODEC", "AUTO (Recommended)"),
                TvSettingsItem("ASPECT RATIO", "Default rendering mode for live streams", "ASPECT", "FIT TO SCREEN")
            )
            "SYSTEM DIAGNOSTICS" -> listOf(
                TvSettingsItem("CLOUD SERVER CONNECTION", "Firebase Realtime DB link state", "DB", "CONNECTED (Online)"),
                TvSettingsItem("CHANNELS PLAYLIST COUNT", "Total items loaded from repository", "PLAYLIST", "${allChannels.size} Channels"),
                TvSettingsItem("NATIVE SYSTEM CORE", "Jetpack Compose TV Engine target", "SYSTEM", "v1.2.0 (Kotlin)"),
                TvSettingsItem("DE-ACTIVATE DEVICE", "Clear activation code and return to activation", "OUT", "RESET DEVICE", true, onLogout)
            )
            else -> emptyList()
        }
    }

    // Clear focus states when category changes to prevent stale preview references
    LaunchedEffect(activeCategory) {
        focusedChannel = null
        focusedSettingItem = settingsItems.firstOrNull()
    }

    Row(
        modifier = Modifier
            .fillMaxSize()
            .background(CanvasColor)
    ) {
        // PANE 1: LEFT MENU (width = 200.dp)
        Column(
            modifier = Modifier
                .width(200.dp)
                .fillMaxHeight()
                .background(SurfaceColor)
                .border(width = 1.dp, color = SurfaceElevatedColor, shape = RoundedCornerShape(0.dp))
                .padding(vertical = 24.dp, horizontal = 12.dp)
        ) {
            Text(
                text = "KOBANI 4K",
                color = BrandGold,
                fontWeight = FontWeight.Black,
                fontSize = 20.sp,
                letterSpacing = 2.sp,
                modifier = Modifier.padding(bottom = 32.dp, start = 12.dp)
            )

            TvMenu.values().forEach { menu ->
                val isSelected = selectedMenu == menu
                val title = when (menu) {
                    TvMenu.LIVE_TV -> "LIVE TV"
                    TvMenu.MOVIES -> "MOVIES"
                    TvMenu.SPORTS -> "SPORTS"
                    TvMenu.FAVORITES -> "FAVORITES"
                    TvMenu.SETTINGS -> "SETTINGS"
                }
                val dotColor = when (menu) {
                    TvMenu.LIVE_TV -> Color(0xFFFF5C61)
                    TvMenu.MOVIES -> Color(0xFF69A8FF)
                    TvMenu.SPORTS -> Color(0xFF4FD39A)
                    TvMenu.FAVORITES -> BrandGold
                    TvMenu.SETTINGS -> Color(0xFFBBC6D8)
                }

                SidebarItem(
                    title = title,
                    isSelected = isSelected,
                    dotColor = dotColor,
                    onFocus = { selectedMenu = menu }
                )
                Spacer(modifier = Modifier.height(10.dp))
            }

            Spacer(modifier = Modifier.weight(1f))

            // SIGN OUT Option explicitly on left menu bottom
            SidebarItem(
                title = "SIGN OUT",
                isSelected = false,
                dotColor = Color(0xFFFF4C4C),
                onFocus = {},
                onClick = onLogout
            )
        }

        // PANE 2: DYNAMIC CATEGORIES (width = 200.dp)
        Column(
            modifier = Modifier
                .width(200.dp)
                .fillMaxHeight()
                .border(width = 1.dp, color = SurfaceElevatedColor, shape = RoundedCornerShape(0.dp))
                .padding(vertical = 24.dp, horizontal = 10.dp)
        ) {
            Text(
                text = "CATEGORIES",
                color = TextSecondary,
                fontWeight = FontWeight.Bold,
                fontSize = 11.sp,
                letterSpacing = 1.sp,
                modifier = Modifier.padding(bottom = 20.dp, start = 8.dp)
            )

            if (isLoading) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = BrandGold, modifier = Modifier.size(24.dp))
                }
            } else if (categories.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("NO ITEMS", color = TextSecondary, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                }
            } else {
                LazyColumn(
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.fillMaxSize()
                ) {
                    items(categories.size) { index ->
                        val cat = categories[index]
                        CategoryItem(
                            title = cat,
                            isSelected = activeCategory == cat,
                            onFocus = { activeCategory = cat }
                        )
                    }
                }
            }
        }

        // PANE 3: CHANNELS LIST or SETTINGS OPTIONS (width = 280.dp)
        Column(
            modifier = Modifier
                .width(280.dp)
                .fillMaxHeight()
                .border(width = 1.dp, color = SurfaceElevatedColor, shape = RoundedCornerShape(0.dp))
                .padding(vertical = 24.dp, horizontal = 12.dp)
        ) {
            val paneTitle = if (selectedMenu == TvMenu.SETTINGS) "OPTIONS" else "STREAMS"
            Text(
                text = paneTitle,
                color = TextSecondary,
                fontWeight = FontWeight.Bold,
                fontSize = 11.sp,
                letterSpacing = 1.sp,
                modifier = Modifier.padding(bottom = 20.dp, start = 8.dp)
            )

            if (selectedMenu == TvMenu.SETTINGS) {
                LazyColumn(
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.fillMaxSize()
                ) {
                    items(settingsItems.size) { index ->
                        val item = settingsItems[index]
                        SettingsRowItem(
                            item = item,
                            onFocus = { focusedSettingItem = item },
                            onClick = {
                                if (item.isAction) {
                                    item.action()
                                }
                            }
                        )
                    }
                }
            } else {
                if (filteredChannels.isEmpty()) {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Text(
                            text = if (selectedMenu == TvMenu.FAVORITES) "FAVORITES EMPTY" else "NO CHANNELS FOUND",
                            color = TextSecondary,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold,
                            textAlign = TextAlign.Center
                        )
                    }
                } else {
                    LazyColumn(
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.fillMaxSize()
                    ) {
                        items(filteredChannels.size) { index ->
                            val ch = filteredChannels[index]
                            ChannelRowItem(
                                channel = ch,
                                isFavorite = favoritesSet.contains(ch.url),
                                onFocus = { focusedChannel = ch },
                                onClick = { onChannelSelected(ch) }
                            )
                        }
                    }
                }
            }
        }

        // PANE 4: PREVIEW & METADATA PANE (weight = 1f)
        Box(
            modifier = Modifier
                .weight(1f)
                .fillMaxHeight()
                .padding(24.dp)
        ) {
            if (selectedMenu == TvMenu.SETTINGS) {
                // Settings details rendering
                val item = focusedSettingItem
                if (item != null) {
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(SurfaceColor, RoundedCornerShape(16.dp))
                            .border(width = 1.dp, color = SurfaceElevatedColor, shape = RoundedCornerShape(16.dp))
                            .padding(32.dp),
                        verticalArrangement = Arrangement.Center,
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Box(
                            modifier = Modifier
                                .size(64.dp)
                                .background(SurfaceElevatedColor, RoundedCornerShape(16.dp)),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = item.iconText,
                                color = BrandGold,
                                fontWeight = FontWeight.Bold,
                                fontSize = 16.sp
                            )
                        }
                        Spacer(modifier = Modifier.height(24.dp))
                        Text(
                            text = item.title,
                            color = BrandGold,
                            fontWeight = FontWeight.Black,
                            fontSize = 20.sp,
                            letterSpacing = 1.sp,
                            textAlign = TextAlign.Center
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = item.value,
                            color = TextPrimary,
                            fontWeight = FontWeight.Bold,
                            fontSize = 14.sp
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = item.description,
                            color = TextSecondary,
                            fontSize = 13.sp,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.fillMaxWidth(0.85f)
                        )
                        
                        if (item.isAction) {
                            Spacer(modifier = Modifier.height(28.dp))
                            ActionButton(label = "EXECUTE ACTION", iconText = "▶") {
                                item.action()
                            }
                        }
                    }
                }
            } else {
                // Live Stream video preview rendering
                Column(modifier = Modifier.fillMaxSize()) {
                    // 16:9 Live TV Player Card
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .aspectRatio(16f / 9f)
                            .clip(RoundedCornerShape(16.dp))
                            .background(SurfaceColor)
                            .border(width = 1.dp, color = SurfaceElevatedColor, shape = RoundedCornerShape(16.dp))
                    ) {
                        val activeChannel = focusedChannel
                        if (activeChannel != null) {
                            var activePreviewUrl by remember { mutableStateOf<String?>(null) }
                            var isPreviewBuffering by remember { mutableStateOf(false) }

                            LaunchedEffect(activeChannel) {
                                activePreviewUrl = null
                                delay(600) // 600ms Debounce to prevent stream switching spam
                                activePreviewUrl = activeChannel.url
                            }

                            val currentUrl = activePreviewUrl
                            if (currentUrl != null) {
                                PreviewPlayer(
                                    url = currentUrl,
                                    onBufferingChanged = { isPreviewBuffering = it }
                                )
                            }

                            // Buffering overlay inside preview window
                            if (isPreviewBuffering || activePreviewUrl == null) {
                                Box(
                                    modifier = Modifier
                                        .fillMaxSize()
                                        .background(Color.Black.copy(alpha = 0.5f)),
                                    contentAlignment = Alignment.Center
                                ) {
                                    CircularProgressIndicator(
                                        color = BrandGold,
                                        modifier = Modifier.size(36.dp)
                                    )
                                }
                            }
                        } else {
                            // Default Fallback
                            Box(
                                modifier = Modifier
                                    .fillMaxSize()
                                    .background(
                                        Brush.verticalGradient(
                                            colors = listOf(SurfaceElevatedColor, CanvasColor)
                                        )
                                    ),
                                contentAlignment = Alignment.Center
                            ) {
                                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                    Text(
                                        text = "★ KOBANI 4K ★",
                                        color = BrandGold,
                                        fontWeight = FontWeight.Black,
                                        fontSize = 24.sp,
                                        letterSpacing = 2.sp
                                    )
                                    Spacer(modifier = Modifier.height(8.dp))
                                    Text(
                                        text = "SCROLL LIST TO PREVIEW STREAMS",
                                        color = TextSecondary,
                                        fontSize = 11.sp,
                                        fontWeight = FontWeight.Bold,
                                        letterSpacing = 1.sp
                                    )
                                }
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(20.dp))

                    // Channel Metadata & Playback Action Buttons
                    val channel = focusedChannel
                    if (channel != null) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            if (!channel.logo.isNullOrEmpty()) {
                                AsyncImage(
                                    model = channel.logo,
                                    contentDescription = null,
                                    modifier = Modifier
                                        .size(60.dp)
                                        .background(Color.White.copy(alpha = 0.08f), RoundedCornerShape(12.dp))
                                        .padding(6.dp)
                                )
                                Spacer(modifier = Modifier.width(16.dp))
                            }
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = channel.name.uppercase(),
                                    color = BrandGold,
                                    fontSize = 18.sp,
                                    fontWeight = FontWeight.Black,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                                Text(
                                    text = "CATEGORY: ${channel.group.uppercase()}",
                                    color = TextSecondary,
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold
                                )
                                Text(
                                    text = channel.url,
                                    color = TextSecondary.copy(alpha = 0.6f),
                                    fontSize = 10.sp,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(20.dp))

                        // Focusable Player Action Row
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            ActionButton(
                                label = "WATCH FULL SCREEN",
                                iconText = "▶"
                            ) {
                                onChannelSelected(channel)
                            }

                            val isFav = favoritesSet.contains(channel.url)
                            ActionButton(
                                label = if (isFav) "REMOVE FAVORITE" else "ADD FAVORITE",
                                iconText = if (isFav) "★" else "☆"
                            ) {
                                toggleFavorite(channel.url)
                            }
                        }

                        Spacer(modifier = Modifier.height(12.dp))
                        Text(
                            text = "HINT: PRESS [DPAD-CENTER/OK] IN STREAMS LIST FOR DIRECT FULLSCREEN",
                            color = TextSecondary.copy(alpha = 0.7f),
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun PreviewPlayer(
    url: String,
    onBufferingChanged: (Boolean) -> Unit
) {
    val context = LocalContext.current
    
    val exoPlayer = remember {
        val loadControl = DefaultLoadControl.Builder()
            .setBufferDurationsMs(3000, 8000, 500, 1000)
            .build()
        ExoPlayer.Builder(context)
            .setLoadControl(loadControl)
            .build()
    }

    LaunchedEffect(url) {
        onBufferingChanged(true)
        exoPlayer.stop()
        val mediaItem = MediaItem.fromUri(Uri.parse(url))
        exoPlayer.setMediaItem(mediaItem)
        exoPlayer.prepare()
        exoPlayer.playWhenReady = true
    }

    DisposableEffect(exoPlayer) {
        val listener = object : Media3Player.Listener {
            override fun onPlaybackStateChanged(state: Int) {
                onBufferingChanged(state == Media3Player.STATE_BUFFERING)
            }
            override fun onPlayerError(error: PlaybackException) {
                onBufferingChanged(false)
            }
        }
        exoPlayer.addListener(listener)
        onDispose {
            exoPlayer.removeListener(listener)
            exoPlayer.release()
        }
    }

    AndroidView(
        factory = { ctx ->
            PlayerView(ctx).apply {
                player = exoPlayer
                useController = false
                resizeMode = androidx.media3.ui.AspectRatioFrameLayout.RESIZE_MODE_ZOOM
            }
        },
        modifier = Modifier.fillMaxSize()
    )
}

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun SidebarItem(
    title: String,
    isSelected: Boolean,
    dotColor: Color,
    onFocus: () -> Unit,
    onClick: () -> Unit = {}
) {
    var isFocused by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(targetValue = if (isFocused) 1.05f else 1.0f)

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
            .height(46.dp)
            .scale(scale)
            .onFocusChanged { 
                isFocused = it.isFocused 
                if (it.isFocused) {
                    onFocus()
                }
            }
    ) {
        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .background(dotColor, RoundedCornerShape(999.dp))
            )
            Spacer(modifier = Modifier.width(12.dp))
            Text(
                text = title,
                fontSize = 13.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 1.sp
            )
        }
    }
}

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun CategoryItem(
    title: String,
    isSelected: Boolean,
    onFocus: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(targetValue = if (isFocused) 1.05f else 1.0f)

    Surface(
        onClick = {},
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
            .height(46.dp)
            .scale(scale)
            .onFocusChanged { 
                isFocused = it.isFocused 
                if (it.isFocused) {
                    onFocus()
                }
            }
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 12.dp),
            contentAlignment = Alignment.CenterStart
        ) {
            Text(
                text = title.uppercase(),
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun ChannelRowItem(
    channel: TvChannel,
    isFavorite: Boolean,
    onFocus: () -> Unit,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(targetValue = if (isFocused) 1.04f else 1.0f)

    Surface(
        onClick = onClick,
        shape = ClickableSurfaceDefaults.shape(shape = RoundedCornerShape(10.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = SurfaceColor,
            focusedContainerColor = SurfaceElevatedColor,
            contentColor = TextPrimary,
            focusedContentColor = TextPrimary
        ),
        border = ClickableSurfaceDefaults.border(
            border = Border(
                border = androidx.compose.foundation.BorderStroke(1.dp, SurfaceElevatedColor),
                shape = RoundedCornerShape(10.dp)
            ),
            focusedBorder = Border(
                border = androidx.compose.foundation.BorderStroke(2.dp, BrandGold),
                shape = RoundedCornerShape(10.dp)
            )
        ),
        modifier = Modifier
            .fillMaxWidth()
            .height(54.dp)
            .scale(scale)
            .onFocusChanged { 
                isFocused = it.isFocused 
                if (it.isFocused) {
                    onFocus()
                }
            }
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
                        .size(36.dp)
                        .background(Color.White.copy(alpha = 0.08f), RoundedCornerShape(6.dp))
                        .padding(4.dp)
                )
            } else {
                Box(
                    modifier = Modifier
                        .size(36.dp)
                        .background(SurfaceElevatedColor, RoundedCornerShape(6.dp)),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "TV",
                        color = BrandGold,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
            
            Spacer(modifier = Modifier.width(12.dp))
            
            Text(
                text = channel.name,
                fontSize = 13.sp,
                fontWeight = FontWeight.Bold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.weight(1f)
            )
            
            if (isFavorite) {
                Spacer(modifier = Modifier.width(6.dp))
                Text(
                    text = "★",
                    color = BrandGold,
                    fontSize = 16.sp
                )
            }
        }
    }
}

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun SettingsRowItem(
    item: TvSettingsItem,
    onFocus: () -> Unit,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(targetValue = if (isFocused) 1.04f else 1.0f)

    Surface(
        onClick = onClick,
        shape = ClickableSurfaceDefaults.shape(shape = RoundedCornerShape(10.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = SurfaceColor,
            focusedContainerColor = SurfaceElevatedColor,
            contentColor = TextPrimary,
            focusedContentColor = TextPrimary
        ),
        border = ClickableSurfaceDefaults.border(
            border = Border(
                border = androidx.compose.foundation.BorderStroke(1.dp, SurfaceElevatedColor),
                shape = RoundedCornerShape(10.dp)
            ),
            focusedBorder = Border(
                border = androidx.compose.foundation.BorderStroke(2.dp, BrandGold),
                shape = RoundedCornerShape(10.dp)
            )
        ),
        modifier = Modifier
            .fillMaxWidth()
            .height(54.dp)
            .scale(scale)
            .onFocusChanged { 
                isFocused = it.isFocused 
                if (it.isFocused) {
                    onFocus()
                }
            }
    ) {
        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .background(SurfaceElevatedColor, RoundedCornerShape(6.dp)),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = item.iconText,
                    color = BrandGold,
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Bold
                )
            }
            
            Spacer(modifier = Modifier.width(12.dp))
            
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = item.title,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = item.value,
                    fontSize = 11.sp,
                    color = TextSecondary,
                    maxLines = 1
                )
            }
        }
    }
}

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun ActionButton(
    label: String,
    iconText: String,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(targetValue = if (isFocused) 1.04f else 1.0f)

    Button(
        onClick = onClick,
        shape = ButtonDefaults.shape(shape = RoundedCornerShape(10.dp)),
        colors = ButtonDefaults.colors(
            containerColor = SurfaceElevatedColor,
            focusedContainerColor = TextPrimary,
            contentColor = TextPrimary,
            focusedContentColor = CanvasColor
        ),
        border = ButtonDefaults.border(
            border = Border(
                border = androidx.compose.foundation.BorderStroke(1.dp, SurfaceElevatedColor),
                shape = RoundedCornerShape(10.dp)
            ),
            focusedBorder = Border(
                border = androidx.compose.foundation.BorderStroke(2.dp, BrandGold),
                shape = RoundedCornerShape(10.dp)
            )
        ),
        modifier = Modifier
            .height(40.dp)
            .scale(scale)
            .onFocusChanged { isFocused = it.isFocused }
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = iconText,
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                color = if (isFocused) CanvasColor else BrandGold
            )
            Text(
                text = label,
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold
            )
        }
    }
}
