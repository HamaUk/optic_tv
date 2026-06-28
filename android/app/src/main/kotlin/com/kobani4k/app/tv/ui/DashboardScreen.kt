package com.kobani4k.app.tv.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.focusRestorer
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.animateColorAsState
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.kobani4k.app.tv.data.PocketBaseRepository
import com.kobani4k.app.tv.data.TvChannel
import com.kobani4k.app.tv.data.TvChannelGroup
import com.kobani4k.app.tv.ui.theme.UltraTokens
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import com.kobani4k.app.tv.ui.theme.ultraCardColors

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

    val focusRequester = remember { FocusRequester() }

    val categories = remember(allChannels, allGroups) {
        if (allGroups.isNotEmpty()) {
            allGroups.map { it.name }
        } else {
            allChannels.map { it.group.ifEmpty { "General" } }.distinct().sorted()
        }
    }

    LaunchedEffect(isLoading, categories) {
        if (!isLoading && categories.isNotEmpty()) {
            try {
                focusRequester.requestFocus()
            } catch (e: Exception) {}
        }
    }
    
    var selectedCategory by rememberSaveable { mutableStateOf<String?>(null) }
    
    LaunchedEffect(categories) {
        if (categories.isNotEmpty() && selectedCategory == null) {
            selectedCategory = categories.first()
        }
    }

    val filteredChannels = remember(allChannels, selectedCategory) {
        allChannels.filter { it.group.ifEmpty { "General" } == selectedCategory }
    }

    Row(
        Modifier
            .fillMaxSize()
            .background(Color(0xFF0F0E17))
    ) {
        if (isLoading) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = UltraTokens.Accent)
            }
        } else {
            // Sidebar
            Column(
                modifier = Modifier
                    .width(280.dp)
                    .fillMaxHeight()
                    .background(Color(0xFF0C0B10))
                    .padding(vertical = 32.dp)
            ) {
                Text(
                    text = "DISCOVER",
                    color = UltraTokens.Fg3,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Black,
                    letterSpacing = 2.sp,
                    modifier = Modifier.padding(start = 32.dp, end = 32.dp, bottom = 24.dp)
                )
                
                LazyColumn(
                    contentPadding = PaddingValues(start = 16.dp, end = 16.dp, bottom = 24.dp),
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    items(categories) { category ->
                        CategoryItem(
                            title = category,
                            isSelected = selectedCategory == category,
                            onClick = { selectedCategory = category },
                            onFocused = { selectedCategory = category },
                            modifier = if (category == categories.firstOrNull()) Modifier.focusRequester(focusRequester) else Modifier
                        )
                    }
                    item {
                        Spacer(modifier = Modifier.height(32.dp))
                        CategoryItem(
                            title = "Settings",
                            isSelected = selectedCategory == "Settings",
                            onClick = { selectedCategory = "Settings" },
                            onFocused = { selectedCategory = "Settings" }
                        )
                    }
                }
            }

            // Main Content Area
            Column(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight()
                    .padding(horizontal = 32.dp, vertical = 24.dp)
            ) {
                Text(
                    text = selectedCategory ?: "All Channels",
                    color = UltraTokens.Fg,
                    fontSize = 32.sp,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(bottom = 24.dp)
                )

                if (selectedCategory == "Settings") {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .weight(1f),
                        contentAlignment = Alignment.Center
                    ) {
                        Button(
                            onClick = onLogout,
                            shape = ButtonDefaults.shape(RoundedCornerShape(12.dp)),
                            colors = ButtonDefaults.colors(
                                containerColor = UltraTokens.Surface2,
                                contentColor = UltraTokens.Fg,
                                focusedContainerColor = UltraTokens.Accent,
                                focusedContentColor = Color.White
                            ),
                            modifier = Modifier.padding(32.dp)
                        ) {
                            Text(
                                "Logout from TV",
                                fontSize = 18.sp,
                                fontWeight = FontWeight.SemiBold,
                                modifier = Modifier.padding(horizontal = 24.dp, vertical = 8.dp)
                            )
                        }
                    }
                } else {
                    LazyVerticalGrid(
                        modifier = Modifier.focusRestorer(),
                        columns = GridCells.Adaptive(minSize = 160.dp),
                        horizontalArrangement = Arrangement.spacedBy(16.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp),
                        contentPadding = PaddingValues(bottom = 32.dp)
                    ) {
                        items(
                            items = filteredChannels,
                            key = { it.url }
                        ) { channel ->
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
fun CategoryItem(
    title: String,
    isSelected: Boolean,
    onClick: () -> Unit,
    onFocused: () -> Unit,
    modifier: Modifier = Modifier
) {
    var isFocused by remember { mutableStateOf(false) }
    
    val animatedScale by animateFloatAsState(if (isFocused) 1.05f else 1f)
    val animatedBg by animateColorAsState(if (isFocused) UltraTokens.Accent else if (isSelected) Color.White.copy(alpha = 0.1f) else Color.Transparent)
    val animatedContent by animateColorAsState(if (isFocused) Color.White else if (isSelected) UltraTokens.Fg else UltraTokens.Fg3)

    Box(
        modifier = modifier
            .fillMaxWidth()
            .scale(animatedScale)
            .clip(RoundedCornerShape(50))
            .background(animatedBg)
            .clickable(onClick = onClick)
            .focusable()
            .onFocusChanged { state ->
                isFocused = state.isFocused
                if (state.isFocused) {
                    onFocused()
                }
            }
            .padding(horizontal = 16.dp, vertical = 12.dp)
    ) {
        Text(
            text = title,
            color = animatedContent,
            fontSize = 16.sp,
            fontWeight = if (isSelected || isFocused) FontWeight.Bold else FontWeight.Medium,
            letterSpacing = 0.5.sp,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
    }
}

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun ChannelCard(
    channel: TvChannel,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    val animatedScale by animateFloatAsState(if (isFocused) 1.08f else 1f)

    Card(
        onClick = onClick,
        shape = CardDefaults.shape(RoundedCornerShape(12.dp)),
        colors = ultraCardColors(
            containerColor = Color(0xFF1A1A24),
            focusedContainerColor = Color(0xFF1A1A24)
        ),
        border = CardDefaults.border(
            focusedBorder = Border(
                border = androidx.compose.foundation.BorderStroke(3.dp, UltraTokens.Accent),
                shape = RoundedCornerShape(12.dp)
            )
        ),
        modifier = Modifier
            .fillMaxWidth()
            .aspectRatio(16f / 9f)
            .scale(animatedScale)
            .onFocusChanged { isFocused = it.isFocused }
    ) {
        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .padding(16.dp),
                contentAlignment = Alignment.Center
            ) {
                if (!channel.logo.isNullOrEmpty()) {
                    AsyncImage(
                        model = channel.logo,
                        contentDescription = channel.name,
                        contentScale = ContentScale.Fit,
                        modifier = Modifier.fillMaxSize()
                    )
                } else {
                    Text(
                        text = channel.name.take(1).uppercase(),
                        color = UltraTokens.Fg3,
                        fontSize = 48.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(
                        if (isFocused) UltraTokens.GradientAccent 
                        else Brush.verticalGradient(listOf(Color.Transparent, Color(0xCC000000)))
                    )
                    .padding(vertical = 12.dp, horizontal = 16.dp),
                contentAlignment = Alignment.CenterStart
            ) {
                Text(
                    text = channel.name,
                    color = Color.White,
                    fontSize = 15.sp,
                    fontWeight = if (isFocused) FontWeight.Bold else FontWeight.Medium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
    }
}
