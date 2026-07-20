package com.kobani4k.app.tv.ui.components

import android.content.Context
import androidx.activity.compose.BackHandler
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.focusable
import androidx.compose.foundation.focusGroup
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.rounded.*
import androidx.compose.material3.Icon
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import android.os.Build
import android.view.KeyEvent
import androidx.compose.foundation.lazy.items
import androidx.compose.ui.draw.scale
import androidx.compose.ui.focus.focusRestorer
import androidx.compose.ui.text.style.TextOverflow
import androidx.tv.material3.Text
import com.kobani4k.app.tv.ui.Locales
import com.kobani4k.app.tv.ui.theme.UltraTokens
import com.kobani4k.app.tv.ui.theme.kobaniFocus
import com.kobani4k.app.tv.ui.theme.scaleOnFocus

// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
//  SETTINGS OVERLAY Ã¢â‚¬â€ Full-Screen Premium Settings
// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

@Composable
fun SettingsOverlay(
    appLanguage: String,
    channelCount: Int,
    categoryCount: Int,
    onLogout: () -> Unit,
    onDismiss: () -> Unit,
    onLanguageChange: (String) -> Unit
) {
    BackHandler { onDismiss() }

    val context = LocalContext.current
    val settingsFocusRequester = remember { FocusRequester() }

    val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

    // Settings state
    var selectedVideoQuality by remember { mutableStateOf(prefs.getString("settings.video_quality", "Auto") ?: "Auto") }
    var selectedAudioLang by remember { mutableStateOf(prefs.getString("settings.audio_lang", "Default") ?: "Default") }
    var selectedSubLang by remember { mutableStateOf(prefs.getString("settings.sub_lang", "Off") ?: "Off") }
    var parentalEnabled by remember { mutableStateOf(prefs.getBoolean("settings.parental", false)) }
    var autoPlayNext by remember { mutableStateOf(prefs.getBoolean("settings.autoplay", true)) }
    var timeFormat24h by remember { mutableStateOf(prefs.getBoolean("settings.time24h", false)) }
    var selectedTheme by remember { mutableStateOf(prefs.getString("settings.theme", "Dark") ?: "Dark") }

    // Helper function to save string
    fun saveStringPref(key: String, value: String) {
        prefs.edit().putString(key, value).apply()
    }
    // Helper function to save boolean
    fun saveBoolPref(key: String, value: Boolean) {
        prefs.edit().putBoolean(key, value).apply()
    }

    // Settings menu categories
    var activeSection by remember { mutableStateOf("general") }

    LaunchedEffect(Unit) {
        delay(200)
        runCatching { settingsFocusRequester.requestFocus() }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(UltraTokens.Background.copy(alpha = 0.97f))
            .focusGroup()
    ) {
        Row(modifier = Modifier.fillMaxSize()) {
            // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â LEFT SIDEBAR Ã¢â‚¬â€ Settings Categories Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
            Column(
                modifier = Modifier
                    .width(280.dp)
                    .fillMaxHeight()
                    .background(UltraTokens.Surface)
                    .padding(vertical = 24.dp)
            ) {
                // Header
                Row(
                    modifier = Modifier.padding(horizontal = 24.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Rounded.Settings,
                        contentDescription = null,
                        tint = UltraTokens.Accent,
                        modifier = Modifier.size(24.dp)
                    )
                    Spacer(Modifier.width(12.dp))
                    Text(
                        Locales.getString("nav_settings", appLanguage),
                        color = Color.White,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 2.sp
                    )
                }

                Spacer(Modifier.height(8.dp))
                Box(
                    Modifier
                        .fillMaxWidth()
                        .height(1.dp)
                        .background(Color.White.copy(alpha = 0.06f))
                )
                Spacer(Modifier.height(16.dp))

                // Category items
                val sections = listOf(
                    Triple("general", Icons.Rounded.Tune, Locales.getString("set_general", appLanguage)),
                    Triple("video", Icons.Rounded.HighQuality, Locales.getString("set_video_audio", appLanguage)),
                    Triple("parental", Icons.Rounded.Lock, Locales.getString("set_parental", appLanguage)),
                    Triple("appearance", Icons.Rounded.Palette, Locales.getString("set_appearance", appLanguage)),
                    Triple("storage", Icons.Rounded.Storage, Locales.getString("set_storage", appLanguage)),
                    Triple("about", Icons.Rounded.Info, Locales.getString("set_about", appLanguage)),
                    Triple("account", Icons.Rounded.AccountCircle, Locales.getString("set_account", appLanguage)),
                )

                LazyColumn(
                    modifier = Modifier
                        .weight(1f)
                        .focusRestorer()
                ) {
                    items(sections) { (key, icon, label) ->
                        SettingsCategoryItem(
                            icon = icon,
                            label = label,
                            isSelected = activeSection == key,
                            modifier = if (key == "general") Modifier.focusRequester(settingsFocusRequester) else Modifier,
                            onFocus = { activeSection = key }
                        )
                    }
                }

                // Close hint at bottom
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 24.dp, vertical = 8.dp)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(Locales.getString("set_press_back", appLanguage), color = UltraTokens.Divider, fontSize = 12.sp)
                    }
                }
            }

            // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â RIGHT CONTENT Ã¢â‚¬â€ Active Section Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight()
                    .padding(horizontal = 48.dp, vertical = 24.dp)
                    .focusGroup()
            ) {
                when (activeSection) {
                    "general" -> GeneralSettingsSection(
                        appLanguage = appLanguage,
                        onLanguageChange = onLanguageChange,
                        autoPlayNext = autoPlayNext,
                        onAutoPlayChange = { 
                            autoPlayNext = it
                            saveBoolPref("settings.autoplay", it)
                        },
                        timeFormat24h = timeFormat24h,
                        onTimeFormatChange = { 
                            timeFormat24h = it
                            saveBoolPref("settings.time24h", it)
                        }
                    )
                    "video" -> VideoAudioSettingsSection(
                        appLanguage = appLanguage,
                        selectedQuality = selectedVideoQuality,
                        onQualityChange = { 
                            selectedVideoQuality = it
                            saveStringPref("settings.video_quality", it)
                        },
                        selectedAudioLang = selectedAudioLang,
                        onAudioLangChange = { 
                            selectedAudioLang = it
                            saveStringPref("settings.audio_lang", it)
                        },
                        selectedSubLang = selectedSubLang,
                        onSubLangChange = { selectedSubLang = it }
                    )
                    "parental" -> ParentalControlsSection(
                        appLanguage = appLanguage,
                        enabled = parentalEnabled,
                        onEnabledChange = { parentalEnabled = it }
                    )
                    "appearance" -> AppearanceSection(
                        appLanguage = appLanguage,
                        selectedTheme = selectedTheme,
                        onThemeChange = { selectedTheme = it }
                    )
                    "storage" -> StorageSection(appLanguage = appLanguage)
                    "about" -> AboutSection(appLanguage = appLanguage)
                    "account" -> AccountSection(
                        appLanguage = appLanguage,
                        channelCount = channelCount,
                        categoryCount = categoryCount,
                        onLogout = onLogout
                    )
                }
            }
        }
    }
}

// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
//  Settings Category Sidebar Item
// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

@Composable
private fun SettingsCategoryItem(
    icon: ImageVector,
    label: String,
    isSelected: Boolean,
    modifier: Modifier = Modifier,
    onFocus: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    val bgColor by animateColorAsState(
        targetValue = when {
            isFocused || isSelected -> Color.White
            else -> Color.Transparent
        },
        animationSpec = tween(200),
        label = "setCatBg"
    )
    val iconTint by animateColorAsState(
        targetValue = when {
            isFocused || isSelected -> Color.Black
            else -> UltraTokens.Divider
        },
        animationSpec = tween(200),
        label = "setCatIcon"
    )
    val textColor = if (isFocused || isSelected) Color.Black else UltraTokens.TextSecondary
    
    val scale by animateFloatAsState(
        targetValue = if (isFocused || isSelected) 1.05f else 1f,
        animationSpec = androidx.compose.animation.core.spring(
            dampingRatio = 0.65f,
            stiffness = androidx.compose.animation.core.Spring.StiffnessLow
        ),
        label = "setCatScale"
    )

    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 2.dp)
            .scale(scale)
            .clip(RoundedCornerShape(12.dp))
            .background(bgColor)
            .border(1.dp, Color.White.copy(alpha = 0.3f), RoundedCornerShape(12.dp))
            .onFocusChanged {
                isFocused = it.isFocused
                if (it.isFocused) onFocus()
            }
            .focusable()
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            icon,
            contentDescription = label,
            tint = iconTint,
            modifier = Modifier.size(20.dp)
        )
        Spacer(Modifier.width(14.dp))
        Text(
            text = label,
            color = textColor,
            fontSize = 14.sp,
            fontWeight = if (isSelected || isFocused) FontWeight.Bold else FontWeight.Medium
        )
    }
}

