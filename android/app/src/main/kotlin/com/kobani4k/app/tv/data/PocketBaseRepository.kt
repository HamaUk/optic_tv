package com.kobani4k.app.tv.data

import kotlinx.coroutines.suspendCancellableCoroutine
import okhttp3.Call
import okhttp3.Callback
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
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
    val drmLicense: String? = null
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

data class TvChannelGroup(
    val key: String,
    val name: String,
    val order: Int
)

class PocketBaseRepository {
    private val client = OkHttpClient()
    private val baseUrl = "https://api.optictv.cloud/api/collections"

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

    suspend fun getChannels(): List<TvChannel> = suspendCancellableCoroutine { cont ->
        val request = Request.Builder()
            .url("$baseUrl/managedPlaylist/records?perPage=500")
            .build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                if (cont.isActive) cont.resume(defaultMockChannels())
            }

            override fun onResponse(call: Call, response: Response) {
                if (!response.isSuccessful) {
                    if (cont.isActive) cont.resume(defaultMockChannels())
                    return
                }

                try {
                    val bodyString = response.body?.string() ?: ""
                    val json = JSONObject(bodyString)
                    val items = json.optJSONArray("items")
                    
                    val channels = mutableListOf<TvChannel>()
                    if (items != null) {
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
                            
                            if (url.isNotEmpty()) {
                                channels.add(TvChannel(name, url, url2, url2Name, url3, url3Name, group, logo, type, order, drmScheme, drmLicense))
                            }
                        }
                    }
                    
                    channels.sortBy { it.order }
                    
                    if (channels.isEmpty()) {
                        if (cont.isActive) cont.resume(defaultMockChannels())
                    } else {
                        if (cont.isActive) cont.resume(channels)
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                    if (cont.isActive) cont.resume(defaultMockChannels())
                }
            }
        })
    }

    private fun defaultMockChannels(): List<TvChannel> {
        return List(20) { index ->
            val isEven = index % 2 == 0
            TvChannel(
                name = "Kobani Channel ${index + 1}",
                url = "https://storage.googleapis.com/exoplayer-test-media-0/BigBuckBunny_320x180.mp4",
                group = if (isEven) "LIVE" else "MOVIES",
                logo = null,
                type = if (isEven) "live" else "movie",
                order = index
            )
        }
    }

    suspend fun getGroups(): List<TvChannelGroup> = suspendCancellableCoroutine { cont ->
        val request = Request.Builder()
            .url("$baseUrl/channelGroups/records?perPage=500")
            .build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                if (cont.isActive) cont.resume(emptyList())
            }

            override fun onResponse(call: Call, response: Response) {
                if (!response.isSuccessful) {
                    if (cont.isActive) cont.resume(emptyList())
                    return
                }

                try {
                    val bodyString = response.body?.string() ?: ""
                    val json = JSONObject(bodyString)
                    val items = json.optJSONArray("items")
                    
                    val groups = mutableListOf<TvChannelGroup>()
                    if (items != null) {
                        for (i in 0 until items.length()) {
                            val child = items.getJSONObject(i)
                            val id = child.optString("id", "")
                            val name = child.optString("name", "Unknown")
                            val order = child.optInt("order", 999999)
                            if (id.isNotEmpty()) {
                                groups.add(TvChannelGroup(id, name, order))
                            }
                        }
                    }
                    
                    groups.sortBy { it.order }
                    
                    if (cont.isActive) cont.resume(groups)
                } catch (e: Exception) {
                    e.printStackTrace()
                    if (cont.isActive) cont.resume(emptyList())
                }
            }
        })
    }
}
