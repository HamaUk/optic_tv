package com.kobani4k.app.tv.ui

import android.graphics.BlurMaskFilter
import android.os.Build
import android.content.Context
import android.view.KeyEvent
import android.widget.TextClock
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.focusGroup
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.itemsIndexed
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.rounded.*
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.scale
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.focusRestorer
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Paint
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.activity.compose.BackHandler
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.kobani4k.app.tv.data.AppPreferences
import com.kobani4k.app.tv.data.PocketBaseRepository
import com.kobani4k.app.tv.data.TvChannel
import com.kobani4k.app.tv.data.TvChannelGroup
import com.kobani4k.app.tv.ui.components.SettingsOverlay
import com.kobani4k.app.tv.ui.Locales
import com.kobani4k.app.tv.ui.theme.GlassPanel
import com.kobani4k.app.tv.ui.theme.UltraTokens
import com.kobani4k.app.tv.ui.theme.scaleOnFocus
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

// ═══════════════════════════════════════════════════════════════════════════
//  DASHBOARD SCREEN — Glassmorphic Gradient-Mesh TV Layout
// ═══════════════════════════════════════════════════════════════════════════

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun DashboardScreen(
    onChannelSelected: (TvChannel) -> Unit,
    onLogout: () -> Unit
) {
    val repository = remember { PocketBaseRepository() }
    val context = LocalContext.current
    val prefs = remember { AppPreferences(context) }
    var favoriteChannels by remember { mutableStateOf(prefs.favoriteChannels) }
    var appLanguage by remember { mutableStateOf(prefs.appLanguage) }
    
    var allChannels by remember { mutableStateOf<List<TvChannel>>(emptyList()) }
    var allGroups by remember { mutableStateOf<List<TvChannelGroup>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    var loadError by remember { mutableStateOf(false) }

    var refreshTick by remember { mutableStateOf(0) }
    var showSettings by remember { mutableStateOf(false) }

    val lifecycleOwner = LocalLifecycleOwner.current
    var hasInitialized by remember { mutableStateOf(false) }
    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME) {
                if (hasInitialized) {
                    refreshTick++
                } else {
                    hasInitialized = true
                }
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
        }
    }

    LaunchedEffect(refreshTick) {
        isLoading = true
        loadError = false
        coroutineScope {
            val groupsDeferred = async { repository.getGroups() }
            val channelsDeferred = async { repository.getChannels() }
            allGroups = groupsDeferred.await()
            val result = channelsDeferred.await()
            if (result == null) {
                loadError = true
            } else {
                allChannels = result
                loadError = false
            }
        }
        isLoading = false
    }

    var selectedCategory by rememberSaveable { mutableStateOf<String?>(null) }
    var focusedChannel by remember { mutableStateOf<TvChannel?>(null) }
    var activeNav by rememberSaveable { mutableStateOf("nav_live_tv") }
    var showSearch by remember { mutableStateOf(false) }
    var railExpanded by remember { mutableStateOf(false) }

    val activeChannels = remember(allChannels, activeNav) {
        when (activeNav) {
            "nav_live_tv" -> allChannels.filter { !it.isMovie() && !it.isSport() }
            "nav_movies" -> allChannels.filter { it.isMovie() }
            "nav_sports" -> allChannels.filter { it.isSport() }
            else -> allChannels
        }
    }

    val categories = remember(activeChannels, allGroups, appLanguage) {
        val catGeneral = Locales.getString("cat_general", appLanguage)
        val activeGroups = activeChannels.map { it.group.ifEmpty { catGeneral } }.distinct()
        val sortedGroups = if (allGroups.isNotEmpty()) {
            activeGroups.sortedBy { groupName ->
                allGroups.indexOfFirst { it.name == groupName }.takeIf { it >= 0 } ?: Int.MAX_VALUE
            }
        } else {
            activeGroups.sorted()
        }
        listOf(Locales.getString("cat_favorites", appLanguage)) + sortedGroups
    }

    val filteredChannels = remember(activeChannels, selectedCategory, favoriteChannels, appLanguage) {
        if (selectedCategory == Locales.getString("cat_favorites", appLanguage)) {
            activeChannels.filter { favoriteChannels.contains(it.url) }
        } else {
            activeChannels.filter { it.group.ifEmpty { Locales.getString("cat_general", appLanguage) } == selectedCategory }
        }
    }

    val channelCounts = remember(activeChannels, favoriteChannels, appLanguage) {
        activeChannels.groupingBy { it.group.ifEmpty { Locales.getString("cat_general", appLanguage) } }
            .eachCount()
            .toMutableMap()
            .apply {
                put(Locales.getString("cat_favorites", appLanguage), activeChannels.count { favoriteChannels.contains(it.url) })
            }
    }

    LaunchedEffect(activeNav) {
        selectedCategory = null
    }

    LaunchedEffect(categories, activeNav) {
        if (categories.isNotEmpty() && (selectedCategory == null || !categories.contains(selectedCategory))) {
            selectedCategory = categories.getOrNull(1) ?: categories.first()
        }
    }
    val categoryFocusRequester = remember { FocusRequester() }
    val navRailFocusRequester = remember { FocusRequester() }

    LaunchedEffect(isLoading, categories, activeNav) {
        if (!isLoading && categories.isNotEmpty()) {
            delay(150)
            runCatching { categoryFocusRequester.requestFocus() }
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        // ═══ ANIMATED GRADIENT MESH BACKGROUND ═══
        GradientMeshBackground()

        Row(
            modifier = Modifier.fillMaxSize()
        ) {
            // ═══ NAV RAIL ═══
            DashboardNavRail(
                activeNav = activeNav,
                appLanguage = appLanguage,
                expanded = railExpanded,
                onExpandChange = { railExpanded = it },
                onNavSelected = { nav ->
                    when (nav) {
                        "nav_settings" -> showSettings = true
                        "nav_search"   -> showSearch = true
                        else -> activeNav = nav
                    }
                },
                focusRequester = navRailFocusRequester
            )

            Column(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight()
            ) {
                // ═══ TOP HEADER BAR ═══
                DashboardHeader(appLanguage = appLanguage, activeNav = activeNav)

                if (isLoading) {
                    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            CircularProgressIndicator(
                                color = UltraTokens.Accent,
                                modifier = Modifier.size(48.dp),
                                strokeWidth = 3.dp
                            )
                            Spacer(Modifier.height(16.dp))
                            Text(
                                Locales.getString("msg_loading", appLanguage),
                                color = UltraTokens.TextSecondary,
                                fontSize = 14.sp
                            )
                        }
                    }
                } else if (loadError) {
                    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Icon(
                                imageVector = Icons.Rounded.Warning,
                                contentDescription = "Error",
                                tint = UltraTokens.Live,
                                modifier = Modifier.size(64.dp)
                            )
                            Spacer(Modifier.height(16.dp))
                            Text(
                                Locales.getString("msg_network_error", appLanguage),
                                color = Color.White,
                                fontSize = 24.sp,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(Modifier.height(8.dp))
                            Text(
                                Locales.getString("msg_unable_to_load", appLanguage),
                                color = UltraTokens.TextSecondary,
                                fontSize = 14.sp
                            )
                            Spacer(Modifier.height(24.dp))
                            Button(
                                onClick = { refreshTick++ },
                                modifier = Modifier.scaleOnFocus(),
                                colors = ButtonDefaults.colors(
                                    containerColor = UltraTokens.Accent,
                                    focusedContainerColor = Color.White,
                                    focusedContentColor = Color.Black
                                )
                            ) {
                                Text(Locales.getString("btn_try_again", appLanguage))
                            }
                        }
                    }
                } else if (activeNav == "nav_movies") {
                    // ═══ MOVIES GRID LAYOUT ═══
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(start = 24.dp)
                    ) {
                        MoviesGridScreen(
                            channels = activeChannels,
                            onMovieClick = onChannelSelected
                        )
                    }
                } else {
                    // ═══ MAIN 2-PANE LAYOUT (Categories + Channels) ═══
                    Row(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(start = 28.dp, end = 28.dp, top = 6.dp, bottom = 22.dp),
                        horizontalArrangement = Arrangement.spacedBy(0.dp)
                    ) {
                        // PANE 1: CATEGORIES (Glass)
                        CategoryPane(
                            categories = categories,
                            selectedCategory = selectedCategory,
                            onCategorySelected = { selectedCategory = it },
                            channelCounts = channelCounts,
                            appLanguage = appLanguage,
                            focusRequester = categoryFocusRequester,
                            onAnyFocus = { railExpanded = false },
                            modifier = Modifier
                                .width(190.dp)
                                .fillMaxHeight()
                        )

                        // PANE 2: CHANNELS (Glass)
                        ChannelPane(
                            channels = filteredChannels,
                            appLanguage = appLanguage,
                            favoriteChannels = favoriteChannels,
                            onToggleFavorite = { channel ->
                                val currentFavorites = favoriteChannels.toMutableSet()
                                if (currentFavorites.contains(channel.url)) {
                                    currentFavorites.remove(channel.url)
                                } else {
                                    currentFavorites.add(channel.url)
                                }
                                favoriteChannels = currentFavorites
                                prefs.favoriteChannels = currentFavorites
                            },
                            onChannelFocused = { focusedChannel = it },
                            onChannelSelected = onChannelSelected,
                            onAnyFocus = { railExpanded = false },
                            modifier = Modifier
                                .weight(1f)
                                .fillMaxHeight()
                        )
                    }
                }
            }
        }

        // ═══ SETTINGS OVERLAY ═══
        AnimatedVisibility(
            visible = showSettings,
            enter = fadeIn(tween(300)) + slideInHorizontally { it / 3 },
            exit = fadeOut(tween(200)) + slideOutHorizontally { it / 3 }
        ) {
            SettingsOverlay(
                appLanguage = appLanguage,
                channelCount = allChannels.size,
                categoryCount = categories.size,
                onLogout = onLogout,
                onDismiss = { showSettings = false },
                onLanguageChange = { newLang ->
                    appLanguage = newLang
                    prefs.appLanguage = newLang
                }
            )
        }

        // ═══ SEARCH OVERLAY ═══
        AnimatedVisibility(
            visible = showSearch,
            enter = fadeIn(tween(300)) + slideInHorizontally { -it / 3 },
            exit = fadeOut(tween(200)) + slideOutHorizontally { -it / 3 }
        ) {
            BackHandler { showSearch = false }
            SearchScreen(
                allChannels = allChannels,
                onChannelSelected = {
                    showSearch = false
                    onChannelSelected(it)
                },
                onBack = { showSearch = false }
            )
        }
    }
}