// ════════════════════════════════════════════════════
//  SECTION: General
// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

@Composable
private fun GeneralSettingsSection(
    appLanguage: String,
    onLanguageChange: (String) -> Unit,
    autoPlayNext: Boolean,
    onAutoPlayChange: (Boolean) -> Unit,
    timeFormat24h: Boolean,
    onTimeFormatChange: (Boolean) -> Unit
) {
    LazyColumn(modifier = Modifier.fillMaxSize()) {
        item { SectionHeader(Locales.getString("gen_title", appLanguage)) }

        item { Spacer(Modifier.height(24.dp)) }

        // Language Dropdown (Simulated as a row that expands or similar? We'll just use a SubHeader and Radios)
        item {
            SettingsSubHeader(Locales.getString("gen_app_lang", appLanguage))
            Text(Locales.getString("gen_app_lang_desc", appLanguage), color = UltraTokens.TextSecondary, fontSize = 12.sp)
            Spacer(Modifier.height(12.dp))
        }

        items(Locales.languages.size) { index ->
            val lang = Locales.languages[index]
            SettingsRadioRow(
                title = lang,
                isSelected = appLanguage == lang,
                onClick = { onLanguageChange(lang) }
            )
        }

        item { Spacer(Modifier.height(24.dp)) }

        item {
            SettingsToggleRow(
                icon = Icons.Rounded.SkipNext,
                title = Locales.getString("gen_autoplay", appLanguage),
                description = Locales.getString("gen_autoplay_desc", appLanguage),
                isEnabled = autoPlayNext,
                onToggle = { onAutoPlayChange(!autoPlayNext) }
            )
            Spacer(Modifier.height(12.dp))
        }

        item {
            SettingsToggleRow(
                icon = Icons.Rounded.Schedule,
                title = Locales.getString("gen_24h", appLanguage),
                description = Locales.getString("gen_24h_desc", appLanguage),
                isEnabled = timeFormat24h,
                onToggle = { onTimeFormatChange(!timeFormat24h) }
            )
        }
    }
}

// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
//  SECTION: Video & Audio
// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

