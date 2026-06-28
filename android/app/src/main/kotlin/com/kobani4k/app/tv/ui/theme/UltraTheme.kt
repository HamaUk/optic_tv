package com.kobani4k.app.tv.ui.theme

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight

object UltraTokens {
    val Accent       = Color(0xFF3881A1)
    val Accent2      = Color(0xFF51AAFF)
    val AccentGlow   = Color(0x8C3881A1)
    val AccentSoft   = Color(0x243881A1)
    val AccentTint   = Color(0x1A3881A1)

    val Live = Color(0xFFFF3A2F)
    val Hd   = Color(0xFF00E5A0)
    val Uhd  = Color(0xFFFFB547)
    val Ok   = Color(0xFF7FFFAF)
    val Warn = Color(0xFFFFB547)

    val Fg  = Color(0xFFE4E4E4)
    val Fg2 = Color(0xFFC7C7CF)
    val Fg3 = Color(0xFF8A8A94)
    val Fg4 = Color(0xFF5A5A64)

    val Line  = Color(0x14FFFFFF)
    val Line2 = Color(0x24FFFFFF)

    val Surface1      = Color(0xFF121319)
    val Surface2      = Color(0xFF202020)
    val Surface3      = Color(0xFF3C3C3C)
    val SurfaceStrong = Color(0xFF424242)
    val Scrim         = Color(0x73000000)
    val ScrimStrong   = Color(0xD9000000)

    val CtaBg        = Color(0xFFF79E0A)
    val CtaFgOnCta   = Color(0xFF0F0E17)

    val RadiusXs: Dp = 6.dp
    val RadiusSm: Dp = 10.dp
    val RadiusMd: Dp = 14.dp
    val RadiusLg: Dp = 20.dp
    val RadiusXl: Dp = 28.dp

    val SidebarCollapsed: Dp = 92.dp
    val SidebarExpanded:  Dp = 220.dp
    val TopBarHeight:     Dp = 76.dp
    val EdgeGutter:       Dp = 80.dp
    val LeftEdge:         Dp = 92.dp
}

object UltraFonts {
    val Sans:  FontFamily = FontFamily.SansSerif
    val Mono:  FontFamily = FontFamily.Monospace
    val Serif: FontFamily = FontFamily.Serif
}

@androidx.compose.runtime.Composable
@androidx.tv.material3.ExperimentalTvMaterial3Api
fun ultraCardColors(
    containerColor: androidx.compose.ui.graphics.Color = UltraTokens.Surface1,
    contentColor: androidx.compose.ui.graphics.Color = UltraTokens.Fg,
    focusedContainerColor: androidx.compose.ui.graphics.Color = UltraTokens.AccentSoft,
    focusedContentColor: androidx.compose.ui.graphics.Color = UltraTokens.Fg,
): androidx.tv.material3.CardColors = androidx.tv.material3.CardDefaults.colors(
    containerColor = containerColor,
    contentColor = contentColor,
    focusedContainerColor = focusedContainerColor,
    focusedContentColor = focusedContentColor,
    pressedContainerColor = focusedContainerColor,
    pressedContentColor = focusedContentColor,
)

@androidx.compose.runtime.Composable
@androidx.tv.material3.ExperimentalTvMaterial3Api
fun ultraButtonColors(
    containerColor: androidx.compose.ui.graphics.Color = UltraTokens.Surface2,
    contentColor: androidx.compose.ui.graphics.Color = UltraTokens.Fg,
    focusedContainerColor: androidx.compose.ui.graphics.Color = UltraTokens.Accent,
    focusedContentColor: androidx.compose.ui.graphics.Color = androidx.compose.ui.graphics.Color.White,
): androidx.tv.material3.ButtonColors = androidx.tv.material3.ButtonDefaults.colors(
    containerColor = containerColor,
    contentColor = contentColor,
    focusedContainerColor = focusedContainerColor,
    focusedContentColor = focusedContentColor,
    pressedContainerColor = focusedContainerColor,
    pressedContentColor = focusedContentColor,
)

object UltraType {
    val HeroDisplay = TextStyle(
        fontFamily = UltraFonts.Serif,
        fontSize = 84.sp,
        lineHeight = 84.sp,
        letterSpacing = (-2.1).sp,
        fontWeight = FontWeight.Normal,
    )
    val ScreenTitle = TextStyle(
        fontFamily = UltraFonts.Sans,
        fontSize = 36.sp,
        lineHeight = 40.sp,
        letterSpacing = (-0.5).sp,
        fontWeight = FontWeight.SemiBold,
    )
    val RailTitle = TextStyle(
        fontFamily = UltraFonts.Sans,
        fontSize = 28.sp,
        lineHeight = 32.sp,
        letterSpacing = (-0.3).sp,
        fontWeight = FontWeight.SemiBold,
    )
    val SerifTitle = TextStyle(
        fontFamily = UltraFonts.Serif,
        fontSize = 28.sp,
        lineHeight = 30.sp,
        letterSpacing = (-0.3).sp,
        fontStyle = FontStyle.Normal,
    )

    val Body  = TextStyle(fontFamily = UltraFonts.Sans, fontSize = 15.sp, lineHeight = 22.sp)
    val Body2 = TextStyle(fontFamily = UltraFonts.Sans, fontSize = 13.sp, lineHeight = 18.sp)
    val Meta  = TextStyle(fontFamily = UltraFonts.Sans, fontSize = 12.sp, lineHeight = 16.sp, color = UltraTokens.Fg3)
    val Eyebrow = TextStyle(
        fontFamily = UltraFonts.Sans,
        fontSize = 13.sp,
        letterSpacing = 2.3.sp,
        fontWeight = FontWeight.Medium,
        color = UltraTokens.Fg3,
    )
    val Mono = TextStyle(fontFamily = UltraFonts.Mono, fontSize = 13.sp)
    val MonoSmall = TextStyle(fontFamily = UltraFonts.Mono, fontSize = 11.sp, color = UltraTokens.Fg3)
}
