package com.kobani4k.app.tv.ui.theme

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import android.view.KeyEvent
import androidx.tv.material3.*

// ═══════════════════════════════════════════════════
//  KOBANI 4K  —  Premium TV Design System
// ═══════════════════════════════════════════════════

object UltraTokens {
    // ═══════════════════════════════════════════════════
    //  Premium TV Palette
    // ═══════════════════════════════════════════════════

    // Primary Palette (Vibrant, high-contrast, premium)
    val Accent       = Color(0xFF00C6FF) // Vivid Cyan-Blue
    val Accent2      = Color(0xFF0072FF) // Deep Royal Blue
    val AccentWarm   = Color(0xFFFF3366) // Neon Coral (CTA)
    val AccentGlow   = Color(0x9900C6FF)
    val AccentSoft   = Color(0x3300C6FF)
    val AccentTint   = Color(0x1A00C6FF)

    val GradientAccent = Brush.linearGradient(listOf(Color(0xFF00C6FF), Color(0xFF0072FF)))
    val GradientHero   = Brush.linearGradient(listOf(Color(0xFF00C6FF), Color(0xFF00E5FF)))
    
    // Status (High-luminance for TV)
    val Live = Color(0xFFFF2A2A)
    val Hd   = Color(0xFF00FFB2)
    val Uhd  = Color(0xFFFFBE0B)
    val Ok   = Color(0xFF38E54D)
    val Warn = Color(0xFFFF5722)

    // Foreground (Crisp legibility)
    val Fg  = Color(0xFFFFFFFF)
    val Fg2 = Color(0xFFE2E8F0)
    val Fg3 = Color(0xFF94A3B8)
    val Fg4 = Color(0xFF64748B)

    // Borders (Subtle glass reflections)
    val Line      = Color(0x1AFFFFFF)
    val Line2     = Color(0x26FFFFFF)
    val LineFocus = Color(0xFF00C6FF)

    // Surfaces (OLED true-blacks and rich dark-blues)
    val BgDeep        = Color(0xFF030509) // Absolute OLED Black
    val Surface1      = Color(0xFF0B111A) // Deep Navy Base
    val Surface2      = Color(0xFF111827) // Elevated Surface
    val Surface3      = Color(0xFF1E293B) // Floating Element
    val SurfaceGlass  = Color(0x40111827) // Rich Glassmorphism
    val SurfacePanel  = Color(0xE60B111A) // Opaque dark panel
    val Scrim         = Color(0x8C000000)
    val ScrimStrong   = Color(0xEE000000)

    // CTA
    val CtaBg      = Color(0xFF00C6FF)
    val CtaFgOnCta = Color(0xFF030509)

    // Radii (Softer, modern curves)
    val RadiusXs: Dp = 8.dp
    val RadiusSm: Dp = 12.dp
    val RadiusMd: Dp = 16.dp
    val RadiusLg: Dp = 24.dp
    val RadiusXl: Dp = 32.dp

    // Layout dimensions
    val SidebarCollapsed: Dp = 96.dp
    val SidebarExpanded:  Dp = 280.dp
    val TopBarHeight:     Dp = 80.dp
    val EdgeGutter:       Dp = 56.dp
}

object UltraFonts {
    val Sans:  FontFamily = FontFamily.SansSerif
    val Mono:  FontFamily = FontFamily.Monospace
    val Serif: FontFamily = FontFamily.Serif
}

// ═══════════════════════════════════════════════════
//  Typography Scale (TV 10-foot optimized)
// ═══════════════════════════════════════════════════

object UltraType {
    val HeroDisplay = TextStyle(
        fontFamily = UltraFonts.Sans,
        fontSize = 54.sp,
        lineHeight = 58.sp,
        letterSpacing = (-2).sp,
        fontWeight = FontWeight.Black,
    )
    val ScreenTitle = TextStyle(
        fontFamily = UltraFonts.Sans,
        fontSize = 40.sp,
        lineHeight = 46.sp,
        letterSpacing = (-1).sp,
        fontWeight = FontWeight.ExtraBold,
    )
    val SectionTitle = TextStyle(
        fontFamily = UltraFonts.Sans,
        fontSize = 28.sp,
        lineHeight = 34.sp,
        fontWeight = FontWeight.Bold,
        letterSpacing = (-0.5).sp,
    )
    val CardTitle = TextStyle(
        fontFamily = UltraFonts.Sans,
        fontSize = 20.sp,
        lineHeight = 26.sp,
        fontWeight = FontWeight.Bold,
    )
    val Body = TextStyle(
        fontFamily = UltraFonts.Sans,
        fontSize = 16.sp,
        lineHeight = 24.sp,
    )
    val Body2 = TextStyle(
        fontFamily = UltraFonts.Sans,
        fontSize = 14.sp,
        lineHeight = 22.sp,
    )
    val Caption = TextStyle(
        fontFamily = UltraFonts.Sans,
        fontSize = 12.sp,
        lineHeight = 16.sp,
        fontWeight = FontWeight.Medium,
        color = UltraTokens.Fg3,
    )
    val Eyebrow = TextStyle(
        fontFamily = UltraFonts.Sans,
        fontSize = 13.sp,
        letterSpacing = 2.5.sp,
        fontWeight = FontWeight.Bold,
        color = UltraTokens.Accent,
    )
    val KeypadDigit = TextStyle(
        fontFamily = UltraFonts.Sans,
        fontSize = 32.sp,
        fontWeight = FontWeight.Black,
    )
    val Mono = TextStyle(fontFamily = UltraFonts.Mono, fontSize = 14.sp)
}

// ═══════════════════════════════════════════════════
//  TV Material 3 Color Helpers
// ═══════════════════════════════════════════════════

@Composable
@ExperimentalTvMaterial3Api
fun ultraCardColors(
    containerColor: Color = UltraTokens.Surface1,
    contentColor: Color = UltraTokens.Fg,
    focusedContainerColor: Color = UltraTokens.AccentSoft,
    focusedContentColor: Color = UltraTokens.Fg,
): CardColors = CardDefaults.colors(
    containerColor = containerColor,
    contentColor = contentColor,
    focusedContainerColor = focusedContainerColor,
    focusedContentColor = focusedContentColor,
    pressedContainerColor = focusedContainerColor,
    pressedContentColor = focusedContentColor,
)

@Composable
@ExperimentalTvMaterial3Api
fun ultraButtonColors(
    containerColor: Color = UltraTokens.Surface2,
    contentColor: Color = UltraTokens.Fg,
    focusedContainerColor: Color = UltraTokens.Accent,
    focusedContentColor: Color = Color.White,
): ButtonColors = ButtonDefaults.colors(
    containerColor = containerColor,
    contentColor = contentColor,
    focusedContainerColor = focusedContainerColor,
    focusedContentColor = focusedContentColor,
    pressedContainerColor = focusedContainerColor,
    pressedContentColor = focusedContentColor,
)
