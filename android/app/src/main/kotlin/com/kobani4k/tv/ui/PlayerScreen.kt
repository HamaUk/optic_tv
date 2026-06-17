package com.kobani4k.tv.ui

import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView
import androidx.tv.material3.Text

@Composable
fun PlayerScreen(channelName: String) {
    val context = LocalContext.current
    
    // Setup ExoPlayer
    val exoPlayer = remember {
        ExoPlayer.Builder(context).build().apply {
            // Using a mock video URL for testing purposes
            val mediaItem = MediaItem.fromUri(Uri.parse("https://storage.googleapis.com/exoplayer-test-media-0/BigBuckBunny_320x180.mp4"))
            setMediaItem(mediaItem)
            prepare()
            playWhenReady = true
        }
    }

    DisposableEffect(Unit) {
        onDispose {
            exoPlayer.release()
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        // 1. Video Player
        AndroidView(
            factory = { ctx ->
                PlayerView(ctx).apply {
                    player = exoPlayer
                    useController = false // We build our own UI overlay
                }
            },
            modifier = Modifier.fillMaxSize()
        )

        // 2. Cinematic Premium HUD Overlay
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        colors = listOf(
                            Color.Black.copy(alpha = 0.85f),
                            Color.Transparent,
                            Color.Transparent,
                            Color.Black.copy(alpha = 0.95f)
                        )
                    )
                )
                .padding(60.dp)
        ) {
            // Top Bar
            Row(
                modifier = Modifier.align(Alignment.TopStart),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Mock Channel Logo placeholder
                Box(
                    modifier = Modifier
                        .size(90.dp)
                        .background(Color.White.copy(alpha = 0.1f), RoundedCornerShape(24.dp))
                )
                Spacer(modifier = Modifier.width(32.dp))
                Column {
                    Text(
                        text = "NOW PLAYING LIVE",
                        color = Color(0xFFFFD700),
                        fontWeight = FontWeight.Black,
                        letterSpacing = 4.sp
                    )
                    Text(
                        text = channelName.uppercase(),
                        color = Color.White,
                        style = androidx.tv.material3.MaterialTheme.typography.displayMedium,
                        fontWeight = FontWeight.Black
                    )
                }
            }

            // Bottom Bar Progress and Hints
            Column(
                modifier = Modifier.align(Alignment.BottomStart)
            ) {
                // Sleek Progress Line
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(4.dp)
                        .background(Color.White.copy(alpha = 0.1f), RoundedCornerShape(2.dp))
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth(0.6f) // Fake 60% progress
                            .height(4.dp)
                            .background(Color(0xFFFFD700), RoundedCornerShape(2.dp))
                    )
                }
                
                Spacer(modifier = Modifier.height(32.dp))
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(horizontalArrangement = Arrangement.spacedBy(40.dp)) {
                        Text("↑ LIVE SETTINGS", color = Color.White54, fontWeight = FontWeight.Bold, letterSpacing = 2.sp)
                        Text("↕ ZAP LIST", color = Color.White54, fontWeight = FontWeight.Bold, letterSpacing = 2.sp)
                        Text("↔ PREV/NEXT", color = Color.White54, fontWeight = FontWeight.Bold, letterSpacing = 2.sp)
                    }
                    Text("LIVE: OK", color = Color(0xFFFFD700).copy(alpha = 0.5f), fontWeight = FontWeight.Black, letterSpacing = 2.sp)
                }
            }
        }
    }
}