// ═══════════════════════════════════════════════════════════════════════════
//  GRADIENT MESH BACKGROUND — Animated drifting color blobs
// ═══════════════════════════════════════════════════════════════════════════

@Composable
private fun GradientMeshBackground() {
    val infiniteTransition = rememberInfiniteTransition(label = "meshBg")
    val phase by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = (2 * PI).toFloat(),
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 30_000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "meshPhase"
    )

    Canvas(
        modifier = Modifier
            .fillMaxSize()
            .background(UltraTokens.Background)
    ) {
        val w = size.width
        val h = size.height

        // Each blob: (color, radius fraction, center-x fraction, center-y fraction, drift-x, drift-y)
        data class Blob(
            val color: Color, val radius: Float,
            val cx: Float, val cy: Float,
            val driftX: Float, val driftY: Float,
            val phaseMultiplier: Float, val alpha: Float
        )

        val blobs = listOf(
            Blob(UltraTokens.Blue, w * 0.30f, -0.12f, -0.16f, 0.06f, 0.05f, 1f, 0.45f),
            Blob(UltraTokens.Violet, w * 0.26f, 0.62f, -0.10f, -0.05f, 0.06f, 0.9f, 0.45f),
            Blob(UltraTokens.Pink, w * 0.22f, 0.30f, 0.62f, 0.04f, -0.05f, 1.1f, 0.40f),
            Blob(UltraTokens.Teal, w * 0.19f, 0.70f, 0.66f, -0.04f, 0.03f, 1.2f, 0.30f),
        )

        drawIntoCanvas { canvas ->
            for (blob in blobs) {
                val t = phase * blob.phaseMultiplier
                val cx = w * (blob.cx + blob.driftX * sin(t))
                val cy = h * (blob.cy + blob.driftY * cos(t))

                val paint = Paint().asFrameworkPaint().apply {
                    isAntiAlias = true
                    color = blob.color.copy(alpha = blob.alpha).toArgb()
                    maskFilter = BlurMaskFilter(blob.radius * 0.7f, BlurMaskFilter.Blur.NORMAL)
                }
                canvas.nativeCanvas.drawCircle(cx, cy, blob.radius, paint)
            }
        }

        // Soft radial vignette
        drawRect(
            brush = Brush.radialGradient(
                colors = listOf(
                    Color.Transparent,
                    UltraTokens.Background.copy(alpha = 0.55f),
                ),
                center = Offset(w / 2, h / 2),
                radius = w * 0.85f
            )
        )
    }
}


