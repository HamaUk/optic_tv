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
    // Primary Palette
    val Accent       = Color(0xFF00A8FF) // Electric Blue
    val Accent2      = Color(0xFF00E5FF) // Neon Cyan
    val AccentWarm   = Color(0xFFF59E0B) // Warm Amber (CTA)
    val AccentGlow   = Color(0x9900A8FF)
    val AccentSoft   = Color(0x3300A8FF)
    val AccentTint   = Color(0x1A00A8FF)

    val GradientAccent = Brush.linearGradient(listOf(Color(0xFF00A8FF), Color(0xFF0066CC)))
    val GradientHero   = Brush.linearGradient(listOf(Color(0xFF00A8FF), Color(0xFF00E5FF)))

    // Status
    val Live = Color(0xFFFF3A2F)
    val Hd   = Color(0xFF00E5A0)
    val Uhd  = Color(0xFFFFB547)
    val Ok   = Color(0xFF7FFFAF)
    val Warn = Color(0xFFFF6B6B)

    // Foreground
    val Fg  = Color(0xFFEAECF0)
    val Fg2 = Color(0xFFC0C5D0)
    val Fg3 = Color(0xFF6B7280)
    val Fg4 = Color(0xFF4B5563)

    // Borders
    val Line      = Color(0x14FFFFFF)
    val Line2     = Color(0x24FFFFFF)
    val LineFocus = Color(0xFF00A8FF)

    // Surfaces (dark with depth)
    val BgDeep        = Color(0xFF06070B)
    val Surface1      = Color(0xFF0D0E14)
    val Surface2      = Color(0xFF14151E)
    val Surface3      = Color(0xFF1C1D28)
    val SurfaceGlass  = Color(0x3314151E) // Glassmorphism
    val SurfacePanel  = Color(0xE60D0E14) // Opaque panel
    val Scrim         = Color(0x73000000)
    val ScrimStrong   = Color(0xD9000000)

    // CTA
    val CtaBg      = Color(0xFF00A8FF)
    val CtaFgOnCta = Color(0xFFFFFFFF)

    // Radii
    val RadiusXs: Dp = 6.dp
    val RadiusSm: Dp = 10.dp
    val RadiusMd: Dp = 14.dp
    val RadiusLg: Dp = 20.dp
    val RadiusXl: Dp = 28.dp

    // Layout dimensions
    val SidebarCollapsed: Dp = 92.dp
    val SidebarExpanded:  Dp = 240.dp
    val TopBarHeight:     Dp = 72.dp
    val EdgeGutter:       Dp = 48.dp
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
        fontSize = 48.sp,
        lineHeight = 52.sp,
        letterSpacing = (-1.5).sp,
        fontWeight = FontWeight.Black,
    )
    val ScreenTitle = TextStyle(
        fontFamily = UltraFonts.Sans,
        fontSize = 36.sp,
        lineHeight = 42.sp,
        letterSpacing = (-0.5).sp,
        fontWeight = FontWeight.Bold,
    )
    val SectionTitle = TextStyle(
        fontFamily = UltraFonts.Sans,
        fontSize = 24.sp,
        lineHeight = 30.sp,
        fontWeight = FontWeight.Bold,
    )
    val CardTitle = TextStyle(
        fontFamily = UltraFonts.Sans,
        fontSize = 18.sp,
        lineHeight = 24.sp,
        fontWeight = FontWeight.SemiBold,
    )
    val Body = TextStyle(
        fontFamily = UltraFonts.Sans,
        fontSize = 16.sp,
        lineHeight = 22.sp,
    )
    val Body2 = TextStyle(
        fontFamily = UltraFonts.Sans,
        fontSize = 14.sp,
        lineHeight = 20.sp,
    )
    val Caption = TextStyle(
        fontFamily = UltraFonts.Sans,
        fontSize = 12.sp,
        lineHeight = 16.sp,
        color = UltraTokens.Fg3,
    )
    val Eyebrow = TextStyle(
        fontFamily = UltraFonts.Sans,
        fontSize = 12.sp,
        letterSpacing = 2.sp,
        fontWeight = FontWeight.Bold,
        color = UltraTokens.Accent,
    )
    val KeypadDigit = TextStyle(
        fontFamily = UltraFonts.Sans,
        fontSize = 28.sp,
        fontWeight = FontWeight.Bold,
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
