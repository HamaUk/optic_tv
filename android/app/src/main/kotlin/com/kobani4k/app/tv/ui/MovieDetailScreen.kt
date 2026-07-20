package com.kobani4k.app.tv.ui

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.tv.material3.Text
import coil.compose.AsyncImage
import com.kobani4k.app.tv.data.TmdbMovie
import com.kobani4k.app.tv.data.TmdbService
import com.kobani4k.app.tv.ui.theme.UltraTokens
import kotlinx.coroutines.delay

@Composable
fun MovieDetailScreen(
    channelName: String,
    streamUrl: String,
    logoUrl: String?,
    onBack: () -> Unit,
    onPlay: () -> Unit
) {
    val tmdbService = remember { TmdbService() }
    var tmdbMovie by remember { mutableStateOf<TmdbMovie?>(null) }
    var isLoading by remember { mutableStateOf(true) }

    val playFocusRequester = remember { FocusRequester() }

    LaunchedEffect(channelName) {
        tmdbMovie = tmdbService.findMovie(channelName)
        isLoading = false
        delay(100) // Slight delay to let UI render before requesting focus
        playFocusRequester.requestFocus()
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(UltraTokens.Background)
    ) {
        // Backdrop Image
        val backdropUrl = tmdbMovie?.backdropUrl ?: tmdbMovie?.posterUrl ?: logoUrl
        if (!backdropUrl.isNullOrEmpty()) {
            AsyncImage(
                model = backdropUrl,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .fillMaxSize()
                    .blur(15.dp)
            )
        }

        // Gradient overlay to make text readable
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.horizontalGradient(
                        colors = listOf(
                            UltraTokens.Background.copy(alpha = 0.95f), // Left side is darker
                            UltraTokens.Background.copy(alpha = 0.7f),
                            Color.Transparent
                        )
                    )
                )
        )
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        colors = listOf(
                            Color.Transparent,
                            UltraTokens.Background.copy(alpha = 0.4f),
                            UltraTokens.Background.copy(alpha = 0.9f)
                        )
                    )
                )
        )

        // Main content
        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(48.dp),
            verticalAlignment = Alignment.Bottom
        ) {
            // Left side: Poster
            val posterUrl = tmdbMovie?.posterUrl ?: logoUrl
            if (!posterUrl.isNullOrEmpty()) {
                AsyncImage(
                    model = posterUrl,
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier
                        .width(240.dp)
                        .height(360.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .border(1.dp, UltraTokens.Divider, RoundedCornerShape(12.dp))
                )
                Spacer(modifier = Modifier.width(48.dp))
            }

            // Right side: Info & Actions
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.Bottom
            ) {
                // Title
                val title = tmdbMovie?.title ?: channelName
                Text(
                    text = title,
                    fontSize = 48.sp,
                    fontWeight = FontWeight.Bold,
                    color = UltraTokens.Text,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )

                Spacer(modifier = Modifier.height(16.dp))

                // Metadata (Rating, Year)
                Row(
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    if (tmdbMovie != null && tmdbMovie!!.rating > 0) {
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(6.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = Icons.Default.Star,
                                contentDescription = null,
                                tint = UltraTokens.Movie,
                                modifier = Modifier.size(20.dp)
                            )
                            Text(
                                text = String.format("%.1f", tmdbMovie!!.rating),
                                color = UltraTokens.Text,
                                fontSize = 18.sp,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                        Text("â€¢", color = UltraTokens.TextSecondary, fontSize = 18.sp)
                    }

                    val year = tmdbMovie?.releaseDate?.take(4)
                    if (!year.isNullOrEmpty()) {
                        Text(
                            text = year,
                            color = UltraTokens.TextSecondary,
                            fontSize = 18.sp
                        )
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // Overview
                Text(
                    text = tmdbMovie?.overview ?: "No description available.",
                    color = UltraTokens.TextSecondary,
                    fontSize = 18.sp,
                    lineHeight = 26.sp,
                    maxLines = 5,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.fillMaxWidth(0.85f)
                )

                Spacer(modifier = Modifier.height(32.dp))

                // Action Buttons
                var playFocused by remember { mutableStateOf(false) }
                val playBgColor = if (playFocused) Color.White else Color.White.copy(alpha = 0.1f)
                val playContentColor = if (playFocused) Color.Black else Color.White
                
                Box(
                    modifier = Modifier
                        .focusRequester(playFocusRequester)
                        .onFocusChanged { playFocused = it.isFocused }
                        .clip(RoundedCornerShape(8.dp))
                        .background(playBgColor)
                        .border(1.dp, if (playFocused) Color.White else Color.White.copy(alpha = 0.3f), RoundedCornerShape(8.dp))
                        .clickable { onPlay() }
                        .focusable()
                        .padding(horizontal = 32.dp, vertical = 16.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.PlayArrow, contentDescription = null, tint = playContentColor, modifier = Modifier.size(24.dp))
                        Spacer(modifier = Modifier.width(12.dp))
                        Text("Play Movie", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = playContentColor)
                    }
                }
            }
        }
        
        // Back Button (Top Left)
        IconButton(
            onClick = onBack,
            modifier = Modifier
                .padding(24.dp)
                .align(Alignment.TopStart)
                .background(Color.Black.copy(alpha = 0.5f), RoundedCornerShape(50))
        ) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                contentDescription = "Back",
                tint = UltraTokens.Text,
                modifier = Modifier.size(28.dp)
            )
        }
    }
}

