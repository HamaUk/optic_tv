package com.kobani4k.app.tv.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.tv.material3.*
import com.kobani4k.app.R
import com.kobani4k.app.tv.data.PocketBaseRepository
import kotlinx.coroutines.launch

// Premium TV Palette matching Zina TV styling
private val CanvasColor = Color(0xFF07111B)
private val SurfaceColor = Color(0xFF0F1B29)
private val SurfaceElevatedColor = Color(0xFF162338)
private val BrandGold = Color(0xFFFFC766)
private val FocusedOutlineColor = Color(0xFFF5F7FB)
private val TextPrimary = Color(0xFFF5F7FB)
private val TextSecondary = Color(0xFFBBC6D8)
private val TextError = Color(0xFFFF4C4C)

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun LoginScreen(onLoginSuccess: () -> Unit) {
    var enteredCode by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
    val repository = remember { PocketBaseRepository() }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(CanvasColor)
    ) {
        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 64.dp, vertical = 48.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // LEFT PANEL: Activation Info matching Zina Login Screen
            Column(
                modifier = Modifier
                    .weight(1.2f)
                    .fillMaxHeight()
                    .padding(end = 64.dp),
                horizontalAlignment = Alignment.Start,
                verticalArrangement = Arrangement.Center
            ) {
                Text(
                    text = "Device Activation",
                    fontSize = 36.sp,
                    color = TextPrimary,
                    fontFamily = PoppinsFamily,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 1.sp
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "To continue with the activation process, please enter your 6-digit PIN code",
                    fontSize = 16.sp,
                    color = Color(0x88FFFFFF), // Zina TV #88ffffff
                    fontFamily = PoppinsFamily,
                    fontWeight = FontWeight.Medium
                )
                Spacer(modifier = Modifier.height(48.dp))

                // Responsive Glow Slots
                Row(
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    for (i in 0 until 6) {
                        val hasDigit = i < enteredCode.length
                        val digitValue = if (hasDigit) enteredCode[i].toString() else ""
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .aspectRatio(1f)
                                .shadow(if (hasDigit) 4.dp else 0.dp, RoundedCornerShape(12.dp))
                                .background(
                                    if (hasDigit) SurfaceElevatedColor else SurfaceColor,
                                    RoundedCornerShape(12.dp)
                                )
                                .border(
                                    width = if (hasDigit) 2.dp else 1.dp,
                                    color = if (hasDigit) BrandGold else SurfaceElevatedColor,
                                    shape = RoundedCornerShape(12.dp)
                                ),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = digitValue,
                                fontSize = 32.sp,
                                fontFamily = PoppinsFamily,
                                color = if (hasDigit) TextPrimary else Color.Transparent,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(48.dp))
                
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        painter = painterResource(id = R.drawable.ic_login),
                        contentDescription = null,
                        tint = BrandGold,
                        modifier = Modifier.size(24.dp)
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(
                        text = if (isLoading) "VERIFYING CODE..." else "WAITING FOR INPUT...",
                        color = if (isLoading) BrandGold else TextSecondary,
                        fontFamily = PoppinsFamily,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 2.sp
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))

                AnimatedVisibility(visible = errorMessage != null) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("!", color = TextError, fontFamily = PoppinsFamily, fontWeight = FontWeight.Bold, fontSize = 20.sp)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = errorMessage ?: "",
                            color = TextError,
                            fontFamily = PoppinsFamily,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
            }

            // RIGHT PANEL: Elegant Keypad matching ZinaKeyboard exactly
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight(),
                contentAlignment = Alignment.Center
            ) {
                // Keypad Container
                Surface(
                    shape = RoundedCornerShape(16.dp),
                    colors = SurfaceDefaults.colors(
                        containerColor = SurfaceColor
                    ),
                    border = Border(
                        border = androidx.compose.foundation.BorderStroke(1.dp, SurfaceElevatedColor),
                        shape = RoundedCornerShape(16.dp)
                    ),
                    modifier = Modifier
                        .width(360.dp)
                        .wrapContentHeight()
                ) {
                    Column(
                        modifier = Modifier
                            .wrapContentSize()
                            .padding(32.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(12.dp)
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
                                    val result = repository.verifyLoginCode(enteredCode)
                                    isLoading = false
                                    when (result) {
                                        "SUCCESS" -> onLoginSuccess()
                                        "ERROR" -> errorMessage = "NETWORK ERROR"
                                        else -> errorMessage = "INVALID OR EXPIRED CODE"
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
                            verticalArrangement = Arrangement.spacedBy(12.dp), // @dimen/keyboardInputMargin
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

                        // Submit Button matching Zina Login Button
                        val isReady = enteredCode.length == 6
                        Button(
                            onClick = { handleSubmit() },
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(56.dp),
                            shape = ButtonDefaults.shape(shape = RoundedCornerShape(12.dp)),
                            colors = ButtonDefaults.colors(
                                containerColor = if (isReady) BrandGold else SurfaceElevatedColor,
                                contentColor = if (isReady) CanvasColor else TextSecondary,
                                focusedContainerColor = FocusedOutlineColor,
                                focusedContentColor = CanvasColor
                            ),
                            scale = ButtonDefaults.scale(focusedScale = 1.05f)
                        ) {
                            if (isLoading) {
                                CircularProgressIndicator(color = CanvasColor, modifier = Modifier.size(24.dp))
                            } else {
                                Text(
                                    text = "LOGIN",
                                    fontFamily = PoppinsFamily,
                                    fontSize = 18.sp,
                                    fontWeight = FontWeight.Bold,
                                    letterSpacing = 1.sp
                                )
                            }
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
    val scale by animateFloatAsState(targetValue = if (isFocused) 1.05f else 1.0f)

    Surface(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .aspectRatio(1f) // Zina Keyboard uses 1:1 ratio
            .scale(scale)
            .onFocusChanged { isFocused = it.isFocused },
        shape = ClickableSurfaceDefaults.shape(shape = RoundedCornerShape(12.dp)), // Zina radius 12dip
        colors = ClickableSurfaceDefaults.colors(
            containerColor = SurfaceColor, // customColorBackgroundVariant
            focusedContainerColor = TextPrimary, // customColorPrimary (white focus)
            contentColor = if (isSpecial) BrandGold else TextPrimary,
            focusedContentColor = CanvasColor
        ),
        border = ClickableSurfaceDefaults.border(
            border = Border(
                border = androidx.compose.foundation.BorderStroke(1.dp, SurfaceElevatedColor),
                shape = RoundedCornerShape(12.dp)
            ),
            focusedBorder = Border(
                border = androidx.compose.foundation.BorderStroke(2.dp, FocusedOutlineColor),
                shape = RoundedCornerShape(12.dp)
            )
        )
    ) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            if (label == "DEL") {
                Text(
                    text = "⌫",
                    fontFamily = PoppinsFamily,
                    fontSize = 24.sp,
                    color = if (isFocused) CanvasColor else BrandGold,
                    fontWeight = FontWeight.Bold
                )
            } else if (label == "CLR") {
                Text(
                    text = "CLR",
                    fontFamily = PoppinsFamily,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold
                )
            } else {
                Text(
                    text = label,
                    fontFamily = PoppinsFamily,
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}