// ═══════════════════════════════════════════════════════════════════════════
//  HEADER BAR
// ═══════════════════════════════════════════════════════════════════════════

@Composable
private fun DashboardHeader(appLanguage: String, activeNav: String) {
    val showLive = activeNav != "nav_movies"

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 32.dp, vertical = 18.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Left: Logo + LIVE badge
        Row(verticalAlignment = Alignment.CenterVertically) {
            // Gradient logo badge
            Box(
                modifier = Modifier
                    .size(34.dp)
                    .clip(RoundedCornerShape(10.dp))
                    .background(
                        Brush.linearGradient(
                            colors = listOf(UltraTokens.Blue, UltraTokens.Violet)
                        )
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    Icons.Rounded.LiveTv,
                    contentDescription = "Logo",
                    tint = Color.White,
                    modifier = Modifier.size(18.dp)
                )
            }

            Spacer(Modifier.width(14.dp))

            Text(
                "KOBANI",
                color = UltraTokens.Text,
                fontSize = 19.sp,
                fontWeight = FontWeight.ExtraBold,
                letterSpacing = 1.5.sp
            )
            Text(
                " 4K",
                color = UltraTokens.Blue,
                fontSize = 19.sp,
                fontWeight = FontWeight.ExtraBold,
                letterSpacing = 1.5.sp
            )

            Spacer(Modifier.width(18.dp))

            Box(
                Modifier
                    .width(1.dp)
                    .height(22.dp)
                    .background(UltraTokens.Hairline)
            )

            Spacer(Modifier.width(18.dp))

            // LIVE badge — conditional
            if (showLive) {
                val infiniteTransition = rememberInfiniteTransition(label = "headerPulse")
                val dotAlpha by infiniteTransition.animateFloat(
                    initialValue = 0.5f,
                    targetValue = 1f,
                    animationSpec = infiniteRepeatable(
                        animation = tween(1600),
                        repeatMode = RepeatMode.Reverse
                    ),
                    label = "dotAlpha"
                )

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier
                        .clip(RoundedCornerShape(20.dp))
                        .background(UltraTokens.Live.copy(alpha = 0.12f))
                        .border(1.dp, UltraTokens.Live.copy(alpha = 0.25f), RoundedCornerShape(20.dp))
                        .padding(horizontal = 10.dp, vertical = 4.dp)
                ) {
                    Box(
                        Modifier
                            .size(6.dp)
                            .clip(CircleShape)
                            .background(UltraTokens.Live.copy(alpha = dotAlpha))
                    )
                    Spacer(Modifier.width(6.dp))
                    Text(
                        Locales.getString("lbl_live", appLanguage),
                        color = UltraTokens.Live,
                        fontSize = 10.5.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 1.2.sp
                    )
                }
            }
        }

        // Right: Clock only
        Row(verticalAlignment = Alignment.CenterVertically) {
            AndroidView(
                factory = { ctx ->
                    TextClock(ctx).apply {
                        format12Hour = "hh:mm a  ·  MMM dd"
                        format24Hour = "HH:mm  ·  MMM dd"
                        textSize = 13f
                        setTextColor(android.graphics.Color.parseColor("#9298AD"))
                        typeface = android.graphics.Typeface.create("sans-serif-medium", android.graphics.Typeface.NORMAL)
                        letterSpacing = 0.03f
                    }
                }
            )
        }
    }
}