@Composable
private fun VideoAudioSettingsSection(
    appLanguage: String,
    selectedQuality: String,
    onQualityChange: (String) -> Unit,
    selectedAudioLang: String,
    onAudioLangChange: (String) -> Unit,
    selectedSubLang: String,
    onSubLangChange: (String) -> Unit
) {
    LazyColumn(modifier = Modifier.fillMaxSize()) {
        item { SectionHeader(Locales.getString("set_video_audio", appLanguage)) }
        item { Spacer(Modifier.height(20.dp)) }

        // Video Quality
        item {
            SettingsSubHeader(Locales.getString("vid_title", appLanguage))
        }
        val qualities = listOf("Auto", "1080p (Full HD)", "720p (HD)", "480p (SD)", "360p")
        items(qualities.size) { index ->
            val titleStr = if(qualities[index] == "Auto") Locales.getString("vid_auto", appLanguage) else qualities[index]
            val isSelected = selectedQuality == qualities[index] || (selectedQuality == "خۆکار" && qualities[index] == "Auto")
            SettingsRadioRow(
                title = titleStr,
                isSelected = isSelected,
                onClick = { onQualityChange(qualities[index]) }
            )
        }

        item { Spacer(Modifier.height(24.dp)) }

        // Audio Language
        item {
            SettingsSubHeader(Locales.getString("vid_audio", appLanguage))
        }
        val audioLangs = listOf("Default", "English", "Arabic", "Kurdish Sorani", "Turkish", "French", "Spanish")
        items(audioLangs.size) { index ->
            val titleStr = when(audioLangs[index]) {
                "Default" -> Locales.getString("aud_default", appLanguage)
                "English" -> Locales.getString("aud_en", appLanguage)
                "Arabic" -> Locales.getString("aud_ar", appLanguage)
                "Kurdish Sorani" -> Locales.getString("aud_ku", appLanguage)
                "Turkish" -> Locales.getString("aud_tr", appLanguage)
                "French" -> Locales.getString("aud_fr", appLanguage)
                "Spanish" -> Locales.getString("aud_es", appLanguage)
                else -> audioLangs[index]
            }
            val isSelected = selectedAudioLang == audioLangs[index] || 
                             (selectedAudioLang == "بنەڕەتی" && audioLangs[index] == "Default") ||
                             (selectedAudioLang == "ئینگلیزی" && audioLangs[index] == "English") ||
                             (selectedAudioLang == "عەرەبی" && audioLangs[index] == "Arabic") ||
                             (selectedAudioLang == "کوردی سۆرانی" && audioLangs[index] == "Kurdish Sorani") ||
                             (selectedAudioLang == "تورکی" && audioLangs[index] == "Turkish") ||
                             (selectedAudioLang == "فەڕەنسی" && audioLangs[index] == "French") ||
                             (selectedAudioLang == "ئیسپانی" && audioLangs[index] == "Spanish")
                             
            SettingsRadioRow(
                title = titleStr,
                isSelected = isSelected,
                onClick = { onAudioLangChange(audioLangs[index]) }
            )
        }

        item { Spacer(Modifier.height(24.dp)) }

        // Subtitle Language
        item {
            SettingsSubHeader(Locales.getString("vid_sub", appLanguage))
        }
        val subLangs = listOf("Off", "English", "Arabic", "Kurdish Sorani", "Turkish", "French", "Spanish")
        items(subLangs.size) { index ->
            val titleStr = when(subLangs[index]) {
                "Off" -> Locales.getString("sub_off", appLanguage)
                "English" -> Locales.getString("aud_en", appLanguage)
                "Arabic" -> Locales.getString("aud_ar", appLanguage)
                "Kurdish Sorani" -> Locales.getString("aud_ku", appLanguage)
                "Turkish" -> Locales.getString("aud_tr", appLanguage)
                "French" -> Locales.getString("aud_fr", appLanguage)
                "Spanish" -> Locales.getString("aud_es", appLanguage)
                else -> subLangs[index]
            }
            val isSelected = selectedSubLang == subLangs[index] || 
                             (selectedSubLang == "بێدەنگ" && subLangs[index] == "Off") ||
                             (selectedSubLang == "ئینگلیزی" && subLangs[index] == "English") ||
                             (selectedSubLang == "عەرەبی" && subLangs[index] == "Arabic") ||
                             (selectedSubLang == "کوردی سۆرانی" && subLangs[index] == "Kurdish Sorani") ||
                             (selectedSubLang == "تورکی" && subLangs[index] == "Turkish") ||
                             (selectedSubLang == "فەڕەنسی" && subLangs[index] == "French") ||
                             (selectedSubLang == "ئیسپانی" && subLangs[index] == "Spanish")
                             
            SettingsRadioRow(
                title = titleStr,
                isSelected = isSelected,
                onClick = { onSubLangChange(subLangs[index]) }
            )
        }
    }
}

// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
//  SECTION: Parental Controls
// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

@Composable
private fun ParentalControlsSection(
    appLanguage: String,
    enabled: Boolean,
    onEnabledChange: (Boolean) -> Unit
) {
    Column(modifier = Modifier.fillMaxSize()) {
        SectionHeader(Locales.getString("par_title", appLanguage))

        Spacer(Modifier.height(24.dp))

        // Lock toggle
        SettingsToggleRow(
            icon = Icons.Rounded.Lock,
            title = Locales.getString("par_enable", appLanguage),
            description = Locales.getString("par_enable_desc", appLanguage),
            isEnabled = enabled,
            onToggle = { onEnabledChange(!enabled) }
        )

        if (enabled) {
            Spacer(Modifier.height(16.dp))

            // PIN display (mock)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(UltraTokens.SurfaceHover)
                    .padding(20.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        Locales.getString("par_current", appLanguage),
                        color = UltraTokens.TextSecondary,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Medium
                    )
                    Spacer(Modifier.height(4.dp))
                    Text(
                        "Ã¢â‚¬Â¢ Ã¢â‚¬Â¢ Ã¢â‚¬Â¢ Ã¢â‚¬Â¢",
                        color = Color.White,
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 4.sp
                    )
                }
                Icon(
                    Icons.Rounded.Edit,
                    contentDescription = "Change PIN",
                    tint = UltraTokens.Accent,
                    modifier = Modifier.size(20.dp)
                )
            }

            Spacer(Modifier.height(16.dp))

            // Info
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(10.dp))
                    .background(UltraTokens.Accent.copy(alpha = 0.08f))
                    .padding(16.dp),
                verticalAlignment = Alignment.Top
            ) {
                Icon(
                    Icons.Rounded.Info,
                    contentDescription = null,
                    tint = UltraTokens.Accent,
                    modifier = Modifier.size(18.dp)
                )
                Spacer(Modifier.width(12.dp))
                Text(
                    Locales.getString("par_desc", appLanguage),
                    color = UltraTokens.TextSecondary,
                    fontSize = 13.sp
                )
            }
        }
    }
}

// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
//  SECTION: Appearance
// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

@Composable
private fun AppearanceSection(
    appLanguage: String,
    selectedTheme: String,
    onThemeChange: (String) -> Unit
) {
    Column(modifier = Modifier.fillMaxSize()) {
        SectionHeader(Locales.getString("app_title", appLanguage))

        Spacer(Modifier.height(24.dp))

        SettingsSubHeader(Locales.getString("app_theme", appLanguage))

        val themes = listOf(
            Triple("dark", UltraTokens.Surface, Locales.getString("app_dark", appLanguage)),
            Triple("amoled", Color.Black, Locales.getString("app_amoled", appLanguage)),
            Triple("blue", Color(0xFF0A1628), Locales.getString("app_blue", appLanguage)),
        )

        themes.forEach { (name, color, desc) ->
            ThemeOptionRow(
                name = if(name == "dark") Locales.getString("app_dark", appLanguage) else if(name == "amoled") Locales.getString("app_amoled", appLanguage) else Locales.getString("app_blue", appLanguage),
                previewColor = color,
                description = desc,
                isSelected = selectedTheme == name,
                onClick = { onThemeChange(name) }
            )
            Spacer(Modifier.height(6.dp))
        }
    }
}

@Composable
private fun ThemeOptionRow(
    name: String,
    previewColor: Color,
    description: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    val bgColor by animateColorAsState(
        when {
            isFocused -> UltraTokens.Accent
            isSelected -> UltraTokens.SurfaceHover
            else -> UltraTokens.SurfaceHover
        },
        tween(200),
        label = "themeBg"
    )

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .scaleOnFocus()
            .clip(RoundedCornerShape(12.dp))
            .background(bgColor)
            .onFocusChanged { isFocused = it.isFocused }
            .focusable()
            .onKeyEvent { ev ->
                if (ev.nativeKeyEvent.action == KeyEvent.ACTION_DOWN &&
                    (ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_DPAD_CENTER ||
                            ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_ENTER || ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_NUMPAD_ENTER)
                ) {
                    onClick()
                    true
                } else false
            }
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Color preview
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(previewColor)
                .border(
                    1.dp,
                    if (isFocused) Color.White.copy(alpha = 0.4f) else Color.White.copy(alpha = 0.1f),
                    RoundedCornerShape(8.dp)
                )
        )
        Spacer(Modifier.width(16.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                name,
                color = if (isFocused) Color.Black else UltraTokens.Text,
                fontSize = 15.sp,
                fontWeight = FontWeight.SemiBold
            )
            Text(
                description,
                color = if (isFocused) Color.Black.copy(alpha = 0.7f) else UltraTokens.Divider,
                fontSize = 12.sp
            )
        }
        // Radio
        Box(
            modifier = Modifier
                .size(18.dp)
                .clip(CircleShape)
                .border(
                    2.dp,
                    if (isFocused) Color.Black else if (isSelected) UltraTokens.Accent else UltraTokens.Divider,
                    CircleShape
                ),
            contentAlignment = Alignment.Center
        ) {
            if (isSelected) {
                Box(
                    modifier = Modifier
                        .size(10.dp)
                        .clip(CircleShape)
                        .background(if (isFocused) Color.Black else UltraTokens.Accent)
                )
            }
        }
    }
}

// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
//  SECTION: Storage & Cache
// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

