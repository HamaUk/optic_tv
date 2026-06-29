// LoginScreen.kt
package com.kobani4k.app.tv.ui

import android.view.KeyEvent
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.*
import androidx.compose.material3.Icon
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.*
import androidx.compose.ui.focus.*
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.key.*
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.foundation.clickable
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.tv.material3.*
import com.kobani4k.app.tv.data.PocketBaseRepository
import com.kobani4k.app.tv.ui.theme.UltraTokens
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.cos
import kotlin.math.sin

private const val MAX_CODE_LENGTH = 10
private const val KEYPAD_ROWS = 4
private const val KEYPAD_COLS = 3

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun LoginScreen(onLoginSuccess: () -> Unit) {
    val repository = remember { PocketBaseRepository() }
    val scope = rememberCoroutineScope()
    val focusManager = LocalFocusManager.current
    val keyboardController = LocalSoftwareKeyboardController.current

    // State
    var loginCode by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var isSuccess by remember { mutableStateOf(false) }
    var showSuccessOverlay by remember { mutableStateOf(false) }

    // Focus states for navigation
    val focusRequesters = remember { List(KEYPAD_ROWS * KEYPAD_COLS + 1) { FocusRequester() } }
    val loginButtonRequester = focusRequesters.last()
    var currentFocusIndex by remember { mutableStateOf(0) }

    // Auto-focus on first key
    LaunchedEffect(Unit) {
        delay(300)
        focusRequesters[0].requestFocus()
    }

    // ─── Background Animation ───
    val infiniteTransition = rememberInfiniteTransition(label = "bgAnim")
    val orb1X by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 100f,
        animationSpec = infiniteRepeatable(
            animation = tween(15000, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "orb1X"
    )
    val orb1Y by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = -80f,
        animationSpec = infiniteRepeatable(
            animation = tween(12000, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "orb1Y"
    )
    val orb2X by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = -120f,
        animationSpec = infiniteRepeatable(
            animation = tween(18000, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "orb2X"
    )
    val orb2Y by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 100f,
        animationSpec = infiniteRepeatable(
            animation = tween(14000, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "orb2Y"
    )
    val orb3Scale by infiniteTransition.animateFloat(
        initialValue = 0.8f,
        targetValue = 1.2f,
        animationSpec = infiniteRepeatable(
            animation = tween(10000, easing = EaseInOutSine),
            repeatMode = RepeatMode.Reverse
        ),
        label = "orb3Scale"
    )

    // ─── Particles ───
    val particles = remember {
        List(12) { index ->
            Particle(
                x = (0..100).random() / 100f,
                y = (0..100).random() / 100f,
                size = (2..5).random().dp,
                speed = (8..20).random() / 10f,
                angle = (0..360).random().toFloat(),
                delay = (0..10000).random().toLong()
            )
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(UltraTokens.BgDeep)
            .onKeyEvent { keyEvent ->
                if (keyEvent.nativeKeyEvent.action == KeyEvent.ACTION_DOWN) {
                    val code = keyEvent.nativeKeyEvent.keyCode
                    when {
                        code in KeyEvent.KEYCODE_0..KeyEvent.KEYCODE_9 -> {
                            val digit = (code - KeyEvent.KEYCODE_0).toString()
                            if (loginCode.length < MAX_CODE_LENGTH && !isLoading) {
                                errorMessage = null
                                loginCode += digit
                            }
                            true
                        }
                        code in KeyEvent.KEYCODE_NUMPAD_0..KeyEvent.KEYCODE_NUMPAD_9 -> {
                            val digit = (code - KeyEvent.KEYCODE_NUMPAD_0).toString()
                            if (loginCode.length < MAX_CODE_LENGTH && !isLoading) {
                                errorMessage = null
                                loginCode += digit
                            }
                            true
                        }
                        code == KeyEvent.KEYCODE_DEL || code == KeyEvent.KEYCODE_FORWARD_DEL -> {
                            if (loginCode.isNotEmpty() && !isLoading) {
                                loginCode = loginCode.dropLast(1)
                                errorMessage = null
                            }
                            true
                        }
                        else -> false
                    }
                } else false
            }
    ) {
        // ─── Animated Background Orbs ───
        Box(
            modifier = Modifier
                .offset(
                    x = (-150 + orb1X * 2).dp,
                    y = (-100 + orb1Y * 2).dp
                )
                .size(700.dp)
                .background(
                    Brush.radialGradient(
                        colors = listOf(
                            UltraTokens.Accent.copy(alpha = 0.08f),
                            Color.Transparent
                        ),
                        radius = 700f
                    )
                )
        )
        Box(
            modifier = Modifier
                .offset(
                    x = (400 + orb2X * 2).dp,
                    y = (200 + orb2Y * 2).dp
                )
                .size(800.dp)
                .background(
                    Brush.radialGradient(
                        colors = listOf(
                            UltraTokens.Accent2.copy(alpha = 0.06f),
                            Color.Transparent
                        ),
                        radius = 800f
                    )
                )
        )
        Box(
            modifier = Modifier
                .offset(x = 150.dp, y = (-50).dp)
                .size(400.dp)
                .scale(orb3Scale)
                .background(
                    Brush.radialGradient(
                        colors = listOf(
                            Color(0xFF6C3CE1).copy(alpha = 0.04f),
                            Color.Transparent
                        ),
                        radius = 400f
                    )
                )
        )

        // ─── Particles ───
        particles.forEach { particle ->
            ParticleView(
                particle = particle,
                modifier = Modifier
            )
        }

        // ─── Main Container ───
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            // ─── Glass Card ───
            Column(
                modifier = Modifier
                    .width(380.dp)
                    .clip(RoundedCornerShape(24.dp))
                    .background(
                        Brush.verticalGradient(
                            colors = listOf(
                                UltraTokens.Surface1.copy(alpha = 0.75f),
                                UltraTokens.Surface1.copy(alpha = 0.6f)
                            )
                        )
                    )
                    .border(
                        width = 1.dp,
                        brush = Brush.verticalGradient(
                            colors = listOf(
                                Color.White.copy(alpha = 0.08f),
                                Color.White.copy(alpha = 0.02f)
                            )
                        ),
                        shape = RoundedCornerShape(24.dp)
                    )
                    .shadow(
                        elevation = 40.dp,
                        shape = RoundedCornerShape(24.dp),
                        clip = false,
                        ambientColor = Color.Black.copy(alpha = 0.5f),
                        spotColor = Color.Black.copy(alpha = 0.3f)
                    )
                    .padding(horizontal = 24.dp, vertical = 24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                // ─── Logo Section ───
                LogoSection()

                Spacer(modifier = Modifier.height(16.dp))

                // ─── Code Display ───
                CodeDisplay(
                    code = loginCode,
                    isError = errorMessage != null,
                    isActive = loginCode.isNotEmpty() || errorMessage != null,
                    maxLength = MAX_CODE_LENGTH
                )

                Spacer(modifier = Modifier.height(6.dp))

                // ─── Error Message ───
                if (errorMessage != null) {
                    ErrorMessage(
                        message = errorMessage ?: "",
                        onDismiss = { errorMessage = null }
                    )
                } else {
                    Spacer(modifier = Modifier.height(16.dp))
                }

                Spacer(modifier = Modifier.height(6.dp))

                // ─── Keypad ───
                KeypadGrid(
                    focusRequesters = focusRequesters.take(KEYPAD_ROWS * KEYPAD_COLS),
                    onDigitPress = { digit ->
                        if (loginCode.length < MAX_CODE_LENGTH && !isLoading) {
                            errorMessage = null
                            loginCode += digit
                        }
                    },
                    onBackspace = {
                        if (loginCode.isNotEmpty() && !isLoading) {
                            loginCode = loginCode.dropLast(1)
                            errorMessage = null
                        }
                    },
                    onClear = {
                        if (!isLoading) {
                            loginCode = ""
                            errorMessage = null
                        }
                    },
                    isLoading = isLoading
                )

                Spacer(modifier = Modifier.height(16.dp))

                // ─── Login Button ───
                LoginButton(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(48.dp)
                        .focusRequester(loginButtonRequester),
                    isLoading = isLoading,
                    enabled = loginCode.isNotBlank() && !isLoading,
                    onClick = {
                        if (loginCode.isNotBlank() && !isLoading) {
                            isLoading = true
                            errorMessage = null
                            scope.launch {
                                val result = repository.verifyLoginCode(loginCode)
                                isLoading = false
                                when (result) {
                                    "SUCCESS" -> {
                                        isSuccess = true
                                        showSuccessOverlay = true
                                        delay(1500)
                                        onLoginSuccess()
                                    }
                                    "ERROR" -> errorMessage = "NETWORK ERROR"
                                    else -> errorMessage = "INVALID OR EXPIRED CODE"
                                }
                            }
                        }
                    }
                )

                Spacer(modifier = Modifier.height(16.dp))

                // ─── Footer ───
                Text(
                    text = "v2.1.0 · Premium Streaming",
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Medium,
                    letterSpacing = 2.sp,
                    color = UltraTokens.Fg4.copy(alpha = 0.5f)
                )
            }

            // ─── Success Overlay ───
            if (showSuccessOverlay) {
                SuccessOverlay(
                    modifier = Modifier
                        .width(520.dp)
                        .height(460.dp)
                        .clip(RoundedCornerShape(32.dp))
                )
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
//  Logo Section
// ═══════════════════════════════════════════════════════════════

@Composable
private fun LogoSection() {
    val infiniteTransition = rememberInfiniteTransition(label = "logoAnim")
    val logoScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.06f,
        animationSpec = infiniteRepeatable(
            animation = tween(3000, easing = EaseInOutSine),
            repeatMode = RepeatMode.Reverse
        ),
        label = "logoScale"
    )
    val glowPulse by infiniteTransition.animateFloat(
        initialValue = 0.3f,
        targetValue = 0.8f,
        animationSpec = infiniteRepeatable(
            animation = tween(2500, easing = EaseInOutSine),
            repeatMode = RepeatMode.Reverse
        ),
        label = "glowPulse"
    )

    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        // Removed TV Icon Box



        // Brand name
        Row(
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "KOBANI",
                fontSize = 28.sp,
                fontWeight = FontWeight.Black,
                letterSpacing = 4.sp,
                color = Color.White,
                style = TextStyle(
                    shadow = Shadow(
                        color = Color.Black.copy(alpha = 0.3f),
                        blurRadius = 10f
                    )
                )
            )
            Spacer(modifier = Modifier.width(6.dp))
            Text(
                text = "4K",
                fontSize = 28.sp,
                fontWeight = FontWeight.Black,
                letterSpacing = 4.sp,
                color = UltraTokens.Accent,
                style = TextStyle(
                    shadow = Shadow(
                        color = UltraTokens.Accent.copy(alpha = 0.3f),
                        blurRadius = 10f
                    )
                )
            )
        }

        Spacer(modifier = Modifier.height(4.dp))

        Text(
            text = "PREMIUM STREAMING",
            fontSize = 10.sp,
            fontWeight = FontWeight.Medium,
            letterSpacing = 4.sp,
            color = UltraTokens.Fg3.copy(alpha = 0.6f)
        )

        Spacer(modifier = Modifier.height(10.dp))

        // Decorative line
        Box(
            modifier = Modifier
                .width(50.dp)
                .height(2.dp)
                .clip(RoundedCornerShape(2.dp))
                .background(
                    Brush.horizontalGradient(
                        colors = listOf(
                            Color.Transparent,
                            UltraTokens.Accent.copy(alpha = 0.4f),
                            Color.Transparent
                        )
                    )
                )
        )
    }
}

// ═══════════════════════════════════════════════════════════════
//  Code Display
// ═══════════════════════════════════════════════════════════════

@Composable
private fun CodeDisplay(
    code: String,
    isError: Boolean,
    isActive: Boolean,
    maxLength: Int
) {
    val infiniteTransition = rememberInfiniteTransition(label = "cursorAnim")
    val cursorAlpha by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(500, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "cursorAlpha"
    )
    val actualCursorAlpha = if (isActive) cursorAlpha else 0f

    val borderColor by animateColorAsState(
        targetValue = when {
            isError -> Color(0xFFFF4757)
            isActive -> UltraTokens.Accent.copy(alpha = 0.4f)
            else -> Color.White.copy(alpha = 0.06f)
        },
        animationSpec = tween(300),
        label = "codeBorder"
    )

    val glowColor by animateColorAsState(
        targetValue = when {
            isError -> Color(0xFFFF4757).copy(alpha = 0.08f)
            isActive -> UltraTokens.Accent.copy(alpha = 0.06f)
            else -> Color.Transparent
        },
        animationSpec = tween(300),
        label = "codeGlow"
    )

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(48.dp)
            .shadow(
                elevation = 0.dp,
                shape = RoundedCornerShape(12.dp),
                clip = false,
                ambientColor = glowColor,
                spotColor = glowColor
            )
            .clip(RoundedCornerShape(12.dp))
            .background(UltraTokens.BgDeep.copy(alpha = 0.7f))
            .border(1.5.dp, borderColor, RoundedCornerShape(12.dp))
            .padding(horizontal = 16.dp),
        contentAlignment = Alignment.Center
    ) {
        if (code.isEmpty()) {
            Row(
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth()
            ) {
                repeat(6) {
                    Box(
                        modifier = Modifier
                            .size(8.dp)
                            .clip(CircleShape)
                            .background(Color.White.copy(alpha = 0.12f))
                    )
                    if (it < 5) Spacer(modifier = Modifier.width(10.dp))
                }
                // Cursor blink when empty
                Box(
                    modifier = Modifier
                        .size(2.dp, 28.dp)
                        .clip(RoundedCornerShape(2.dp))
                        .background(UltraTokens.Accent)
                        .alpha(actualCursorAlpha)
                )
            }
        } else {
            Row(
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth()
            ) {
                code.forEachIndexed { index, char ->
                    AnimatedContent(
                        targetState = char,
                        transitionSpec = {
                            (fadeIn(animationSpec = tween(200)) +
                                    scaleIn(initialScale = 0.6f, animationSpec = spring(
                                        dampingRatio = Spring.DampingRatioMediumBouncy,
                                        stiffness = Spring.StiffnessLow
                                    ))) togetherWith fadeOut(animationSpec = tween(200))
                        },
                        label = "digitAnim"
                    ) { digit ->
                        Text(
                            text = digit.toString(),
                            fontSize = 24.sp,
                            fontWeight = FontWeight.Bold,
                            letterSpacing = 2.sp,
                            color = if (isError) Color(0xFFFF4757) else UltraTokens.Accent,
                            modifier = Modifier.width(24.dp),
                            textAlign = TextAlign.Center
                        )
                    }
                    if (index < code.length - 1 || index < maxLength - 1) {
                        Spacer(modifier = Modifier.width(4.dp))
                    }
                }
                // Cursor blink after last digit
                if (code.length < maxLength) {
                    Spacer(modifier = Modifier.width(4.dp))
                    Box(
                        modifier = Modifier
                            .size(2.dp, 28.dp)
                            .clip(RoundedCornerShape(2.dp))
                            .background(UltraTokens.Accent)
                            .alpha(actualCursorAlpha)
                    )
                }
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
//  Error Message
// ═══════════════════════════════════════════════════════════════

@Composable
private fun ErrorMessage(
    message: String,
    onDismiss: () -> Unit
) {
    AnimatedVisibility(
        visible = true,
        enter = fadeIn() + slideInVertically(initialOffsetY = { -20 }),
        exit = fadeOut() + slideOutVertically(targetOffsetY = { -20 })
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(24.dp)
                .padding(horizontal = 8.dp),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Rounded.Warning,
                contentDescription = null,
                tint = Color(0xFFFF4757),
                modifier = Modifier.size(16.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = message,
                color = Color(0xFFFF4757),
                fontSize = 13.sp,
                fontWeight = FontWeight.SemiBold,
                letterSpacing = 0.5.sp,
                textAlign = TextAlign.Center
            )
        }
    }
}

// ═══════════════════════════════════════════════════════════════
//  Keypad Grid
// ═══════════════════════════════════════════════════════════════

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
private fun KeypadGrid(
    focusRequesters: List<FocusRequester>,
    onDigitPress: (String) -> Unit,
    onBackspace: () -> Unit,
    onClear: () -> Unit,
    isLoading: Boolean
) {
    val keys = listOf(
        listOf("1", "2", "3"),
        listOf("4", "5", "6"),
        listOf("7", "8", "9"),
        listOf("CLR", "0", "⌫")
    )

    var focusedKey by remember { mutableStateOf<Pair<Int, Int>?>(null) }

    Column(
        verticalArrangement = Arrangement.spacedBy(8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.fillMaxWidth()
    ) {
        keys.forEachIndexed { rowIndex, row ->
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                row.forEachIndexed { colIndex, key ->
                    val index = rowIndex * KEYPAD_COLS + colIndex
                    val isFocused = focusedKey == (rowIndex to colIndex)

                    KeypadButton(
                        label = key,
                        modifier = Modifier
                            .weight(1f)
                            .height(44.dp)
                            .focusRequester(focusRequesters[index])
                            .onFocusChanged { focusState ->
                                if (focusState.isFocused) {
                                    focusedKey = rowIndex to colIndex
                                }
                            }
                            .onKeyEvent { keyEvent ->
                                if (keyEvent.nativeKeyEvent.action == KeyEvent.ACTION_DOWN) {
                                    when (keyEvent.nativeKeyEvent.keyCode) {
                                        KeyEvent.KEYCODE_DPAD_CENTER,
                                        KeyEvent.KEYCODE_ENTER,
                                        KeyEvent.KEYCODE_NUMPAD_ENTER,
                                        KeyEvent.KEYCODE_BUTTON_A -> {
                                            handleKeyPress(key, onDigitPress, onBackspace, onClear)
                                            true
                                        }
                                        else -> false
                                    }
                                } else false
                            }
                            .focusable(),
                        isFocused = isFocused,
                        isLoading = isLoading,
                        onClick = {
                            handleKeyPress(key, onDigitPress, onBackspace, onClear)
                        }
                    )
                }
            }
        }
    }
}

private fun handleKeyPress(
    key: String,
    onDigitPress: (String) -> Unit,
    onBackspace: () -> Unit,
    onClear: () -> Unit
) {
    when (key) {
        "CLR" -> onClear()
        "⌫" -> onBackspace()
        else -> onDigitPress(key)
    }
}

// ═══════════════════════════════════════════════════════════════
//  Keypad Button
// ═══════════════════════════════════════════════════════════════

@Composable
private fun KeypadButton(
    label: String,
    modifier: Modifier = Modifier,
    isFocused: Boolean,
    isLoading: Boolean,
    onClick: () -> Unit
) {
    val isSpecial = label == "CLR" || label == "⌫"

    val scale by animateFloatAsState(
        targetValue = if (isFocused) 1.06f else 1f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessLow
        ),
        label = "keyScale"
    )

    val bgColor by animateColorAsState(
        targetValue = when {
            isLoading -> UltraTokens.Surface3
            isFocused -> UltraTokens.Accent
            else -> UltraTokens.Surface3.copy(alpha = 0.6f)
        },
        animationSpec = tween(150),
        label = "keyBg"
    )

    val borderColor by animateColorAsState(
        targetValue = when {
            isFocused -> UltraTokens.Accent.copy(alpha = 0.6f)
            else -> Color.White.copy(alpha = 0.04f)
        },
        animationSpec = tween(150),
        label = "keyBorder"
    )

    val glowColor by animateColorAsState(
        targetValue = if (isFocused) UltraTokens.Accent.copy(alpha = 0.15f) else Color.Transparent,
        animationSpec = tween(150),
        label = "keyGlow"
    )

    // Ripple effect for press
    var rippleScale by remember { mutableStateOf(0f) }
    var rippleAlpha by remember { mutableStateOf(0f) }

    LaunchedEffect(isFocused) {
        if (isFocused) {
            rippleScale = 1f
            rippleAlpha = 1f
            delay(300)
            rippleAlpha = 0f
        }
    }

    Box(
        modifier = modifier
            .scale(scale)
            .shadow(
                elevation = if (isFocused) 16.dp else 4.dp,
                shape = RoundedCornerShape(14.dp),
                clip = false,
                ambientColor = glowColor,
                spotColor = glowColor
            )
            .clip(RoundedCornerShape(14.dp))
            .background(bgColor)
            .border(1.5.dp, borderColor, RoundedCornerShape(14.dp))
            .focusable()
            .onKeyEvent { keyEvent ->
                if (keyEvent.nativeKeyEvent.action == KeyEvent.ACTION_DOWN) {
                    when (keyEvent.nativeKeyEvent.keyCode) {
                        KeyEvent.KEYCODE_DPAD_CENTER,
                        KeyEvent.KEYCODE_ENTER,
                        KeyEvent.KEYCODE_NUMPAD_ENTER,
                        KeyEvent.KEYCODE_BUTTON_A -> {
                            onClick()
                            true
                        }
                        else -> false
                    }
                } else false
            }
            .clickable(
                enabled = !isLoading,
                onClick = onClick
            ),
        contentAlignment = Alignment.Center
    ) {
        // Ripple overlay
        if (isFocused) {
            Box(
                modifier = Modifier
                    .size(100.dp)
                    .scale(rippleScale)
                    .alpha(rippleAlpha * 0.3f)
                    .clip(CircleShape)
                    .background(UltraTokens.Accent.copy(alpha = 0.2f))
            )
        }

        // Focus ring glow
        if (isFocused) {
            Box(
                modifier = Modifier
                    .matchParentSize()
                    .clip(RoundedCornerShape(14.dp))
                    .background(
                        Brush.radialGradient(
                            colors = listOf(
                                UltraTokens.Accent.copy(alpha = 0.05f),
                                Color.Transparent
                            ),
                            radius = 80f
                        )
                    )
            )
        }

        when {
            label == "⌫" -> {
                Icon(
                    imageVector = Icons.Rounded.Backspace,
                    contentDescription = "Backspace",
                    tint = if (isFocused) Color.White else UltraTokens.Fg2,
                    modifier = Modifier.size(24.dp)
                )
            }
            isSpecial -> {
                Text(
                    text = label,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 1.sp,
                    color = if (isFocused) Color.White else UltraTokens.Fg3
                )
            }
            else -> {
                Text(
                    text = label,
                    fontSize = 24.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = if (isFocused) Color.White else UltraTokens.Fg
                )
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
//  Login Button
// ═══════════════════════════════════════════════════════════════

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
private fun LoginButton(
    modifier: Modifier = Modifier,
    isLoading: Boolean,
    enabled: Boolean,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    val scale by animateFloatAsState(
        targetValue = when {
            isLoading -> 0.97f
            isFocused -> 1.04f
            else -> 1f
        },
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessLow
        ),
        label = "btnScale"
    )

    val glowColor by animateColorAsState(
        targetValue = if (isFocused && enabled) UltraTokens.Accent.copy(alpha = 0.2f) else Color.Transparent,
        animationSpec = tween(300),
        label = "btnGlow"
    )

    // Shimmer animation for loading state
    val shimmerOffset by animateFloatAsState(
        targetValue = if (isLoading) 2f else 0f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "shimmer"
    )

    Box(
        modifier = modifier
            .height(48.dp)
            .scale(scale)
            .shadow(
                elevation = if (isFocused) 24.dp else 8.dp,
                shape = RoundedCornerShape(12.dp),
                clip = false,
                ambientColor = glowColor,
                spotColor = glowColor
            )
            .clip(RoundedCornerShape(16.dp))
            .then(
                if (isLoading) Modifier.background(UltraTokens.Surface3)
                else Modifier.background(
                    Brush.horizontalGradient(
                        colors = listOf(
                            UltraTokens.Accent,
                            UltraTokens.Accent2
                        )
                    )
                )
            )
            .border(
                width = if (isFocused) 2.dp else 0.dp,
                color = Color.White.copy(alpha = if (isFocused) 0.2f else 0f),
                shape = RoundedCornerShape(16.dp)
            )
            .onFocusChanged { focusState ->
                isFocused = focusState.isFocused
            }
            .onKeyEvent { keyEvent ->
                if (keyEvent.nativeKeyEvent.action == KeyEvent.ACTION_DOWN) {
                    when (keyEvent.nativeKeyEvent.keyCode) {
                        KeyEvent.KEYCODE_DPAD_CENTER,
                        KeyEvent.KEYCODE_ENTER,
                        KeyEvent.KEYCODE_NUMPAD_ENTER,
                        KeyEvent.KEYCODE_BUTTON_A -> {
                            if (enabled && !isLoading) onClick()
                            true
                        }
                        else -> false
                    }
                } else false
            }
            .focusable(enabled = !isLoading),
        contentAlignment = Alignment.Center
    ) {
        // Shimmer overlay
        if (isLoading) {
            Box(
                modifier = Modifier
                    .matchParentSize()
                    .clip(RoundedCornerShape(16.dp))
                    .background(
                        Brush.horizontalGradient(
                            colors = listOf(
                                Color.Transparent,
                                Color.White.copy(alpha = 0.1f),
                                Color.Transparent
                            ),
                            startX = shimmerOffset * 2f - 1f,
                            endX = shimmerOffset * 2f + 1f
                        )
                    )
            )
        }

        // Focus glow overlay
        if (isFocused && !isLoading) {
            Box(
                modifier = Modifier
                    .matchParentSize()
                    .clip(RoundedCornerShape(16.dp))
                    .background(
                        Brush.radialGradient(
                            colors = listOf(
                                Color.White.copy(alpha = 0.05f),
                                Color.Transparent
                            ),
                            radius = 100f
                        )
                    )
            )
        }

        if (isLoading) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Center
            ) {
                CircularProgressIndicator(
                    modifier = Modifier.size(22.dp),
                    color = Color.White,
                    strokeWidth = 2.5.dp
                )
                Spacer(modifier = Modifier.width(14.dp))
                Text(
                    text = "AUTHENTICATING...",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    letterSpacing = 2.sp,
                    color = Color.White.copy(alpha = 0.8f)
                )
            }
        } else {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Center
            ) {
                Icon(
                    imageVector = Icons.Rounded.PlayArrow,
                    contentDescription = null,
                    tint = if (enabled) Color.White else UltraTokens.Fg4,
                    modifier = Modifier.size(22.dp)
                )
                Spacer(modifier = Modifier.width(10.dp))
                Text(
                    text = "ACTIVATE",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 4.sp,
                    color = if (enabled) Color.White else UltraTokens.Fg4
                )
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
//  Success Overlay
// ═══════════════════════════════════════════════════════════════

@Composable
private fun SuccessOverlay(
    modifier: Modifier = Modifier
) {
    var scale by remember { mutableStateOf(0f) }
    var alpha by remember { mutableStateOf(0f) }

    LaunchedEffect(Unit) {
        scale = 0f
        alpha = 0f
        delay(100)
        scale = 1f
        alpha = 1f
    }

    Box(
        modifier = modifier
            .background(Color.Black.copy(alpha = 0.7f))
            .padding(40.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            // Animated checkmark
            Box(
                modifier = Modifier
                    .size(100.dp)
                    .scale(scale)
                    .alpha(alpha)
                    .clip(CircleShape)
                    .background(
                        Brush.radialGradient(
                            colors = listOf(
                                UltraTokens.Accent.copy(alpha = 0.3f),
                                Color.Transparent
                            )
                        )
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Rounded.CheckCircle,
                    contentDescription = "Success",
                    tint = UltraTokens.Accent,
                    modifier = Modifier.size(60.dp)
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Success text with animation
            AnimatedVisibility(
                visible = true,
                enter = fadeIn(animationSpec = tween(500, delayMillis = 300)) +
                        slideInVertically(initialOffsetY = { 20 })
            ) {
                Text(
                    text = "ACTIVATED!",
                    fontSize = 28.sp,
                    fontWeight = FontWeight.Black,
                    letterSpacing = 4.sp,
                    color = Color.White
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            AnimatedVisibility(
                visible = true,
                enter = fadeIn(animationSpec = tween(500, delayMillis = 500))
            ) {
                Text(
                    text = "Your device is now ready",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium,
                    color = UltraTokens.Fg3
                )
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════
//  Particle System
// ═══════════════════════════════════════════════════════════════

private data class Particle(
    val x: Float,
    val y: Float,
    val size: Dp,
    val speed: Float,
    val angle: Float,
    val delay: Long
)

@Composable
private fun ParticleView(
    particle: Particle,
    modifier: Modifier = Modifier
) {
    val infiniteTransition = rememberInfiniteTransition(label = "particleAnim")
    val offsetX by infiniteTransition.animateFloat(
        initialValue = particle.x,
        targetValue = particle.x + cos(particle.angle) * 0.3f,
        animationSpec = infiniteRepeatable(
            animation = tween(
                durationMillis = (10000 / particle.speed).toInt(),
                easing = LinearEasing,
                delayMillis = particle.delay.toInt()
            ),
            repeatMode = RepeatMode.Reverse
        ),
        label = "particleX"
    )
    val offsetY by infiniteTransition.animateFloat(
        initialValue = particle.y,
        targetValue = particle.y + sin(particle.angle) * 0.3f,
        animationSpec = infiniteRepeatable(
            animation = tween(
                durationMillis = (12000 / particle.speed).toInt(),
                easing = LinearEasing,
                delayMillis = particle.delay.toInt()
            ),
            repeatMode = RepeatMode.Reverse
        ),
        label = "particleY"
    )
    val alpha by infiniteTransition.animateFloat(
        initialValue = 0.2f,
        targetValue = 0.8f,
        animationSpec = infiniteRepeatable(
            animation = tween(
                durationMillis = (2000 / particle.speed).toInt(),
                easing = EaseInOutSine,
                delayMillis = particle.delay.toInt()
            ),
            repeatMode = RepeatMode.Reverse
        ),
        label = "particleAlpha"
    )

    Box(
        modifier = modifier
            .offset(
                x = (offsetX * 1000).dp,
                y = (offsetY * 1000).dp
            )
            .size(particle.size)
            .alpha(alpha)
            .clip(CircleShape)
            .background(
                Brush.radialGradient(
                    colors = listOf(
                        UltraTokens.Accent.copy(alpha = 0.5f),
                        Color.Transparent
                    )
                )
            )
    )
}

// ═══════════════════════════════════════════════════════════════
//  Extension: Color.copy with alpha
// ═══════════════════════════════════════════════════════════════

private fun Color.copy(alpha: Float): Color = this.copy(alpha = alpha)