// ═══════════════════════════════════════════════════════════════════════════
//  NAV RAIL — Collapsible, glassmorphic
// ═══════════════════════════════════════════════════════════════════════════

@Composable
private fun DashboardNavRail(
    activeNav: String,
    appLanguage: String,
    expanded: Boolean,
    onExpandChange: (Boolean) -> Unit,
    onNavSelected: (String) -> Unit,
    focusRequester: FocusRequester
) {
    val items = listOf(
        Triple("nav_live_tv", Icons.Rounded.Tv, Locales.getString("nav_live_tv", appLanguage)),
        Triple("nav_movies", Icons.Rounded.Movie, Locales.getString("nav_movies", appLanguage)),
        Triple("nav_sports", Icons.Rounded.SportsBaseball, Locales.getString("nav_sports", appLanguage)),
    )

    val utilityItems = listOf(
        Triple("nav_search", Icons.Rounded.Search, Locales.getString("nav_search", appLanguage)),
        Triple("nav_settings", Icons.Rounded.Settings, Locales.getString("nav_settings", appLanguage)),
    )

    val animatedWidth by animateDpAsState(
        targetValue = if (expanded) 224.dp else 104.dp,
        animationSpec = tween(380, easing = FastOutSlowInEasing),
        label = "railWidth"
    )

    Box(
        modifier = Modifier
            .width(animatedWidth)
            .fillMaxHeight()
            .background(Color(0x59151520)) // ~35% translucent
            .border(
                width = 0.dp,
                color = Color.Transparent,
                shape = RoundedCornerShape(0.dp)
            )
    ) {
        // Right edge hairline
        Box(
            Modifier
                .width(1.dp)
                .fillMaxHeight()
                .align(Alignment.CenterEnd)
                .background(UltraTokens.Hairline)
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(vertical = 28.dp, horizontal = 14.dp),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            // Main nav items
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                items.forEachIndexed { index, (key, icon, label) ->
                    NavRailItem(
                        label = label,
                        icon = icon,
                        expanded = expanded,
                        isActive = activeNav == key,
                        modifier = if (index == 0) Modifier.focusRequester(focusRequester) else Modifier,
                        onFocusGained = { onExpandChange(true) },
                        onClick = { onNavSelected(key) },
                        onDpadRight = { onExpandChange(false) }
                    )
                }
            }

            // Utility items (search, settings)
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                utilityItems.forEach { (key, icon, label) ->
                    NavRailItem(
                        label = label,
                        icon = icon,
                        expanded = expanded,
                        isActive = false,
                        modifier = Modifier,
                        onFocusGained = { onExpandChange(true) },
                        onClick = { onNavSelected(key) },
                        onDpadRight = { onExpandChange(false) }
                    )
                }
            }
        }
    }
}

