package com.kobani4k.app.tv.ui

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.rounded.Movie
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedButton
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.tv.material3.Text
import coil.compose.AsyncImage
import com.kobani4k.app.tv.data.TmdbMovie
import com.kobani4k.app.tv.data.TmdbService
import com.kobani4k.app.tv.data.TvChannel
import com.kobani4k.app.tv.ui.theme.UltraTokens

@Composable
fun MoviesGridScreen(
    channels: List<TvChannel>,
    onMovieClick: (TvChannel) -> Unit
) {
    val tmdbService = remember { TmdbService() }
    val groupedChannels = remember(channels) {
        channels.groupBy { if (it.group.isBlank()) "Movies" else it.group }
    }

    // Default to the first channel
    var focusedChannel by remember { mutableStateOf<TvChannel?>(channels.firstOrNull()) }
    var focusedTmdbMovie by remember { mutableStateOf<TmdbMovie?>(null) }
    
    // Fetch TMDB data for the focused channel for the hero section
    LaunchedEffect(focusedChannel) {
        focusedChannel?.let { channel ->
            focusedTmdbMovie = tmdbService.findMovie(channel.name)
        }
    }

    val listState = rememberLazyListState()

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(UltraTokens.Background)
    ) {
        // Hero Section Background + Overlay
        MovieHeroSection(
            channel = focusedChannel,
            tmdbMovie = focusedTmdbMovie,
            onPlayClick = { focusedChannel?.let { onMovieClick(it) } }
        )

        // Scrollable Rows
        LazyColumn(
            state = listState,
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(top = 280.dp, bottom = 48.dp) // Push down past hero
        ) {
            groupedChannels.forEach { (groupName, groupChannels) ->
                item(key = groupName) {
                    MovieContentRow(
                        title = groupName,
                        channels = groupChannels,
                        tmdbService = tmdbService,
                        onItemFocus = { channel ->
                            focusedChannel = channel
                        },
                        onItemClick = { channel ->
                            onMovieClick(channel)
                        }
                    )
                }
            }
        }
        
        // Top Gradient overlay
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(120.dp)
                .background(
                    brush = Brush.verticalGradient(
                        colors = listOf(UltraTokens.Background, Color.Transparent)
                    )
                )
        )
    }
}

@Composable
fun MovieHeroSection(
    channel: TvChannel?,
    tmdbMovie: TmdbMovie?,
    onPlayClick: () -> Unit
) {
    val configuration = LocalConfiguration.current
    val heroHeight = (configuration.screenHeightDp * 0.55f).dp

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(heroHeight)
    ) {
        // Background Image
        val backdropUrl = tmdbMovie?.backdropUrl ?: tmdbMovie?.posterUrl ?: channel?.logo
        if (!backdropUrl.isNullOrEmpty()) {
            AsyncImage(
                model = backdropUrl,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .fillMaxSize()
                    .blur(10.dp)
            )
        } else {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(UltraTokens.Surface)
            )
        }

        // Gradient overlay
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        colors = listOf(
                            Color.Transparent,
                            UltraTokens.Background.copy(alpha = 0.5f),
                            UltraTokens.Background
                        )
                    )
                )
        )

        // Content
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 24.dp, vertical = 10.dp)
                .padding(top = 30.dp),
            verticalArrangement = Arrangement.Bottom
        ) {
            val title = tmdbMovie?.title ?: channel?.name ?: ""
            Text(
                text = title,
                fontSize = 32.sp,
                fontWeight = FontWeight.Bold,
                color = UltraTokens.Text,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )

            Spacer(modifier = Modifier.height(8.dp))

            Row(
                horizontalArrangement = Arrangement.spacedBy(7.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (tmdbMovie != null && tmdbMovie.rating > 0) {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.Star,
                            contentDescription = null,
                            tint = UltraTokens.Movie, // using movie token yellow
                            modifier = Modifier.size(16.dp)
                        )
                        Text(
                            text = String.format("%.1f", tmdbMovie.rating),
                            color = UltraTokens.Text,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                    Text("-", color = UltraTokens.TextSecondary, fontSize = 14.sp)
                }

                val year = tmdbMovie?.releaseDate?.take(4)
                if (!year.isNullOrEmpty()) {
                    Text(
                        text = year,
                        color = UltraTokens.TextSecondary,
                        fontSize = 14.sp
                    )
                }
            }

            Spacer(modifier = Modifier.height(7.dp))

            Text(
                text = tmdbMovie?.overview ?: "No description available.",
                color = UltraTokens.TextSecondary,
                maxLines = 3,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.widthIn(max = 600.dp),
                fontSize = 15.sp
            )

            Spacer(modifier = Modifier.height(16.dp))

            Row(
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                // Play button
                var playFocused by remember { mutableStateOf(false) }
                val playBgColor = if (playFocused) Color.White else Color.Transparent
                val playContentColor = if (playFocused) Color.Black else Color.White
                
                Box(
                    modifier = Modifier
                        .onFocusChanged { playFocused = it.isFocused }
                        .clip(RoundedCornerShape(8.dp))
                        .background(playBgColor)
                        .border(1.dp, Color.White, RoundedCornerShape(8.dp))
                        .clickable { onPlayClick() }
                        .focusable()
                        .padding(horizontal = 20.dp, vertical = 10.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.PlayArrow, contentDescription = null, tint = playContentColor, modifier = Modifier.size(20.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Play", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = playContentColor)
                    }
                }
                
                // Info button
                var infoFocused by remember { mutableStateOf(false) }
                val infoBgColor = if (infoFocused) Color.White else Color.Transparent
                val infoContentColor = if (infoFocused) Color.Black else Color.White
                
                Box(
                    modifier = Modifier
                        .onFocusChanged { infoFocused = it.isFocused }
                        .clip(RoundedCornerShape(8.dp))
                        .background(infoBgColor)
                        .border(1.dp, Color.White, RoundedCornerShape(8.dp))
                        .clickable { /* Not implemented yet */ }
                        .focusable()
                        .padding(horizontal = 20.dp, vertical = 10.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.Info, contentDescription = null, tint = infoContentColor, modifier = Modifier.size(20.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Info", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = infoContentColor)
                    }
                }
            }
        }
    }
}

@Composable
fun MovieContentRow(
    title: String,
    channels: List<TvChannel>,
    tmdbService: TmdbService,
    onItemFocus: (TvChannel) -> Unit,
    onItemClick: (TvChannel) -> Unit
) {
    val listState = rememberLazyListState()

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 12.dp)
    ) {
        Text(
            text = title,
            fontSize = 20.sp,
            fontWeight = FontWeight.Bold,
            color = UltraTokens.Text,
            modifier = Modifier.padding(horizontal = 24.dp)
        )

        Spacer(modifier = Modifier.height(12.dp))

        LazyRow(
            state = listState,
            contentPadding = PaddingValues(horizontal = 24.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp),
            modifier = Modifier.fillMaxWidth()
        ) {
            items(channels) { channel ->
                MoviePosterCard(
                    channel = channel,
                    tmdbService = tmdbService,
                    onFocus = { onItemFocus(channel) },
                    onClick = { onItemClick(channel) }
                )
            }
        }
    }
}

