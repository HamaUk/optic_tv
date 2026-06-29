package com.kobani4k.app.tv.ui.theme

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.*
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.*
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import android.view.KeyEvent
import androidx.tv.material3.*

// ═══════════════════════════════════════════════════════
//  KOBANI 4K  —  Premium TV Design System v2.0
//  Rich Filled Theme · Depth · Layered Surfaces · Solid
// ═══════════════════════════════════════════════════════

// ─── Animation Specs ──────────────────────────────
object UltraEasing {
    val Standard   = FastOutSlowInEasing
    val Decelerate = LinearOutSlowInEasing
    val Emphasized = CubicBezierEasing(0.05f, 0.7f, 0.1f, 1.0f)
    val Bouncy     = CubicBezierEasing(0.3f, 1.3f, 0.4f, 0.95f)
}

object UltraDuration {
    const val Fast     = 200
    const val Standard = 350
    const val Slow     = 500
}

// ─── Elevation System (material depth) ───────────
object UltraElevation {
    val Rest    = 0.dp
    val Hover   = 4.dp
    val Focus   = 8.dp
    val Pressed = 2.dp
    val Modal   = 24.dp
    val Overlay = 32.dp
}

// ═══════════════════════════════════════════════════
//  RICH COLOR PALETTE
// ═══════════════════════════════════════════════════

object UltraTokens {
    // ── Primary Brand ─────────────────────────────
    val Brand500  = Color(0xFF00A8FF) // Electric Blue
    val Brand400  = Color(0xFF33BBFF)
    val Brand300  = Color(0xFF66D0FF)
    val Brand600  = Color(0xFF0088CC)
    val Brand700  = Color(0xFF006699)
    val Brand800  = Color(0xFF004466)
    val Brand900  = Color(0xFF002233)

    val Amber500  = Color(0xFFF59E0B)
    val Amber400  = Color(0xFFF7B733)
    val Amber600  = Color(0xFFD97706)

    // ── Neutrals ──────────────────────────────────
    val White      = Color(0xFFFFFFFF)
    val Gray50     = Color(0xFFF8FAFC)
    val Gray100    = Color(0xFFF1F5F9)
    val Gray200    = Color(0xFFE2E8F0)
    val Gray300    = Color(0xFFCBD5E1)
    val Gray400    = Color(0xFF94A3B8)
    val Gray500    = Color(0xFF64748B)
    val Gray600    = Color(0xFF475569)
    val Gray700    = Color(0xFF334155)
    val Gray800    = Color(0xFF1E293B)
    val Gray850    = Color(0xFF172033)
    val Gray900    = Color(0xFF0F172A)
    val Gray950    = Color(0xFF080C14)
    val Black      = Color(0xFF020409)

    // ── Semantic ──────────────────────────────────
    val Success500 = Color(0xFF22C55E)
    val Success600 = Color(0xFF16A34A)
    val SuccessBg  = Color(0xFF052E16)
    val SuccessFg  = Color(0xFF86EFAC)

    val Error500   = Color(0xFFEF4444)
    val Error600   = Color(0xFFDC2626)
    val ErrorBg    = Color(0xFF450A0A)
    val ErrorFg    = Color(0xFFFCA5A5)

    val Warning500 = Color(0xFFF59E0B)
    val WarningBg  = Color(0xFF451A03)
    val WarningFg  = Color(0xFFFDE68A)

    // ── Surfaces (Rich Dark Layered) ──────────────
    val BgCanvas      = Color(0xFF060810) // Deepest
    val BgBase        = Color(0xFF0A0D18) // App background
    val SurfaceBase   = Color(0xFF0F1320) // Cards at rest
    val SurfaceRaised = Color(0xFF151A2B) // Hover state
    val SurfaceFocus  = Color(0xFF1A2035) // Focused card fill
    val SurfaceOverlay = Color(0xFF1F2640) // Modal / sheet
    val SurfaceInput  = Color(0xFF111624) // Text field bg

    // ── Foreground (High contrast TV) ────────────
    val FgPrimary   = Color(0xFFF1F5F9) // Headlines, main text
    val FgSecondary = Color(0xFFCBD5E1) // Body, secondary
    val FgTertiary  = Color(0xFF94A3B8) // Captions, meta
    val FgDisabled  = Color(0xFF64748B) // Disabled text
    val FgInverse   = Color(0xFF0F172A) // On brand bg

    // ── Borders & Dividers ───────────────────────
    val BorderSubtle    = Color(0xFF1E293B) // Between cards
    val BorderDefault   = Color(0xFF334155) // Input borders
    val BorderFocus     = Color(0xFF00A8FF) // Focus ring
    val BorderAccent    = Color(0xFF0088CC) // Active indicator
    val DividerSubtle   = Color(0xFF1A2235)
    val DividerDefault  = Color(0xFF263148)

