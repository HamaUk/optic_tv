package com.kobani4k.app.tv.ui.theme

import android.os.Build
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.scale
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.*
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.*
import androidx.compose.ui.unit.*
import androidx.tv.material3.*

// ═══════════════════════════════════════════════════════════════════
// KOBANI 4K — GLASSMORPHIC DESIGN SYSTEM
// ═══════════════════════════════════════════════════════════════════

object UltraTokens {

    // ─── Backgrounds ───
    val Background   = Color(0xFF07070C)   // deep void
    val Surface      = Color(0xFF0D0D14)   // panels base
    val SurfaceHover = Color(0xFF151520)

    // ─── Glass ───
    val Glass       = Color(0x0DFFFFFF)   // ~5 % white
    val GlassStrong = Color(0x17FFFFFF)   // ~9 % white
    val Hairline    = Color(0x17FFFFFF)   // translucent borders

    // ─── Brand / Accent ───
    val Accent     = Color(0xFF5B7CF7)    // primary blue
    val AccentDark = Color(0xFF4A68D4)
    val AccentGradient = Brush.horizontalGradient(listOf(Accent, Color(0xFF9A5BF0)))

    val Blue   = Color(0xFF5B7CF7)
    val Violet = Color(0xFF9A5BF0)
    val Pink   = Color(0xFFF45BB0)
    val Teal   = Color(0xFF31D8C4)
    val Amber  = Color(0xFFF7B955)

    // ─── IPTV ───
    val Live   = Color(0xFFFF4D5E)
    val Movie  = Color(0xFFF7B955)
    val Sports = Color(0xFF31D8C4)
    val UHD    = Color(0xFFFF6D00)

    // ─── Typography ───
    val Text          = Color(0xFFF4F5FA)  // ink
    val TextSecondary = Color(0xFF9298AD)  // ink dim
    val TextFaint     = Color(0xFF5B6178)  // ink faint
    val Divider       = Color(0x22FFFFFF)

    // ─── Focus ───
    val Focus = Color(0xFF5B7CF7)

    // ─── Radius ───
    val RadiusLg   = 22.dp
    val RadiusMd   = 16.dp
    val CardRadius = 16.dp
    val ButtonRadius = 12.dp

    // ─── TV Layout ───
    val SideBar       = 220.dp
    val TopBar        = 80.dp
    val ScreenPadding = 50.dp

    // backward compat aliases
    val SurfaceSelected = Color(0xFF1E1E28)
}


// ═══════════════════════════════════════════════════════════════════
// GLASS PANEL — shared translucent container
// ═══════════════════════════════════════════════════════════════════

@Composable
fun GlassPanel(
    modifier: Modifier = Modifier,
    borderRadius: RoundedCornerShape = RoundedCornerShape(UltraTokens.RadiusMd),
    content: @Composable BoxScope.() -> Unit
) {
    Box(
        modifier = modifier
            .clip(borderRadius)
            .background(UltraTokens.Glass)
            .border(1.dp, UltraTokens.Hairline, borderRadius),
        content = content
    )
}


// ═══════════════════════════════════════════════════════════════════
// Typography
// ═══════════════════════════════════════════════════════════════════

object UltraFonts {
    val Main = FontFamily.SansSerif
}

object UltraType {

    val Hero = TextStyle(
        fontFamily = UltraFonts.Main,
        fontSize = 42.sp,
        fontWeight = FontWeight.Bold,
        color = UltraTokens.Text
    )

    val Title = TextStyle(
        fontFamily = UltraFonts.Main,
        fontSize = 32.sp,
        fontWeight = FontWeight.Bold,
        color = UltraTokens.Text
    )

    val Section = TextStyle(
        fontFamily = UltraFonts.Main,
        fontSize = 24.sp,
        fontWeight = FontWeight.Bold,
        color = UltraTokens.Text
    )

    val Card = TextStyle(
        fontFamily = UltraFonts.Main,
        fontSize = 18.sp,
        fontWeight = FontWeight.SemiBold,
        color = UltraTokens.Text
    )

    val Body = TextStyle(
        fontFamily = UltraFonts.Main,
        fontSize = 16.sp,
        color = UltraTokens.TextSecondary
    )
}


// ═══════════════════════════════════════════════════════════════════
// TV Focus System — brighter-border style (no color inversion)
// ═══════════════════════════════════════════════════════════════════

@Composable
fun Modifier.scaleOnFocus(scaleFactor: Float = 1.05f): Modifier {
    var focused by remember { mutableStateOf(false) }

    val scale by animateFloatAsState(
        targetValue = if (focused) scaleFactor else 1f,
        animationSpec = androidx.compose.animation.core.spring(
            dampingRatio = 0.65f,
            stiffness = androidx.compose.animation.core.Spring.StiffnessLow
        ),
        label = "generic_focus_scale"
    )

    return this
        .scale(scale)
        .onFocusChanged { focused = it.isFocused }
}

@Composable
fun Modifier.kobaniFocus(): Modifier {
    var focused by remember { mutableStateOf(false) }

    val scale by animateFloatAsState(
        targetValue = if (focused) 1.04f else 1f,
        animationSpec = androidx.compose.animation.core.spring(
            dampingRatio = 0.65f,
            stiffness = androidx.compose.animation.core.Spring.StiffnessLow
        ),
        label = "focus_scale"
    )

    val borderColor by animateColorAsState(
        targetValue = if (focused) Color.White.copy(alpha = 0.55f) else Color.Transparent,
        animationSpec = tween(200),
        label = "focus_border"
    )

    return this
        .scale(scale)
        .border(
            width = if (focused) 1.5.dp else 0.dp,
            color = borderColor,
            shape = RoundedCornerShape(UltraTokens.CardRadius)
        )
        .onFocusChanged { focused = it.isFocused }
}


// ═══════════════════════════════════════════════════════════════════
// Cards & Buttons
// ═══════════════════════════════════════════════════════════════════

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun kobaniCardColors(): CardColors {
    return CardDefaults.colors(
        containerColor = UltraTokens.Glass,
        contentColor = Color.White,
        focusedContainerColor = UltraTokens.GlassStrong,
        focusedContentColor = Color.White
    )
}

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun kobaniButtonColors(): ButtonColors {
    return ButtonDefaults.colors(
        containerColor = UltraTokens.Glass,
        contentColor = Color.White,
        focusedContainerColor = Color.White,
        focusedContentColor = Color.Black
    )
}


// ═══════════════════════════════════════════════════════════════════
// IPTV Badge Colors
// ═══════════════════════════════════════════════════════════════════

fun iptvBadgeColor(type: String): Color {
    return when (type.lowercase()) {
        "live"  -> UltraTokens.Live
        "movie" -> UltraTokens.Movie
        "sport" -> UltraTokens.Sports
        "4k"    -> UltraTokens.UHD
        else    -> UltraTokens.Accent
    }
}
