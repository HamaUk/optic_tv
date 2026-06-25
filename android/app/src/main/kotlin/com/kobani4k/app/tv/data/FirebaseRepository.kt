package com.kobani4k.app.tv.data

import com.google.firebase.database.FirebaseDatabase
import kotlinx.coroutines.tasks.await

data class TvChannel(
    val name: String = "",
    val url: String = "",
    val group: String = "General",
    val logo: String? = null,
    val type: String = "live"
)

class FirebaseRepository {
    private val db = FirebaseDatabase.getInstance().reference

    suspend fun verifyLoginCode(code: String): String = kotlin.coroutines.suspendCoroutine { cont ->
        val normalizedInput = code.replace("\\s+".toRegex(), "").lowercase()
        if (normalizedInput.isEmpty()) {
            cont.resumeWith(Result.success("INVALID"))
            return@suspendCoroutine
        }

        var isResumed = false
        val handler = android.os.Handler(android.os.Looper.getMainLooper())
        
        val timeoutRunnable = Runnable {
            if (!isResumed) {
                isResumed = true
                cont.resumeWith(Result.success("ERROR"))
            }
        }
        handler.postDelayed(timeoutRunnable, 8000L)

        db.child("sync/global/loginCodes").get().addOnCompleteListener { task ->
            if (isResumed) return@addOnCompleteListener
            isResumed = true
            handler.removeCallbacks(timeoutRunnable)

            if (task.isSuccessful) {
                val snapshot = task.result
                if (snapshot != null && snapshot.exists()) {
                    for (child in snapshot.children) {
                        val activeValue = child.child("active").value
                        val active = activeValue != false

                        val rawCode = child.child("code").value ?: continue
                        var normalizedDbCode = rawCode.toString().trim()
                        if (normalizedDbCode.endsWith(".0")) {
                            normalizedDbCode = normalizedDbCode.substring(0, normalizedDbCode.length - 2)
                        }
                        normalizedDbCode = normalizedDbCode.replace("\\s+".toRegex(), "").lowercase()

                        if (!active || normalizedDbCode.isEmpty() || normalizedDbCode != normalizedInput) {
                            continue
                        }

                        val expiresAtRaw = child.child("expiresAt").value
                        if (expiresAtRaw != null) {
                            try {
                                val expiresAtStr = expiresAtRaw.toString()
                                val expireTime = try {
                                    java.time.OffsetDateTime.parse(expiresAtStr).toInstant()
                                } catch (e: Exception) {
                                    java.time.Instant.parse(expiresAtStr)
                                }
                                val now = java.time.Instant.now()
                                if (now.isAfter(expireTime)) {
                                    continue
                                }
                            } catch (e: Exception) {
                                e.printStackTrace()
                            }
                        }
                        cont.resumeWith(Result.success("SUCCESS"))
                        return@addOnCompleteListener
                    }
                }
                cont.resumeWith(Result.success("INVALID"))
            } else {
                task.exception?.printStackTrace()
                cont.resumeWith(Result.success("ERROR"))
            }
        }
    }

    /**
     * Fetches the actual channels from Firebase Realtime Database.
     * Maps them to TvChannel structures.
     */
    suspend fun getChannels(): List<TvChannel> = kotlin.coroutines.suspendCoroutine { cont ->
        var isResumed = false
        val handler = android.os.Handler(android.os.Looper.getMainLooper())
        
        val timeoutRunnable = Runnable {
            if (!isResumed) {
                isResumed = true
                cont.resumeWith(Result.success(defaultMockChannels()))
            }
        }
        handler.postDelayed(timeoutRunnable, 8000L)

        db.child("sync/global/managedPlaylist").get().addOnCompleteListener { task ->
            if (isResumed) return@addOnCompleteListener
            isResumed = true
            handler.removeCallbacks(timeoutRunnable)

            if (task.isSuccessful) {
                val snapshot = task.result
                if (snapshot != null && snapshot.exists()) {
                    val channels = mutableListOf<TvChannel>()
                    for (child in snapshot.children) {
                        val name = child.child("name").getValue(String::class.java) ?: "Unknown"
                        val url = child.child("url").getValue(String::class.java) ?: ""
                        
                        var group = child.child("group").getValue(String::class.java)
                        if (group == null) {
                             group = child.child("category").getValue(String::class.java)
                        }
                        if (group == null) {
                             group = "General"
                        }
                        
                        var logo = child.child("logo").getValue(String::class.java)
                        if (logo == null) {
                             logo = child.child("icon_url").getValue(String::class.java)
                        }
                        
                        val type = child.child("type").getValue(String::class.java) ?: "live"
                        
                        if (url.isNotEmpty()) {
                            channels.add(TvChannel(name, url, group, logo, type))
                        }
                    }
                    
                    channels.sortBy { it.name.lowercase() }
                    
                    if (channels.isEmpty()) {
                        cont.resumeWith(Result.success(defaultMockChannels()))
                    } else {
                        cont.resumeWith(Result.success(channels))
                    }
                } else {
                    cont.resumeWith(Result.success(defaultMockChannels()))
                }
            } else {
                task.exception?.printStackTrace()
                cont.resumeWith(Result.success(defaultMockChannels()))
            }
        }
    }

    private fun defaultMockChannels(): List<TvChannel> {
        return List(20) { index ->
            val isEven = index % 2 == 0
            TvChannel(
                name = "Kobani Channel ${index + 1}",
                url = "https://storage.googleapis.com/exoplayer-test-media-0/BigBuckBunny_320x180.mp4",
                group = if (isEven) "LIVE" else "MOVIES",
                logo = null,
                type = if (isEven) "live" else "movie"
            )
        }
    }
}