@Composable
private fun NavRailItem(
    label: String,
    icon: ImageVector,
    expanded: Boolean,
    isActive: Boolean,
    modifier: Modifier = Modifier,
    onFocusGained: () -> Unit,
    onClick: () -> Unit,
    onDpadRight: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    val highlighted = isActive || isFocused

    val bgColor by animateColorAsState(
        targetValue = when {
            isActive -> UltraTokens.Blue.copy(alpha = 0.22f)
            isFocused -> UltraTokens.GlassStrong
            else -> Color.Transparent
        },
        animationSpec = tween(250),
        label = "navBg"
    )

    val borderColor by animateColorAsState(
        targetValue = if (highlighted) Color.White.copy(alpha = 0.18f) else Color.Transparent,
        animationSpec = tween(200),
        label = "navBorder"
    )

    val iconAlpha = if (highlighted) 1f else 0.72f

    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(56.dp)
            .clip(RoundedCornerShape(16.dp))
            .background(bgColor)
            .border(1.dp, borderColor, RoundedCornerShape(16.dp))
            .onFocusChanged {
                isFocused = it.isFocused
                if (it.isFocused) onFocusGained()
            }
            .focusable()
            .onKeyEvent { ev ->
                if (ev.nativeKeyEvent.action == KeyEvent.ACTION_DOWN) {
                    when (ev.nativeKeyEvent.keyCode) {
                        KeyEvent.KEYCODE_DPAD_CENTER, KeyEvent.KEYCODE_ENTER,
                        KeyEvent.KEYCODE_NUMPAD_ENTER -> {
                            onClick()
                            true
                        }
                        KeyEvent.KEYCODE_DPAD_RIGHT -> {
                            onDpadRight()
                            false // let focus system handle the move
                        }
                        else -> false
                    }
                } else false
            }
            .clickable(onClick = onClick)
            .padding(horizontal = 15.dp),
        contentAlignment = Alignment.CenterStart
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(
                icon,
                contentDescription = label,
                tint = Color.White.copy(alpha = iconAlpha),
                modifier = Modifier.size(22.dp)
            )

            Spacer(Modifier.width(14.dp))

            // Label — clipped fade in/out
            AnimatedVisibility(
                visible = expanded,
                enter = fadeIn(tween(220)) + expandHorizontally(tween(380)),
                exit = fadeOut(tween(150)) + shrinkHorizontally(tween(280))
            ) {
                Text(
                    label.uppercase(),
                    color = UltraTokens.Text,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.SemiBold,
                    letterSpacing = 0.3.sp,
                    maxLines = 1,
                    overflow = TextOverflow.Clip
                )
            }
        }
    }
}


