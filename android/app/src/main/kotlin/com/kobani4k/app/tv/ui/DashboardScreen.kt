package com.kobani4k.app.tv.ui

import android.os.Build
import android.view.KeyEvent
import android.widget.TextClock
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
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
import androidx.activity.compose.BackHandler
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.kobani4k.app.tv.data.PocketBaseRepository
import com.kobani4k.app.tv.data.TvChannel
import com.kobani4k.app.tv.data.TvChannelGroup
import com.kobani4k.app.tv.ui.theme.UltraTokens
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay

// ═══════════════════════════════════════════════════
//  DASHBOARD SCREEN — Premium 3-Pane TV Layout
// ═══════════════════════════════════════════════════

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun DashboardScreen(
    onChannelSelected: (TvChannel) -> Unit,
    onLogout: () -> Unit
) {
    val repository = remember { PocketBaseRepository() }
    var allChannels by remember { mutableStateOf<List<TvChannel>>(emptyList()) }
    var allGroups by remember { mutableStateOf<List<TvChannelGroup>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }

    // Settings overlay state
    var showSettings by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        coroutineScope {
            val groupsDeferred = async { repository.getGroups() }
            val channelsDeferred = async { repository.getChannels() }
            allGroups = groupsDeferred.await()
            allChannels = channelsDeferred.await()
        }
        isLoading = false
    }

    val categories = remember(allChannels, allGroups) {
        if (allGroups.isNotEmpty()) allGroups.map { it.name }
        else allChannels.map { it.group.ifEmpty { "General" } }.distinct().sorted()
    }

    var selectedCategory by rememberSaveable { mutableStateOf<String?>(null) }
    var focusedChannel by remember { mutableStateOf<TvChannel?>(null) }

    val filteredChannels = remember(allChannels, selectedCategory) {
        allChannels.filter { it.group.ifEmpty { "General" } == selectedCategory }
    }

    LaunchedEffect(categories) {
        if (categories.isNotEmpty() && selectedCategory == null) {
            selectedCategory = categories.first()
        }
    }

    val categoryFocusRequester = remember { FocusRequester() }
    LaunchedEffect(isLoading, categories) {
        if (!isLoading && categories.isNotEmpty()) {
            delay(150)
            runCatching { categoryFocusRequester.requestFocus() }
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(UltraTokens.Background)
        ) {
            // ═══ TOP HEADER BAR ═══
            DashboardHeader(onSettingsClick = { showSettings = true })

            if (isLoading) {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        CircularProgressIndicator(
                            color = UltraTokens.Blue,
                            modifier = Modifier.size(48.dp),
                            strokeWidth = 3.dp
                        )
                        Spacer(Modifier.height(16.dp))
                        Text(
                            "Loading channels...",
                            color = UltraTokens.TextSecondary,
                            fontSize = 14.sp
                        )
                    }
                }
            } else {
                // ═══ MAIN 3-PANE LAYOUT ═══
                Row(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(start = 24.dp, end = 24.dp, top = 12.dp, bottom = 16.dp),
                    horizontalArrangement = Arrangement.spacedBy(20.dp)
                ) {
                    // PANE 1: CATEGORIES
                    CategoryPane(
                        categories = categories,
                        selectedCategory = selectedCategory,
                        onCategorySelected = { selectedCategory = it },
                        channelCounts = allChannels.groupingBy { it.group.ifEmpty { "General" } }.eachCount(),
                        focusRequester = categoryFocusRequester,
                        modifier = Modifier
                            .width(UltraTokens.SideBar)
                            .fillMaxHeight()
                    )

                    // PANE 2: CHANNEL LIST
                    ChannelPane(
                        channels = filteredChannels,
                        onChannelFocused = { focusedChannel = it },
                        onChannelSelected = onChannelSelected,
                        modifier = Modifier
                            .width(380.dp)
                            .fillMaxHeight()
                    )

                    // PANE 3: PREVIEW
                    PreviewPane(
                        channel = focusedChannel ?: filteredChannels.firstOrNull(),
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxHeight()
                    )
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
                channelCount = allChannels.size,
                categoryCount = categories.size,
                onLogout = onLogout,
                onDismiss = { showSettings = false }
            )
        }
    }
}

// ═══════════════════════════════════════════════════
//  HEADER BAR
// ═══════════════════════════════════════════════════

