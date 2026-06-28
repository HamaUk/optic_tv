package com.kobani4k.app.tv.ui

import android.content.Context
import androidx.compose.animation.*
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.type
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.kobani4k.app.R
import com.kobani4k.app.tv.data.PocketBaseRepository
import com.kobani4k.app.tv.data.TvChannel

// Premium TV Palette matching Zina TV styling
private val CanvasColor = Color(0xFF07111B)
private val SurfaceColor = Color(0xFF0F1B29)
private val SurfaceElevatedColor = Color(0xFF162338)
private val BrandGold = Color(0xFFFFC766)
private val FocusedOutlineColor = Color(0xFFF5F7FB)
private val TextPrimary = Color(0xFFF5F7FB)
private val TextSecondary = Color(0xFFBBC6D8)

val PoppinsFamily = FontFamily(
    Font(R.font.poppins_regular, FontWeight.Normal),
    Font(R.font.poppins_medium, FontWeight.Medium),
    Font(R.font.poppins_bold, FontWeight.Bold)
)

enum class TvMenu { LIVE_TV, MOVIES, SPORTS, FAVORITES, SETTINGS }

data class TvSettingsItem(
    val title: String,
    val description: String,
    val iconId: Int,
    val value: String,
    val isAction: Boolean = false,
    val action: () -> Unit = {}
)

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun DashboardScreen(
    onChannelSelected: (TvChannel) -> Unit,
    onLogout: () -> Unit
) {
    val context = LocalContext.current
    val repository = remember { PocketBaseRepository() }
    
    // Playlists and settings
    var allChannels by remember { mutableStateOf<List<TvChannel>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    
    // Favorites states
    val sharedPrefs = remember(context) { context.getSharedPreferences("TvFavorites", Context.MODE_PRIVATE) }
    var favoritesSet by remember { mutableStateOf(sharedPrefs.getStringSet("urls", emptySet()) ?: emptySet()) }

    fun toggleFavorite(url: String) {
        val newSet = if (favoritesSet.contains(url)) favoritesSet - url else favoritesSet + url
        favoritesSet = newSet
        sharedPrefs.edit().putStringSet("urls", newSet).apply()
    }

    // Active Navigation items
    var selectedMenu by remember { mutableStateOf(TvMenu.LIVE_TV) }
    var activeCategory by remember { mutableStateOf<String?>(null) }
    
    // Fetch channels on start
    LaunchedEffect(Unit) {
        allChannels = repository.getChannels()
        isLoading = false
    }

    // Computed categories
    val categories = remember(allChannels, selectedMenu, favoritesSet) {
        when (selectedMenu) {
            TvMenu.LIVE_TV -> allChannels.filter { it.type == "live" && !it.group.contains("sport", ignoreCase = true) }.map { it.group.trim().ifEmpty { "General" } }.distinct().sorted()
            TvMenu.MOVIES -> allChannels.filter { it.type == "movie" }.map { it.group.trim().ifEmpty { "General" } }.distinct().sorted()
            TvMenu.SPORTS -> allChannels.filter { it.group.contains("sport", ignoreCase = true) || it.type == "sports" }.map { it.group.trim().ifEmpty { "Sports" } }.distinct().sorted()
            TvMenu.FAVORITES -> listOf("FAVORITE CHANNELS")
            TvMenu.SETTINGS -> emptyList()
        }
    }

    val filteredChannels = remember(allChannels, selectedMenu, activeCategory, favoritesSet) {
        if (activeCategory == null) return@remember emptyList<TvChannel>()
        when (selectedMenu) {
            TvMenu.LIVE_TV -> allChannels.filter { it.type == "live" && !it.group.contains("sport", ignoreCase = true) && (it.group.trim().ifEmpty { "General" } == activeCategory) }
            TvMenu.MOVIES -> allChannels.filter { it.type == "movie" && (it.group.trim().ifEmpty { "General" } == activeCategory) }
            TvMenu.SPORTS -> allChannels.filter { (it.group.contains("sport", ignoreCase = true) || it.type == "sports") && (it.group.trim().ifEmpty { "Sports" } == activeCategory) }
            TvMenu.FAVORITES -> allChannels.filter { favoritesSet.contains(it.url) }
            TvMenu.SETTINGS -> emptyList()
        }
    }

    val settingsItems = remember(allChannels, onLogout) {
        listOf(
            TvSettingsItem("LOW LATENCY MODE", "Start streams with a tight 500ms buffer", R.drawable.ic_play, "ENABLED"),
            TvSettingsItem("HARDWARE ACCELERATION", "Use GPU-driven hardware codecs", R.drawable.ic_settings, "AUTO"),
            TvSettingsItem("ASPECT RATIO", "Default rendering mode for live streams", R.drawable.ic_fit, "FIT TO SCREEN"),
            TvSettingsItem("CLOUD SERVER CONNECTION", "PocketBase server link state", R.drawable.globe, "CONNECTED"),
            TvSettingsItem("CHANNELS PLAYLIST COUNT", "Total items loaded from repository", R.drawable.ic_live, "${allChannels.size} Channels"),
            TvSettingsItem("DE-ACTIVATE DEVICE", "Clear activation code and return to activation", R.drawable.ic_exit_app, "RESET DEVICE", true, onLogout)
        )
    }

    LaunchedEffect(selectedMenu) {
        if (selectedMenu == TvMenu.FAVORITES) {
            activeCategory = "FAVORITE CHANNELS"
        } else {
            activeCategory = null
        }
    }

    Row(
        modifier = Modifier
            .fillMaxSize()
            .background(CanvasColor)
    ) {
        // PANE 1: LEFT NAVIGATION MENU
        Column(
            modifier = Modifier
                .fillMaxWidth(0.25f)
                .fillMaxHeight()
                .background(SurfaceColor)
                .border(width = 1.dp, color = SurfaceElevatedColor, shape = RoundedCornerShape(0.dp))
                .padding(vertical = 32.dp, horizontal = 24.dp)
        ) {
            Text(
                text = "KOBANI 4K",
                color = BrandGold,
                fontFamily = PoppinsFamily,
                fontWeight = FontWeight.Bold,
                fontSize = 24.sp,
                letterSpacing = 2.sp,
                modifier = Modifier.padding(bottom = 48.dp, start = 12.dp)
            )

            TvMenu.values().forEach { menu ->
                val isSelected = selectedMenu == menu
                val title = when (menu) {
                    TvMenu.LIVE_TV -> "LIVE TV"
                    TvMenu.MOVIES -> "MOVIES"
                    TvMenu.SPORTS -> "SPORTS"
                    TvMenu.FAVORITES -> "FAVORITES"
                    TvMenu.SETTINGS -> "SETTINGS"
                }
                val icon = when (menu) {
                    TvMenu.LIVE_TV -> R.drawable.ic_live_tv
                    TvMenu.MOVIES -> R.drawable.ic_movies
                    TvMenu.SPORTS -> R.drawable.ic_series // Using series as generic for sports if no ball icon
                    TvMenu.FAVORITES -> R.drawable.ic_favorite_filled
                    TvMenu.SETTINGS -> R.drawable.ic_settings
                }

                SidebarItem(
                    title = title,
                    iconId = icon,
                    isSelected = isSelected,
                    onFocus = { selectedMenu = menu }
                )
                Spacer(modifier = Modifier.height(16.dp))
            }

            Spacer(modifier = Modifier.weight(1f))

            SidebarItem(
                title = "SIGN OUT",
                iconId = R.drawable.ic_exit_app,
                isSelected = false,
                onFocus = {},
                onClick = onLogout
            )
        }

        // PANE 2: DYNAMIC CONTENT GRID
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .fillMaxHeight()
                .padding(32.dp)
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 32.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = when {
                        selectedMenu == TvMenu.SETTINGS -> "SYSTEM SETTINGS"
                        activeCategory != null -> activeCategory!!.uppercase()
                        else -> "CATEGORIES"
                    },
                    color = TextPrimary,
                    fontFamily = PoppinsFamily,
                    fontSize = 28.sp,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 1.sp
                )
                
                if (activeCategory != null && selectedMenu != TvMenu.FAVORITES && selectedMenu != TvMenu.SETTINGS) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(painter = painterResource(id = R.drawable.ic_back), contentDescription = null, tint = TextSecondary, modifier = Modifier.size(20.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(text = "BACK TO CATEGORIES", color = TextSecondary, fontFamily = PoppinsFamily, fontSize = 14.sp, fontWeight = FontWeight.Medium)
                    }
                }
            }

            if (isLoading) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = BrandGold, modifier = Modifier.size(48.dp))
                }
            } else if (selectedMenu == TvMenu.SETTINGS) {
                LazyVerticalGrid(
                    columns = GridCells.Fixed(2),
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp),
                    modifier = Modifier.fillMaxSize()
                ) {
                    items(settingsItems.size) { index ->
                        val item = settingsItems[index]
                        SettingsCard(item = item, onClick = { if (item.isAction) item.action() })
                    }
                }
            } else if (activeCategory == null) {
                if (categories.isEmpty()) {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Text("NO CATEGORIES FOUND", color = TextSecondary, fontFamily = PoppinsFamily, fontSize = 16.sp, fontWeight = FontWeight.Medium)
                    }
                } else {
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(4),
                        horizontalArrangement = Arrangement.spacedBy(16.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp),
                        modifier = Modifier.fillMaxSize()
                    ) {
                        items(categories.size) { index ->
                            val cat = categories[index]
                            CategoryCard(title = cat, onClick = { activeCategory = cat })
                        }
                    }
                }
            } else {
                if (filteredChannels.isEmpty()) {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Text("NO CHANNELS IN THIS CATEGORY", color = TextSecondary, fontFamily = PoppinsFamily, fontSize = 16.sp, fontWeight = FontWeight.Medium)
                    }
                } else {
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(3),
                        horizontalArrangement = Arrangement.spacedBy(16.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp),
                        modifier = Modifier.fillMaxSize()
                    ) {
                        items(filteredChannels.size) { index ->
                            val ch = filteredChannels[index]
                            ChannelCard(
                                channel = ch,
                                isFavorite = favoritesSet.contains(ch.url),
                                onClick = { onChannelSelected(ch) },
                                onToggleFavorite = { toggleFavorite(ch.url) },
                                onBackPress = { activeCategory = null }
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
    iconId: Int,
    isSelected: Boolean,
    onFocus: () -> Unit,
    onClick: () -> Unit = {}
) {
    var isFocused by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(targetValue = if (isFocused) 1.05f else 1.0f)

    Surface(
        onClick = onClick,
        shape = ClickableSurfaceDefaults.shape(shape = RoundedCornerShape(12.dp)),
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
                shape = RoundedCornerShape(12.dp)
            ),
            focusedBorder = Border(
                border = androidx.compose.foundation.BorderStroke(2.dp, FocusedOutlineColor),
                shape = RoundedCornerShape(12.dp)
            )
        ),
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp)
            .scale(scale)
            .onFocusChanged { 
                isFocused = it.isFocused 
                if (it.isFocused) {
                    onFocus()
                }
            }
    ) {
        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                painter = painterResource(id = iconId),
                contentDescription = null,
                modifier = Modifier.size(24.dp),
                tint = if (isFocused) CanvasColor else (if (isSelected) BrandGold else TextSecondary)
            )
            Spacer(modifier = Modifier.width(16.dp))
            Text(
                text = title,
                fontFamily = PoppinsFamily,
                fontSize = 15.sp,
                fontWeight = FontWeight.Medium,
                letterSpacing = 1.sp
            )
        }
    }
}

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun CategoryCard(
    title: String,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(targetValue = if (isFocused) 1.05f else 1.0f)

    Surface(
        onClick = onClick,
        shape = ClickableSurfaceDefaults.shape(shape = RoundedCornerShape(16.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = SurfaceElevatedColor,
            focusedContainerColor = TextPrimary,
            contentColor = TextPrimary,
            focusedContentColor = CanvasColor
        ),
        border = ClickableSurfaceDefaults.border(
            border = Border(
                border = androidx.compose.foundation.BorderStroke(1.dp, SurfaceColor),
                shape = RoundedCornerShape(16.dp)
            ),
            focusedBorder = Border(
                border = androidx.compose.foundation.BorderStroke(3.dp, BrandGold),
                shape = RoundedCornerShape(16.dp)
            )
        ),
        modifier = Modifier
            .fillMaxWidth()
            .aspectRatio(1.5f)
            .scale(scale)
            .onFocusChanged { isFocused = it.isFocused }
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = title.uppercase(),
                fontFamily = PoppinsFamily,
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun ChannelCard(
    channel: TvChannel,
    isFavorite: Boolean,
    onClick: () -> Unit,
    onToggleFavorite: () -> Unit,
    onBackPress: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(targetValue = if (isFocused) 1.05f else 1.0f)

    Surface(
        onClick = onClick,
        onLongClick = onToggleFavorite,
        shape = ClickableSurfaceDefaults.shape(shape = RoundedCornerShape(16.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = SurfaceColor,
            focusedContainerColor = SurfaceElevatedColor,
            contentColor = TextPrimary,
            focusedContentColor = TextPrimary
        ),
        border = ClickableSurfaceDefaults.border(
            border = Border(
                border = androidx.compose.foundation.BorderStroke(1.dp, SurfaceElevatedColor),
                shape = RoundedCornerShape(16.dp)
            ),
            focusedBorder = Border(
                border = androidx.compose.foundation.BorderStroke(3.dp, BrandGold),
                shape = RoundedCornerShape(16.dp)
            )
        ),
        modifier = Modifier
            .fillMaxWidth()
            .height(96.dp)
            .scale(scale)
            .onFocusChanged { isFocused = it.isFocused }
            .onKeyEvent { keyEvent ->
                if (keyEvent.type == androidx.compose.ui.input.key.KeyEventType.KeyDown) {
                    when (keyEvent.key) {
                        androidx.compose.ui.input.key.Key.Back -> {
                            onBackPress()
                            true
                        }
                        else -> false
                    }
                } else false
            }
    ) {
        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (!channel.logo.isNullOrEmpty()) {
                AsyncImage(
                    model = channel.logo,
                    contentDescription = null,
                    modifier = Modifier
                        .size(64.dp)
                        .background(Color.White.copy(alpha = 0.08f), RoundedCornerShape(12.dp))
                        .padding(8.dp)
                )
            } else {
                Box(
                    modifier = Modifier
                        .size(64.dp)
                        .background(SurfaceElevatedColor, RoundedCornerShape(12.dp)),
                    contentAlignment = Alignment.Center
                ) {
                    Text("TV", fontFamily = PoppinsFamily, fontSize = 16.sp, color = BrandGold, fontWeight = FontWeight.Bold)
                }
            }
            Spacer(modifier = Modifier.width(16.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = channel.name.uppercase(),
                    fontFamily = PoppinsFamily,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Spacer(modifier = Modifier.height(4.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    if (isFavorite) {
                        Icon(painter = painterResource(id = R.drawable.ic_favorite_filled), contentDescription = null, tint = BrandGold, modifier = Modifier.size(12.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(text = "FAVORITE", fontFamily = PoppinsFamily, fontSize = 11.sp, fontWeight = FontWeight.Medium, color = BrandGold)
                    } else {
                        Text(text = "LIVE STREAM", fontFamily = PoppinsFamily, fontSize = 11.sp, fontWeight = FontWeight.Medium, color = TextSecondary)
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun SettingsCard(
    item: TvSettingsItem,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(targetValue = if (isFocused) 1.03f else 1.0f)

    Surface(
        onClick = onClick,
        shape = ClickableSurfaceDefaults.shape(shape = RoundedCornerShape(16.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = SurfaceColor,
            focusedContainerColor = SurfaceElevatedColor,
            contentColor = TextPrimary,
            focusedContentColor = TextPrimary
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
        modifier = Modifier
            .fillMaxWidth()
            .height(110.dp)
            .scale(scale)
            .onFocusChanged { isFocused = it.isFocused }
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            verticalArrangement = Arrangement.Center
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(painter = painterResource(id = item.iconId), contentDescription = null, tint = BrandGold, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = item.title,
                        fontFamily = PoppinsFamily,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold,
                        color = BrandGold
                    )
                }
                Text(
                    text = item.value,
                    fontFamily = PoppinsFamily,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium,
                    color = TextPrimary
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = item.description,
                fontFamily = PoppinsFamily,
                fontSize = 12.sp,
                color = TextSecondary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}