// ═══════════════════════════════════════════════════════════════════════════
//  CATEGORY PANE — Glassmorphic with count badges
// ═══════════════════════════════════════════════════════════════════════════

@Composable
private fun CategoryPane(
    categories: List<String>,
    selectedCategory: String?,
    onCategorySelected: (String) -> Unit,
    channelCounts: Map<String, Int>,
    appLanguage: String,
    focusRequester: FocusRequester,
    onAnyFocus: () -> Unit,
    modifier: Modifier = Modifier
) {
    GlassPanel(
        modifier = modifier,
        borderRadius = RoundedCornerShape(
            topStart = UltraTokens.RadiusLg,
            bottomStart = UltraTokens.RadiusLg,
            topEnd = 0.dp,
            bottomEnd = 0.dp
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(vertical = 20.dp, horizontal = 10.dp)
        ) {
            Text(
                text = Locales.getString("lbl_categories", appLanguage).uppercase(),
                color = UltraTokens.TextFaint,
                fontSize = 10.5.sp,
                letterSpacing = 2.sp,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.padding(start = 12.dp, bottom = 12.dp)
            )

            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(2.dp),
                modifier = Modifier
                    .fillMaxSize()
                    .focusRestorer()
            ) {
                items(categories) { category ->
                    val isSelected = selectedCategory == category
                    val initialFocusCategory = categories.getOrNull(1) ?: categories.firstOrNull()
                    CategoryItem(
                        title = category,
                        count = channelCounts[category] ?: 0,
                        isSelected = isSelected,
                        onFocus = {
                            onAnyFocus()
                            onCategorySelected(category)
                        },
                        modifier = if (category == initialFocusCategory) {
                            Modifier.focusRequester(focusRequester)
                        } else Modifier
                    )
                }
            }
        }
    }
}