    // ── Filled Accent Surfaces ───────────────────
    val AccentSurface     = Color(0xFF0A1A2B) // Subtle blue tint
    val AccentSurfaceHover = Color(0xFF0F2440)
    val AccentSurfaceFocus = Color(0xFF142E52)

    // ── Selection & Highlight ────────────────────
    val SelectionBg    = Color(0xFF1A3050)
    val SelectionBorder = Color(0xFF00A8FF)

    // ── CTA Filled Button ────────────────────────
    val CtaBg      = Color(0xFF00A8FF)
    val CtaHover   = Color(0xFF0088CC)
    val CtaPressed = Color(0xFF006699)
    val CtaFg      = Color(0xFFFFFFFF)

    // ── Secondary Button ─────────────────────────
    val SecondaryBg     = Color(0xFF1E293B)
    val SecondaryHover  = Color(0xFF334155)
    val SecondaryFg     = Color(0xFFF1F5F9)

    // ── Badge Fills ──────────────────────────────
    val BadgeHdBg    = Color(0xFF052E16)
    val BadgeHdFg    = Color(0xFF86EFAC)
    val BadgeUhdBg   = Color(0xFF451A03)
    val BadgeUhdFg   = Color(0xFFFDE68A)
    val BadgeLiveBg  = Color(0xFF450A0A)
    val BadgeLiveFg  = Color(0xFFFCA5A5)
    val BadgeNewBg   = Color(0xFF0A1A2B)
    val BadgeNewFg   = Color(0xFF66D0FF)

    // ── Radii ────────────────────────────────────
    val RadiusNone  = 0.dp
    val RadiusXs    = 4.dp
    val RadiusSm    = 8.dp
    val RadiusMd    = 12.dp
    val RadiusLg    = 16.dp
    val RadiusXl    = 24.dp
    val RadiusFull  = 999.dp

    // ── Layout ───────────────────────────────────
    val SidebarCollapsed  = 88.dp
    val SidebarExpanded   = 260.dp
    val TopBarHeight      = 72.dp
    val EdgeGutter        = 48.dp
    val CardWidth         = 200.dp
    val CardHeight        = 288.dp
    val WideCardWidth     = 340.dp
    val PosterWidth       = 160.dp
    val PosterHeight      = 240.dp
    val IconXs            = 16.dp
    val IconSm            = 20.dp
    val IconMd            = 28.dp
    val IconLg            = 40.dp
    val IconXl            = 56.dp
    val FocusRing         = 2.dp
    val DividerH          = 1.dp
    val DividerV          = 1.dp
}

// ═══════════════════════════════════════════════════
//  TYPOGRAPHY
// ═══════════════════════════════════════════════════

object UltraFonts {
    val Sans:  FontFamily = FontFamily.SansSerif
    val Mono:  FontFamily = FontFamily.Monospace
    val Serif: FontFamily = FontFamily.Serif
}

object UltraType {
    val HeroDisplay = TextStyle(
        fontFamily = UltraFonts.Sans, fontSize = 48.sp,
        lineHeight = 52.sp, letterSpacing = (-1.5).sp,
        fontWeight = FontWeight.Black, color = UltraTokens.FgPrimary
    )
    val ScreenTitle = TextStyle(
        fontFamily = UltraFonts.Sans, fontSize = 36.sp,
        lineHeight = 42.sp, letterSpacing = (-0.5).sp,
        fontWeight = FontWeight.Bold, color = UltraTokens.FgPrimary
    )
    val SectionTitle = TextStyle(
        fontFamily = UltraFonts.Sans, fontSize = 24.sp,
        lineHeight = 30.sp, fontWeight = FontWeight.Bold,
        color = UltraTokens.FgPrimary
    )
    val CardTitle = TextStyle(
        fontFamily = UltraFonts.Sans, fontSize = 18.sp,
        lineHeight = 24.sp, fontWeight = FontWeight.SemiBold,
        color = UltraTokens.FgPrimary
    )
    val Body = TextStyle(
        fontFamily = UltraFonts.Sans, fontSize = 16.sp,
        lineHeight = 22.sp, color = UltraTokens.FgSecondary
    )
    val Body2 = TextStyle(
        fontFamily = UltraFonts.Sans, fontSize = 14.sp,
        lineHeight = 20.sp, color = UltraTokens.FgSecondary
    )
    val Caption = TextStyle(
        fontFamily = UltraFonts.Sans, fontSize = 12.sp,
        lineHeight = 16.sp, color = UltraTokens.FgTertiary
    )
    val Eyebrow = TextStyle(
        fontFamily = UltraFonts.Sans, fontSize = 12.sp,
        letterSpacing = 2.sp, fontWeight = FontWeight.Bold,
        color = UltraTokens.Brand500
    )
    val KeypadDigit = TextStyle(
        fontFamily = UltraFonts.Sans, fontSize = 28.sp,
        fontWeight = FontWeight.Bold, color = UltraTokens.FgPrimary
    )
    val Mono = TextStyle(
        fontFamily = UltraFonts.Mono, fontSize = 14.sp,
        color = UltraTokens.FgSecondary
    )
    val Badge = TextStyle(
        fontFamily = UltraFonts.Sans, fontSize = 10.sp,
        fontWeight = FontWeight.Bold, letterSpacing = 1.sp
    )
    val Button = TextStyle(
        fontFamily = UltraFonts.Sans, fontSize = 16.sp,
        fontWeight = FontWeight.SemiBold, letterSpacing = 0.5.sp
    )
    val NavLabel = TextStyle(
        fontFamily = UltraFonts.Sans, fontSize = 13.sp,
        fontWeight = FontWeight.Medium, color = UltraTokens.FgSecondary
    )
}

