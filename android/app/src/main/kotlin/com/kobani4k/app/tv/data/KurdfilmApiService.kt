package com.kobani4k.app.tv.data

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONObject
import org.json.JSONArray
import java.net.URLDecoder

data class KurdfilmMovie(
    val id: Int,
    val title: String,
    val image: String,
    val rating: Double,
    val releaseDate: String,
    val type: String
)

data class KurdfilmServer(
    val name: String,
    val url: String
)

data class KurdfilmDetail(
    val id: Int,
    val title: String,
    val description: String,
    val director: String,
    val cast: List<String>,
    val duration: String,
    val rating: Double,
    val releaseDate: String,
    val servers: List<KurdfilmServer>,
    val embedUrl: String?
)

class KurdfilmApiService {
    private val client = OkHttpClient()
    private val baseUrl = "https://app.kurdfilm.krd/api"

    suspend fun getLatestMovies(page: Int = 1): List<KurdfilmMovie> = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url("$baseUrl/titles?kind=movie&sort=newest&per_page=100&page=$page")
                .build()

            val response = client.newCall(request).execute()
            if (!response.isSuccessful) return@withContext emptyList()
            
            val json = JSONObject(response.body?.string() ?: "")
            val data = json.optJSONArray("data") ?: return@withContext emptyList()
            
            val movies = mutableListOf<KurdfilmMovie>()
            for (i in 0 until data.length()) {
                val item = data.getJSONObject(i)
                movies.add(
                    KurdfilmMovie(
                        id = item.optInt("id"),
                        title = item.optString("title"),
                        image = item.optString("image"),
                        rating = item.optDouble("rating", 0.0),
                        releaseDate = item.optString("releasedate"),
                        type = item.optString("type")
                    )
                )
            }
            movies
        } catch (e: Exception) {
            e.printStackTrace()
            emptyList()
        }
    }

    suspend fun getMovieDetails(movieId: Int): KurdfilmDetail? = withContext(Dispatchers.IO) {
        try {
            // Check both endpoints to be safe (like the HTML player does)
            val endpoints = listOf(
                "$baseUrl/movies/$movieId",
                "$baseUrl/titles/$movieId"
            )
            
            var detailJson: JSONObject? = null
            for (endpoint in endpoints) {
                val request = Request.Builder().url(endpoint).build()
                val response = client.newCall(request).execute()
                if (response.isSuccessful) {
                    val body = response.body?.string() ?: ""
                    val root = JSONObject(body)
                    detailJson = root.optJSONObject("data") ?: root
                    break
                }
            }
            
            if (detailJson == null) return@withContext null
            
            val castArray = detailJson.optJSONArray("cast") ?: JSONArray()
            val castList = mutableListOf<String>()
            for (i in 0 until castArray.length()) {
                castList.add(castArray.getString(i))
            }
            
            val serversArray = detailJson.optJSONArray("servers") ?: JSONArray()
            val serversList = mutableListOf<KurdfilmServer>()
            for (i in 0 until serversArray.length()) {
                val serverObj = serversArray.getJSONObject(i)
                serversList.add(
                    KurdfilmServer(
                        name = serverObj.optString("name"),
                        url = serverObj.optString("url")
                    )
                )
            }
            
            KurdfilmDetail(
                id = detailJson.optInt("id", movieId),
                title = detailJson.optString("title"),
                description = detailJson.optString("description"),
                director = detailJson.optString("director"),
                cast = castList,
                duration = detailJson.optString("duration"),
                rating = detailJson.optDouble("rating", 0.0),
                releaseDate = detailJson.optString("releasedate"),
                servers = serversList,
                embedUrl = detailJson.optString("embed_url", null).takeIf { it.isNotEmpty() } ?: detailJson.optString("video_url", null)
            )
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    // Helper to extract the real video URL from kurdfilm proxy servers
    fun extractVideoUrl(serverUrl: String): String {
        if (serverUrl.contains("kurdfilm.krd/play-kf")) {
            try {
                val uri = android.net.Uri.parse(serverUrl)
                val urlParam = uri.getQueryParameter("url")
                if (urlParam != null) {
                    return URLDecoder.decode(urlParam, "UTF-8")
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        return serverUrl
    }
}