@Composable
private fun DashboardHeader(onSettingsClick: () -> Unit) {
    var settingsFocused by remember { mutableStateOf(false) }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        UltraTokens.Surface.copy(alpha = 0.95f),
                        UltraTokens.Surface.copy(alpha = 0.4f),
                        Color.Transparent
                    )
                )
            )
            .padding(horizontal = 32.dp, vertical = 14.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Logo & Title
        Row(verticalAlignment = Alignment.CenterVertically) {
            val infiniteTransition = rememberInfiniteTransition(label = "headerPulse")
            val dotAlpha by infiniteTransition.animateFloat(
                initialValue = 0.5f,
                targetValue = 1f,
                animationSpec = infiniteRepeatable(
                    animation = tween(1500),
                    repeatMode = RepeatMode.Reverse
                ),
                label = "dotAlpha"
            )

            Icon(
                Icons.Rounded.LiveTv,
                contentDescription = "Logo",
                tint = UltraTokens.Blue,
                modifier = Modifier.size(28.dp)
            )
            Spacer(Modifier.width(12.dp))
            Text(
                "KOBANI",
                color = Color.White,
                fontSize = 18.sp,
                fontWeight = FontWeight.Black,
                letterSpacing = 2.sp
            )
            Text(
                " 4K",
                color = UltraTokens.Blue,
                fontSize = 18.sp,
                fontWeight = FontWeight.Black,
                letterSpacing = 2.sp
            )

            Spacer(Modifier.width(20.dp))

            Box(
                Modifier
                    .width(1.dp)
                    .height(20.dp)
                    .background(UltraTokens.Divider.copy(alpha = 0.4f))
            )

            Spacer(Modifier.width(20.dp))

            // LIVE badge
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier
                    .clip(RoundedCornerShape(4.dp))
                    .background(UltraTokens.Live.copy(alpha = 0.15f))
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
                    "LIVE",
                    color = UltraTokens.Live,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 1.sp
                )
            }
        }

        // Right: Clock & Settings
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            AndroidView(
                factory = { ctx ->
                    TextClock(ctx).apply {
                        format12Hour = "hh:mm a  |  MMM dd"
                        format24Hour = "HH:mm  |  MMM dd"
                        textSize = 14f
                        setTextColor(android.graphics.Color.parseColor("#6B7280"))
                        typeface = android.graphics.Typeface.DEFAULT_BOLD
                    }
                }
            )

            // Settings button
            val settingsScale by animateFloatAsState(
                if (settingsFocused) 1.2f else 1f,
                tween(200),
                label = "settingsScale"
            )
            val settingsBg by animateColorAsState(
                if (settingsFocused) UltraTokens.Blue else Color.Transparent,
                tween(200),
                label = "settingsBg"
            )

            Box(
                modifier = Modifier
                    .size(36.dp)
                    .scale(settingsScale)
                    .clip(CircleShape)
                    .background(settingsBg)
                    .onFocusChanged { settingsFocused = it.isFocused }
                    .focusable()
                    .onKeyEvent { ev ->
                        if (ev.nativeKeyEvent.action == KeyEvent.ACTION_DOWN &&
                            (ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_DPAD_CENTER ||
                                    ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_ENTER || ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_NUMPAD_ENTER)
                        ) {
                            onSettingsClick()
                            true
                        } else false
                    },
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    Icons.Rounded.Settings,
                    contentDescription = "Settings",
                    tint = if (settingsFocused) Color.White else UltraTokens.TextSecondary,
                    modifier = Modifier.size(20.dp)
                )
            }
        }
    }
}

// ═══════════════════════════════════════════════════
//  SETTINGS OVERLAY — Full-Screen Premium Settings
// ═══════════════════════════════════════════════════

@Composable
private fun SettingsOverlay(
    channelCount: Int,
    categoryCount: Int,
    onLogout: () -> Unit,
    onDismiss: () -> Unit
) {
    BackHandler { onDismiss() }

    val context = LocalContext.current
    val settingsFocusRequester = remember { FocusRequester() }

    // Settings state
    var selectedVideoQuality by rememberSaveable { mutableStateOf("Auto") }
    var selectedAudioLang by rememberSaveable { mutableStateOf("Default") }
    var selectedSubLang by rememberSaveable { mutableStateOf("Off") }
    var parentalEnabled by rememberSaveable { mutableStateOf(false) }
    var autoPlayNext by rememberSaveable { mutableStateOf(true) }
    var timeFormat24h by rememberSaveable { mutableStateOf(false) }
    var selectedTheme by rememberSaveable { mutableStateOf("Dark") }

    // Settings menu categories
    var activeSection by remember { mutableStateOf("general") }

    LaunchedEffect(Unit) {
        delay(200)
        runCatching { settingsFocusRequester.requestFocus() }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(UltraTokens.Background.copy(alpha = 0.97f))
    ) {
        Row(modifier = Modifier.fillMaxSize()) {
            // ═══ LEFT SIDEBAR — Settings Categories ═══
            Column(
                modifier = Modifier
                    .width(280.dp)
                    .fillMaxHeight()
                    .background(UltraTokens.Surface)
                    .padding(vertical = 24.dp)
            ) {
                // Header
                Row(
                    modifier = Modifier.padding(horizontal = 24.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Rounded.Settings,
                        contentDescription = null,
                        tint = UltraTokens.Blue,
                        modifier = Modifier.size(24.dp)
                    )
                    Spacer(Modifier.width(12.dp))
                    Text(
                        "SETTINGS",
                        color = Color.White,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 2.sp
                    )
                }

                Spacer(Modifier.height(8.dp))
                Box(
                    Modifier
                        .fillMaxWidth()
                        .height(1.dp)
                        .background(Color.White.copy(alpha = 0.06f))
                )
                Spacer(Modifier.height(16.dp))

                // Category items
                val sections = listOf(
                    Triple("general", Icons.Rounded.Tune, "General"),
                    Triple("video", Icons.Rounded.HighQuality, "Video & Audio"),
                    Triple("parental", Icons.Rounded.Lock, "Parental Controls"),
                    Triple("appearance", Icons.Rounded.Palette, "Appearance"),
                    Triple("storage", Icons.Rounded.Storage, "Storage & Cache"),
                    Triple("about", Icons.Rounded.Info, "About"),
                    Triple("account", Icons.Rounded.AccountCircle, "Account"),
                )

                LazyColumn(
                    modifier = Modifier
                        .weight(1f)
                        .focusRestorer()
                ) {
                    items(sections) { (key, icon, label) ->
                        SettingsCategoryItem(
                            icon = icon,
                            label = label,
                            isSelected = activeSection == key,
                            modifier = if (key == "general") Modifier.focusRequester(settingsFocusRequester) else Modifier,
                            onFocus = { activeSection = key }
                        )
                    }
                }

                // Close hint at bottom
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 24.dp, vertical = 8.dp)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("Press ", color = UltraTokens.Divider, fontSize = 12.sp)
                        Text("BACK", color = UltraTokens.Blue, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                        Text(" to close", color = UltraTokens.Divider, fontSize = 12.sp)
                    }
                }
            }

            // ═══ RIGHT CONTENT — Active Section ═══
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight()
                    .padding(horizontal = 48.dp, vertical = 24.dp)
            ) {
                Crossfade(targetState = activeSection, animationSpec = tween(250), label = "settingsSection") { section ->
                    when (section) {
                        "general" -> GeneralSettingsSection(
                            autoPlayNext = autoPlayNext,
                            onAutoPlayChange = { autoPlayNext = it },
                            timeFormat24h = timeFormat24h,
                            onTimeFormatChange = { timeFormat24h = it }
                        )
                        "video" -> VideoAudioSettingsSection(
                            selectedQuality = selectedVideoQuality,
                            onQualityChange = { selectedVideoQuality = it },
                            selectedAudioLang = selectedAudioLang,
                            onAudioLangChange = { selectedAudioLang = it },
                            selectedSubLang = selectedSubLang,
                            onSubLangChange = { selectedSubLang = it }
                        )
                        "parental" -> ParentalControlsSection(
                            enabled = parentalEnabled,
                            onEnabledChange = { parentalEnabled = it }
                        )
                        "appearance" -> AppearanceSection(
                            selectedTheme = selectedTheme,
                            onThemeChange = { selectedTheme = it }
                        )
                        "storage" -> StorageSection()
                        "about" -> AboutSection()
                        "account" -> AccountSection(
                            channelCount = channelCount,
                            categoryCount = categoryCount,
                            onLogout = onLogout
                        )
                    }
                }
            }
        }
    }
}