// ═══════════════════════════════════════════════════
//  FOCUS ANIMATION HELPERS (Solid Fill, No Glow)
// ═══════════════════════════════════════════════════

object UltraFocus {

    /**
     * Smooth scale + background color transition on focus.
     * Card fills from SurfaceBase → SurfaceFocus.
     */
    @Composable
    fun cardScaleAndFill(
        isFocused: Boolean,
        scaleAmount: Float = 1.04f
    ): Modifier {
        val scale by animateFloatAsState(
            targetValue = if (isFocused) scaleAmount else 1f,
            animationSpec = spring(
                dampingRatio = Spring.DampingRatioMediumBouncy,
                stiffness = Spring.StiffnessMediumLow
            ),
            label = "focusScale"
        )
        return Modifier.scale(scale)
    }

    /**
     * Color transition for filled card backgrounds.
     * Use with Modifier.background().
     */
    @Composable
    fun cardFillColor(isFocused: Boolean): Color {
        return animateColorAsState(
            targetValue = if (isFocused) UltraTokens.SurfaceFocus else UltraTokens.SurfaceBase,
            animationSpec = tween(UltraDuration.Standard, easing = UltraEasing.Standard),
            label = "cardFill"
        ).value
    }

    /**
     * Color transition for accent-filled surfaces.
     */
    @Composable
    fun accentFillColor(isFocused: Boolean): Color {
        return animateColorAsState(
            targetValue = if (isFocused) UltraTokens.AccentSurfaceFocus else UltraTokens.AccentSurface,
            animationSpec = tween(UltraDuration.Standard, easing = UltraEasing.Standard),
            label = "accentFill"
        ).value
    }

    /**
     * Solid border color transition for focus rings.
     */
    @Composable
    fun borderColor(isFocused: Boolean): Color {
        return animateColorAsState(
            targetValue = if (isFocused) UltraTokens.BorderFocus else UltraTokens.BorderSubtle,
            animationSpec = tween(UltraDuration.Fast, easing = UltraEasing.Standard),
            label = "borderColor"
        ).value
    }
}

// ═══════════════════════════════════════════════════
//  BADGE COMPONENTS
// ═══════════════════════════════════════════════════

object UltraBadge {

    /** Quality badge: HD, FHD, 4K, 8K */
    @Composable
    fun quality(
        text: String,
        bgColor: Color = UltraTokens.BadgeHdBg,
        fgColor: Color = UltraTokens.BadgeHdFg
    ) {
        Box(
            modifier = Modifier
                .clip(RoundedCornerShape(UltraTokens.RadiusXs))
                .background(bgColor)
                .padding(horizontal = 8.dp, vertical = 3.dp)
        ) {
            androidx.compose.material3.Text(
                text = text,
                style = UltraType.Badge.copy(color = fgColor),
                textAlign = TextAlign.Center
            )
        }
    }