@Composable
private fun CategoryItem(
    title: String,
    count: Int,
    isSelected: Boolean,
    onFocus: () -> Unit,
    modifier: Modifier = Modifier
) {
    var isFocused by remember { mutableStateOf(false) }
    val highlighted = isFocused || isSelected

    val bgColor by animateColorAsState(
        targetValue = when {
            isSelected -> UltraTokens.Violet.copy(alpha = 0.16f)
            isFocused -> UltraTokens.GlassStrong
            else -> Color.Transparent
        },
        animationSpec = tween(200),
        label = "catBg"
    )

    val borderColor by animateColorAsState(
        targetValue = when {
            isSelected -> UltraTokens.Violet.copy(alpha = 0.35f)
            isFocused -> Color.White.copy(alpha = 0.14f)
            else -> Color.Transparent
        },
        animationSpec = tween(200),
        label = "catBorder"
    )

    val textColor by animateColorAsState(
        targetValue = if (highlighted) Color.White else UltraTokens.TextSecondary,
        animationSpec = tween(200),
        label = "catText"
    )

    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 4.dp, vertical = 2.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(bgColor)
            .border(1.dp, borderColor, RoundedCornerShape(12.dp))
            .onFocusChanged {
                isFocused = it.isFocused
                if (it.isFocused) onFocus()
            }
            .focusable()
            .padding(horizontal = 14.dp, vertical = 12.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.weight(1f)
            ) {
                // Teal dot for selected
                if (isSelected) {
                    Box(
                        Modifier
                            .size(4.dp)
                            .clip(CircleShape)
                            .background(UltraTokens.Teal)
                    )
                    Spacer(Modifier.width(8.dp))
                }

                Text(
                    text = title.replaceFirstChar {
                        if (it.isLowerCase()) it.titlecase(java.util.Locale.getDefault()) else it.toString()
                    },
                    color = textColor,
                    fontSize = 13.5.sp,
                    fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Medium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }

            // Count badge
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(8.dp))
                    .background(Color.White.copy(alpha = if (isSelected) 0.12f else 0.06f))
                    .padding(horizontal = 7.dp, vertical = 2.dp)
            ) {
                Text(
                    "$count",
                    color = if (isSelected) UltraTokens.Text else UltraTokens.TextFaint,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Medium
                )
            }
        }
    }
}


// ═══════════════════════════════════════════════════════════════════════════
//  CHANNEL PANE — Glassmorphic grid
// ═══════════════════════════════════════════════════════════════════════════

