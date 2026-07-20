package com.kobani4k.app

import android.app.UiModeManager
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import androidx.media3.common.util.UnstableApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import android.view.WindowManager
import io.flutter.plugin.common.MethodChannel
import com.kobani4k.player.NativeExoPlayer
import java.io.File

@UnstableApi
class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.optic.iptv/device"
    private val PLAYER_CHANNEL = "com.kobani4k/native_player"

    private var nativeExoPlayer: NativeExoPlayer? = null

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        GlobalProxyBypass.apply() // Enforce proxy bypass for ExoPlayer and native HTTP
        if (isTelevisionDevice()) {
            val intent = android.content.Intent(this, com.kobani4k.app.tv.TvMainActivity::class.java)
            startActivity(intent)
            finish()
        }
    }

    /// Many STBs / TV boxes still report [Configuration.UI_MODE_TYPE_NORMAL] while exposing
    /// leanback or television system features. Relying only on [UiModeManager] keeps Flutter on
    /// a [TextField], and the TV IME often covers the whole screen with a grey layer.
    private fun isTelevisionDevice(): Boolean {
        val uiModeManager = getSystemService(UI_MODE_SERVICE) as UiModeManager
        if (uiModeManager.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION) {
            return true
        }
        val pm = packageManager
        if (pm.hasSystemFeature(PackageManager.FEATURE_TELEVISION)) {
            return true
        }
        if (pm.hasSystemFeature(PackageManager.FEATURE_LEANBACK)) {
            return true
        }
        return false
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    /**
     * Native OS-level VPN and Proxy detection.
     * Uses ConnectivityManager + NetworkCapabilities — the most reliable method on Android.
     * Also checks system proxy properties which packet sniffers like HttpCanary set.
     */
    fun isVpnOrProxyActive(): Boolean {
        // 1. Check for VPN transport via ConnectivityManager (works on Android 8+)
        val cm = getSystemService(CONNECTIVITY_SERVICE) as? ConnectivityManager ?: return false
        val activeNetwork = cm.activeNetwork
        if (activeNetwork != null) {
            val caps = cm.getNetworkCapabilities(activeNetwork)
            if (caps != null && caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) {
                return true
            }
        }
        // 2. Check for a system-level HTTP proxy (set by apps like HttpCanary, PCAPdroid)
        val proxyHost = System.getProperty("http.proxyHost")
        val proxyPort = System.getProperty("http.proxyPort")
        if (!proxyHost.isNullOrEmpty() && !proxyPort.isNullOrEmpty()) {
            return true
        }
        // 3. Check for HTTPS proxy as well
        val httpsProxy = System.getProperty("https.proxyHost")
        if (!httpsProxy.isNullOrEmpty()) {
            return true
        }
        return false
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Device info channel (existing)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "isTelevision") {
                result.success(isTelevisionDevice())
            } else if (call.method == "isVpnOrProxyActive") {
                result.success(isVpnOrProxyActive())
            } else if (call.method == "isPackageInstalled") {
                val packageName = call.argument<String>("packageName")
                if (packageName != null) {
                    result.success(isPackageInstalled(packageName))
                } else {
                    result.error("INVALID_ARGUMENT", "packageName is required", null)
                }
            } else if (call.method == "installApk") {
                val apkPath = call.argument<String>("apkPath")
                if (apkPath != null) {
                    try {
                        val file = File(apkPath)
                        val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(uri, "application/vnd.android.package-archive")
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INSTALL_FAILED", e.message, null)
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "apkPath is required", null)
                }
            } else {
                result.notImplemented()
            }
        }

        // Native ExoPlayer channel — Texture-based rendering
        val playerChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PLAYER_CHANNEL)
        val player = NativeExoPlayer(
            context = this,
            methodChannel = playerChannel,
            textureRegistry = flutterEngine.renderer,
        )
        nativeExoPlayer = player

        // Route player MethodChannel calls to the native engine
        playerChannel.setMethodCallHandler { call, result ->
            player.handleMethodCall(call, result)
        }

        // Register the PlatformView factory for HDR-capable SurfaceView rendering
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "com.kobani4k/native_player_view",
            com.kobani4k.player.NativeExoPlayerPlatformViewFactory(player)
        )
    }

    override fun onDestroy() {
        nativeExoPlayer?.dispose()
        nativeExoPlayer = null
        super.onDestroy()
    }
}
