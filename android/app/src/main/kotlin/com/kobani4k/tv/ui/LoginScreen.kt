package com.kobani4k.tv.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.blur
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.tv.material3.*
import com.airbnb.lottie.compose.*
import com.kobani4k.tv.data.FirebaseRepository
import kotlinx.coroutines.launch

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun LoginScreen(onLoginSuccess: () -> Unit) {
    var enteredCode by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()
    val repository = remember { FirebaseRepository() }

    // Premium Lottie Background
    val composition by rememberLottieComposition(LottieCompositionSpec.Url("https://assets3.lottiefiles.com/packages/lf20_M9pWvS.json"))
    
    Box(modifier = Modifier.fillMaxSize().background(Color.Black)) {
        LottieAnimation(
            composition = composition,
            iterations = LottieConstants.IterateForever,
            modifier = Modifier.fillMaxSize().alpha(0.4f)
        )

        Row(
            modifier = Modifier.fillMaxSize(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // LEFT: Premium Branding
            Column(
                modifier = Modifier
                    .weight(1.2f)
                    .fillMaxHeight(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Text(
                    text = "KOBANI 4K",
                    style = MaterialTheme.typography.displayLarge,
                    color = Color(0xFFFFD700), // Gold
                    fontWeight = FontWeight.Black,
                    letterSpacing = 8.sp
                )
                Spacer(modifier = Modifier.height(60.dp))
                
                // Animated Glass Display for Code
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    for (i in 0 until 6) {
                        val hasDigit = i < enteredCode.length
                        Box(
                            modifier = Modifier
                                .size(72.dp, 90.dp)
                                .background(
                                    Color.White.copy(alpha = if (hasDigit) 0.15f else 0.05f),
                                    RoundedCornerShape(16.dp)
                                )
                                .border(
                                    width = if (hasDigit) 2.dp else 1.dp,
                                    color = if (hasDigit) Color(0xFFFFD700) else Color.White.copy(alpha = 0.2f),
                                    shape = RoundedCornerShape(16.dp)
                                ),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = if (hasDigit) enteredCode[i].toString() else "",
                                fontSize = 42.sp,
                                color = Color.White,
                                fontWeight = FontWeight.Black
                            )
                        }
                    }
                }

                AnimatedVisibility(visible = errorMessage != null) {
                    Text(
                        text = errorMessage ?: "",
                        color = Color(0xFFFF4444),
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.padding(top = 24.dp)
                    )
                }
            }

            // RIGHT: Glassmorphism Keypad
            Box(
                modifier = Modifier
                    .width(420.dp)
                    .fillMaxHeight()
                    .padding(40.dp)
            ) {
                // Frosted Glass Effect Base
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .blur(30.dp)
                        .background(Color.White.copy(alpha = 0.03f), RoundedCornerShape(32.dp))
                )

                // Keypad Content
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .border(
                            1.dp,
                            Brush.linearGradient(listOf(Color.White.copy(alpha = 0.3f), Color.Transparent)),
                            RoundedCornerShape(32.dp)
                        )
                        .padding(32.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    fun onDigit(digit: String) {
                        if (enteredCode.length < 6) {
                            enteredCode += digit
                            errorMessage = null
                        }
                    }

                    fun onBackspace() {
                        if (enteredCode.isNotEmpty()) enteredCode = enteredCode.dropLast(1)
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

                    rows.forEach { row ->
                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            row.forEach { key ->
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
                        Spacer(modifier = Modifier.height(16.dp))
                    }

                    Spacer(modifier = Modifier.height(16.dp))
                    
                    Button(
                        onClick = { handleSubmit() },
                        modifier = Modifier.fillMaxWidth().height(64.dp),
                        shape = ButtonDefaults.shape(shape = RoundedCornerShape(16.dp)),
                        colors = ButtonDefaults.colors(
                            containerColor = if (enteredCode.length == 6) Color(0xFFFFD700) else Color.White.copy(alpha = 0.08f),
                            contentColor = Color.Black
                        )
                    ) {
                        Text(
                            text = if (isLoading) "VERIFYING..." else "ACTIVATE DEVICE", 
                            fontWeight = FontWeight.Black, 
                            letterSpacing = 2.sp,
                            color = if (enteredCode.length == 6) Color.Black else Color.White.copy(alpha = 0.4f)
                        )
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun KeypadButton(label: String, isSpecial: Boolean = false, onClick: () -> Unit) {
    Button(
        onClick = onClick,
        modifier = Modifier.size(90.dp, 80.dp),
        shape = ButtonDefaults.shape(shape = RoundedCornerShape(16.dp)),
        colors = ButtonDefaults.colors(
            containerColor = Color.White.copy(alpha = 0.05f),
            focusedContainerColor = Color.White,
            contentColor = if (isSpecial) Color(0xFFFFD700) else Color.White,
            focusedContentColor = Color.Black
        )
    ) {
        Text(label, fontSize = 22.sp, fontWeight = FontWeight.Bold)
    }
}
