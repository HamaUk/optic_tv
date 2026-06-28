package com.kobani4k.app.tv.ui

import android.view.KeyEvent
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Backspace
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.LiveTv
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.tv.material3.*
import com.kobani4k.app.tv.data.PocketBaseRepository
import com.kobani4k.app.tv.ui.theme.UltraTokens
import com.kobani4k.app.tv.ui.theme.UltraType
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

private const val MAX_CODE_LENGTH = 10

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun LoginScreen(onLoginSuccess: () -> Unit) {
    val repository = remember { PocketBaseRepository() }
    val scope = rememberCoroutineScope()

    var loginCode by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    // Background animation
    val infiniteTransition = rememberInfiniteTransition(label = "bg")
    val orbPulse by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 1000f,
        animationSpec = infiniteRepeatable(
            animation = tween(20000, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "orbPulse"
    )

    val focusRequester1 = remember { FocusRequester() }

    LaunchedEffect(Unit) {
        delay(200)
        runCatching { focusRequester1.requestFocus() }
    }

    fun onDigitPress(digit: String) {
        if (loginCode.length < MAX_CODE_LENGTH && !isLoading) {
            errorMessage = null
            loginCode += digit
        }
    }

    fun onBackspace() {
        if (loginCode.isNotEmpty() && !isLoading) {
            loginCode = loginCode.dropLast(1)
        }
    }

    fun onClear() {
        if (!isLoading) {
            loginCode = ""
            errorMessage = null
        }
    }

    fun onLogin() {
        if (loginCode.isNotBlank() && !isLoading) {
            isLoading = true
            errorMessage = null
            scope.launch {
                val result = repository.verifyLoginCode(loginCode)
                isLoading = false
                when (result) {
                    "SUCCESS" -> onLoginSuccess()
                    "ERROR" -> errorMessage = "NETWORK ERROR"
                    else -> errorMessage = "INVALID OR EXPIRED CODE"
                }
            }
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(UltraTokens.BgDeep)
    ) {
        // ─── Animated Orbs ───
        Box(
            modifier = Modifier
                .offset(x = (-200).dp, y = (-150).dp)
                .size(700.dp)
                .background(
                    Brush.radialGradient(
                        colors = listOf(UltraTokens.Accent.copy(alpha = 0.15f), Color.Transparent),
                        radius = 700f + (orbPulse / 5f)
                    )
                )
        )
        Box(
            modifier = Modifier
                .offset(x = 500.dp, y = 250.dp)
                .size(800.dp)
                .background(
                    Brush.radialGradient(
                        colors = listOf(UltraTokens.Accent2.copy(alpha = 0.10f), Color.Transparent),
                        radius = 800f - (orbPulse / 5f)
                    )
                )
        )

        // ─── Main Two-Column Layout ───
        Row(
            modifier = Modifier.fillMaxSize(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // ═══ LEFT SIDE — Brand Hero ═══
            Box(
                modifier = Modifier
                    .weight(0.42f)
                    .fillMaxHeight(),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    // Animated logo icon
                    val logoScale by infiniteTransition.animateFloat(
                        initialValue = 1f,
                        targetValue = 1.08f,
                        animationSpec = infiniteRepeatable(
                            animation = tween(3000, easing = EaseInOutSine),
                            repeatMode = RepeatMode.Reverse
                        ),
                        label = "logoScale"
                    )

                    Box(
                        modifier = Modifier
                            .size(100.dp)
                            .scale(logoScale)
                            .clip(CircleShape)
                            .background(
                                Brush.radialGradient(
                                    colors = listOf(
                                        UltraTokens.Accent.copy(alpha = 0.3f),
                                        UltraTokens.Accent.copy(alpha = 0.05f),
                                        Color.Transparent
                                    )
                                )
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            Icons.Rounded.LiveTv,
                            contentDescription = "Logo",
                            tint = UltraTokens.Accent,
                            modifier = Modifier.size(52.dp)
                        )
                    }

                    Spacer(Modifier.height(32.dp))

                    Row(
                        horizontalArrangement = Arrangement.Center,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "KOBANI",
                            fontSize = 42.sp,
                            fontWeight = FontWeight.Black,
                            letterSpacing = 3.sp,
                            color = Color.White
                        )
                        Spacer(Modifier.width(8.dp))
                        Text(
                            text = "4K",
                            fontSize = 42.sp,
                            fontWeight = FontWeight.Black,
                            letterSpacing = 3.sp,
                            color = UltraTokens.Accent
                        )
                    }

                    Spacer(Modifier.height(12.dp))

                    Text(
                        text = "PREMIUM STREAMING",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium,
                        letterSpacing = 4.sp,
                        color = UltraTokens.Fg3,
                        textAlign = TextAlign.Center
                    )

                    Spacer(Modifier.height(48.dp))

                    // Decorative line
                    Box(
                        modifier = Modifier
                            .width(60.dp)
                            .height(3.dp)
                            .clip(RoundedCornerShape(2.dp))
                            .background(UltraTokens.GradientHero)
                    )
                }
            }

            // ═══ RIGHT SIDE — Login Card ═══
            Box(
                modifier = Modifier
                    .weight(0.58f)
                    .fillMaxHeight(),
                contentAlignment = Alignment.Center
            ) {
                // Glassmorphism card
                Column(
                    modifier = Modifier
                        .width(480.dp)
                        .clip(RoundedCornerShape(28.dp))
                        .background(UltraTokens.Surface1.copy(alpha = 0.85f))
                        .border(
                            1.dp,
                            Brush.linearGradient(
                                colors = listOf(
                                    Color.White.copy(alpha = 0.08f),
                                    Color.White.copy(alpha = 0.02f)
                                )
                            ),
                            RoundedCornerShape(28.dp)
                        )
                        .padding(horizontal = 40.dp, vertical = 36.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "Activation Code",
                        fontSize = 22.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )

                    Spacer(Modifier.height(6.dp))

                    Text(
                        text = "Enter your code using the keypad below",
                        fontSize = 14.sp,
                        color = UltraTokens.Fg3,
                        textAlign = TextAlign.Center
                    )

                    Spacer(Modifier.height(28.dp))

                    // ─── Code Display ───
                    CodeDisplay(code = loginCode)

                    Spacer(Modifier.height(8.dp))

                    // Error message
                    if (errorMessage != null) {
                        Text(
                            text = errorMessage ?: "",
                            color = UltraTokens.Warn,
                            fontSize = 13.sp,
                            fontWeight = FontWeight.SemiBold,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.padding(vertical = 4.dp)
                        )
                    }

                    Spacer(Modifier.height(16.dp))

                    // ─── Numeric Keypad ───
                    NumericKeypad(
                        onDigit = ::onDigitPress,
                        onBackspace = ::onBackspace,
                        onClear = ::onClear,
                        firstKeyFocusRequester = focusRequester1
                    )

                    Spacer(Modifier.height(24.dp))

                    // ─── Login Button ───
                    LoginButton(
                        isLoading = isLoading,
                        enabled = loginCode.isNotBlank(),
                        onClick = ::onLogin
                    )
                }
            }
        }
    }
}

// ═══════════════════════════════════════════════════
//  Code Display — PIN-style digit boxes
// ═══════════════════════════════════════════════════

@Composable
private fun CodeDisplay(code: String) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp)
            .clip(RoundedCornerShape(14.dp))
            .background(UltraTokens.BgDeep)
            .border(
                1.dp,
                if (code.isNotEmpty()) UltraTokens.Accent.copy(alpha = 0.4f) else Color.White.copy(alpha = 0.08f),
                RoundedCornerShape(14.dp)
            ),
        contentAlignment = Alignment.Center
    ) {
        if (code.isEmpty()) {
            Text(
                text = "• • • • • •",
                fontSize = 24.sp,
                color = UltraTokens.Fg4,
                letterSpacing = 6.sp,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center
            )
        } else {
            Text(
                text = code,
                fontSize = 28.sp,
                color = UltraTokens.Accent,
                letterSpacing = 8.sp,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center
            )
        }
    }
}