@Composable
private fun StorageSection(appLanguage: String) {
    Column(modifier = Modifier.fillMaxSize()) {
        SectionHeader(Locales.getString("sto_title", appLanguage))

        Spacer(Modifier.height(24.dp))

        // Cache info card
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(14.dp))
                .background(UltraTokens.SurfaceHover)
                .padding(20.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(Locales.getString("sto_img", appLanguage), color = UltraTokens.TextSecondary, fontSize = 12.sp)
                Spacer(Modifier.height(4.dp))
                Text(
                    Locales.getString("sto_img_desc", appLanguage),
                    color = UltraTokens.Text,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Medium
                )
            }
            Icon(
                Icons.Rounded.Image,
                contentDescription = null,
                tint = UltraTokens.Divider,
                modifier = Modifier.size(24.dp)
            )
        }

        Spacer(Modifier.height(12.dp))

        // Clear cache button
        SettingsActionButton(
            icon = Icons.Rounded.DeleteSweep,
            title = Locales.getString("sto_clear", appLanguage),
            description = Locales.getString("sto_clear_desc", appLanguage),
            accentColor = UltraTokens.Movie,
            onClick = { /* Clear cache logic */ }
        )

        Spacer(Modifier.height(12.dp))

        SettingsActionButton(
            icon = Icons.Rounded.Refresh,
            title = Locales.getString("sto_refresh", appLanguage),
            description = Locales.getString("sto_refresh_desc", appLanguage),
            accentColor = UltraTokens.Accent,
            onClick = { /* Refresh logic */ }
        )
    }
}

// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
//  SECTION: About
// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

@Composable
private fun AboutSection(appLanguage: String) {
    Column(modifier = Modifier.fillMaxSize()) {
        SectionHeader(Locales.getString("abt_title", appLanguage))

        Spacer(Modifier.height(24.dp))

        // App info card
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(16.dp))
                .background(UltraTokens.SurfaceHover)
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                Icons.Rounded.LiveTv,
                contentDescription = null,
                tint = UltraTokens.Accent,
                modifier = Modifier.size(48.dp)
            )
            Spacer(Modifier.height(12.dp))
            Row {
                Text(
                    "KOBANI ",
                    color = Color.White,
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Black,
                    letterSpacing = 2.sp
                )
                Text(
                    "4K",
                    color = UltraTokens.Accent,
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Black,
                    letterSpacing = 2.sp
                )
            }
            Spacer(Modifier.height(4.dp))
            Text(
                Locales.getString("abt_prem", appLanguage),
                color = UltraTokens.Divider,
                fontSize = 13.sp,
                letterSpacing = 2.sp
            )
        }

        Spacer(Modifier.height(20.dp))

        // Version details
        val infoItems = listOf(
            Pair(Locales.getString("abt_ver", appLanguage), "2.0.0"),
            Pair(Locales.getString("abt_build", appLanguage), "TV-Compose"),
            Pair(Locales.getString("abt_plat", appLanguage), "Android ${Build.VERSION.RELEASE}"),
            Pair(Locales.getString("abt_dev", appLanguage), Build.MODEL),
            Pair(Locales.getString("abt_api", appLanguage), Build.VERSION.SDK_INT.toString()),
        )

        infoItems.forEach { (label, value) ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(label, color = UltraTokens.TextSecondary, fontSize = 14.sp)
                Text(
                    value,
                    color = UltraTokens.Text,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium
                )
            }
            Box(
                Modifier
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(Color.White.copy(alpha = 0.04f))
            )
        }
    }
}

// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
//  SECTION: Account
// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

