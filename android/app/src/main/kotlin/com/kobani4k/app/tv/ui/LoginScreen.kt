package com.kobani4k.app.tv.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.tv.material3.*
import com.kobani4k.app.tv.data.PocketBaseRepository
import com.kobani4k.app.tv.ui.theme.UltraTokens
import com.kobani4k.app.tv.ui.theme.UltraFonts
import kotlinx.coroutines.launch

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
            .background(
                Brush.radialGradient(
                    colors = listOf(UltraTokens.Surface1, Color.Black),
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
                    color = UltraTokens.Fg,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 8.sp,
                )
                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    text = "ENTER DEVICE ACTIVATION CODE",
                    fontSize = 15.sp,
                    color = UltraTokens.Fg3,
                    fontWeight = FontWeight.Medium,
                    letterSpacing = 3.sp
                )
                Spacer(modifier = Modifier.height(56.dp))

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
                                    if (hasDigit) UltraTokens.SurfaceStrong else UltraTokens.Surface2,
                                    RoundedCornerShape(16.dp)
                                )
                                .border(
                                    width = if (hasDigit) 2.dp else 1.dp,
                                    color = if (hasDigit) UltraTokens.Accent else UltraTokens.Line2,
                                    shape = RoundedCornerShape(16.dp)
                                ),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = digitValue,
                                fontSize = 42.sp,
                                color = if (hasDigit) UltraTokens.Fg else Color.Transparent,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(32.dp))

                AnimatedVisibility(visible = errorMessage != null) {
                    Text(
                        text = errorMessage ?: "",
                        color = UltraTokens.Warn,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 1.sp
                    )
                }
            }

            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight()
                    .padding(vertical = 16.dp),
                contentAlignment = Alignment.Center
            ) {
                Surface(
                    shape = RoundedCornerShape(28.dp),
                    colors = SurfaceDefaults.colors(
                        containerColor = UltraTokens.Surface2
                    ),
                    border = Border(
                        border = androidx.compose.foundation.BorderStroke(1.dp, UltraTokens.Line2),
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

                        val isReady = enteredCode.length == 6
                        Button(
                            onClick = { handleSubmit() },
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(64.dp),
                            shape = ButtonDefaults.shape(shape = RoundedCornerShape(16.dp)),
                            colors = ButtonDefaults.colors(
                                containerColor = if (isReady) UltraTokens.Accent else UltraTokens.Surface3,
                                contentColor = UltraTokens.Fg,
                                focusedContainerColor = UltraTokens.Fg,
                                focusedContentColor = Color.Black
                            ),
                            scale = ButtonDefaults.scale(focusedScale = 1.05f)
                        ) {
                            Text(
                                text = if (isLoading) "VERIFYING..." else "ACTIVATE DEVICE",
                                fontSize = 16.sp,
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
            containerColor = UltraTokens.Surface3,
            focusedContainerColor = UltraTokens.Fg,
            contentColor = if (isSpecial) UltraTokens.Accent else UltraTokens.Fg,
            focusedContentColor = Color.Black
        ),
        scale = ButtonDefaults.scale(focusedScale = 1.08f),
        border = ButtonDefaults.border(
            border = Border(
                border = androidx.compose.foundation.BorderStroke(1.dp, UltraTokens.Line2),
                shape = RoundedCornerShape(16.dp)
            ),
            focusedBorder = Border(
                border = androidx.compose.foundation.BorderStroke(2.dp, UltraTokens.Accent),
                shape = RoundedCornerShape(16.dp)
            )
        )
    ) {
        Text(
            text = label,
            fontSize = 20.sp,
            fontWeight = FontWeight.Medium
        )
    }
}