@Composable
fun MoviePosterCard(
    channel: TvChannel,
    tmdbService: TmdbService,
    onFocus: () -> Unit,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    var tmdbMovie by remember { mutableStateOf<TmdbMovie?>(null) }
    var isLoading by remember { mutableStateOf(true) }

    LaunchedEffect(channel.name) {
        tmdbMovie = tmdbService.findMovie(channel.name)
        isLoading = false
    }

    val scale by animateFloatAsState(if (isFocused) 1.05f else 1f, label = "scale")
    
    // Card container
    Box(
        modifier = Modifier
            .width(120.dp)
            .height(180.dp)
            .scale(scale)
            .then(
                if (isFocused) {
                    Modifier.border(
                        width = 3.dp,
                        color = UltraTokens.Accent,
                        shape = RoundedCornerShape(8.dp)
                    )
                } else Modifier
            )
            .clip(RoundedCornerShape(8.dp))
            .background(UltraTokens.Surface)
            .onFocusChanged { 
                isFocused = it.isFocused 
                if (it.isFocused) {
                    onFocus()
                }
            }
            .clickable { onClick() }
            .focusable(),
        contentAlignment = Alignment.Center
    ) {
        // Poster Image
        if (tmdbMovie?.posterUrl != null) {
            AsyncImage(
                model = tmdbMovie!!.posterUrl,
                contentDescription = channel.name,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize()
            )
        } else if (!channel.logo.isNullOrEmpty()) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                AsyncImage(
                    model = channel.logo,
                    contentDescription = channel.name,
                    contentScale = ContentScale.Fit,
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(16.dp)
                )
                
                // Fallback title below logo if no TMDB
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .align(Alignment.BottomCenter)
                        .background(Color.Black.copy(0.6f))
                        .padding(8.dp)
                ) {
                    Text(
                        text = channel.name,
                        color = Color.White,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.SemiBold,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            }
        } else {
            Column(
                modifier = Modifier.padding(8.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Icon(
                    imageVector = Icons.Rounded.Movie,
                    contentDescription = null,
                    tint = UltraTokens.TextSecondary,
                    modifier = Modifier.size(32.dp)
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = channel.name,
                    color = Color.White,
                    fontSize = 12.sp,
                    maxLines = 3,
                    overflow = TextOverflow.Ellipsis,
                    textAlign = TextAlign.Center
                )
            }
        }

        // Rating badge
        if (tmdbMovie != null && tmdbMovie!!.rating > 0) {
            Box(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(6.dp)
                    .background(
                        Color.Black.copy(alpha = 0.7f),
                        RoundedCornerShape(4.dp)
                    )
                    .padding(horizontal = 6.dp, vertical = 2.dp)
            ) {
                Text(
                    text = String.format("%.1f", tmdbMovie!!.rating),
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                    color = UltraTokens.Text
                )
            }
        }
    }
}

