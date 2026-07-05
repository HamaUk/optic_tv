package com.kobani4k.app.tv.ui

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Movie
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.tv.material3.Text
import androidx.compose.material3.Icon
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

    LazyVerticalGrid(
        columns = GridCells.Fixed(4),
        contentPadding = PaddingValues(start = 24.dp, end = 24.dp, top = 24.dp, bottom = 48.dp),
        horizontalArrangement = Arrangement.spacedBy(20.dp),
        verticalArrangement = Arrangement.spacedBy(24.dp),
        modifier = Modifier.fillMaxSize()
    ) {
        items(channels) { channel ->
            MovieCard(
                channel = channel,
                tmdbService = tmdbService,
                onClick = { onMovieClick(channel) }
            )
        }
    }
}

@Composable
fun MovieCard(
    channel: TvChannel,
    tmdbService: TmdbService,
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
    val borderColor = if (isFocused) UltraTokens.Blue else Color.Transparent

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .scale(scale)
            .clip(RoundedCornerShape(12.dp))
            .border(3.dp, borderColor, RoundedCornerShape(12.dp))
            .onFocusChanged { isFocused = it.isFocused }
            .focusable()
            .clickable { onClick() }
            .background(Color.Black.copy(alpha = 0.4f)),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Poster area
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(2f / 3f)
                .background(Color.White.copy(0.05f)),
            contentAlignment = Alignment.Center
        ) {
            if (tmdbMovie?.posterUrl != null) {
                AsyncImage(
                    model = tmdbMovie!!.posterUrl,
                    contentDescription = channel.name,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize()
                )
            } else if (!channel.logo.isNullOrEmpty()) {
                AsyncImage(
                    model = channel.logo,
                    contentDescription = channel.name,
                    contentScale = ContentScale.Fit,
                    modifier = Modifier.fillMaxSize().padding(16.dp)
                )
            } else {
                Icon(
                    imageVector = Icons.Rounded.Movie,
                    contentDescription = null,
                    tint = UltraTokens.TextSecondary,
                    modifier = Modifier.size(48.dp)
                )
            }
        }
        
        // Title area
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(Color.Black.copy(0.6f))
                .padding(12.dp)
        ) {
            Text(
                text = tmdbMovie?.title ?: channel.name,
                color = Color.White,
                fontSize = 14.sp,
                fontWeight = FontWeight.SemiBold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}