    /** Live indicator dot + label */
    @Composable
    fun live() {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                modifier = Modifier
                    .size(7.dp)
                    .clip(CircleShape)
                    .background(UltraTokens.Error500)
            )
            Spacer(modifier = Modifier.width(6.dp))
            androidx.compose.material3.Text(
                text = "LIVE",
                style = UltraType.Badge.copy(color = UltraTokens.BadgeLiveFg)
            )
        }
    }

    /** "New" label for fresh content */
    @Composable
    fun new() {
        Box(
            modifier = Modifier
                .clip(RoundedCornerShape(UltraTokens.RadiusXs))
                .background(UltraTokens.BadgeNewBg)
                .padding(horizontal = 8.dp, vertical = 3.dp)
        ) {
            androidx.compose.material3.Text(
                text = "NEW",
                style = UltraType.Badge.copy(color = UltraTokens.BadgeNewFg)
            )
        }
    }
}

// ═══════════════════════════════════════════════════
//  MATERIAL 3 COLOR COMPOSABLES
// ═══════════════════════════════════════════════════

@Composable
@ExperimentalTvMaterial3Api
fun ultraCardColors(
    containerColor: Color = UltraTokens.SurfaceBase,
    contentColor: Color = UltraTokens.FgPrimary,
    focusedContainerColor: Color = UltraTokens.SurfaceFocus,
    focusedContentColor: Color = UltraTokens.FgPrimary,
): CardColors = CardDefaults.colors(
    containerColor = containerColor,
    contentColor = contentColor,
    focusedContainerColor = focusedContainerColor,
    focusedContentColor = focusedContentColor,
    pressedContainerColor = UltraTokens.AccentSurfaceHover,
    pressedContentColor = focusedContentColor,
)

@Composable
@ExperimentalTvMaterial3Api
fun ultraButtonColors(
    containerColor: Color = UltraTokens.SecondaryBg,
    contentColor: Color = UltraTokens.SecondaryFg,
    focusedContainerColor: Color = UltraTokens.SecondaryHover,
    focusedContentColor: Color = UltraTokens.SecondaryFg,
): ButtonColors = ButtonDefaults.colors(
    containerColor = containerColor,
    contentColor = contentColor,
    focusedContainerColor = focusedContainerColor,
    focusedContentColor = focusedContentColor,
    pressedContainerColor = UltraTokens.SurfaceFocus,
    pressedContentColor = focusedContentColor,
)

@Composable
@ExperimentalTvMaterial3Api
fun ultraCtaColors(): ButtonColors = ButtonDefaults.colors(
    containerColor = UltraTokens.CtaBg,
    contentColor = UltraTokens.CtaFg,
    focusedContainerColor = UltraTokens.CtaHover,
    focusedContentColor = UltraTokens.CtaFg,
    pressedContainerColor = UltraTokens.CtaPressed,
    pressedContentColor = UltraTokens.CtaFg,
)

@Composable
@ExperimentalTvMaterial3Api
fun ultraOutlineButtonColors(): ButtonColors = ButtonDefaults.colors(
    containerColor = Color.Transparent,
    contentColor = UltraTokens.FgPrimary,
    focusedContainerColor = UltraTokens.AccentSurfaceHover,
    focusedContentColor = UltraTokens.Brand400,
    pressedContainerColor = UltraTokens.AccentSurface,
    pressedContentColor = UltraTokens.Brand500,
)

// ═══════════════════════════════════════════════════
//  SURFACE GRADIENTS (Subtle Depth, No Glow)
// ═══════════════════════════════════════════════════

object UltraGradients {

    /** Dark radial vignette for backgrounds */
    val bgVignette = Brush.radialGradient(
        colors = listOf(
            UltraTokens.Gray900,
            UltraTokens.Gray950,
            UltraTokens.Black
        ),
        center = Offset(600f, 400f),
        radius = 1800f
    )

    /** Subtle surface gradient for hero areas */
    val surfaceHero = Brush.verticalGradient(
        colors = listOf(
            UltraTokens.SurfaceBase,
            UltraTokens.BgBase
        )
    )

    /** Sidebar gradient */
    val sidebar = Brush.horizontalGradient(
        colors = listOf(
            UltraTokens.Black,
            UltraTokens.Gray950,
            UltraTokens.BgBase
        )
    )

    /** Top bar gradient */
    val topBar = Brush.verticalGradient(
        colors = listOf(
            UltraTokens.Black.copy(alpha = 0.95f),
            UltraTokens.Black.copy(alpha = 0.6f),
            Color.Transparent
        )
    )

    /** Bottom scrim for poster overlays */
    val posterScrim = Brush.verticalGradient(
        colors = listOf(
            Color.Transparent,
            UltraTokens.Black.copy(alpha = 0.7f),
            UltraTokens.Black.copy(alpha = 0.95f)
        )
    )

    /** Accent gradient for hero CTAs */
    val accentFill = Brush.horizontalGradient(
        colors = listOf(
            UltraTokens.Brand500,
            UltraTokens.Brand600
        )
    )
}