// ═══════════════════════════════════════════════════
//  Settings Category Sidebar Item
// ═══════════════════════════════════════════════════

@Composable
private fun SettingsCategoryItem(
    icon: ImageVector,
    label: String,
    isSelected: Boolean,
    modifier: Modifier = Modifier,
    onFocus: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    val bgColor by animateColorAsState(
        when {
            isFocused -> UltraTokens.Blue
            isSelected -> UltraTokens.SurfaceHover
            else -> Color.Transparent
        },
        tween(200),
        label = "setCatBg"
    )
    val iconTint by animateColorAsState(
        when {
            isFocused -> Color.White
            isSelected -> UltraTokens.Blue
            else -> UltraTokens.Divider
        },
        tween(200),
        label = "setCatIcon"
    )
    val scale by animateFloatAsState(
        if (isFocused) 1.03f else 1f,
        tween(150),
        label = "setCatScale"
    )

    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 2.dp)
            .scale(scale)
            .clip(RoundedCornerShape(10.dp))
            .background(bgColor)
            .onFocusChanged {
                isFocused = it.isFocused
                if (it.isFocused) onFocus()
            }
            .focusable()
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            icon,
            contentDescription = label,
            tint = iconTint,
            modifier = Modifier.size(20.dp)
        )
        Spacer(Modifier.width(14.dp))
        Text(
            text = label,
            color = if (isFocused) Color.White else if (isSelected) UltraTokens.Text else UltraTokens.TextSecondary,
            fontSize = 14.sp,
            fontWeight = if (isSelected || isFocused) FontWeight.SemiBold else FontWeight.Normal
        )
    }
}

// ═══════════════════════════════════════════════════
//  SECTION: General
// ═══════════════════════════════════════════════════

@Composable
private fun GeneralSettingsSection(
    autoPlayNext: Boolean,
    onAutoPlayChange: (Boolean) -> Unit,
    timeFormat24h: Boolean,
    onTimeFormatChange: (Boolean) -> Unit
) {
    Column(modifier = Modifier.fillMaxSize()) {
        SectionHeader("General Settings")

        Spacer(Modifier.height(24.dp))

        // Auto-play next channel
        SettingsToggleRow(
            icon = Icons.Rounded.SkipNext,
            title = "Auto-play next channel",
            description = "Automatically switch to the next channel when stream ends",
            isEnabled = autoPlayNext,
            onToggle = { onAutoPlayChange(!autoPlayNext) }
        )

        Spacer(Modifier.height(12.dp))

        // Time Format
        SettingsToggleRow(
            icon = Icons.Rounded.Schedule,
            title = "24-hour time format",
            description = "Use 24h clock instead of 12h AM/PM",
            isEnabled = timeFormat24h,
            onToggle = { onTimeFormatChange(!timeFormat24h) }
        )
    }
}

// ═══════════════════════════════════════════════════
//  SECTION: Video & Audio
// ═══════════════════════════════════════════════════

