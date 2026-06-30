package com.kobani4k.app.tv.data

import kotlinx.coroutines.*
import okhttp3.Call
import okhttp3.Callback
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import org.json.JSONObject
import java.io.IOException
import java.time.ZoneOffset
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter
import java.util.UUID

object TvViewerService {
    private val client = OkHttpClient()
    private const val BASE_URL = "https://api.optictv.cloud/api/collections/liveViewers/records"
    private val JSON = "application/json; charset=utf-8".toMediaType()
    
    private var deviceId: String? = null
    private var currentRecordId: String? = null
    private var heartbeatJob: Job? = null
    private val coroutineScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    private fun getDeviceId(): String {
        if (deviceId == null) {
            deviceId = "TV_" + UUID.randomUUID().toString().substring(0, 8)
        }
        return deviceId!!
    }

    private fun sanitizeKey(url: String): String {
        return url.replace(Regex("[\\.#\\$\\[\\]]"), "_")
            .replace(Regex("[/:]"), "_")
    }

    fun joinChannel(channelUrl: String) {
        val sanitizedKey = sanitizeKey(channelUrl)
        if (sanitizedKey.isEmpty()) return

        coroutineScope.launch {
            leaveChannelSync() // Ensure we leave old channel

            val devId = getDeviceId()
            val now = ZonedDateTime.now(ZoneOffset.UTC).format(DateTimeFormatter.ISO_INSTANT)
            
            // Check if record exists
            val request = Request.Builder()
                .url("$BASE_URL?filter=(deviceId='$devId')")
                .build()

            try {
                val response = client.newCall(request).execute()
                val bodyString = response.body?.string() ?: ""
                val json = JSONObject(bodyString)
                val items = json.optJSONArray("items")

                val payload = JSONObject().apply {
                    put("channelKey", sanitizedKey)
                    put("deviceId", devId)
                    put("lastSeen", now)
                }.toString().toRequestBody(JSON)

                if (items != null && items.length() > 0) {
                    val existingId = items.getJSONObject(0).getString("id")
                    currentRecordId = existingId
                    // Update existing
                    val updateReq = Request.Builder()
                        .url("$BASE_URL/$existingId")
                        .patch(payload)
                        .build()
                    client.newCall(updateReq).execute().close()
                } else {
                    // Create new
                    val createReq = Request.Builder()
                        .url(BASE_URL)
                        .post(payload)
                        .build()
                    val createRes = client.newCall(createReq).execute()
                    val createBody = createRes.body?.string() ?: ""
                    currentRecordId = JSONObject(createBody).optString("id")
                }
                
                startHeartbeat()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    fun leaveChannel() {
        coroutineScope.launch {
            leaveChannelSync()
        }
    }

    private fun leaveChannelSync() {
        heartbeatJob?.cancel()
        heartbeatJob = null

        val recordId = currentRecordId
        if (recordId != null) {
            try {
                val req = Request.Builder()
                    .url("$BASE_URL/$recordId")
                    .delete()
                    .build()
                client.newCall(req).execute().close()
            } catch (e: Exception) {
                e.printStackTrace()
            }
            currentRecordId = null
        }
    }

    private fun startHeartbeat() {
        heartbeatJob?.cancel()
        heartbeatJob = coroutineScope.launch {
            while (isActive) {
                delay(10000) // 10 seconds
                val recordId = currentRecordId ?: continue
                val now = ZonedDateTime.now(ZoneOffset.UTC).format(DateTimeFormatter.ISO_INSTANT)
                val payload = JSONObject().apply {
                    put("lastSeen", now)
                }.toString().toRequestBody(JSON)

                try {
                    val req = Request.Builder()
                        .url("$BASE_URL/$recordId")
                        .patch(payload)
                        .build()
                    client.newCall(req).execute().close()
                } catch (e: Exception) {
                    // Ignore transient network errors
                }
            }
        }
    }
}
