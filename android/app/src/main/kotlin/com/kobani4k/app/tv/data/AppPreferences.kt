package com.kobani4k.app.tv.data

import android.content.Context
import android.content.SharedPreferences

class AppPreferences(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

    var videoQuality: String
        get() = prefs.getString("settings.video_quality", "Auto") ?: "Auto"
        set(value) = prefs.edit().putString("settings.video_quality", value).apply()

    var audioLang: String
        get() = prefs.getString("settings.audio_lang", "Default") ?: "Default"
        set(value) = prefs.edit().putString("settings.audio_lang", value).apply()

    var subLang: String
        get() = prefs.getString("settings.sub_lang", "Off") ?: "Off"
        set(value) = prefs.edit().putString("settings.sub_lang", value).apply()

    var parentalEnabled: Boolean
        get() = prefs.getBoolean("settings.parental", false)
        set(value) = prefs.edit().putBoolean("settings.parental", value).apply()

    var autoPlayNext: Boolean
        get() = prefs.getBoolean("settings.autoplay", true)
        set(value) = prefs.edit().putBoolean("settings.autoplay", value).apply()

    var timeFormat24h: Boolean
        get() = prefs.getBoolean("settings.time24h", false)
        set(value) = prefs.edit().putBoolean("settings.time24h", value).apply()

    var theme: String
        get() = prefs.getString("settings.theme", "Dark") ?: "Dark"
        set(value) = prefs.edit().putString("settings.theme", value).apply()
        
    // Example for login data if needed
    var isLoggedIn: Boolean
        get() = prefs.getBoolean("is_logged_in", false)
        set(value) = prefs.edit().putBoolean("is_logged_in", value).apply()
        
    var favoriteChannels: Set<String>
        get() = prefs.getStringSet("settings.favorites", emptySet()) ?: emptySet()
        set(value) = prefs.edit().putStringSet("settings.favorites", value).apply()

    var appLanguage: String
        get() = prefs.getString("settings.app_lang", "Kurdish Sorani") ?: "Kurdish Sorani"
        set(value) = prefs.edit().putString("settings.app_lang", value).apply()

    fun clear() {
        prefs.edit().clear().apply()
    }
}