// ═══════════════════════════════════════════════════
//  Numeric Keypad — 4x3 grid, fully D-pad navigable
// ═══════════════════════════════════════════════════

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
private fun NumericKeypad(
    onDigit: (String) -> Unit,
    onBackspace: () -> Unit,
    onClear: () -> Unit,
    firstKeyFocusRequester: FocusRequester
) {
    val keys = listOf(
        listOf("1", "2", "3"),
        listOf("4", "5", "6"),
        listOf("7", "8", "9"),
        listOf("CLR", "0", "⌫")
    )

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
                    val isFirstKey = rowIndex == 0 && colIndex == 0
                    KeypadButton(
                        label = key,
                        modifier = Modifier
                            .weight(1f)
                            .then(
                                if (isFirstKey) Modifier.focusRequester(firstKeyFocusRequester)
                                else Modifier
                            ),
                        onClick = {
                            when (key) {
                                "CLR" -> onClear()
                                "⌫" -> onBackspace()
                                else -> onDigit(key)
                            }
                        }
                    )
                }
            }
        }
    }
}

@Composable
private fun KeypadButton(
    label: String,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(
        if (isFocused) 1.08f else 1f,
        animationSpec = tween(150),
        label = "keyScale"
    )
    val bgColor by animateColorAsState(
        if (isFocused) UltraTokens.Accent else UltraTokens.Surface3,
        animationSpec = tween(150),
        label = "keyBg"
    )
    val borderColor by animateColorAsState(
        if (isFocused) UltraTokens.Accent else Color.White.copy(alpha = 0.06f),
        animationSpec = tween(150),
        label = "keyBorder"
    )

    val isSpecial = label == "CLR" || label == "⌫"

    Box(
        modifier = modifier
            .height(52.dp)
            .scale(scale)
            .clip(RoundedCornerShape(12.dp))
            .background(bgColor)
            .border(1.dp, borderColor, RoundedCornerShape(12.dp))
            .onFocusChanged { isFocused = it.isFocused }
            .focusable()
            .onKeyEvent { keyEvent ->
                if (keyEvent.nativeKeyEvent.action == KeyEvent.ACTION_DOWN) {
                    when (keyEvent.nativeKeyEvent.keyCode) {
                        KeyEvent.KEYCODE_DPAD_CENTER, KeyEvent.KEYCODE_ENTER, KeyEvent.KEYCODE_NUMPAD_ENTER -> {
                            onClick()
                            true
                        }
                        else -> false
                    }
                } else false
            },
        contentAlignment = Alignment.Center
    ) {
        if (label == "⌫") {
            Icon(
                Icons.Rounded.Backspace,
                contentDescription = "Backspace",
                tint = if (isFocused) Color.White else UltraTokens.Fg2,
                modifier = Modifier.size(24.dp)
            )
        } else {
            Text(
                text = label,
                fontSize = if (isSpecial) 14.sp else 22.sp,
                fontWeight = if (isSpecial) FontWeight.Bold else FontWeight.SemiBold,
                letterSpacing = if (isSpecial) 1.sp else 0.sp,
                color = if (isFocused) Color.White else if (isSpecial) UltraTokens.Fg3 else UltraTokens.Fg
            )
        }
    }
}