@Composable
private fun AccountSection(
    appLanguage: String,
    channelCount: Int,
    categoryCount: Int,
    onLogout: () -> Unit
) {
    Column(modifier = Modifier.fillMaxSize()) {
        SectionHeader(Locales.getString("acc_title", appLanguage))

        Spacer(Modifier.height(24.dp))

        // Account info
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(14.dp))
                .background(UltraTokens.SurfaceHover)
                .padding(20.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(52.dp)
                    .clip(CircleShape)
                    .background(UltraTokens.SurfaceHover),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    Icons.Rounded.Person,
                    contentDescription = null,
                    tint = UltraTokens.Accent,
                    modifier = Modifier.size(28.dp)
                )
            }
            Spacer(Modifier.width(16.dp))
            Column {
                Text(
                    Locales.getString("acc_active", appLanguage),
                    color = Color.White,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold
                )
                Spacer(Modifier.height(4.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        Modifier
                            .size(6.dp)
                            .clip(CircleShape)
                            .background(UltraTokens.Sports)
                    )
                    Spacer(Modifier.width(6.dp))
                    Text(
                        Locales.getString("acc_act_via", appLanguage),
                        color = UltraTokens.TextSecondary,
                        fontSize = 13.sp
                    )
                }
            }
        }

        Spacer(Modifier.height(16.dp))

        // Stats
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            StatCard(
                label = Locales.getString("lbl_channels", appLanguage),
                value = channelCount.toString(),
                icon = Icons.Rounded.LiveTv,
                modifier = Modifier.weight(1f)
            )
            StatCard(
                label = Locales.getString("lbl_categories", appLanguage),
                value = categoryCount.toString(),
                icon = Icons.Rounded.Category,
                modifier = Modifier.weight(1f)
            )
        }

        Spacer(Modifier.height(32.dp))

        // Logout button
        SettingsActionButton(
            icon = Icons.Rounded.Logout,
            title = Locales.getString("acc_signout", appLanguage),
            description = Locales.getString("acc_signout_desc", appLanguage),
            accentColor = UltraTokens.Movie,
            onClick = onLogout
        )
    }
}

@Composable
private fun StatCard(
    label: String,
    value: String,
    icon: ImageVector,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .background(UltraTokens.SurfaceHover)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(RoundedCornerShape(10.dp))
                .background(UltraTokens.SurfaceHover),
            contentAlignment = Alignment.Center
        ) {
            Icon(icon, contentDescription = null, tint = UltraTokens.Accent, modifier = Modifier.size(20.dp))
        }
        Spacer(Modifier.width(12.dp))
        Column {
            Text(value, color = Color.White, fontSize = 22.sp, fontWeight = FontWeight.Bold)
            Text(label, color = UltraTokens.Divider, fontSize = 12.sp)
        }
    }
}

// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
//  SHARED SETTINGS COMPONENTS
// Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

@Composable
private fun SectionHeader(title: String) {
    Text(
        text = title,
        color = Color.White,
        fontSize = 24.sp,
        fontWeight = FontWeight.Bold
    )
}

@Composable
private fun SettingsSubHeader(title: String) {
    Text(
        text = title,
        color = UltraTokens.Accent,
        fontSize = 11.sp,
        fontWeight = FontWeight.Bold,
        letterSpacing = 2.sp,
        modifier = Modifier.padding(vertical = 10.dp)
    )
}

@Composable
private fun SettingsToggleRow(
    icon: ImageVector,
    title: String,
    description: String,
    isEnabled: Boolean,
    onToggle: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    val bgColor by animateColorAsState(
        if (isFocused) UltraTokens.Accent.copy(alpha = 0.15f) else UltraTokens.SurfaceHover,
        tween(200),
        label = "toggleBg"
    )
    val borderColor by animateColorAsState(
        if (isFocused) UltraTokens.Accent else Color.Transparent,
        tween(200),
        label = "toggleBorder"
    )

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .scaleOnFocus()
            .clip(RoundedCornerShape(14.dp))
            .background(bgColor)
            .border(1.5.dp, borderColor, RoundedCornerShape(14.dp))
            .onFocusChanged { isFocused = it.isFocused }
            .focusable()
            .onKeyEvent { ev ->
                if (ev.nativeKeyEvent.action == KeyEvent.ACTION_DOWN &&
                    (ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_DPAD_CENTER ||
                            ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_ENTER || ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_NUMPAD_ENTER)
                ) {
                    onToggle()
                    true
                } else false
            }
            .padding(20.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            icon,
            contentDescription = null,
            tint = if (isFocused) UltraTokens.Accent else UltraTokens.Divider,
            modifier = Modifier.size(22.dp)
        )
        Spacer(Modifier.width(16.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                title,
                color = if (isFocused) Color.White else UltraTokens.Text,
                fontSize = 15.sp,
                fontWeight = FontWeight.SemiBold
            )
            Spacer(Modifier.height(2.dp))
            Text(
                description,
                color = if (isFocused) Color.White.copy(alpha = 0.7f) else UltraTokens.Divider,
                fontSize = 12.sp
            )
        }
        Spacer(Modifier.width(16.dp))

        // Toggle switch
        val toggleBg by animateColorAsState(
            if (isEnabled) UltraTokens.Accent else UltraTokens.SurfaceSelected,
            tween(200),
            label = "switchBg"
        )
        val knobOffset by animateFloatAsState(
            if (isEnabled) 1f else 0f,
            tween(200),
            label = "knobOffset"
        )

        Box(
            modifier = Modifier
                .width(44.dp)
                .height(24.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(toggleBg)
                .padding(3.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(18.dp)
                    .offset(x = (knobOffset * 20).dp)
                    .clip(CircleShape)
                    .background(Color.White)
            )
        }
    }
}