@Composable
private fun VideoAudioSettingsSection(
    selectedQuality: String,
    onQualityChange: (String) -> Unit,
    selectedAudioLang: String,
    onAudioLangChange: (String) -> Unit,
    selectedSubLang: String,
    onSubLangChange: (String) -> Unit
) {
    LazyColumn(modifier = Modifier.fillMaxSize()) {
        item { SectionHeader("Video & Audio") }
        item { Spacer(Modifier.height(20.dp)) }

        // Video Quality
        item {
            SettingsSubHeader("DEFAULT VIDEO QUALITY")
        }
        val qualities = listOf("Auto", "1080p (Full HD)", "720p (HD)", "480p (SD)", "360p")
        items(qualities.size) { index ->
            SettingsRadioRow(
                title = qualities[index],
                isSelected = selectedQuality == qualities[index],
                onClick = { onQualityChange(qualities[index]) }
            )
        }

        item { Spacer(Modifier.height(24.dp)) }

        // Audio Language
        item {
            SettingsSubHeader("DEFAULT AUDIO LANGUAGE")
        }
        val audioLangs = listOf("Default", "English", "Arabic", "Kurdish", "Turkish", "French", "Spanish")
        items(audioLangs.size) { index ->
            SettingsRadioRow(
                title = audioLangs[index],
                isSelected = selectedAudioLang == audioLangs[index],
                onClick = { onAudioLangChange(audioLangs[index]) }
            )
        }

        item { Spacer(Modifier.height(24.dp)) }

        // Subtitle Language
        item {
            SettingsSubHeader("DEFAULT SUBTITLE LANGUAGE")
        }
        val subLangs = listOf("Off", "English", "Arabic", "Kurdish", "Turkish", "French", "Spanish")
        items(subLangs.size) { index ->
            SettingsRadioRow(
                title = subLangs[index],
                isSelected = selectedSubLang == subLangs[index],
                onClick = { onSubLangChange(subLangs[index]) }
            )
        }
    }
}

// ═══════════════════════════════════════════════════
//  SECTION: Parental Controls
// ═══════════════════════════════════════════════════

@Composable
private fun ParentalControlsSection(
    enabled: Boolean,
    onEnabledChange: (Boolean) -> Unit
) {
    Column(modifier = Modifier.fillMaxSize()) {
        SectionHeader("Parental Controls")

        Spacer(Modifier.height(24.dp))

        // Lock toggle
        SettingsToggleRow(
            icon = Icons.Rounded.Lock,
            title = "Enable PIN Lock",
            description = "Require a 4-digit PIN to access restricted channels",
            isEnabled = enabled,
            onToggle = { onEnabledChange(!enabled) }
        )

        if (enabled) {
            Spacer(Modifier.height(16.dp))

            // PIN display (mock)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(UltraTokens.SurfaceHover)
                    .padding(20.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        "Current PIN",
                        color = UltraTokens.TextSecondary,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Medium
                    )
                    Spacer(Modifier.height(4.dp))
                    Text(
                        "• • • •",
                        color = Color.White,
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 4.sp
                    )
                }
                Icon(
                    Icons.Rounded.Edit,
                    contentDescription = "Change PIN",
                    tint = UltraTokens.Blue,
                    modifier = Modifier.size(20.dp)
                )
            }

            Spacer(Modifier.height(16.dp))

            // Info
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(10.dp))
                    .background(UltraTokens.Blue.copy(alpha = 0.08f))
                    .padding(16.dp),
                verticalAlignment = Alignment.Top
            ) {
                Icon(
                    Icons.Rounded.Info,
                    contentDescription = null,
                    tint = UltraTokens.Blue,
                    modifier = Modifier.size(18.dp)
                )
                Spacer(Modifier.width(12.dp))
                Text(
                    "When enabled, restricted channels will require the PIN before playback.",
                    color = UltraTokens.TextSecondary,
                    fontSize = 13.sp
                )
            }
        }
    }
}

// ═══════════════════════════════════════════════════
//  SECTION: Appearance
// ═══════════════════════════════════════════════════

@Composable
private fun AppearanceSection(
    selectedTheme: String,
    onThemeChange: (String) -> Unit
) {
    Column(modifier = Modifier.fillMaxSize()) {
        SectionHeader("Appearance")

        Spacer(Modifier.height(24.dp))

        SettingsSubHeader("THEME")

        val themes = listOf(
            Triple("Dark", UltraTokens.Surface, "Standard dark theme"),
            Triple("AMOLED", Color.Black, "Pure black for OLED screens"),
            Triple("Blue", Color(0xFF0A1628), "Deep navy blue theme"),
        )

        themes.forEach { (name, color, desc) ->
            ThemeOptionRow(
                name = name,
                previewColor = color,
                description = desc,
                isSelected = selectedTheme == name,
                onClick = { onThemeChange(name) }
            )
            Spacer(Modifier.height(6.dp))
        }
    }
}

@Composable
private fun ThemeOptionRow(
    name: String,
    previewColor: Color,
    description: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    val bgColor by animateColorAsState(
        when {
            isFocused -> UltraTokens.Blue
            isSelected -> UltraTokens.SurfaceHover
            else -> UltraTokens.SurfaceHover
        },
        tween(200),
        label = "themeBg"
    )

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(bgColor)
            .onFocusChanged { isFocused = it.isFocused }
            .focusable()
            .onKeyEvent { ev ->
                if (ev.nativeKeyEvent.action == KeyEvent.ACTION_DOWN &&
                    (ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_DPAD_CENTER ||
                            ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_ENTER || ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_NUMPAD_ENTER)
                ) {
                    onClick()
                    true
                } else false
            }
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Color preview
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(previewColor)
                .border(
                    1.dp,
                    if (isFocused) Color.White.copy(alpha = 0.4f) else Color.White.copy(alpha = 0.1f),
                    RoundedCornerShape(8.dp)
                )
        )
        Spacer(Modifier.width(16.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                name,
                color = if (isFocused) Color.White else UltraTokens.Text,
                fontSize = 15.sp,
                fontWeight = FontWeight.SemiBold
            )
            Text(
                description,
                color = if (isFocused) Color.White.copy(alpha = 0.7f) else UltraTokens.Divider,
                fontSize = 12.sp
            )
        }
        // Radio
        Box(
            modifier = Modifier
                .size(18.dp)
                .clip(CircleShape)
                .border(
                    2.dp,
                    if (isFocused) Color.White else if (isSelected) UltraTokens.Blue else UltraTokens.Divider,
                    CircleShape
                ),
            contentAlignment = Alignment.Center
        ) {
            if (isSelected) {
                Box(
                    modifier = Modifier
                        .size(10.dp)
                        .clip(CircleShape)
                        .background(if (isFocused) Color.White else UltraTokens.Blue)
                )
            }
        }
    }
}

