package com.kobani4k.app.tv.ui

import android.os.Build
import android.content.Context
import android.view.KeyEvent
import android.widget.TextClock
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
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
import androidx.compose.ui.draw.scale
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.focusRestorer
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
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
import kotlinx.coroutines.launch

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
                    // ═══ KURDFILM MOVIES LAYOUT (API + Ad-Blocking) ═══
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(start = 24.dp)
                    ) {
                        KurdfilmMoviesScreen()
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
//  STATIC GRADIENT MESH BACKGROUND — Color blobs, zero per-frame cost.
//  Previously used BlurMaskFilter + InfiniteTransition which consumed GPU on
//  every frame and competed directly with D-PAD focus animations.
// ═══════════════════════════════════════════════════════════════════════════

@Composable
private fun GradientMeshBackground() {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
    )
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
            // App Logo
            Image(
                painter = painterResource(id = com.kobani4k.app.R.drawable.app_logo),
                contentDescription = "KOBANI 4K Logo",
                modifier = Modifier.size(36.dp)
            )

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

    val scale by animateFloatAsState(
        targetValue = if (highlighted) 1.05f else 1f,
        animationSpec = tween(80),
        label = "nav_scale"
    )

    val bgColor = if (highlighted) Color.White else Color.Transparent
    val borderColor = if (highlighted) Color.White else Color.Transparent
    val contentColor = if (highlighted) Color.Black else Color.White.copy(alpha = 0.72f)

    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(56.dp)
            .scale(scale)
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
            .padding(horizontal = if (expanded) 15.dp else 0.dp),
        contentAlignment = if (expanded) Alignment.CenterStart else Alignment.Center
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = if (expanded) Arrangement.Start else Arrangement.Center
        ) {
            Icon(
                icon,
                contentDescription = label,
                tint = contentColor,
                modifier = Modifier.size(22.dp)
            )
            if (expanded) {
                Spacer(Modifier.width(14.dp))
                Text(
                    label.uppercase(),
                    color = contentColor,
                    fontSize = 14.sp,
                    fontWeight = if (highlighted) FontWeight.Bold else FontWeight.Medium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
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

    val scale by animateFloatAsState(
        targetValue = if (highlighted) 1.05f else 1f,
        animationSpec = tween(80),
        label = "cat_scale"
    )

    val bgColor = if (highlighted) Color.White else Color.Transparent
    val borderColor = if (highlighted) Color.White else Color.Transparent
    val textColor = if (highlighted) Color.Black else UltraTokens.TextSecondary
    val countColor = if (highlighted) Color.Black.copy(alpha = 0.75f) else UltraTokens.Divider

    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 4.dp, vertical = 2.dp)
            .scale(scale)
            .clip(RoundedCornerShape(12.dp))
            .background(bgColor)
            .border(1.dp, borderColor, RoundedCornerShape(12.dp))
            .onFocusChanged {
                isFocused = it.isFocused
                if (it.isFocused) onFocus()
            }
            .clickable(onClick = onFocus)
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
                // Dot indicator for active selection when not focused
                if (isSelected && !isFocused) {
                    Box(
                        Modifier
                            .size(6.dp)
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
    // 150ms debounce on focus callbacks — prevents rapid D-PAD holds from
    // triggering state updates and recompositions on every intermediate card.
    val scope = rememberCoroutineScope()
    var focusDebounceJob by remember { mutableStateOf<kotlinx.coroutines.Job?>(null) }

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
                            // Cancel any pending debounce and restart — only
                            // the card the user rests on fires the callback.
                            focusDebounceJob?.cancel()
                            focusDebounceJob = scope.launch {
                                delay(150)
                                onChannelFocused(channel)
                            }
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

    // Fast scale: tween(100ms) instead of StiffnessLow spring (~300ms).
    // Provides snappy visual pop without eating into the frame budget.
    val scale by animateFloatAsState(
        targetValue = if (isFocused) 1.05f else 1f,
        animationSpec = tween(durationMillis = 100),
        label = "cardScale"
    )

    // Instant colors — no animateColorAsState tween lag.
    // With 25+ cards visible, removing 3 × animateColorAsState each saves ~75
    // active Choreographer callbacks per frame during navigation.
    val bgColor     = if (isFocused) Color.White.copy(alpha = 0.09f) else Color.White.copy(alpha = 0.035f)
    val borderColor = if (isFocused) Color.White.copy(alpha = 0.75f) else UltraTokens.Hairline
    val borderWidth = if (isFocused) 2.dp else 1.dp

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .aspectRatio(1.15f)
            .scale(scale)
            .clip(RoundedCornerShape(16.dp))
            .background(bgColor)
            .border(borderWidth, borderColor, RoundedCornerShape(16.dp))
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

        // Channel Logo — fill card area
        if (!channel.logo.isNullOrEmpty()) {
            AsyncImage(
                model = channel.logo,
                contentDescription = channel.name,
                contentScale = ContentScale.Fit,
                modifier = Modifier
                    .fillMaxSize()
                    .padding(start = 4.dp, end = 4.dp, top = 4.dp, bottom = 22.dp)
                    .clip(RoundedCornerShape(12.dp))
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
                color = Color.White,
                fontSize = 11.sp,
                fontWeight = FontWeight.SemiBold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                textAlign = TextAlign.Center
            )
        }
    }
}