@OptIn(ExperimentalComposeUiApi::class, ExperimentalFoundationApi::class)
@Composable
private fun ChannelPane(
    channels: List<TvChannel>,
    appLanguage: String,
    favoriteChannels: Set<String>,
    onToggleFavorite: (TvChannel) -> Unit,
    onChannelFocused: (TvChannel) -> Unit,
    onChannelSelected: (TvChannel) -> Unit,
    onAnyFocus: () -> Unit,
    modifier: Modifier = Modifier
) {
    GlassPanel(
        modifier = modifier,
        borderRadius = RoundedCornerShape(
            topStart = 0.dp,
            bottomStart = 0.dp,
            topEnd = UltraTokens.RadiusLg,
            bottomEnd = UltraTokens.RadiusLg
        )
    ) {
        Column(modifier = Modifier.fillMaxSize().padding(vertical = 20.dp, horizontal = 22.dp)) {
            // Header
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 16.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    Locales.getString("lbl_channels", appLanguage).uppercase(),
                    color = UltraTokens.Teal,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 2.sp
                )
                Text(
                    "${channels.size}",
                    color = UltraTokens.TextFaint,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Medium
                )
            }

            LazyVerticalGrid(
                columns = GridCells.Fixed(5),
                modifier = Modifier
                    .fillMaxSize()
                    .focusRestorer(),
                contentPadding = PaddingValues(vertical = 6.dp),
                horizontalArrangement = Arrangement.spacedBy(18.dp),
                verticalArrangement = Arrangement.spacedBy(18.dp)
            ) {
                itemsIndexed(channels, key = { index, c -> "$index:${c.url}" }) { index, channel ->
                    ChannelCard(
                        channel = channel,
                        isFavorite = favoriteChannels.contains(channel.url),
                        onToggleFavorite = { onToggleFavorite(channel) },
                        onClick = { onChannelSelected(channel) },
                        onFocus = {
                            onAnyFocus()
                            onChannelFocused(channel)
                        }
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun ChannelCard(
    channel: TvChannel,
    isFavorite: Boolean,
    onToggleFavorite: () -> Unit,
    onClick: () -> Unit,
    onFocus: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    val scale by animateFloatAsState(
        targetValue = if (isFocused) 1.05f else 1f,
        animationSpec = spring(
            dampingRatio = 0.65f,
            stiffness = Spring.StiffnessLow
        ),
        label = "cardScale"
    )

    val bgColor by animateColorAsState(
        targetValue = if (isFocused) Color.White.copy(alpha = 0.07f) else Color.White.copy(alpha = 0.035f),
        animationSpec = tween(220),
        label = "cardBg"
    )

    val borderColor by animateColorAsState(
        targetValue = if (isFocused) Color.White.copy(alpha = 0.55f) else UltraTokens.Hairline,
        animationSpec = tween(220),
        label = "cardBorder"
    )

    val contentColor = Color.White

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .aspectRatio(1.15f)
            .scale(scale)
            .clip(RoundedCornerShape(16.dp))
            .background(bgColor)
            .border(1.dp, borderColor, RoundedCornerShape(16.dp))
            .then(
                if (isFocused) {
                    Modifier.drawBehind {
                        // Subtle shadow on focus
                        drawRect(
                            brush = Brush.verticalGradient(
                                colors = listOf(Color.Transparent, Color.Black.copy(alpha = 0.25f)),
                                startY = size.height * 0.7f,
                                endY = size.height * 1.3f
                            )
                        )
                    }
                } else Modifier
            )
            .onFocusChanged {
                isFocused = it.isFocused
                if (it.isFocused) onFocus()
            }
            .combinedClickable(
                onClick = { onClick() },
                onLongClick = { onToggleFavorite() }
            ),
        contentAlignment = Alignment.Center
    ) {
        // Channel Logo — safe-area padding
        if (!channel.logo.isNullOrEmpty()) {
            AsyncImage(
                model = channel.logo,
                contentDescription = channel.name,
                contentScale = ContentScale.Fit,
                modifier = Modifier
                    .fillMaxSize()
                    .padding(start = 10.dp, end = 10.dp, top = 14.dp, bottom = 26.dp)
            )
        } else {
            // Initials fallback
            val initials = channel.name
                .split(" ")
                .filter { it.isNotEmpty() }
                .take(2)
                .joinToString("") { it.first().uppercase() }

            Text(
                text = initials,
                color = UltraTokens.TextSecondary,
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 0.5.sp
            )
        }

        // Favorite heart, top right
        val heartIcon = if (isFavorite) Icons.Rounded.Favorite else Icons.Rounded.FavoriteBorder
        val heartTint = if (isFavorite) Color(0xFFFF4081) else Color.White.copy(alpha = 0.7f)

        Icon(
            imageVector = heartIcon,
            contentDescription = "Favorite",
            tint = heartTint,
            modifier = Modifier
                .align(Alignment.TopEnd)
                .padding(9.dp)
                .size(15.dp)
        )

        // Name bar with gradient fade, bottom
        Box(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .background(
                    Brush.verticalGradient(
                        colors = listOf(
                            Color.Transparent,
                            Color.Black.copy(alpha = 0.85f)
                        )
                    )
                )
                .padding(start = 8.dp, end = 8.dp, top = 16.dp, bottom = 7.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = channel.name,
                color = contentColor,
                fontSize = 11.sp,
                fontWeight = FontWeight.SemiBold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                textAlign = TextAlign.Center
            )
        }
    }
}
