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
import com.kobani4k.app.tv.ui.VodPlayerScreen
import android.content.Context
import java.net.URLDecoder
import java.net.URLEncoder

class TvMainActivity : ComponentActivity() {
    @OptIn(ExperimentalTvMaterial3Api::class)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        com.kobani4k.app.GlobalProxyBypass.apply() // Enforce proxy bypass for ExoPlayer and native HTTP
        setContent {
            MaterialTheme(
                colorScheme = darkColorScheme()
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(MaterialTheme.colorScheme.background)
                ) {
                    val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    val initialSession = prefs.getBoolean("flutter.auth_logged_in", false)
                    val startDest = if (initialSession) "dashboard" else "login"

                    val navController = rememberNavController()

                    NavHost(navController = navController, startDestination = startDest) {
                        composable("login") {
                            LoginScreen(
                                onLoginSuccess = {
                                    prefs.edit().putBoolean("flutter.auth_logged_in", true).apply()
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
                                    
                                    // FIX: Provide a fallback string so the route doesn't break
                                    val safeLogo = if (channel.logo.isNullOrEmpty()) "NO_LOGO" else channel.logo
                                    val encodedLogo = URLEncoder.encode(safeLogo, "UTF-8")
                                    
                                    val route = if (channel.isMovie()) "vod_player" else "player"
                                    navController.navigate("$route/$encodedName/$encodedUrl/$encodedLogo")
                                },
                                onLogout = {
                                    prefs.edit().putBoolean("flutter.auth_logged_in", false).apply()
                                    navController.navigate("login") {
                                        popUpTo("dashboard") { inclusive = true }
                                    }
                                }
                            )
                        }
                        composable("player/{channelName}/{streamUrl}/{logoUrl}") { backStackEntry ->
                            val channelName = URLDecoder.decode(backStackEntry.arguments?.getString("channelName") ?: "Unknown", "UTF-8")
                            val streamUrl = URLDecoder.decode(backStackEntry.arguments?.getString("streamUrl") ?: "", "UTF-8")
                            val rawLogoUrl = URLDecoder.decode(backStackEntry.arguments?.getString("logoUrl") ?: "", "UTF-8")

                            // FIX: Convert "NO_LOGO" back to null
                            val logoUrl = if (rawLogoUrl == "NO_LOGO" || rawLogoUrl.isEmpty()) null else rawLogoUrl

                            PlayerScreen(
                                channelName = channelName,
                                streamUrl = streamUrl,
                                logoUrl = logoUrl,
                                onBack = { navController.popBackStack() }
                            )
                        }
                        composable("vod_player/{channelName}/{streamUrl}/{logoUrl}") { backStackEntry ->
                            val channelName = URLDecoder.decode(backStackEntry.arguments?.getString("channelName") ?: "Unknown", "UTF-8")
                            val streamUrl = URLDecoder.decode(backStackEntry.arguments?.getString("streamUrl") ?: "", "UTF-8")
                            val rawLogoUrl = URLDecoder.decode(backStackEntry.arguments?.getString("logoUrl") ?: "", "UTF-8")

                            val logoUrl = if (rawLogoUrl == "NO_LOGO" || rawLogoUrl.isEmpty()) null else rawLogoUrl

                            VodPlayerScreen(
                                channelName = channelName,
                                streamUrl = streamUrl,
                                logoUrl = logoUrl,
                                onBack = { navController.popBackStack() }
                            )
                        }
                    }
                }
            }
        }
    }
}
