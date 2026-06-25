package com.kobani4k.app.tv.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.tv.material3.*
import com.kobani4k.app.tv.data.FirebaseRepository
import kotlinx.coroutines.launch

// Refined Premium Palette
private val BackgroundDark = Color(0xFF04080F)
private val BackgroundGradientEnd = Color(0xFF0F1A2C)
private val SurfaceColor = Color(0x40162338) // Glass effect
private val SurfaceElevatedColor = Color(0x801E2E4A)
private val BrandGold = Color(0xFFFFD700)
private val BrandGoldMuted = Color(0x40FFD700)
private val FocusedOutlineColor = Color(0xFFFFFFFF)
private val TextPrimary = Color(0xFFFFFFFF)
private val TextSecondary = Color(0xFF90A4BE)
private val TextError = Color(0xFFFF4C4C)

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun LoginScreen(onLoginSuccess: () -> Unit) {
    var enteredCode by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
    val repository = remember { FirebaseRepository() }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.radialGradient(
                    colors = listOf(BackgroundGradientEnd, BackgroundDark),
                    radius = 1200f
                )
            )
    ) {
        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 48.dp, vertical = 32.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // LEFT PANEL: Luxury Branding & Activation Fields
            Column(
                modifier = Modifier
                    .weight(1.3f)
                    .fillMaxHeight()
                    .padding(end = 40.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Text(
                    text = "KOBANI 4K",
                    fontSize = 54.sp,
                    color = BrandGold,
                    fontWeight = FontWeight.Black,
                    letterSpacing = 8.sp,
                    style = androidx.compose.ui.text.TextStyle(
                        shadow = androidx.compose.ui.graphics.Shadow(
                            color = BrandGoldMuted,
                            blurRadius = 20f
                        )
                    )
                )
                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    text = "ENTER DEVICE ACTIVATION CODE",
                    fontSize = 15.sp,
                    color = TextSecondary,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 3.sp
                )
                Spacer(modifier = Modifier.height(56.dp))

                // Responsive Glow Slots
                Row(
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    modifier = Modifier.fillMaxWidth(0.9f)
                ) {
                    for (i in 0 until 6) {
                        val hasDigit = i < enteredCode.length
                        val digitValue = if (hasDigit) enteredCode[i].toString() else ""
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .aspectRatio(0.85f)
                                .shadow(if (hasDigit) 8.dp else 0.dp, RoundedCornerShape(16.dp))
                                .background(
                                    if (hasDigit) SurfaceElevatedColor else SurfaceColor,
                                    RoundedCornerShape(16.dp)
                                )
                                .border(
                                    width = if (hasDigit) 2.dp else 1.dp,
                                    color = if (hasDigit) BrandGold else SurfaceElevatedColor,
                                    shape = RoundedCornerShape(16.dp)
                                ),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = digitValue,
                                fontSize = 42.sp,
                                color = if (hasDigit) TextPrimary else Color.Transparent,
                                fontWeight = FontWeight.ExtraBold
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(32.dp))

                AnimatedVisibility(visible = errorMessage != null) {
                    Text(
                        text = errorMessage ?: "",
                        color = TextError,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 1.sp
                    )
                }
            }

            // RIGHT PANEL: Elegant Keypad
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight()
                    .padding(vertical = 16.dp),
                contentAlignment = Alignment.Center
            ) {
                // Keypad Card Surface
                Surface(
                    shape = RoundedCornerShape(28.dp),
                    colors = SurfaceDefaults.colors(
                        containerColor = SurfaceColor
                    ),
                    border = Border(
                        border = androidx.compose.foundation.BorderStroke(1.dp, SurfaceElevatedColor),
                        shape = RoundedCornerShape(28.dp)
                    ),
                    modifier = Modifier
                        .width(340.dp)
                        .wrapContentHeight()
                ) {
                    Column(
                        modifier = Modifier
                            .wrapContentSize()
                            .padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        fun onDigit(digit: String) {
                            if (enteredCode.length < 6) {
                                enteredCode += digit
                                errorMessage = null
                            }
                        }

                        fun onBackspace() {
                            if (enteredCode.isNotEmpty()) {
                                enteredCode = enteredCode.dropLast(1)
                            }
                            errorMessage = null
                        }

                        fun onClear() {
                            enteredCode = ""
                            errorMessage = null
                        }

                        fun handleSubmit() {
                            if (enteredCode.length == 6 && !isLoading) {
                                isLoading = true
                                errorMessage = null
                                scope.launch {
                                    val success = repository.verifyLoginCode(enteredCode)
                                    isLoading = false
                                    if (success) {
                                        onLoginSuccess()
                                    } else {
                                        errorMessage = "INVALID OR EXPIRED CODE"
                                    }
                                }
                            }
                        }

                        val rows = listOf(
                            listOf("1", "2", "3"),
                            listOf("4", "5", "6"),
                            listOf("7", "8", "9"),
                            listOf("DEL", "0", "CLR")
                        )

                        Column(
                            verticalArrangement = Arrangement.spacedBy(14.dp),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            rows.forEach { row ->
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.spacedBy(14.dp)
                                ) {
                                    row.forEach { key ->
                                        Box(modifier = Modifier.weight(1f)) {
                                            KeypadButton(
                                                label = key,
                                                isSpecial = key == "DEL" || key == "CLR"
                                            ) {
                                                when (key) {
                                                    "DEL" -> onBackspace()
                                                    "CLR" -> onClear()
                                                    else -> onDigit(key)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(8.dp))

                        // Submit Button
                        val isReady = enteredCode.length == 6
                        Button(
                            onClick = { handleSubmit() },
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(64.dp),
                            shape = ButtonDefaults.shape(shape = RoundedCornerShape(16.dp)),
                            colors = ButtonDefaults.colors(
                                containerColor = if (isReady) BrandGold else SurfaceElevatedColor,
                                contentColor = if (isReady) BackgroundDark else TextSecondary,
                                focusedContainerColor = FocusedOutlineColor,
                                focusedContentColor = BackgroundDark
                            ),
                            scale = ButtonDefaults.scale(focusedScale = 1.05f)
                        ) {
                            Text(
                                text = if (isLoading) "VERIFYING..." else "ACTIVATE DEVICE",
                                fontSize = 18.sp,
                                fontWeight = FontWeight.ExtraBold,
                                letterSpacing = 2.sp
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
fun KeypadButton(
    label: String,
    isSpecial: Boolean,
    onClick: () -> Unit
) {
    Button(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .aspectRatio(1.4f),
        shape = ButtonDefaults.shape(shape = RoundedCornerShape(16.dp)),
        colors = ButtonDefaults.colors(
            containerColor = SurfaceElevatedColor.copy(alpha = 0.6f),
            focusedContainerColor = FocusedOutlineColor,
            contentColor = if (isSpecial) BrandGold else TextPrimary,
            focusedContentColor = BackgroundDark
        ),
        scale = ButtonDefaults.scale(focusedScale = 1.08f),
        border = ButtonDefaults.border(
            border = Border(
                border = androidx.compose.foundation.BorderStroke(1.dp, SurfaceElevatedColor),
                shape = RoundedCornerShape(16.dp)
            ),
            focusedBorder = Border(
                border = androidx.compose.foundation.BorderStroke(3.dp, BrandGold),
                shape = RoundedCornerShape(16.dp)
            )
        )
    ) {
        Text(
            text = label,
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold
        )
    }
}
