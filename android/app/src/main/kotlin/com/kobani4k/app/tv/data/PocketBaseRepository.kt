package com.kobani4k.app.tv.data

import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlinx.coroutines.Dispatchers
import okhttp3.Call
import okhttp3.Callback
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.io.IOException
import java.time.Instant
import java.time.OffsetDateTime
import kotlin.coroutines.resume

data class TvChannel(
    val name: String = "",
    val url: String = "",
    val url2: String? = null,
    val url2Name: String? = null,
    val url3: String? = null,
    val url3Name: String? = null,
    val group: String = "General",
    val logo: String? = null,
    val type: String = "live",
    val order: Int = 999999,
    val drmScheme: String? = null,
    val drmLicense: String? = null,
    val userAgent: String? = null,
    val referer: String? = null
) {
    fun isMovie(): Boolean {
        if (type == "movie") return true
        if (type == "live") return false

        val g = group.lowercase()
        val n = name.lowercase()
        
        if (g.contains("live tv") || g == "live" || n.contains(" (live)")) return false
        if (g.contains("tv") && !g.contains("movie") && !g.contains("cinema")) return false

        if (g == "movies" || g == "vod" || g == "cinema" || g == "films") return true

        val movieKeywords = listOf("vod", "box office", "uhd", "4k", "action", "comedy", "horror", "drama", "thriller", "animation", "documentary")
        val isTaggedName = movieKeywords.any { n.contains(it) }
        
        return isTaggedName || g.contains("movie") || g.contains("film")
    }

    fun isSport(): Boolean {
        if (type == "sport") return true
        
        val g = group.lowercase()
        val n = name.lowercase()
        
        val sportKeywords = listOf("sport", "bein", "ad sports", "ssc", "eurospot", "espn", "arena", "bt sport", "sky sport", "alkass", "starzplay sports")
        return sportKeywords.any { g.contains(it) } || sportKeywords.any { n.contains(it) }
    }
}

// Bug 2 fix: added 'icon' field with default empty string.
// Previous code passed icon URL as 3rd positional arg but TvChannelGroup
// only had (key, name, order: Int) — caused a type mismatch compile crash.
data class TvChannelGroup(
    val key: String,
    val name: String,
    val order: Int,
    val icon: String = ""
)

data class AppUpdateInfo(
    val isActive: Boolean,
    val apkUrl: String,
    val versionCode: Int,
    val versionName: String,
    val releaseNotes: String
)

class PocketBaseRepository {
    private val client = OkHttpClient()
    private val baseUrl = "https://api.optictv.cloud/api/collections"

    companion object {
        private val sessionId = java.util.UUID.randomUUID().toString()
        private var userId: String? = null
    }

