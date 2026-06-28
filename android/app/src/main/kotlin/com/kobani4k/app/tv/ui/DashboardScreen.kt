package com.kobani4k.app.tv.ui

import android.widget.TextClock
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.kobani4k.app.tv.data.PocketBaseRepository
import com.kobani4k.app.tv.data.TvChannel
import com.kobani4k.app.tv.data.TvChannelGroup
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay

// ==========================================
// THEME COLORS (Premium Modern Dark)
// ==========================================
val BgDark = Color(0xFF0A0A0F)
val PanelDark = Color(0xFF14141E)
val AccentPrimary = Color(0xFF0EA5E9) // A beautiful, premium Sky Blue / Cyan (Mix of Smarters & Modern)
val TextPrimary = Color(0xFFFFFFFF)
val TextSecondary = Color(0xFF94A3B8)

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

    val focusRequester = remember { FocusRequester() }
    LaunchedEffect(isLoading, categories) {
        if (!isLoading && categories.isNotEmpty()) {
            delay(100)
            runCatching { focusRequester.requestFocus() }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BgDark)
    ) {
        // ==========================================
        // 1. TOP HEADER BAR
        // ==========================================
        TopHeaderBar(onLogout = onLogout)

        if (isLoading) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = AccentPrimary)
            }
        } else {
            // ==========================================
            // 2. MAIN 3-PANE LAYOUT
            // ==========================================
            Row(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 24.dp, vertical = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(24.dp)
            ) {
                
                // PANE 1: CATEGORIES
                CategoryListPane(
                    categories = categories,
                    selectedCategory = selectedCategory,
                    onCategorySelected = { selectedCategory = it },
                    focusRequester = focusRequester,
                    channelCounts = allChannels.groupingBy { it.group.ifEmpty { "General" } }.eachCount(),
                    modifier = Modifier.width(280.dp).fillMaxHeight()
                )

                // PANE 2: CHANNEL LIST
                ChannelListPane(
                    channels = filteredChannels,
                    onChannelFocused = { focusedChannel = it },
                    onChannelSelected = onChannelSelected,
                    modifier = Modifier.width(360.dp).fillMaxHeight()
                )

                // PANE 3: PREVIEW & INFO
                PreviewPane(
                    channel = focusedChannel ?: filteredChannels.firstOrNull(),
                    modifier = Modifier.weight(1f).fillMaxHeight()
                )
            }
        }
    }
}

// ==========================================
// HEADER BAR COMPONENT
// ==========================================
@Composable
fun TopHeaderBar(onLogout: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(PanelDark.copy(alpha = 0.6f))
            .padding(horizontal = 32.dp, vertical = 16.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Logo & Title
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Rounded.LiveTv, contentDescription = "Logo", tint = AccentPrimary, modifier = Modifier.size(32.dp))
            Spacer(Modifier.width(12.dp))
            Text("PREMIUM", color = TextPrimary, fontSize = 20.sp, fontWeight = FontWeight.Black, letterSpacing = 2.sp)
            Text(" TV", color = AccentPrimary, fontSize = 20.sp, fontWeight = FontWeight.Black, letterSpacing = 2.sp)
            
            Spacer(Modifier.width(24.dp))
            Box(Modifier.width(2.dp).height(24.dp).background(TextSecondary.copy(0.3f)))
            Spacer(Modifier.width(24.dp))
            
            Text("LIVE", color = TextSecondary, fontSize = 16.sp, fontWeight = FontWeight.Medium)
        }

        // Clock & Action Icons
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(24.dp)) {
            // TV System Clock
            AndroidView(
                factory = { ctx ->
                    TextClock(ctx).apply {
                        format12Hour = "hh:mm a  |  MMM dd, yyyy"
                        format24Hour = "HH:mm  |  MMM dd, yyyy"
                        textSize = 16f
                        setTextColor(android.graphics.Color.parseColor("#94A3B8"))
                        typeface = android.graphics.Typeface.DEFAULT_BOLD
                    }
                }
            )

            Icon(Icons.Rounded.Search, contentDescription = "Search", tint = TextPrimary, modifier = Modifier.size(24.dp))
            Icon(Icons.Rounded.Settings, contentDescription = "Settings", tint = TextPrimary, modifier = Modifier.size(24.dp).clickable { onLogout() })
        }
    }
}

