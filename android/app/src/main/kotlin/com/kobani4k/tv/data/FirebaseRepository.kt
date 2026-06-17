package com.kobani4k.tv.data

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

    /**
     * Verifies if a given 6-digit code exists in `sync/global/loginCodes`.
     * Returns true if successful, false otherwise.
     */
    suspend fun verifyLoginCode(code: String): Boolean {
        return try {
            val snapshot = db.child("sync/global/loginCodes").child(code).get().await()
            snapshot.exists()
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    /**
     * Fetches the actual channels from Firebase Realtime Database.
     * Maps them to TvChannel structures.
     */
    suspend fun getChannels(): List<TvChannel> {
        return try {
            val snapshot = db.child("sync/global/managedPlaylist").get().await()
            if (snapshot.exists()) {
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
                
                // Sort by name case-insensitive by default
                channels.sortBy { it.name.lowercase() }
                
                channels.ifEmpty { defaultMockChannels() }
            } else {
                defaultMockChannels()
            }
        } catch (e: Exception) {
            e.printStackTrace()
            defaultMockChannels()
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