@Composable
private fun SettingsRadioRow(
    title: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    val bgColor by animateColorAsState(
        when {
            isFocused -> UltraTokens.Accent
            isSelected -> UltraTokens.SurfaceHover
            else -> Color.Transparent
        },
        tween(150),
        label = "sRadioBg"
    )

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .scaleOnFocus()
            .clip(RoundedCornerShape(8.dp))
            .background(bgColor)
            .onFocusChanged { isFocused = it.isFocused }
            .focusable()
            .onKeyEvent { ev ->
                if (ev.nativeKeyEvent.action == KeyEvent.ACTION_DOWN &&
                    (ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_DPAD_CENTER ||
                            ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_ENTER || ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_NUMPAD_ENTER)
                ) {
                    onClick()
                    true
                } else false
            }
            .padding(horizontal = 14.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = title,
            color = if (isFocused) Color.Black else if (isSelected) UltraTokens.Accent else UltraTokens.TextSecondary,
            fontSize = 14.sp,
            fontWeight = if (isSelected || isFocused) FontWeight.SemiBold else FontWeight.Normal
        )

        Box(
            modifier = Modifier
                .size(18.dp)
                .clip(CircleShape)
                .border(
                    2.dp,
                    if (isFocused) Color.Black
                    else if (isSelected) UltraTokens.Accent
                    else UltraTokens.Divider,
                    CircleShape
                ),
            contentAlignment = Alignment.Center
        ) {
            if (isSelected) {
                Box(
                    modifier = Modifier
                        .size(10.dp)
                        .clip(CircleShape)
                        .background(if (isFocused) Color.Black else UltraTokens.Accent)
                )
            }
        }
    }
}

@Composable
private fun SettingsActionButton(
    icon: ImageVector,
    title: String,
    description: String,
    accentColor: Color,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    val bgColor by animateColorAsState(
        if (isFocused) accentColor else UltraTokens.SurfaceHover,
        tween(200),
        label = "actionBg"
    )
    val borderColor by animateColorAsState(
        if (isFocused) accentColor else Color.Transparent,
        tween(200),
        label = "actionBorder"
    )
    val scale by animateFloatAsState(
        if (isFocused) 1.05f else 1f,
        androidx.compose.animation.core.spring(
            dampingRatio = 0.65f,
            stiffness = androidx.compose.animation.core.Spring.StiffnessLow
        ),
        label = "actionScale"
    )

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .scale(scale)
            .clip(RoundedCornerShape(14.dp))
            .background(bgColor)
            .border(1.5.dp, borderColor, RoundedCornerShape(14.dp))
            .onFocusChanged { isFocused = it.isFocused }
            .focusable()
            .onKeyEvent { ev ->
                if (ev.nativeKeyEvent.action == KeyEvent.ACTION_DOWN &&
                    (ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_DPAD_CENTER ||
                            ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_ENTER || ev.nativeKeyEvent.keyCode == KeyEvent.KEYCODE_NUMPAD_ENTER)
                ) {
                    onClick()
                    true
                } else false
            }
            .padding(20.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            icon,
            contentDescription = null,
            tint = if (isFocused) (if (accentColor == UltraTokens.Accent) Color.Black else Color.White) else accentColor,
            modifier = Modifier.size(22.dp)
        )
        Spacer(Modifier.width(16.dp))
        Column {
            Text(
                title,
                color = if (isFocused) (if (accentColor == UltraTokens.Accent) Color.Black else Color.White) else UltraTokens.Text,
                fontSize = 15.sp,
                fontWeight = FontWeight.SemiBold
            )
            Text(
                description,
                color = if (isFocused) (if (accentColor == UltraTokens.Accent) Color.Black.copy(alpha = 0.7f) else Color.White.copy(alpha = 0.7f)) else UltraTokens.Divider,
                fontSize = 12.sp
            )
        }
    }
}

