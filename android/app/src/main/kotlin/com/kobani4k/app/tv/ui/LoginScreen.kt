package com.kobani4k.app.tv.ui

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.tv.material3.*
import com.kobani4k.app.tv.data.PocketBaseRepository
import com.kobani4k.app.tv.ui.theme.UltraTokens
import kotlinx.coroutines.launch

@OptIn(ExperimentalTvMaterial3Api::class)
@Composable
fun LoginScreen(onLoginSuccess: () -> Unit) {
    val repository = remember { PocketBaseRepository() }
    val scope = rememberCoroutineScope()

    var loginCode by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    // Background animation (Dynamic Orbs)
    val infiniteTransition = rememberInfiniteTransition(label = "bg")
    val gradientOffset by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 1000f,
        animationSpec = infiniteRepeatable(
            animation = tween(15000, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "gradientOffset"
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF09090C)),
        contentAlignment = Alignment.Center
    ) {
        // Dynamic Orbs
        Box(
            modifier = Modifier
                .offset(x = (-300).dp, y = (-200).dp)
                .size(700.dp)
                .background(
                    Brush.radialGradient(
                        colors = listOf(UltraTokens.Accent.copy(alpha = 0.2f), Color.Transparent),
                        radius = 700f + (gradientOffset / 5f)
                    )
                )
        )
        Box(
            modifier = Modifier
                .offset(x = 350.dp, y = 200.dp)
                .size(800.dp)
                .background(
                    Brush.radialGradient(
                        colors = listOf(Color(0xFF6C20D6).copy(alpha = 0.15f), Color.Transparent),
                        radius = 800f - (gradientOffset / 5f)
                    )
                )
        )

        Surface(
            modifier = Modifier
                .width(440.dp)
                .padding(24.dp),
            shape = RoundedCornerShape(32.dp),
            colors = SurfaceDefaults.colors(
                containerColor = Color(0xFF13141B).copy(alpha = 0.75f)
            ),
            border = Border(
                border = androidx.compose.foundation.BorderStroke(
                    1.dp, 
                    Brush.linearGradient(
                        colors = listOf(Color.White.copy(alpha = 0.1f), Color.White.copy(alpha = 0.02f))
                    )
                ),
                shape = RoundedCornerShape(32.dp)
            )
        ) {
            Column(
                modifier = Modifier.padding(horizontal = 40.dp, vertical = 48.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(24.dp)
            ) {
                // Kobani4k Logo Text
                Row(
                    modifier = Modifier.padding(bottom = 4.dp),
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "KOBANI ",
                        fontSize = 32.sp,
                        fontWeight = FontWeight.Black,
                        letterSpacing = 2.sp,
                        color = Color.White
                    )
                    Text(
                        text = "4K",
                        fontSize = 32.sp,
                        fontWeight = FontWeight.Black,
                        letterSpacing = 2.sp,
                        color = UltraTokens.Accent
                    )
                }

                Text(
                    text = "Enter your activation code below to sync your playlist.",
                    fontSize = 14.sp,
                    color = UltraTokens.Fg3,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(bottom = 8.dp)
                )

                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(56.dp)
                        .background(Color(0xFF1A1B22), RoundedCornerShape(12.dp))
                        .border(1.dp, Color.White.copy(alpha = 0.05f), RoundedCornerShape(12.dp))
                        .padding(horizontal = 20.dp),
                    contentAlignment = Alignment.CenterStart
                ) {
                    androidx.compose.foundation.text.BasicTextField(
                        value = loginCode,
                        onValueChange = { loginCode = it },
                        textStyle = androidx.compose.ui.text.TextStyle(
                            color = UltraTokens.Fg,
                            textAlign = TextAlign.Center,
                            fontWeight = FontWeight.Bold,
                            letterSpacing = 3.sp,
                            fontSize = 18.sp
                        ),
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                        decorationBox = { innerTextField ->
                            if (loginCode.isEmpty()) {
                                Text(
                                    text = "ACTIVATION CODE",
                                    color = UltraTokens.Fg3.copy(alpha = 0.6f),
                                    textAlign = TextAlign.Center,
                                    fontWeight = FontWeight.Medium,
                                    letterSpacing = 2.sp,
                                    modifier = Modifier.fillMaxWidth()
                                )
                            }
                            innerTextField()
                        }
                    )
                }

                if (errorMessage != null) {
                    Text(
                        text = errorMessage ?: "",
                        color = UltraTokens.Warn,
                        fontSize = 12.sp,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(top = 2.dp)
                    )
                }

                Spacer(modifier = Modifier.height(8.dp))
                
                // Button Animation
                val buttonScale by animateFloatAsState(
                    targetValue = if (isLoading) 0.95f else 1f,
                    animationSpec = spring(dampingRatio = Spring.DampingRatioMediumBouncy, stiffness = Spring.StiffnessLow),
                    label = "buttonScale"
                )

                Button(
                    onClick = { 
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
                    },
                    modifier = Modifier
                        .width(240.dp)
                        .height(48.dp)
                        .scale(buttonScale),
                    shape = ButtonDefaults.shape(RoundedCornerShape(12.dp)),
                    colors = ButtonDefaults.colors(
                        containerColor = UltraTokens.Accent,
                        contentColor = Color.White,
                        focusedContainerColor = UltraTokens.AccentGlow,
                        focusedContentColor = Color.White
                    )
                ) {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
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
                                Spacer(modifier = Modifier.width(12.dp))
                                Text(
                                    text = "Authenticating...",
                                    fontSize = 14.sp,
                                    fontWeight = FontWeight.SemiBold
                                )
                            }
                        } else {
                            Text(
                                text = "Log In",
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Bold,
                                letterSpacing = 1.sp,
                                textAlign = TextAlign.Center
                            )
                        }
                    }
                }
            }
        }
    }
}
