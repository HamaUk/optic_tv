package com.kobani4k.app.tv.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.kobani4k.app.tv.data.PocketBaseRepository
import com.kobani4k.app.tv.data.TvChannel
import com.kobani4k.app.tv.ui.theme.UltraFonts
import com.kobani4k.app.tv.ui.theme.UltraTokens
import com.kobani4k.app.tv.ui.theme.ultraCardColors

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun DashboardScreen(
    onChannelSelected: (TvChannel) -> Unit,
    onLogout: () -> Unit
) {
    val repository = remember { PocketBaseRepository() }
    var allChannels by remember { mutableStateOf<List<TvChannel>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }

    LaunchedEffect(Unit) {
        allChannels = repository.getChannels()
        isLoading = false
    }

    val liveChannels = remember(allChannels) { allChannels.filter { it.type == "live" && !it.group.contains("sport", true) } }
    val movies = remember(allChannels) { allChannels.filter { it.type == "movie" } }
    val sports = remember(allChannels) { allChannels.filter { it.group.contains("sport", true) || it.type == "sports" } }

    Column(
        Modifier
            .fillMaxSize()
            .background(Color(0xFF0F0E17))
            .verticalScroll(rememberScrollState()),
    ) {
        if (isLoading) {
            Box(Modifier.fillMaxSize().height(420.dp), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = UltraTokens.Accent)
            }
        } else {
            // Hero Banner
            val heroChannel = movies.firstOrNull() ?: liveChannels.firstOrNull()
            if (heroChannel != null) {
                HeroBanner(
                    title = heroChannel.name,
                    subtitle = "Featured",
                    eyebrow = "RECOMMENDED",
                    image = heroChannel.logo,
                    primaryLabel = "Play",
                    onPrimary = { onChannelSelected(heroChannel) }
                )
            } else {
                Box(
                    modifier = Modifier.fillMaxWidth().height(420.dp).background(UltraTokens.Surface1),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        "KOBANI 4K",
                        fontSize = 50.sp,
                        color = UltraTokens.Fg,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
            
            Spacer(Modifier.height(40.dp))

            if (liveChannels.isNotEmpty()) {
                ContentRail(title = "Live TV", items = liveChannels) { c ->
                    PosterCard(
                        title = c.name,
                        poster = c.logo,
                        subtitle = "Live",
                        aspect = 16f / 9f,
                        onClick = { onChannelSelected(c) }
                    )
                }
            }

            if (movies.isNotEmpty()) {
                ContentRail(title = "Movies", items = movies) { m ->
                    PosterCard(
                        title = m.name,
                        poster = m.logo,
                        subtitle = "Movie",
                        onClick = { onChannelSelected(m) }
                    )
                }
            }

            if (sports.isNotEmpty()) {
                ContentRail(title = "Sports", items = sports) { c ->
                    PosterCard(
                        title = c.name,
                        poster = c.logo,
                        subtitle = "Live Sports",
                        aspect = 16f / 9f,
                        onClick = { onChannelSelected(c) }
                    )
                }
            }

            Spacer(Modifier.height(80.dp))
        }
    }
}

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun HeroBanner(
    title: String,
    subtitle: String? = null,
    eyebrow: String? = null,
    image: String? = null,
    primaryLabel: String = "Play",
    onPrimary: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(420.dp),
    ) {
        Box(
            Modifier
                .fillMaxSize()
                .background(
                    Brush.radialGradient(
                        colors = listOf(
                            Color(0xFF3C1F26),
                            Color(0xFF160910),
                            Color(0xFF050203),
                        ),
                        center = Offset(1450f, 360f),
                        radius = 1100f,
                    )
                ),
        )
        if (!image.isNullOrEmpty()) {
            AsyncImage(
                model = image,
                contentDescription = title,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize().clip(RoundedCornerShape(0.dp)),
            )
        }
        Box(
            Modifier
                .fillMaxSize()
                .background(
                    Brush.horizontalGradient(
                        0f to Color(0xF2000000),
                        0.45f to Color(0x73000000),
                        0.8f to Color.Transparent,
                    )
                ),
        )
        Box(
            Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        0f to Color.Transparent,
                        0.92f to UltraTokens.Surface1,
                        1f to Color(0xFF000000),
                    )
                ),
        )

        Column(
            modifier = Modifier
                .align(Alignment.CenterStart)
                .widthIn(max = 760.dp)
                .padding(start = 80.dp, top = 60.dp, end = 40.dp),
            verticalArrangement = Arrangement.spacedBy(0.dp),
        ) {
            if (eyebrow != null) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(width = 24.dp, height = 1.dp).background(UltraTokens.Accent))
                    Spacer(Modifier.width(12.dp))
                    Text(
                        eyebrow,
                        color = UltraTokens.Accent,
                        fontSize = 13.sp,
                        letterSpacing = 2.3.sp,
                        fontWeight = FontWeight.Medium,
                    )
                }
                Spacer(Modifier.height(18.dp))
            }
            Text(
                title,
                color = UltraTokens.Fg,
                fontSize = 54.sp,
                lineHeight = 58.sp,
                fontWeight = FontWeight.Bold,
                maxLines = 2,
            )
            if (subtitle != null) {
                Spacer(Modifier.height(20.dp))
                Text(
                    subtitle,
                    color = UltraTokens.Fg2,
                    fontSize = 20.sp,
                    lineHeight = 28.sp,
                    fontWeight = FontWeight.Light,
                    maxLines = 3,
                )
            }
            Spacer(Modifier.height(28.dp))
            Button(
                onClick = onPrimary,
                shape = ButtonDefaults.shape(RoundedCornerShape(14.dp)),
                colors = ButtonDefaults.colors(
                    containerColor = UltraTokens.CtaBg,
                    contentColor = UltraTokens.CtaFgOnCta,
                ),
                modifier = Modifier
                    .border(3.dp, UltraTokens.Accent, RoundedCornerShape(14.dp)),
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.PlayArrow, contentDescription = null, modifier = Modifier.size(18.dp), tint = UltraTokens.CtaFgOnCta)
                    Spacer(Modifier.width(10.dp))
                    Text(primaryLabel, fontSize = 16.sp, fontWeight = FontWeight.SemiBold, color = UltraTokens.CtaFgOnCta)
                }
            }
        }
    }
}

