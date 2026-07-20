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
import androidx.tv.material3.Typography
import androidx.tv.material3.darkColorScheme
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.Font
import androidx.compose.runtime.*
import android.content.SharedPreferences
import com.kobani4k.app.tv.ui.DashboardScreen
import com.kobani4k.app.tv.ui.LoginScreen
import com.kobani4k.app.tv.ui.MovieDetailScreen
import com.kobani4k.app.tv.ui.PlayerScreen
import com.kobani4k.app.tv.ui.VodPlayerScreen
import com.kobani4k.app.R
import android.content.Context
import android.view.WindowManager
import android.util.Base64

// Safe Base64 helpers — avoids all route-breaking characters
private fun b64Encode(value: String): String =
    Base64.encodeToString(value.toByteArray(Charsets.UTF_8), Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING)

private fun b64Decode(value: String): String =
    String(Base64.decode(value, Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING), Charsets.UTF_8)

class TvMainActivity : ComponentActivity() {
    @OptIn(ExperimentalTvMaterial3Api::class)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        com.kobani4k.app.GlobalProxyBypass.apply() // Enforce proxy bypass for ExoPlayer and native HTTP
        setContent {
            val context = androidx.compose.ui.platform.LocalContext.current
            val prefs = remember { com.kobani4k.app.tv.data.AppPreferences(context) }
            val sharedPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            var appLanguage by remember { mutableStateOf(prefs.appLanguage) }

            DisposableEffect(sharedPrefs) {
                val listener = SharedPreferences.OnSharedPreferenceChangeListener { sp, key ->
                    if (key == "settings.app_lang") {
                        appLanguage = sp.getString(key, "Kurdish Sorani") ?: "Kurdish Sorani"
                    }
                }
                sharedPrefs.registerOnSharedPreferenceChangeListener(listener)
                onDispose {
                    sharedPrefs.unregisterOnSharedPreferenceChangeListener(listener)
                }
            }

            val rabarFontFamily = FontFamily(
                Font(R.font.rabar_021, weight = androidx.compose.ui.text.font.FontWeight.Normal),
                Font(R.font.rabar_021, weight = androidx.compose.ui.text.font.FontWeight.Medium),
                Font(R.font.rabar_021, weight = androidx.compose.ui.text.font.FontWeight.SemiBold),
                Font(R.font.rabar_021, weight = androidx.compose.ui.text.font.FontWeight.Bold),
                Font(R.font.rabar_021, weight = androidx.compose.ui.text.font.FontWeight.ExtraBold)
            )
            val defaultTypography = Typography()
            val customTypography = if (appLanguage == "Kurdish Sorani" || appLanguage == "Arabic") {
                Typography(
                    displayLarge = defaultTypography.displayLarge.copy(fontFamily = rabarFontFamily),
                    displayMedium = defaultTypography.displayMedium.copy(fontFamily = rabarFontFamily),
                    displaySmall = defaultTypography.displaySmall.copy(fontFamily = rabarFontFamily),
                    headlineLarge = defaultTypography.headlineLarge.copy(fontFamily = rabarFontFamily),
                    headlineMedium = defaultTypography.headlineMedium.copy(fontFamily = rabarFontFamily),
                    headlineSmall = defaultTypography.headlineSmall.copy(fontFamily = rabarFontFamily),
                    titleLarge = defaultTypography.titleLarge.copy(fontFamily = rabarFontFamily),
                    titleMedium = defaultTypography.titleMedium.copy(fontFamily = rabarFontFamily),
                    titleSmall = defaultTypography.titleSmall.copy(fontFamily = rabarFontFamily),
                    labelLarge = defaultTypography.labelLarge.copy(fontFamily = rabarFontFamily),
                    labelMedium = defaultTypography.labelMedium.copy(fontFamily = rabarFontFamily),
                    labelSmall = defaultTypography.labelSmall.copy(fontFamily = rabarFontFamily),
                    bodyLarge = defaultTypography.bodyLarge.copy(fontFamily = rabarFontFamily),
                    bodyMedium = defaultTypography.bodyMedium.copy(fontFamily = rabarFontFamily),
                    bodySmall = defaultTypography.bodySmall.copy(fontFamily = rabarFontFamily)
                )
            } else {
                defaultTypography
            }

            MaterialTheme(
                colorScheme = darkColorScheme(),
                typography = customTypography
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(MaterialTheme.colorScheme.background)
                ) {
                    val initialSession = sharedPrefs.getBoolean("flutter.auth_logged_in", false)
                    val startDest = if (initialSession) "dashboard" else "login"

                    val navController = rememberNavController()

                    NavHost(navController = navController, startDestination = startDest) {
                        composable("login") {
                            LoginScreen(
                                onLoginSuccess = {
                                    sharedPrefs.edit().putBoolean("flutter.auth_logged_in", true).apply()
                                    navController.navigate("dashboard") {
                                        popUpTo("login") { inclusive = true }
                                    }
                                }
                            )
                        }
                        composable("dashboard") {
                            DashboardScreen(
                                onChannelSelected = { channel ->
                                    if (channel.url.isNullOrEmpty()) return@DashboardScreen
                                    val safeName    = if (channel.name.isNullOrEmpty()) "Unknown" else channel.name
                                    val safeUrl     = channel.url
                                    val safeLogo    = if (channel.logo.isNullOrEmpty()) "EMPTY_LOGO" else channel.logo

                                    val encodedName = b64Encode(safeName)
                                    val encodedUrl  = b64Encode(safeUrl)
                                    val encodedLogo = b64Encode(safeLogo)

                                    val route = if (channel.isMovie()) "movie_detail" else "player"
                                    try {
                                        navController.navigate("$route/$encodedName/$encodedUrl/$encodedLogo")
                                    } catch (e: Exception) {
                                        android.util.Log.e("TvMainActivity", "Navigation failed: ${e.message}")
                                    }
                                },
                                onLogout = {
                                    sharedPrefs.edit().putBoolean("flutter.auth_logged_in", false).apply()
                                    navController.navigate("login") {
                                        popUpTo("dashboard") { inclusive = true }
                                    }
                                }
                            )
                        }
                        composable("player/{channelName}/{streamUrl}/{logoUrl}") { backStackEntry ->
                            val rawName     = try { b64Decode(backStackEntry.arguments?.getString("channelName") ?: "") } catch (_: Exception) { "Unknown" }
                            val rawUrl      = try { b64Decode(backStackEntry.arguments?.getString("streamUrl") ?: "") } catch (_: Exception) { "" }
                            val rawLogoUrl  = try { b64Decode(backStackEntry.arguments?.getString("logoUrl") ?: "") } catch (_: Exception) { "" }

                            val channelName = if (rawName == "Unknown") "" else rawName
                            val streamUrl   = if (rawUrl == "EMPTY_URL") "" else rawUrl
                            val logoUrl     = if (rawLogoUrl == "EMPTY_LOGO") null else rawLogoUrl

                            PlayerScreen(
                                channelName = channelName,
                                streamUrl = streamUrl,
                                logoUrl = logoUrl,
                                onBack = { navController.popBackStack() }
                            )
                        }
                        composable("vod_player/{channelName}/{streamUrl}/{logoUrl}") { backStackEntry ->
                            val rawName     = try { b64Decode(backStackEntry.arguments?.getString("channelName") ?: "") } catch (_: Exception) { "Unknown" }
                            val rawUrl      = try { b64Decode(backStackEntry.arguments?.getString("streamUrl") ?: "") } catch (_: Exception) { "" }
                            val rawLogoUrl  = try { b64Decode(backStackEntry.arguments?.getString("logoUrl") ?: "") } catch (_: Exception) { "" }

                            val channelName = if (rawName == "Unknown") "" else rawName
                            val streamUrl   = if (rawUrl == "EMPTY_URL") "" else rawUrl
                            val logoUrl     = if (rawLogoUrl == "EMPTY_LOGO") null else rawLogoUrl

                            VodPlayerScreen(
                                channelName = channelName,
                                streamUrl = streamUrl,
                                logoUrl = logoUrl,
                                onBack = { navController.popBackStack() }
                            )
                        }
                        composable("movie_detail/{channelName}/{streamUrl}/{logoUrl}") { backStackEntry ->
                            val rawName     = try { b64Decode(backStackEntry.arguments?.getString("channelName") ?: "") } catch (_: Exception) { "Unknown" }
                            val rawUrl      = try { b64Decode(backStackEntry.arguments?.getString("streamUrl") ?: "") } catch (_: Exception) { "" }
                            val rawLogoUrl  = try { b64Decode(backStackEntry.arguments?.getString("logoUrl") ?: "") } catch (_: Exception) { "" }

                            val channelName = if (rawName == "Unknown") "" else rawName
                            val streamUrl   = if (rawUrl == "EMPTY_URL") "" else rawUrl
                            val logoUrl     = if (rawLogoUrl == "EMPTY_LOGO") null else rawLogoUrl
                            
                            val encodedName = backStackEntry.arguments?.getString("channelName") ?: ""
                            val encodedUrl = backStackEntry.arguments?.getString("streamUrl") ?: ""
                            val encodedLogo = backStackEntry.arguments?.getString("logoUrl") ?: ""

                            MovieDetailScreen(
                                channelName = channelName,
                                streamUrl = streamUrl,
                                logoUrl = logoUrl,
                                onBack = { navController.popBackStack() },
                                onPlay = {
                                    navController.navigate("vod_player/$encodedName/$encodedUrl/$encodedLogo")
                                }
                            )
                        }
                    }
                }
            }
        }
    }
}