    fun postAnalyticsEvent(eventType: String, channelId: String = "", channelName: String = "", context: android.content.Context? = null) {
        if (userId == null && context != null) {
            userId = android.provider.Settings.Secure.getString(context.contentResolver, android.provider.Settings.Secure.ANDROID_ID)
            if (userId == null) {
                userId = java.util.UUID.randomUUID().toString()
            }
        }
        val uid = userId ?: "unknown_tv_user"
        
        val json = JSONObject()
        json.put("user_id", uid)
        json.put("session_id", sessionId)
        json.put("event_type", eventType)
        json.put("channel_id", channelId)
        json.put("channel_name", channelName)

        val mediaType = "application/json; charset=utf-8".toMediaType()
        val body = json.toString().toRequestBody(mediaType)
        val request = Request.Builder()
            .url("$baseUrl/analytics_events/records")
            .post(body)
            .build()
            
        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {}
            override fun onResponse(call: Call, response: Response) { response.close() }
        })
    }

    suspend fun checkAppUpdate(): AppUpdateInfo? = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url("$baseUrl/updateManager/records/globalupdate123")
                .build()
            val response = client.newCall(request).execute()
            if (!response.isSuccessful) return@withContext null
            val bodyString = response.body?.string() ?: ""
            val json = JSONObject(bodyString)
            
            return@withContext AppUpdateInfo(
                isActive = json.optBoolean("isActive", false),
                apkUrl = json.optString("apkUrl", ""),
                versionCode = 999999,
                versionName = "New Update",
                releaseNotes = "A new update is available."
            )
        } catch (e: Exception) {
            e.printStackTrace()
            return@withContext null
        }
    }

    suspend fun verifyLoginCode(code: String): String = suspendCancellableCoroutine { cont ->
        val normalizedInput = code.replace("\\s+".toRegex(), "").lowercase()
        if (normalizedInput.isEmpty()) {
            if (cont.isActive) cont.resume("INVALID")
            return@suspendCancellableCoroutine
        }

        val request = Request.Builder()
            .url("$baseUrl/loginCodes/records?filter=(code='$normalizedInput')")
            .build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                if (cont.isActive) cont.resume("ERROR")
            }

            override fun onResponse(call: Call, response: Response) {
                if (!response.isSuccessful) {
                    if (cont.isActive) cont.resume("ERROR")
                    return
                }

                try {
                    val bodyString = response.body?.string() ?: ""
                    val json = JSONObject(bodyString)
                    val items = json.optJSONArray("items")
                    
                    if (items != null && items.length() > 0) {
                        for (i in 0 until items.length()) {
                            val item = items.getJSONObject(i)
                            val active = item.optBoolean("active", true)
                            if (!active) continue
                            
                            val expiresAtRaw = item.optString("expiresAt", "")
                            if (expiresAtRaw.isNotEmpty()) {
                                try {
                                    val expireTime = try {
                                        OffsetDateTime.parse(expiresAtRaw.replace(" ", "T")).toInstant()
                                    } catch (e: Exception) {
                                        Instant.parse(expiresAtRaw.replace(" ", "T") + "Z")
                                    }
                                    val now = Instant.now()
                                    if (now.isAfter(expireTime)) {
                                        continue
                                    }
                                } catch (e: Exception) {
                                    e.printStackTrace()
                                }
                            }
                            if (cont.isActive) {
                                cont.resume("SUCCESS")
                                return
                            }
                        }
                    }
                    if (cont.isActive) cont.resume("INVALID")
                } catch (e: Exception) {
                    e.printStackTrace()
                    if (cont.isActive) cont.resume("ERROR")
                }
            }
        })
    }

    // Fetch ALL pages instead of just the first 500
    suspend fun getChannels(): List<TvChannel>? = withContext(Dispatchers.IO) {
        val channels = mutableListOf<TvChannel>()
        var page = 1
        var totalPages = 1
        
        try {
            while (page <= totalPages) {
                val request = Request.Builder()
                    .url("$baseUrl/managedPlaylist/records?perPage=500&page=$page")
                    .build()
                
                val response = client.newCall(request).execute()
                if (!response.isSuccessful) {
                    if (page == 1) return@withContext null else break
                }
                
                val bodyString = response.body?.string() ?: ""
                val json = JSONObject(bodyString)
                
                totalPages = json.optInt("totalPages", 1)
                val items = json.optJSONArray("items") ?: break
                
                for (i in 0 until items.length()) {
                    val child = items.getJSONObject(i)
                    val name = child.optString("name", "Unknown")
                    val url = child.optString("url", "")
                    val url2Raw = child.optString("url2", null)
                    val url2NameRaw = child.optString("url2Name", null)
                    val url3Raw = child.optString("url3", null)
                    val url3NameRaw = child.optString("url3Name", null)
                    
                    val url2 = if (url2Raw == "null" || url2Raw.isNullOrEmpty()) null else url2Raw
                    val url2Name = if (url2NameRaw == "null" || url2NameRaw.isNullOrEmpty()) null else url2NameRaw
                    val url3 = if (url3Raw == "null" || url3Raw.isNullOrEmpty()) null else url3Raw
                    val url3Name = if (url3NameRaw == "null" || url3NameRaw.isNullOrEmpty()) null else url3NameRaw
                    
                    var group = child.optString("group", null)
                    if (group == null || group == "null" || group.isEmpty()) {
                        group = child.optString("category", "General")
                    }
                    
                    var logo: String? = child.optString("logo", null)
                    if (logo == null || logo == "null" || logo.isEmpty()) {
                        logo = child.optString("icon_url", null)
                    }
                    if (logo == "null") logo = null
                    
                    val type = child.optString("type", "live")
                    val order = child.optInt("order", 999999)
                    
                    val drmSchemeRaw = child.optString("drmScheme", null)
                    val drmScheme = if (drmSchemeRaw == "null" || drmSchemeRaw.isNullOrEmpty()) null else drmSchemeRaw
                    val drmLicenseRaw = child.optString("drmLicense", null)
                    val drmLicense = if (drmLicenseRaw == "null" || drmLicenseRaw.isNullOrEmpty()) null else drmLicenseRaw
                    
                    val userAgentRaw = child.optString("userAgent", null)
                    val userAgent = if (userAgentRaw == "null" || userAgentRaw.isNullOrEmpty()) null else userAgentRaw
                    val refererRaw = child.optString("referer", null)
                    val referer = if (refererRaw == "null" || refererRaw.isNullOrEmpty()) null else refererRaw
                    
                    if (url.isNotEmpty()) {
                        channels.add(TvChannel(name, url, url2, url2Name, url3, url3Name, group, logo, type, order, drmScheme, drmLicense, userAgent, referer))
                    }
                }
                page++
            }
            
            channels.sortBy { it.order }
            return@withContext channels.ifEmpty { null }
        } catch (e: Exception) {
            e.printStackTrace()
            return@withContext null
        }
    }

    suspend fun getGroups(): List<TvChannelGroup> = withContext(Dispatchers.IO) {
        val groups = mutableListOf<TvChannelGroup>()
        var page = 1
        var totalPages = 1
        
        try {
            while (page <= totalPages) {
                val request = Request.Builder()
                    .url("$baseUrl/channelGroups/records?perPage=500&page=$page")
                    .build()
                    
                val response = client.newCall(request).execute()
                if (!response.isSuccessful) {
                    if (page == 1) return@withContext emptyList() else break
                }
                
                val bodyString = response.body?.string() ?: ""
                val json = JSONObject(bodyString)
                
                totalPages = json.optInt("totalPages", 1)
                val items = json.optJSONArray("items") ?: break
                
                for (i in 0 until items.length()) {
                    val child = items.getJSONObject(i)
                    val name = child.optString("name", "Unknown")
                    val order = child.optInt("order", 999)
                    val icon = child.optString("icon_url", "")
                    
                    // Bug 2 fix: use named parameters to avoid positional type confusion
                    groups.add(TvChannelGroup(key = name, name = name, order = order, icon = icon))
                }
                page++
            }
            
            groups.sortBy { it.order }
            // Always return "All" and "Favorites" first
            val predefined = listOf(
                // Bug 2 fix: use named parameters, icon is the 4th param not 3rd
                TvChannelGroup(key = "All", name = "All", order = -2, icon = ""),
                TvChannelGroup(key = "Favorites", name = "Favorites", order = -1, icon = "")
            )
            return@withContext predefined + groups
        } catch (e: Exception) {
            e.printStackTrace()
            return@withContext emptyList()
        }
    }
}