// ═══════════════════════════════════════════════════
//  SECTION: Storage & Cache
// ═══════════════════════════════════════════════════

@Composable
private fun StorageSection() {
    Column(modifier = Modifier.fillMaxSize()) {
        SectionHeader("Storage & Cache")

        Spacer(Modifier.height(24.dp))

        // Cache info card
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(14.dp))
                .background(UltraTokens.SurfaceHover)
                .padding(20.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text("Image Cache", color = UltraTokens.TextSecondary, fontSize = 12.sp)
                Spacer(Modifier.height(4.dp))
                Text(
                    "Cached channel logos and images",
                    color = UltraTokens.Text,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Medium
                )
            }
            Icon(
                Icons.Rounded.Image,
                contentDescription = null,
                tint = UltraTokens.Divider,
                modifier = Modifier.size(24.dp)
            )
        }

        Spacer(Modifier.height(12.dp))

        // Clear cache button
        SettingsActionButton(
            icon = Icons.Rounded.DeleteSweep,
            title = "Clear Image Cache",
            description = "Remove all cached channel logos",
            accentColor = UltraTokens.Movie,
            onClick = { /* Clear cache logic */ }
        )

        Spacer(Modifier.height(12.dp))

        SettingsActionButton(
            icon = Icons.Rounded.Refresh,
            title = "Refresh Channel Data",
            description = "Re-download all channel and group data",
            accentColor = UltraTokens.Blue,
            onClick = { /* Refresh logic */ }
        )
    }
}

// ═══════════════════════════════════════════════════
//  SECTION: About
// ═══════════════════════════════════════════════════

@Composable
private fun AboutSection() {
    Column(modifier = Modifier.fillMaxSize()) {
        SectionHeader("About")

        Spacer(Modifier.height(24.dp))

        // App info card
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(16.dp))
                .background(UltraTokens.SurfaceHover)
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                Icons.Rounded.LiveTv,
                contentDescription = null,
                tint = UltraTokens.Blue,
                modifier = Modifier.size(48.dp)
            )
            Spacer(Modifier.height(12.dp))
            Row {
                Text(
                    "KOBANI ",
                    color = Color.White,
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Black,
                    letterSpacing = 2.sp
                )
                Text(
                    "4K",
                    color = UltraTokens.Blue,
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Black,
                    letterSpacing = 2.sp
                )
            }
            Spacer(Modifier.height(4.dp))
            Text(
                "Premium Streaming",
                color = UltraTokens.Divider,
                fontSize = 13.sp,
                letterSpacing = 2.sp
            )
        }

        Spacer(Modifier.height(20.dp))

        // Version details
        val infoItems = listOf(
            Pair("App Version", "2.0.0"),
            Pair("Build", "TV-Compose"),
            Pair("Platform", "Android ${Build.VERSION.RELEASE}"),
            Pair("Device", Build.MODEL),
            Pair("API Level", Build.VERSION.SDK_INT.toString()),
        )

        infoItems.forEach { (label, value) ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(label, color = UltraTokens.TextSecondary, fontSize = 14.sp)
                Text(
                    value,
                    color = UltraTokens.Text,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium
                )
            }
            Box(
                Modifier
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(Color.White.copy(alpha = 0.04f))
            )
        }
    }
}

// ═══════════════════════════════════════════════════
//  SECTION: Account
// ═══════════════════════════════════════════════════

@Composable
private fun AccountSection(
    channelCount: Int,
    categoryCount: Int,
    onLogout: () -> Unit
) {
    Column(modifier = Modifier.fillMaxSize()) {
        SectionHeader("Account")

        Spacer(Modifier.height(24.dp))

        // Account info
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(14.dp))
                .background(UltraTokens.SurfaceHover)
                .padding(20.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(52.dp)
                    .clip(CircleShape)
                    .background(UltraTokens.SurfaceHover),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    Icons.Rounded.Person,
                    contentDescription = null,
                    tint = UltraTokens.Blue,
                    modifier = Modifier.size(28.dp)
                )
            }
            Spacer(Modifier.width(16.dp))
            Column {
                Text(
                    "Active Subscription",
                    color = Color.White,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold
                )
                Spacer(Modifier.height(4.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        Modifier
                            .size(6.dp)
                            .clip(CircleShape)
                            .background(UltraTokens.Sports)
                    )
                    Spacer(Modifier.width(6.dp))
                    Text(
                        "Activated via login code",
                        color = UltraTokens.TextSecondary,
                        fontSize = 13.sp
                    )
                }
            }
        }

        Spacer(Modifier.height(16.dp))

        // Stats
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            StatCard(
                label = "Channels",
                value = channelCount.toString(),
                icon = Icons.Rounded.LiveTv,
                modifier = Modifier.weight(1f)
            )
            StatCard(
                label = "Categories",
                value = categoryCount.toString(),
                icon = Icons.Rounded.Category,
                modifier = Modifier.weight(1f)
            )
        }

        Spacer(Modifier.height(32.dp))

        // Logout button
        SettingsActionButton(
            icon = Icons.Rounded.Logout,
            title = "Sign Out",
            description = "Log out and return to the login screen",
            accentColor = UltraTokens.Movie,
            onClick = onLogout
        )
    }
}

