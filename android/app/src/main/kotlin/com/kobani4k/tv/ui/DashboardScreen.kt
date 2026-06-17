package com.kobani4k.tv.ui

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.kobani4k.tv.data.FirebaseRepository
import com.kobani4k.tv.data.TvChannel

// Theme Colors matching StreamVault
private val CanvasColor = Color(0xFF07111B)
private val CanvasElevated = Color(0xFF0B1622)
private val SurfaceColor = Color(0xFF0F1B29)
private val SurfaceElevatedColor = Color(0xFF162338)
private val BrandGold = Color(0xFFFFC766)
private val FocusedOutlineColor = Color(0xFFF5F7FB)
private val TextPrimary = Color(0xFFF5F7FB)
private val TextSecondary = Color(0xFFBBC6D8)

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun DashboardScreen(
    onChannelSelected: (TvChannel) -> Unit,
    onLogout: () -> Unit
) {
    var selectedCategory by remember { mutableStateOf("LIVE") }
    var allChannels by remember { mutableStateOf<List<TvChannel>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }

    val repository = remember { FirebaseRepository() }

    LaunchedEffect(Unit) {
        allChannels = repository.getChannels()
        isLoading = false
    }

    // Filter channels based on selection
    val filteredChannels = remember(allChannels, selectedCategory) {
        when (selectedCategory) {
            "LIVE" -> allChannels.filter { 
                it.type == "live" && !it.group.contains("sport", ignoreCase = true) 
            }
            "SPORTS" -> allChannels.filter { 
                it.group.contains("sport", ignoreCase = true) 
            }
            "MOVIES" -> allChannels.filter { 
                it.type == "movie" 
            }
            else -> emptyList()
        }
    }

    Row(
        modifier = Modifier
            .fillMaxSize()
            .background(CanvasColor)
    ) {
        // 1. LEFT SIDEBAR NAVIGATION (Static for perfect focus stability)
        Column(
            modifier = Modifier
                .width(260.dp)
                .fillMaxHeight()
                .background(SurfaceColor)
                .border(
                    width = 1.dp,
                    color = SurfaceElevatedColor,
                    shape = RoundedCornerShape(0.dp)
                )
                .padding(24.dp),
            horizontalAlignment = Alignment.Start
        ) {
            Text(
                text = "KOBANI 4K",
                color = BrandGold,
                fontWeight = FontWeight.Black,
                fontSize = 24.sp,
                letterSpacing = 3.sp,
                modifier = Modifier.padding(bottom = 40.dp, start = 12.dp)
            )

            SidebarItem(
                title = "LIVE TV",
                isSelected = selectedCategory == "LIVE",
                dotColor = Color(0xFFFF5C61) // Live Red
            ) { selectedCategory = "LIVE" }
            
            Spacer(modifier = Modifier.height(14.dp))
            
            SidebarItem(
                title = "MOVIES & VOD",
                isSelected = selectedCategory == "MOVIES",
                dotColor = Color(0xFF69A8FF) // Brand Blue
            ) { selectedCategory = "MOVIES" }
            
            Spacer(modifier = Modifier.height(14.dp))
            
            SidebarItem(
                title = "SPORTS LIVE",
                isSelected = selectedCategory == "SPORTS",
                dotColor = Color(0xFF4FD39A) // Sport Green
            ) { selectedCategory = "SPORTS" }
            
            Spacer(modifier = Modifier.height(14.dp))
            
            SidebarItem(
                title = "SETTINGS",
                isSelected = selectedCategory == "SETTINGS",
                dotColor = Color(0xFFFFC766) // Amber/Settings
            ) { selectedCategory = "SETTINGS" }
        }

        // 2. MAIN CONTENT AREA
        Column(
            modifier = Modifier
                .weight(1f)
                .fillMaxHeight()
                .padding(horizontal = 40.dp, vertical = 28.dp)
        ) {
            // Header Section
            val titleText = when (selectedCategory) {
                "LIVE" -> "LIVE STREAMING CHANNELS"
                "MOVIES" -> "MOVIES & VOD CATALOG"
                "SPORTS" -> "LIVE SPORTS NETWORKS"
                else -> "SETTINGS & UTILITIES"
            }
            Text(
                text = titleText,
                fontSize = 32.sp,
                color = TextPrimary,
                fontWeight = FontWeight.Black,
                letterSpacing = 2.sp
            )
            
            Spacer(modifier = Modifier.height(28.dp))

            if (isLoading) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "Synchronizing Playlists from Server...",
                        color = TextSecondary,
                        fontSize = 18.sp
                    )
                }
            } else if (selectedCategory == "SETTINGS") {
                // SYSTEM SETTINGS VIEW
                LazyVerticalGrid(
                    columns = GridCells.Fixed(2),
                    horizontalArrangement = Arrangement.spacedBy(20.dp),
                    verticalArrangement = Arrangement.spacedBy(20.dp),
                    modifier = Modifier.fillMaxSize()
                ) {
                    item {
                        SettingsCard(
                            title = "DATABASE CLOUD STATUS",
                            subtitle = "Firebase Database connection status",
                            value = "CONNECTED (Online)",
                            iconText = "DB"
                        )
                    }
                    item {
                        SettingsCard(
                            title = "PLAYLIST INDEX",
                            subtitle = "Total channels parsed from managed playlist",
                            value = "${allChannels.size} Channels Synced",
                            iconText = "CH"
                        )
                    }
                    item {
                        SettingsCard(
                            title = "SYSTEM DIAGNOSTICS",
                            subtitle = "Native TV Application build target version",
                            value = "v1.0.15 (Compose TV Engine)",
                            iconText = "SYS"
                        )
                    }
                    item {
                        SettingsCard(
                            title = "SIGN OUT / RESET CODE",
                            subtitle = "Return to 6-digit device activation code prompt",
                            value = "TAP TO DE-ACTIVATE",
                            iconText = "OUT",
                            isAction = true,
                            onClick = onLogout
                        )
                    }
                }
            } else {
                // CHANNELS GRID VIEW
                if (filteredChannels.isEmpty()) {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "No channels found in this category.",
                            color = TextSecondary,
                            fontSize = 16.sp
                        )
                    }
                } else {
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(4),
                        contentPadding = PaddingValues(bottom = 40.dp),
                        horizontalArrangement = Arrangement.spacedBy(20.dp),
                        verticalArrangement = Arrangement.spacedBy(20.dp),
                        modifier = Modifier.fillMaxSize()
                    ) {
                        items(filteredChannels.size) { index ->
                            val channel = filteredChannels[index]
                            ChannelCard(
                                channel = channel,
                                onClick = { onChannelSelected(channel) }
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
fun SidebarItem(
    title: String,
    isSelected: Boolean,
    dotColor: Color,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(targetValue = if (isFocused) 1.04f else 1.0f)

    Surface(
        onClick = onClick,
        shape = ClickableSurfaceDefaults.shape(shape = RoundedCornerShape(14.dp)),
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
                shape = RoundedCornerShape(14.dp)
            ),
            focusedBorder = Border(
                border = androidx.compose.foundation.BorderStroke(2.dp, FocusedOutlineColor),
                shape = RoundedCornerShape(14.dp)
            )
        ),
        modifier = Modifier
            .fillMaxWidth()
            .height(54.dp)
            .scale(scale)
            .onFocusChanged { isFocused = it.isFocused }
    ) {
        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .background(dotColor, RoundedCornerShape(999.dp))
            )
            Spacer(modifier = Modifier.width(16.dp))
            Text(
                text = title,
                fontSize = 15.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 1.sp
            )
        }
    }
}

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun ChannelCard(channel: TvChannel, onClick: () -> Unit) {
    var isFocused by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(targetValue = if (isFocused) 1.06f else 1.0f)

    Surface(
        onClick = onClick,
        shape = ClickableSurfaceDefaults.shape(shape = RoundedCornerShape(16.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = SurfaceColor,
            focusedContainerColor = SurfaceElevatedColor
        ),
        border = ClickableSurfaceDefaults.border(
            border = Border(
                border = androidx.compose.foundation.BorderStroke(1.dp, SurfaceElevatedColor),
                shape = RoundedCornerShape(16.dp)
            ),
            focusedBorder = Border(
                border = androidx.compose.foundation.BorderStroke(2.dp, BrandGold),
                shape = RoundedCornerShape(16.dp)
            )
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.0f), // Handled by scale modifier
        modifier = Modifier
            .fillMaxWidth()
            .aspectRatio(16f / 10f)
            .scale(scale)
            .onFocusChanged { isFocused = it.isFocused }
    ) {
        Box(modifier = Modifier.fillMaxSize()) {
            if (!channel.logo.isNullOrEmpty()) {
                AsyncImage(
                    model = channel.logo,
                    contentDescription = channel.name,
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(14.dp)
                        .align(Alignment.Center)
                )
                // Semi-translucent footer overlay for title readability
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(30.dp)
                        .background(Color.Black.copy(alpha = 0.7f))
                        .align(Alignment.BottomCenter),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = channel.name,
                        color = Color.White,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1,
                        modifier = Modifier.padding(horizontal = 8.dp)
                    )
                }
            } else {
                // Colorful text fallback gradient card
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(
                            Brush.linearGradient(
                                colors = listOf(SurfaceElevatedColor, CanvasColor)
                            )
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = channel.name,
                        color = TextPrimary,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(12.dp)
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun SettingsCard(
    title: String,
    subtitle: String,
    value: String,
    iconText: String,
    isAction: Boolean = false,
    onClick: () -> Unit = {}
) {
    var isFocused by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(targetValue = if (isFocused) 1.03f else 1.0f)

    Surface(
        onClick = onClick,
        enabled = isAction,
        shape = ClickableSurfaceDefaults.shape(shape = RoundedCornerShape(20.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = SurfaceColor,
            focusedContainerColor = TextPrimary,
            contentColor = TextPrimary,
            focusedContentColor = CanvasColor
        ),
        border = ClickableSurfaceDefaults.border(
            border = Border(
                border = androidx.compose.foundation.BorderStroke(1.dp, SurfaceElevatedColor),
                shape = RoundedCornerShape(20.dp)
            ),
            focusedBorder = Border(
                border = androidx.compose.foundation.BorderStroke(2.dp, FocusedOutlineColor),
                shape = RoundedCornerShape(20.dp)
            )
        ),
        modifier = Modifier
            .fillMaxWidth()
            .height(110.dp)
            .scale(scale)
            .onFocusChanged { isFocused = it.isFocused }
    ) {
        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 20.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(52.dp)
                    .background(
                        if (isFocused) CanvasColor.copy(alpha = 0.1f) else SurfaceElevatedColor,
                        RoundedCornerShape(12.dp)
                    ),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = iconText,
                    fontWeight = FontWeight.Bold,
                    color = if (isFocused) CanvasColor else BrandGold,
                    fontSize = 14.sp
                )
            }
            Spacer(modifier = Modifier.width(16.dp))
            Column(
                verticalArrangement = Arrangement.Center
            ) {
                Text(
                    text = title,
                    fontWeight = FontWeight.Bold,
                    fontSize = 14.sp,
                    color = if (isFocused) CanvasColor else BrandGold
                )
                Text(
                    text = subtitle,
                    fontSize = 11.sp,
                    color = if (isFocused) CanvasColor.copy(alpha = 0.7f) else TextSecondary,
                    maxLines = 1
                )
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    text = value,
                    fontWeight = FontWeight.Black,
                    fontSize = 13.sp,
                    color = if (isFocused) CanvasColor else TextPrimary
                )
            }
        }
    }
}
