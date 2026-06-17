package com.kobani4k.tv.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.scale
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.tv.material3.*
import com.airbnb.lottie.compose.*
import com.kobani4k.tv.data.FirebaseRepository
import kotlinx.coroutines.launch

// Premium Palette
private val CanvasColor = Color(0xFF07111B)
private val CanvasElevated = Color(0xFF0B1622)
private val SurfaceColor = Color(0xFF0F1B29)
private val SurfaceElevatedColor = Color(0xFF162338)
private val BrandGold = Color(0xFFFFC766)
private val BrandGoldMuted = Color(0x33FFC766)
private val FocusedOutlineColor = Color(0xFFF5F7FB)
private val TextPrimary = Color(0xFFF5F7FB)
private val TextSecondary = Color(0xFFBBC6D8)
private val TextError = Color(0xFFFF5C61)

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun LoginScreen(onLoginSuccess: () -> Unit) {
    var enteredCode by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
    val repository = remember { FirebaseRepository() }

    // Premium Lottie Background
    val composition by rememberLottieComposition(
        LottieCompositionSpec.Url("https://assets3.lottiefiles.com/packages/lf20_M9pWvS.json")
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    colors = listOf(CanvasColor, CanvasElevated)
                )
            )
    ) {
        LottieAnimation(
            composition = composition,
            iterations = LottieConstants.IterateForever,
            modifier = Modifier
                .fillMaxSize()
                .alpha(0.2f)
        )

        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 48.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // LEFT PANEL: Luxury Branding & Activation Fields
            Column(
                modifier = Modifier
                    .weight(1.2f)
                    .fillMaxHeight(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Text(
                    text = "KOBANI 4K",
                    fontSize = 46.sp,
                    color = BrandGold,
                    fontWeight = FontWeight.Black,
                    letterSpacing = 6.sp
                )
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    text = "ENTER DEVICE ACTIVATION CODE",
                    fontSize = 14.sp,
                    color = TextSecondary,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 2.sp
                )
                Spacer(modifier = Modifier.height(48.dp))

                // Modern Glow Slots
                Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                    for (i in 0 until 6) {
                        val hasDigit = i < enteredCode.length
                        val digitValue = if (hasDigit) enteredCode[i].toString() else ""
                        Box(
                            modifier = Modifier
                                .size(70.dp, 88.dp)
                                .background(
                                    if (hasDigit) SurfaceElevatedColor else SurfaceColor,
                                    RoundedCornerShape(18.dp)
                                )
                                .border(
                                    width = if (hasDigit) 2.dp else 1.dp,
                                    color = if (hasDigit) BrandGold else SurfaceElevatedColor,
                                    shape = RoundedCornerShape(18.dp)
                                ),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = digitValue,
                                fontSize = 38.sp,
                                color = if (hasDigit) TextPrimary else TextSecondary.copy(alpha = 0.5f),
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

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
                    .width(420.dp)
                    .fillMaxHeight()
                    .padding(vertical = 40.dp)
            ) {
                // Keypad Card Surface
                Surface(
                    shape = RoundedCornerShape(32.dp),
                    colors = SurfaceDefaults.colors(
                        containerColor = SurfaceColor.copy(alpha = 0.9f)
                    ),
                    border = Border(
                        border = androidx.compose.foundation.BorderStroke(1.dp, SurfaceElevatedColor),
                        shape = RoundedCornerShape(32.dp)
                    ),
                    modifier = Modifier.fillMaxSize()
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(28.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.SpaceBetween
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
                            verticalArrangement = Arrangement.spacedBy(12.dp),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            rows.forEach { row ->
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.spacedBy(12.dp)
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

                        Spacer(modifier = Modifier.height(16.dp))

                        // Submit Button
                        Button(
                            onClick = { handleSubmit() },
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(60.dp),
                            shape = ButtonDefaults.shape(shape = RoundedCornerShape(16.dp)),
                            colors = ButtonDefaults.colors(
                                containerColor = if (enteredCode.length == 6) BrandGold else SurfaceElevatedColor,
                                contentColor = if (enteredCode.length == 6) CanvasColor else TextSecondary,
                                focusedContainerColor = TextPrimary,
                                focusedContentColor = CanvasColor
                            )
                        ) {
                            Text(
                                text = if (isLoading) "VERIFYING..." else "ACTIVATE DEVICE",
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold,
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
    var isFocused by remember { mutableStateOf(false) }
    val scale by animateFloatAsState(targetValue = if (isFocused) 1.08f else 1.0f)

    Button(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .height(68.dp)
            .scale(scale)
            .onFocusChanged { isFocused = it.isFocused },
        shape = ButtonDefaults.shape(shape = RoundedCornerShape(16.dp)),
        colors = ButtonDefaults.colors(
            containerColor = SurfaceElevatedColor.copy(alpha = 0.5f),
            focusedContainerColor = TextPrimary,
            contentColor = if (isSpecial) BrandGold else TextPrimary,
            focusedContentColor = CanvasColor
        ),
        border = ButtonDefaults.border(
            border = Border(
                border = androidx.compose.foundation.BorderStroke(1.dp, SurfaceElevatedColor),
                shape = RoundedCornerShape(16.dp)
            ),
            focusedBorder = Border(
                border = androidx.compose.foundation.BorderStroke(2.dp, FocusedOutlineColor),
                shape = RoundedCornerShape(16.dp)
            )
        )
    ) {
        Text(
            text = label,
            fontSize = 20.sp,
            fontWeight = FontWeight.Bold
        )
    }
}