// ==========================================
// PANE 1: CATEGORY LIST
// ==========================================
@Composable
fun CategoryListPane(
    categories: List<String>,
    selectedCategory: String?,
    onCategorySelected: (String) -> Unit,
    focusRequester: FocusRequester,
    channelCounts: Map<String, Int>,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier) {
        // Search bar mock
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(8.dp))
                .background(PanelDark)
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(Icons.Rounded.Search, contentDescription = null, tint = TextSecondary, modifier = Modifier.size(20.dp))
            Spacer(Modifier.width(12.dp))
            Text("Search in categories...", color = TextSecondary, fontSize = 14.sp)
        }

        Spacer(Modifier.height(16.dp))

        LazyColumn(
            contentPadding = PaddingValues(bottom = 24.dp),
            modifier = Modifier.fillMaxSize().focusRestorer()
        ) {
            items(categories) { category ->
                val isSelected = selectedCategory == category
                CategoryRowItem(
                    title = category,
                    count = channelCounts[category] ?: 0,
                    isSelected = isSelected,
                    onFocus = { onCategorySelected(category) },
                    modifier = if (category == categories.firstOrNull()) Modifier.focusRequester(focusRequester) else Modifier
                )
                Box(modifier = Modifier.fillMaxWidth().height(1.dp).background(TextSecondary.copy(alpha = 0.1f)))
            }
        }
    }
}

@Composable
fun CategoryRowItem(title: String, count: Int, isSelected: Boolean, onFocus: () -> Unit, modifier: Modifier = Modifier) {
    var isFocused by remember { mutableStateOf(false) }
    
    // Smooth transition colors
    val bgColor by animateColorAsState(if (isFocused) AccentPrimary else if (isSelected) PanelDark else Color.Transparent)
    val contentColor by animateColorAsState(if (isFocused) Color.White else if (isSelected) AccentPrimary else TextSecondary)

    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp))
            .background(bgColor)
            .focusable()
            .onFocusChanged { 
                isFocused = it.isFocused
                if (it.isFocused) onFocus()
            }
            .padding(horizontal = 16.dp, vertical = 18.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = title.uppercase(),
            color = contentColor,
            fontSize = 14.sp,
            fontWeight = if (isSelected || isFocused) FontWeight.Bold else FontWeight.Medium,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.weight(1f)
        )
        Text(
            text = count.toString(),
            color = if (isFocused) Color.White else TextSecondary,
            fontSize = 14.sp,
            fontWeight = FontWeight.Bold
        )
    }
}

// ==========================================
// PANE 2: CHANNEL LIST
// ==========================================
@Composable
fun ChannelListPane(
    channels: List<TvChannel>,
    onChannelFocused: (TvChannel) -> Unit,
    onChannelSelected: (TvChannel) -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .background(PanelDark)
    ) {
        // Pane Header
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(AccentPrimary.copy(alpha = 0.1f))
                .padding(horizontal = 16.dp, vertical = 12.dp)
        ) {
            Text("CHANNELS", color = AccentPrimary, fontSize = 12.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.sp)
        }

        LazyColumn(
            modifier = Modifier.fillMaxSize().focusRestorer(),
            contentPadding = PaddingValues(vertical = 8.dp)
        ) {
            items(channels, key = { it.url }) { channel ->
                ChannelRowItem(
                    channel = channel,
                    onClick = { onChannelSelected(channel) },
                    onFocus = { onChannelFocused(channel) }
                )
            }
        }
    }
}