@Composable
private fun StatCard(
    label: String,
    value: String,
    icon: ImageVector,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .background(UltraTokens.SurfaceHover)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(RoundedCornerShape(10.dp))
                .background(UltraTokens.SurfaceHover),
            contentAlignment = Alignment.Center
        ) {
            Icon(icon, contentDescription = null, tint = UltraTokens.Blue, modifier = Modifier.size(20.dp))
        }
        Spacer(Modifier.width(12.dp))
        Column {
            Text(value, color = Color.White, fontSize = 22.sp, fontWeight = FontWeight.Bold)
            Text(label, color = UltraTokens.Divider, fontSize = 12.sp)
        }
    }
}

// ═══════════════════════════════════════════════════
//  SHARED SETTINGS COMPONENTS
// ═══════════════════════════════════════════════════

@Composable
private fun SectionHeader(title: String) {
    Text(
        text = title,
        color = Color.White,
        fontSize = 24.sp,
        fontWeight = FontWeight.Bold
    )
}

@Composable
private fun SettingsSubHeader(title: String) {
    Text(
        text = title,
        color = UltraTokens.Blue,
        fontSize = 11.sp,
        fontWeight = FontWeight.Bold,
        letterSpacing = 2.sp,
        modifier = Modifier.padding(vertical = 10.dp)
    )
}

@Composable
private fun SettingsToggleRow(
    icon: ImageVector,
    title: String,
    description: String,
    isEnabled: Boolean,
    onToggle: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    val bgColor by animateColorAsState(
        if (isFocused) UltraTokens.Blue.copy(alpha = 0.15f) else UltraTokens.SurfaceHover,
        tween(200),
        label = "toggleBg"
    )
    val borderColor by animateColorAsState(
        if (isFocused) UltraTokens.Blue else Color.Transparent,
        tween(200),
        label = "toggleBorder"
    )

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(bgColor)
            .border(1.5.dp, borderColor, RoundedCornerShape(14.dp))
            .onFocusChanged { isFocused = it.isFocused }
            .focusable()
            .onKeyEvent { ev ->
                if (ev.nativeKeyEvent.action == KeyEvent.ACTION_DOWN &&
                    (ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_DPAD_CENTER ||
                            ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_ENTER || ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_NUMPAD_ENTER)
                ) {
                    onToggle()
                    true
                } else false
            }
            .padding(20.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            icon,
            contentDescription = null,
            tint = if (isFocused) UltraTokens.Blue else UltraTokens.Divider,
            modifier = Modifier.size(22.dp)
        )
        Spacer(Modifier.width(16.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                title,
                color = if (isFocused) Color.White else UltraTokens.Text,
                fontSize = 15.sp,
                fontWeight = FontWeight.SemiBold
            )
            Spacer(Modifier.height(2.dp))
            Text(
                description,
                color = if (isFocused) Color.White.copy(alpha = 0.7f) else UltraTokens.Divider,
                fontSize = 12.sp
            )
        }
        Spacer(Modifier.width(16.dp))

        // Toggle switch
        val toggleBg by animateColorAsState(
            if (isEnabled) UltraTokens.Blue else UltraTokens.SurfaceSelected,
            tween(200),
            label = "switchBg"
        )
        val knobOffset by animateFloatAsState(
            if (isEnabled) 1f else 0f,
            tween(200),
            label = "knobOffset"
        )

        Box(
            modifier = Modifier
                .width(44.dp)
                .height(24.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(toggleBg)
                .padding(3.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(18.dp)
                    .offset(x = (knobOffset * 20).dp)
                    .clip(CircleShape)
                    .background(Color.White)
            )
        }
    }
}

@Composable
private fun SettingsRadioRow(
    title: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    val bgColor by animateColorAsState(
        when {
            isFocused -> UltraTokens.Blue
            isSelected -> UltraTokens.SurfaceHover
            else -> Color.Transparent
        },
        tween(150),
        label = "sRadioBg"
    )

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp))
            .background(bgColor)
            .onFocusChanged { isFocused = it.isFocused }
            .focusable()
            .onKeyEvent { ev ->
                if (ev.nativeKeyEvent.action == KeyEvent.ACTION_DOWN &&
                    (ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_DPAD_CENTER ||
                            ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_ENTER || ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_NUMPAD_ENTER)
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
            color = if (isFocused) Color.White else if (isSelected) UltraTokens.Blue else UltraTokens.TextSecondary,
            fontSize = 14.sp,
            fontWeight = if (isSelected || isFocused) FontWeight.SemiBold else FontWeight.Normal
        )

        Box(
            modifier = Modifier
                .size(18.dp)
                .clip(CircleShape)
                .border(
                    2.dp,
                    if (isFocused) Color.White
                    else if (isSelected) UltraTokens.Blue
                    else UltraTokens.Divider,
                    CircleShape
                ),
            contentAlignment = Alignment.Center
        ) {
            if (isSelected) {
                Box(
                    modifier = Modifier
                        .size(10.dp)
                        .clip(CircleShape)
                        .background(if (isFocused) Color.White else UltraTokens.Blue)
                )
            }
        }
    }
}

