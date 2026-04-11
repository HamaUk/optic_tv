package com.optic.iptv

import android.app.UiModeManager
import android.content.pm.PackageManager
import android.content.res.Configuration
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.optic.iptv/device"

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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "isTelevision") {
                result.success(isTelevisionDevice())
            } else {
                result.notImplemented()
            }
        }
    }
}