@Composable
fun ChannelRowItem(channel: TvChannel, onClick: () -> Unit, onFocus: () -> Unit) {
    var isFocused by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(if (isFocused) 1.02f else 1f, tween(150))
    val bgColor by animateColorAsState(if (isFocused) AccentPrimary else Color.Transparent)

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .scale(scale)
            .background(bgColor)
            .clickable(onClick = onClick)
            .focusable()
            .onFocusChanged { 
                isFocused = it.isFocused
                if (it.isFocused) onFocus()
            }
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Channel Logo
        Box(
            modifier = Modifier
                .size(48.dp)
                .clip(RoundedCornerShape(6.dp))
                .background(Color.White.copy(if (isFocused) 0.2f else 0.05f))
                .padding(4.dp),
            contentAlignment = Alignment.Center
        ) {
            if (!channel.logo.isNullOrEmpty()) {
                AsyncImage(
                    model = channel.logo,
                    contentDescription = null,
                    contentScale = ContentScale.Fit,
                    modifier = Modifier.fillMaxSize()
                )
            } else {
                Text(channel.name.take(2).uppercase(), color = Color.White, fontSize = 14.sp, fontWeight = FontWeight.Bold)
            }
        }

        Spacer(Modifier.width(16.dp))

        // Channel Info
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = channel.name,
                color = TextPrimary,
                fontSize = 16.sp,
                fontWeight = if (isFocused) FontWeight.Bold else FontWeight.Medium,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Spacer(Modifier.height(4.dp))
            Text(
                text = "Live Broadcast", // Fallback since no EPG
                color = if (isFocused) Color.White.copy(0.8f) else TextSecondary,
                fontSize = 12.sp,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}

// ==========================================
// PANE 3: PREVIEW & INFO
// ==========================================
@Composable
fun PreviewPane(channel: TvChannel?, modifier: Modifier = Modifier) {
    Crossfade(targetState = channel, animationSpec = tween(400)) { ch ->
        if (ch == null) return@Crossfade

        Column(modifier = modifier) {
            
            // 1. Fake Video Player / Hero Image Box (16:9)
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .aspectRatio(16f / 9f)
                    .clip(RoundedCornerShape(12.dp))
                    .background(Color.Black)
            ) {
                // Background Glow
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Brush.radialGradient(listOf(AccentPrimary.copy(alpha = 0.2f), Color.Black)))
                )
                
                // Big Logo Placeholder for Video
                if (!ch.logo.isNullOrEmpty()) {
                    AsyncImage(
                        model = ch.logo,
                        contentDescription = null,
                        contentScale = ContentScale.Fit,
                        modifier = Modifier
                            .fillMaxSize(0.6f)
                            .align(Alignment.Center)
                    )
                }

                // "LIVE" Badge on the player
                Row(
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .padding(16.dp)
                        .clip(RoundedCornerShape(4.dp))
                        .background(Color.Red)
                        .padding(horizontal = 8.dp, vertical = 4.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(Modifier.size(6.dp).clip(CircleShape).background(Color.White))
                    Spacer(Modifier.width(6.dp))
                    Text("LIVE", color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                }
            }

            Spacer(Modifier.height(32.dp))

            // 2. Channel Details (No EPG)
            Column(modifier = Modifier.padding(horizontal = 16.dp)) {
                // Category Tag
                Text(
                    text = ch.group.ifEmpty { "General" }.uppercase(),
                    color = AccentPrimary,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 1.sp
                )
                
                Spacer(Modifier.height(8.dp))
                
                // Channel Name
                Text(
                    text = ch.name,
                    color = TextPrimary,
                    fontSize = 32.sp,
                    fontWeight = FontWeight.Black,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
                
                Spacer(Modifier.height(24.dp))

                // Info / Instructions
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Rounded.PlayCircle, contentDescription = null, tint = TextSecondary, modifier = Modifier.size(24.dp))
                    Spacer(Modifier.width(12.dp))
                    Text(
                        text = "Press OK or Center button to watch in full screen.",
                        color = TextSecondary,
                        fontSize = 16.sp
                    )
                }
            }
        }
    }
}