@Composable
private fun SettingsActionButton(
    icon: ImageVector,
    title: String,
    description: String,
    accentColor: Color,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    val bgColor by animateColorAsState(
        if (isFocused) accentColor else UltraTokens.SurfaceHover,
        tween(200),
        label = "actionBg"
    )
    val borderColor by animateColorAsState(
        if (isFocused) accentColor else Color.Transparent,
        tween(200),
        label = "actionBorder"
    )
    val scale by animateFloatAsState(
        if (isFocused) 1.02f else 1f,
        tween(150),
        label = "actionScale"
    )

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .scale(scale)
            .clip(RoundedCornerShape(14.dp))
            .background(bgColor)
            .border(1.5.dp, borderColor, RoundedCornerShape(14.dp))
            .onFocusChanged { isFocused = it.isFocused }
            .focusable()
            .onKeyEvent { ev ->
                if (ev.nativeKeyEvent.action == KeyEvent.ACTION_DOWN &&
                    (ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_DPAD_CENTER ||
                            ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_ENTER || ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_NUMPAD_ENTER)
                ) {
                    onClick()
                    true
                } else false
            }
            .padding(20.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            icon,
            contentDescription = null,
            tint = if (isFocused) Color.White else accentColor,
            modifier = Modifier.size(22.dp)
        )
        Spacer(Modifier.width(16.dp))
        Column {
            Text(
                title,
                color = if (isFocused) Color.White else UltraTokens.Text,
                fontSize = 15.sp,
                fontWeight = FontWeight.SemiBold
            )
            Text(
                description,
                color = if (isFocused) Color.White.copy(alpha = 0.7f) else UltraTokens.Divider,
                fontSize = 12.sp
            )
        }
    }
}

// ═══════════════════════════════════════════════════
//  PANE 1: CATEGORY LIST
// ═══════════════════════════════════════════════════

