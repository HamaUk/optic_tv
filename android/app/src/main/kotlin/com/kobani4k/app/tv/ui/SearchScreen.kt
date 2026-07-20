package com.kobani4k.app.tv.ui

import android.view.KeyEvent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.*
import androidx.compose.material3.Icon
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.focusRestorer
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.tv.material3.Text
import coil.compose.AsyncImage
import com.kobani4k.app.tv.data.TvChannel
import com.kobani4k.app.tv.ui.theme.UltraTokens

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  TV KEYBOARD LAYOUT
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

private val keyboardRows = listOf(
    listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "0"),
    listOf("Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"),
    listOf("A", "S", "D", "F", "G", "H", "J", "K", "L", "âŒ«"),
    listOf("Z", "X", "C", "V", "B", "N", "M", " ", ".", "âœ“")
)

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  SEARCH SCREEN
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

@Composable
fun SearchScreen(
    allChannels: List<TvChannel>,
    onChannelSelected: (TvChannel) -> Unit,
    onBack: () -> Unit
) {
    var query by remember { mutableStateOf("") }
    val searchFocusRequester = remember { FocusRequester() }

    val results by remember(query) {
        derivedStateOf {
            if (query.isBlank()) emptyList()
            else allChannels.filter { it.name.contains(query.trim(), ignoreCase = true) }
        }
    }

    LaunchedEffect(Unit) {
        runCatching { searchFocusRequester.requestFocus() }
    }

    Row(
        modifier = Modifier
            .fillMaxSize()
            .background(UltraTokens.Background)
    ) {
        // â”€â”€ LEFT: Keyboard + Query Box â”€â”€
        Column(
            modifier = Modifier
                .width(460.dp)
                .fillMaxHeight()
                .background(UltraTokens.Surface)
                .padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Title
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    Icons.Rounded.Search,
                    contentDescription = null,
                    tint = UltraTokens.Accent,
                    modifier = Modifier.size(26.dp)
                )
                Spacer(Modifier.width(10.dp))
                Text(
                    "SEARCH",
                    color = Color.White,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Black,
                    letterSpacing = 3.sp
                )
            }

            // Query display box
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(UltraTokens.SurfaceHover)
                    .border(1.dp, UltraTokens.Accent.copy(alpha = 0.5f), RoundedCornerShape(12.dp))
                    .padding(horizontal = 16.dp, vertical = 14.dp)
            ) {
                if (query.isEmpty()) {
                    Text(
                        "Type to search channels & moviesâ€¦",
                        color = UltraTokens.Divider,
                        fontSize = 15.sp
                    )
                } else {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            query,
                            color = Color.White,
                            fontSize = 15.sp,
                            fontWeight = FontWeight.SemiBold,
                            modifier = Modifier.weight(1f)
                        )
                        Text(
                            "${results.size} results",
                            color = UltraTokens.Accent,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }

            // TV Keyboard
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                keyboardRows.forEachIndexed { rowIdx, row ->
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        row.forEachIndexed { colIdx, key ->
                            val keyFocusRequester = remember { FocusRequester() }
                            val isFirstKey = rowIdx == 0 && colIdx == 0
                            val isBackspace = key == "âŒ«"
                            val isConfirmKey = key == "âœ“"

                            KeyboardKey(
                                label = key,
                                isSpecial = isBackspace || isConfirmKey,
                                focusRequester = if (isFirstKey) searchFocusRequester else keyFocusRequester,
                                modifier = Modifier.weight(1f),
                                onClick = {
                                    when {
                                        isBackspace -> if (query.isNotEmpty()) query = query.dropLast(1)
                                        isConfirmKey -> { /* query is live â€” nothing extra needed */ }
                                        else -> query += key
                                    }
                                }
                            )
                        }
                    }
                }
            }

            // Back hint
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(8.dp))
                    .background(UltraTokens.SurfaceHover)
                    .padding(horizontal = 14.dp, vertical = 10.dp)
            ) {
                Icon(Icons.Rounded.ArrowBack, null, tint = UltraTokens.Divider, modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(8.dp))
                Text("Press BACK to return", color = UltraTokens.Divider, fontSize = 12.sp)
            }
        }

        // â”€â”€ RIGHT: Results â”€â”€
        Box(
            modifier = Modifier
                .weight(1f)
                .fillMaxHeight()
                .padding(horizontal = 24.dp, vertical = 24.dp)
        ) {
            when {
                query.isBlank() -> {
                    // Empty state
                    Column(
                        modifier = Modifier.fillMaxSize(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        Icon(
                            Icons.Rounded.Search,
                            contentDescription = null,
                            tint = UltraTokens.Divider,
                            modifier = Modifier.size(80.dp)
                        )
                        Spacer(Modifier.height(16.dp))
                        Text(
                            "Start typing to search",
                            color = UltraTokens.TextSecondary,
                            fontSize = 18.sp,
                            fontWeight = FontWeight.Medium
                        )
                        Spacer(Modifier.height(8.dp))
                        Text(
                            "Search across all channels and movies",
                            color = UltraTokens.Divider,
                            fontSize = 13.sp
                        )
                    }
                }

                results.isEmpty() -> {
                    // No results state
                    Column(
                        modifier = Modifier.fillMaxSize(),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        Icon(
                            Icons.Rounded.SearchOff,
                            contentDescription = null,
                            tint = UltraTokens.Divider,
                            modifier = Modifier.size(72.dp)
                        )
                        Spacer(Modifier.height(16.dp))
                        Text(
                            "No results for \"$query\"",
                            color = UltraTokens.TextSecondary,
                            fontSize = 18.sp,
                            fontWeight = FontWeight.Medium
                        )
                        Spacer(Modifier.height(8.dp))
                        Text(
                            "Try a different search term",
                            color = UltraTokens.Divider,
                            fontSize = 13.sp
                        )
                    }
                }

                else -> {
                    // Results grid
                    Column {
                        Text(
                            "${results.size} results for \"$query\"",
                            color = UltraTokens.TextSecondary,
                            fontSize = 13.sp,
                            modifier = Modifier.padding(bottom = 12.dp)
                        )
                        LazyVerticalGrid(
                            columns = GridCells.Fixed(4),
                            contentPadding = PaddingValues(bottom = 24.dp),
                            horizontalArrangement = Arrangement.spacedBy(14.dp),
                            verticalArrangement = Arrangement.spacedBy(14.dp),
                            modifier = Modifier
                                .fillMaxSize()
                                .focusRestorer()
                        ) {
                            items(results) { channel ->
                                SearchResultCard(
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
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  KEYBOARD KEY
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

@Composable
private fun KeyboardKey(
    label: String,
    isSpecial: Boolean,
    focusRequester: FocusRequester,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    val bgColor by animateColorAsState(
        if (isFocused) Color.White
        else if (isSpecial) UltraTokens.SurfaceSelected
        else Color.Black,
        tween(120), label = "keyBg"
    )
    val textColor = if (isFocused) Color.Black else Color.White
    val scale by animateFloatAsState(if (isFocused) 1.1f else 1f, tween(100), label = "keyScale")

    Box(
        modifier = modifier
            .height(40.dp)
            .scale(scale)
            .clip(RoundedCornerShape(6.dp))
            .background(bgColor)
            .border(1.dp, Color.White.copy(alpha = 0.2f), RoundedCornerShape(6.dp))
            .focusRequester(focusRequester)
            .onFocusChanged { isFocused = it.isFocused }
            .focusable()
            .onKeyEvent { ev ->
                if (ev.nativeKeyEvent.action == KeyEvent.ACTION_DOWN &&
                    ev.nativeKeyEvent.keyCode in listOf(
                        KeyEvent.KEYCODE_DPAD_CENTER, KeyEvent.KEYCODE_ENTER,
                        KeyEvent.KEYCODE_NUMPAD_ENTER, KeyEvent.KEYCODE_SPACE
                    )
                ) { onClick(); true } else false
            }
            .clickable { onClick() },
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = label,
            color = textColor,
            fontSize = if (label.length > 1) 12.sp else 14.sp,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center
        )
    }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  SEARCH RESULT CARD
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

@Composable
private fun SearchResultCard(
    channel: TvChannel,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    val scale by animateFloatAsState(if (isFocused) 1.06f else 1f, tween(150), label = "cardScale")
    val borderColor by animateColorAsState(
        if (isFocused) UltraTokens.Accent else Color.White.copy(alpha = 0.1f),
        tween(150), label = "cardBorder"
    )

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .scale(scale)
            .clip(RoundedCornerShape(12.dp))
            .background(Color.Black.copy(alpha = 0.6f))
            .border(2.dp, borderColor, RoundedCornerShape(12.dp))
            .onFocusChanged { isFocused = it.isFocused }
            .focusable()
            .onKeyEvent { ev ->
                if (ev.nativeKeyEvent.action == KeyEvent.ACTION_DOWN &&
                    ev.nativeKeyEvent.keyCode in listOf(
                        KeyEvent.KEYCODE_DPAD_CENTER, KeyEvent.KEYCODE_ENTER,
                        KeyEvent.KEYCODE_NUMPAD_ENTER
                    )
                ) { onClick(); true } else false
            }
            .clickable { onClick() },
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Logo / Thumbnail
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(16f / 9f)
                .background(UltraTokens.SurfaceSelected),
            contentAlignment = Alignment.Center
        ) {
            if (!channel.logo.isNullOrEmpty()) {
                AsyncImage(
                    model = channel.logo,
                    contentDescription = channel.name,
                    contentScale = ContentScale.Fit,
                    modifier = Modifier.fillMaxSize().padding(10.dp)
                )
            } else {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(
                        imageVector = if (channel.type == "movie") Icons.Rounded.Movie else Icons.Rounded.LiveTv,
                        contentDescription = null,
                        tint = UltraTokens.Divider,
                        modifier = Modifier.size(32.dp)
                    )
                }
            }

            // Type badge
            Box(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(6.dp)
                    .clip(RoundedCornerShape(4.dp))
                    .background(
                        when (channel.type) {
                            "movie"  -> UltraTokens.Movie.copy(alpha = 0.9f)
                            "sports" -> UltraTokens.Sports.copy(alpha = 0.9f)
                            else     -> UltraTokens.Live.copy(alpha = 0.9f)
                        }
                    )
                    .padding(horizontal = 6.dp, vertical = 2.dp)
            ) {
                Text(
                    text = channel.type.uppercase().take(4),
                    color = Color.White,
                    fontSize = 9.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }

        // Name
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(if (isFocused) UltraTokens.Accent else UltraTokens.SurfaceHover)
                .padding(horizontal = 10.dp, vertical = 8.dp)
        ) {
            Text(
                text = channel.name,
                color = Color.White,
                fontSize = 12.sp,
                fontWeight = FontWeight.SemiBold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}