// ═══════════════════════════════════════════════════
//  Login Button
// ═══════════════════════════════════════════════════

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
private fun LoginButton(
    isLoading: Boolean,
    enabled: Boolean,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(
        if (isLoading) 0.96f else if (isFocused) 1.04f else 1f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessLow
        ),
        label = "btnScale"
    )
    val bgColor by animateColorAsState(
        if (isFocused) UltraTokens.Accent else if (enabled) UltraTokens.Accent.copy(alpha = 0.7f) else UltraTokens.Surface3,
        label = "btnBg"
    )
    val borderColor by animateColorAsState(
        if (isFocused) Color.White.copy(alpha = 0.3f) else Color.Transparent,
        label = "btnBorder"
    )

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(54.dp)
            .scale(scale)
            .clip(RoundedCornerShape(14.dp))
            .background(bgColor)
            .border(2.dp, borderColor, RoundedCornerShape(14.dp))
            .onFocusChanged { isFocused = it.isFocused }
            .focusable()
            .onKeyEvent { keyEvent ->
                if (keyEvent.nativeKeyEvent.action == KeyEvent.ACTION_DOWN) {
                    when (keyEvent.nativeKeyEvent.keyCode) {
                        KeyEvent.KEYCODE_DPAD_CENTER, KeyEvent.KEYCODE_ENTER, KeyEvent.KEYCODE_NUMPAD_ENTER -> {
                            onClick()
                            true
                        }
                        else -> false
                    }
                } else false
            },
        contentAlignment = Alignment.Center
    ) {
        if (isLoading) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Center
            ) {
                CircularProgressIndicator(
                    modifier = Modifier.size(20.dp),
                    color = Color.White,
                    strokeWidth = 2.5.dp
                )
                Spacer(Modifier.width(12.dp))
                Text(
                    text = "Authenticating...",
                    fontSize = 15.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = Color.White
                )
            }
        } else {
            Text(
                text = "LOG IN",
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 2.sp,
                color = if (enabled) Color.White else UltraTokens.Fg4
            )
        }
    }
}