@Composable
private fun CategoryPane(
    categories: List<String>,
    selectedCategory: String?,
    onCategorySelected: (String) -> Unit,
    channelCounts: Map<String, Int>,
    focusRequester: FocusRequester,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier) {
        Text(
            text = "CATEGORIES",
            color = UltraTokens.Divider,
            fontSize = 11.sp,
            fontWeight = FontWeight.Bold,
            letterSpacing = 2.sp,
            modifier = Modifier.padding(start = 16.dp, bottom = 12.dp)
        )

        LazyColumn(
            contentPadding = PaddingValues(bottom = 24.dp),
            modifier = Modifier
                .fillMaxSize()
                .clip(RoundedCornerShape(16.dp))
                .background(UltraTokens.Surface.copy(alpha = 0.5f))
                .focusRestorer()
        ) {
            items(categories) { category ->
                val isSelected = selectedCategory == category
                CategoryItem(
                    title = category,
                    count = channelCounts[category] ?: 0,
                    isSelected = isSelected,
                    onFocus = { onCategorySelected(category) },
                    modifier = if (category == categories.firstOrNull()) {
                        Modifier.focusRequester(focusRequester)
                    } else Modifier
                )
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

    val bgColor by animateColorAsState(
        when {
            isFocused -> UltraTokens.Blue
            isSelected -> UltraTokens.SurfaceHover
            else -> Color.Transparent
        },
        tween(200),
        label = "catBg"
    )
    val textColor by animateColorAsState(
        when {
            isFocused -> Color.White
            isSelected -> UltraTokens.Blue
            else -> UltraTokens.TextSecondary
        },
        tween(200),
        label = "catText"
    )
    val scale by animateFloatAsState(
        if (isFocused) 1.03f else 1f,
        tween(150),
        label = "catScale"
    )

    Row(
        modifier = modifier
            .fillMaxWidth()
            .scale(scale)
            .clip(RoundedCornerShape(10.dp))
            .background(bgColor)
            .onFocusChanged {
                isFocused = it.isFocused
                if (it.isFocused) onFocus()
            }
            .focusable()
            .padding(horizontal = 16.dp, vertical = 15.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = title.uppercase(),
            color = textColor,
            fontSize = 13.sp,
            fontWeight = if (isSelected || isFocused) FontWeight.Bold else FontWeight.Medium,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            letterSpacing = if (isFocused) 0.5.sp else 0.sp,
            modifier = Modifier.weight(1f)
        )
        Box(
            modifier = Modifier
                .clip(RoundedCornerShape(6.dp))
                .background(
                    if (isFocused) Color.White.copy(alpha = 0.2f)
                    else if (isSelected) UltraTokens.SurfaceHover
                    else UltraTokens.SurfaceSelected
                )
                .padding(horizontal = 8.dp, vertical = 3.dp)
        ) {
            Text(
                text = count.toString(),
                color = if (isFocused) Color.White else UltraTokens.Divider,
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

// ═══════════════════════════════════════════════════
//  PANE 2: CHANNEL LIST
// ═══════════════════════════════════════════════════

@Composable
private fun ChannelPane(
    channels: List<TvChannel>,
    onChannelFocused: (TvChannel) -> Unit,
    onChannelSelected: (TvChannel) -> Unit,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(topStart = 14.dp, topEnd = 14.dp))
                .background(UltraTokens.Blue.copy(alpha = 0.08f))
                .padding(horizontal = 16.dp, vertical = 10.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                "CHANNELS",
                color = UltraTokens.Blue,
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 2.sp
            )
            Text(
                "${channels.size}",
                color = UltraTokens.Divider,
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold
            )
        }

        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .clip(RoundedCornerShape(bottomStart = 14.dp, bottomEnd = 14.dp))
                .background(UltraTokens.Surface.copy(alpha = 0.5f))
                .focusRestorer(),
            contentPadding = PaddingValues(vertical = 6.dp)
        ) {
            items(channels, key = { it.url }) { channel ->
                ChannelItem(
                    channel = channel,
                    onClick = { onChannelSelected(channel) },
                    onFocus = { onChannelFocused(channel) }
                )
            }
        }
    }
}

@Composable
private fun ChannelItem(
    channel: TvChannel,
    onClick: () -> Unit,
    onFocus: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(if (isFocused) 1.02f else 1f, tween(150), label = "chScale")
    val bgColor by animateColorAsState(
        if (isFocused) UltraTokens.Blue else Color.Transparent,
        tween(200),
        label = "chBg"
    )

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 6.dp, vertical = 2.dp)
            .scale(scale)
            .clip(RoundedCornerShape(10.dp))
            .background(bgColor)
            .onFocusChanged {
                isFocused = it.isFocused
                if (it.isFocused) onFocus()
            }
            .focusable()
            .onKeyEvent { ev ->
                if (ev.nativeKeyEvent.action == KeyEvent.ACTION_DOWN &&
                    (ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_DPAD_CENTER ||
                            ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_ENTER || ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_NUMPAD_ENTER)
                ) {
                    onClick()
                    true
                } else false
            }
            .padding(horizontal = 12.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(44.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(
                    if (isFocused) Color.White.copy(alpha = 0.15f)
                    else UltraTokens.SurfaceSelected
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
                    color = if (isFocused) Color.White else UltraTokens.TextSecondary,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }

        Spacer(Modifier.width(12.dp))

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = channel.name,
                color = if (isFocused) Color.White else UltraTokens.Text,
                fontSize = 14.sp,
                fontWeight = if (isFocused) FontWeight.Bold else FontWeight.Medium,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Spacer(Modifier.height(2.dp))
            Text(
                text = channel.group.ifEmpty { "General" },
                color = if (isFocused) Color.White.copy(alpha = 0.7f) else UltraTokens.Divider,
                fontSize = 11.sp,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }

        if (channel.type == "live") {
            Box(
                modifier = Modifier
                    .size(6.dp)
                    .clip(CircleShape)
                    .background(if (isFocused) Color.White else UltraTokens.Sports.copy(alpha = 0.6f))
            )
        }
    }
}

// ═══════════════════════════════════════════════════
//  PANE 3: PREVIEW & INFO
// ═══════════════════════════════════════════════════

@Composable
private fun PreviewPane(
    channel: TvChannel?,
    modifier: Modifier = Modifier
) {
    Crossfade(
        targetState = channel,
        animationSpec = tween(400),
        label = "preview"
    ) { ch ->
        if (ch == null) {
            Box(modifier = modifier, contentAlignment = Alignment.Center) {
                Text("Select a channel", color = UltraTokens.Divider, fontSize = 16.sp)
            }
            return@Crossfade
        }

        Column(modifier = modifier) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .aspectRatio(16f / 9f)
                    .clip(RoundedCornerShape(16.dp))
                    .background(Color.Black)
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(
                            Brush.radialGradient(
                                colors = listOf(
                                    UltraTokens.Blue.copy(alpha = 0.15f),
                                    Color.Black
                                )
                            )
                        )
                )

                if (!ch.logo.isNullOrEmpty()) {
                    AsyncImage(
                        model = ch.logo,
                        contentDescription = null,
                        contentScale = ContentScale.Fit,
                        modifier = Modifier
                            .fillMaxSize(0.5f)
                            .align(Alignment.Center)
                    )
                } else {
                    Text(
                        text = ch.name.take(3).uppercase(),
                        color = UltraTokens.Blue.copy(alpha = 0.4f),
                        fontSize = 64.sp,
                        fontWeight = FontWeight.Black,
                        modifier = Modifier.align(Alignment.Center)
                    )
                }

                Row(
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .padding(16.dp)
                        .clip(RoundedCornerShape(6.dp))
                        .background(UltraTokens.Live)
                        .padding(horizontal = 10.dp, vertical = 5.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        Modifier
                            .size(6.dp)
                            .clip(CircleShape)
                            .background(Color.White)
                    )
                    Spacer(Modifier.width(6.dp))
                    Text(
                        "LIVE",
                        color = Color.White,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 1.sp
                    )
                }

                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(80.dp)
                        .align(Alignment.BottomCenter)
                        .background(
                            Brush.verticalGradient(
                                colors = listOf(Color.Transparent, Color.Black.copy(alpha = 0.8f))
                            )
                        )
                )
            }

            Spacer(Modifier.height(28.dp))

            Column(modifier = Modifier.padding(horizontal = 16.dp)) {
                Text(
                    text = ch.group.ifEmpty { "General" }.uppercase(),
                    color = UltraTokens.Blue,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 2.sp
                )

                Spacer(Modifier.height(8.dp))

                Text(
                    text = ch.name,
                    color = Color.White,
                    fontSize = 28.sp,
                    fontWeight = FontWeight.Black,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )

                Spacer(Modifier.height(20.dp))

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier
                        .clip(RoundedCornerShape(8.dp))
                        .background(UltraTokens.SurfaceHover)
                        .padding(horizontal = 16.dp, vertical = 10.dp)
                ) {
                    Icon(
                        Icons.Rounded.PlayCircle,
                        contentDescription = null,
                        tint = UltraTokens.Blue,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(Modifier.width(10.dp))
                    Text(
                        text = "Press Sports to watch",
                        color = UltraTokens.TextSecondary,
                        fontSize = 14.sp
                    )
                }

                Spacer(Modifier.height(16.dp))

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(4.dp))
                            .background(UltraTokens.Sports.copy(alpha = 0.15f))
                            .padding(horizontal = 8.dp, vertical = 3.dp)
                    ) {
                        Text(
                            text = ch.type.uppercase(),
                            color = UltraTokens.Sports,
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Bold,
                            letterSpacing = 1.sp
                        )
                    }
                }
            }
        }
    }
}