@Composable
fun <T> ContentRail(
    title: String,
    items: List<T>,
    modifier: Modifier = Modifier,
    content: @Composable (T) -> Unit,
) {
    Column(modifier = modifier.fillMaxWidth()) {
        Text(
            title,
            color = UltraTokens.Fg,
            fontSize = 24.sp,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.padding(start = 80.dp, bottom = 16.dp)
        )
        LazyRow(
            contentPadding = PaddingValues(horizontal = 80.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            items(items) { item ->
                content(item)
            }
        }
        Spacer(Modifier.height(32.dp))
    }
}

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun PosterCard(
    title: String,
    poster: String?,
    subtitle: String? = null,
    aspect: Float = 2f / 3f,
    onClick: () -> Unit
) {
    Card(
        onClick = onClick,
        shape = CardDefaults.shape(RoundedCornerShape(10.dp)),
        colors = ultraCardColors(
            containerColor = UltraTokens.Surface2,
            focusedContainerColor = UltraTokens.AccentSoft
        ),
        modifier = Modifier.width(if (aspect > 1f) 260.dp else 160.dp)
    ) {
        Column {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .aspectRatio(aspect)
                    .background(UltraTokens.Surface1)
            ) {
                if (!poster.isNullOrEmpty()) {
                    AsyncImage(
                        model = poster,
                        contentDescription = title,
                        contentScale = ContentScale.Crop,
                        modifier = Modifier.fillMaxSize()
                    )
                }
            }
            Column(Modifier.padding(12.dp)) {
                Text(
                    title,
                    color = UltraTokens.Fg,
                    fontSize = 14.sp,
                    maxLines = 1,
                    fontWeight = FontWeight.Medium
                )
                if (subtitle != null) {
                    Spacer(Modifier.height(4.dp))
                    Text(
                        subtitle,
                        color = UltraTokens.Fg3,
                        fontSize = 12.sp,
                        maxLines = 1
                    )
                }
            }
        }
    }
}
