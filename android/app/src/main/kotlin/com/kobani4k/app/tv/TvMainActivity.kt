package com.kobani4k.app.tv

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.ui.Modifier
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.tv.material3.ExperimentalTvMaterial3Api
import androidx.tv.material3.MaterialTheme
import androidx.tv.material3.darkColorScheme
import com.kobani4k.app.tv.ui.DashboardScreen
import com.kobani4k.app.tv.ui.LoginScreen
import com.kobani4k.app.tv.ui.PlayerScreen
import java.net.URLDecoder
import java.net.URLEncoder

class TvMainActivity : ComponentActivity() {
    @OptIn(ExperimentalTvMaterial3Api::class)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme(
                colorScheme = darkColorScheme()
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(MaterialTheme.colorScheme.background)
                ) {
                    val navController = rememberNavController()

                    NavHost(navController = navController, startDestination = "login") {
                        composable("login") {
                            LoginScreen(
                                onLoginSuccess = {
                                    navController.navigate("dashboard") {
                                        popUpTo("login") { inclusive = true }
                                    }
                                }
                            )
                        }
                        composable("dashboard") {
                            DashboardScreen(
                                onChannelSelected = { channel ->
                                    val encodedName = URLEncoder.encode(channel.name, "UTF-8")
                                    val encodedUrl = URLEncoder.encode(channel.url, "UTF-8")
                                    val encodedLogo = URLEncoder.encode(channel.logo ?: "", "UTF-8")
                                    navController.navigate("player/$encodedName/$encodedUrl/$encodedLogo")
                                },
                                onLogout = {
                                    navController.navigate("login") {
                                        popUpTo("dashboard") { inclusive = true }
                                    }
                                }
                            )
                        }
                        composable("player/{channelName}/{streamUrl}/{logoUrl}") { backStackEntry ->
                            val channelName = URLDecoder.decode(backStackEntry.arguments?.getString("channelName") ?: "Unknown", "UTF-8")
                            val streamUrl = URLDecoder.decode(backStackEntry.arguments?.getString("streamUrl") ?: "", "UTF-8")
                            val logoUrl = URLDecoder.decode(backStackEntry.arguments?.getString("logoUrl") ?: "", "UTF-8")

                            PlayerScreen(
                                channelName = channelName,
                                streamUrl = streamUrl,
                                logoUrl = logoUrl.ifEmpty { null },
                                onBack = { navController.popBackStack() }
                            )
                        }
                    }
                }
            }
        }
    }
}
