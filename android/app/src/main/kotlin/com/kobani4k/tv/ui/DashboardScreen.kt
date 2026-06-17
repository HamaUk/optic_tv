package com.kobani4k.tv.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.tv.foundation.lazy.grid.TvGridCells
import androidx.tv.foundation.lazy.grid.TvLazyVerticalGrid
import androidx.tv.material3.*
import com.kobani4k.tv.data.FirebaseRepository

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun DashboardScreen(onChannelSelected: (String) -> Unit) {
    var selectedCategory by remember { mutableStateOf("LIVE") }
    var channels by remember { mutableStateOf<List<String>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    
    val repository = remember { FirebaseRepository() }

    LaunchedEffect(Unit) {
        channels = repository.getChannels()
        isLoading = false
    }

    Row(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.horizontalGradient(
                    colors = listOf(Color(0xFF0F0F0F), Color(0xFF1A1A1A))
                )
            )
    ) {
        // Frosted Glass Sidebar Navigation
        NavigationDrawer(
            drawerContent = {
                Column(
                    modifier = Modifier
                        .fillMaxHeight()
                        .background(Color.Black.copy(alpha = 0.5f))
                        .border(1.dp, Brush.verticalGradient(listOf(Color.White.copy(alpha=0.1f), Color.Transparent)))
                        .padding(24.dp),
                    verticalArrangement = Arrangement.Center
                ) {
                    Text(
                        text = "KOBANI 4K",
                        color = Color(0xFFFFD700),
                        fontWeight = FontWeight.Black,
                        fontSize = 18.sp,
                        letterSpacing = 2.sp,
                        modifier = Modifier.padding(bottom = 60.dp, start = 16.dp)
                    )
                    
                    SidebarItem("LIVE", selectedCategory == "LIVE") { selectedCategory = "LIVE" }
                    Spacer(modifier = Modifier.height(16.dp))
                    SidebarItem("MOVIES", selectedCategory == "MOVIES") { selectedCategory = "MOVIES" }
                    Spacer(modifier = Modifier.height(16.dp))
                    SidebarItem("SPORTS", selectedCategory == "SPORTS") { selectedCategory = "SPORTS" }
                    Spacer(modifier = Modifier.height(16.dp))
                    SidebarItem("SETTINGS", selectedCategory == "SETTINGS") { selectedCategory = "SETTINGS" }
                }
            }
        ) {
            // Main Content Area
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 48.dp, vertical = 32.dp)
            ) {
                Text(
                    text = selectedCategory,
                    style = MaterialTheme.typography.displaySmall,
                    color = Color.White,
                    fontWeight = FontWeight.Black,
                    letterSpacing = 4.sp
                )
                Spacer(modifier = Modifier.height(32.dp))
                
                if (isLoading) {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Text("Loading Channels...", color = Color.White54)
                    }
                } else {
                    TvLazyVerticalGrid(
                        columns = TvGridCells.Fixed(4),
                        contentPadding = PaddingValues(bottom = 64.dp),
                        horizontalArrangement = Arrangement.spacedBy(20.dp),
                        verticalArrangement = Arrangement.spacedBy(20.dp),
                        modifier = Modifier.fillMaxSize()
                    ) {
                        items(channels.size) { index ->
                            ChannelCard(
                                name = channels[index],
                                onClick = { onChannelSelected(channels[index]) }
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
fun SidebarItem(title: String, isSelected: Boolean, onClick: () -> Unit) {
    Surface(
        onClick = onClick,
        shape = ClickableSurfaceDefaults.shape(shape = RoundedCornerShape(12.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = if (isSelected) Color(0xFFFFD700).copy(alpha = 0.15f) else Color.Transparent,
            focusedContainerColor = Color.White,
            contentColor = if (isSelected) Color(0xFFFFD700) else Color.White54,
            focusedContentColor = Color.Black
        ),
        modifier = Modifier.width(180.dp)
    ) {
        Box(
            modifier = Modifier.padding(16.dp),
            contentAlignment = Alignment.CenterStart
        ) {
            Text(
                text = title,
                fontWeight = FontWeight.Bold,
                letterSpacing = 2.sp
            )
        }
    }
}

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun ChannelCard(name: String, onClick: () -> Unit) {
    Surface(
        onClick = onClick,
        shape = ClickableSurfaceDefaults.shape(shape = RoundedCornerShape(16.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = Color.White.copy(alpha = 0.05f),
            focusedContainerColor = Color.White
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.05f),
        modifier = Modifier
            .fillMaxWidth()
            .aspectRatio(16f / 9f) // Standard TV aspect ratio
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.radialGradient(
                        colors = listOf(Color.White.copy(alpha = 0.1f), Color.Transparent)
                    )
                ),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = name,
                fontWeight = FontWeight.Bold,
                fontSize = 18.sp,
                modifier = Modifier.padding(16.dp)
            )
        }
    }
}
