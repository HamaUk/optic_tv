package com.kobani4k.tv.data

import com.google.firebase.database.FirebaseDatabase
import kotlinx.coroutines.tasks.await

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
     * In the Flutter app, playlists are parsed from an M3U file, but they might
     * also be retrieved via `sync/global/playlists`.
     * This is a mock structure based on typical IPTV Firebase setups.
     */
    suspend fun getChannels(): List<String> {
        return try {
            val snapshot = db.child("sync/global/playlists").get().await()
            if (snapshot.exists()) {
                val channels = mutableListOf<String>()
                for (child in snapshot.children) {
                    val name = child.child("name").getValue(String::class.java)
                    if (name != null) channels.add(name)
                }
                channels.ifEmpty { defaultMockChannels() }
            } else {
                defaultMockChannels()
            }
        } catch (e: Exception) {
            e.printStackTrace()
            defaultMockChannels()
        }
    }

    private fun defaultMockChannels(): List<String> {
        return List(20) { "Kobani Channel ${it + 1}" }
    }
}
