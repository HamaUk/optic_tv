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
    val group: String = "General",
    val logo: String? = null,
    val type: String = "live",
    val order: Int = 999999,
    val drmScheme: String? = null,
    val drmLicense: String? = null
)

data class TvChannelGroup(
    val key: String,
    val name: String,
    val order: Int
)

class PocketBaseRepository {
    private val client = OkHttpClient()
    private val baseUrl = "http://64.225.76.43/api/collections"

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
                                channels.add(TvChannel(name, url, group, logo, type, order, drmScheme, drmLicense))
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
