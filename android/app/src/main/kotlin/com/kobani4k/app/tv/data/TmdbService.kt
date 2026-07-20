package com.kobani4k.app.tv.data

import kotlinx.coroutines.suspendCancellableCoroutine
import okhttp3.Call
import okhttp3.Callback
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import org.json.JSONObject
import java.io.IOException
import kotlin.coroutines.resume

data class TmdbMovie(
    val id: Int,
    val title: String,
    val overview: String,
    val posterUrl: String?,
    val backdropUrl: String?,
    val rating: Double,
    val releaseDate: String?
)

class TmdbService {
    private val client = OkHttpClient()
    private val baseUrl = "https://api.themoviedb.org/3"
    private val imageBaseUrl = "https://image.tmdb.org/t/p/w500"
    private val backdropBaseUrl = "https://image.tmdb.org/t/p/w1280"
    private val readAccessToken = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI4MGFiN2UxNzgxMDkzMGEwM2JjYWViYTZjOThhYTY1NiIsIm5iZiI6MTc3NTkzNTI1NS42ODksInN1YiI6IjY5ZGE5ZjE3OTA4MTdjYjk3MzAyNmRjNSIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.DEgqhdxcwvDTo_a0gL6514ZdZX7Rt_3rB7zbRHDsiQM"

    // Simple in-memory cache to avoid repeated network calls for the same movie title
    private val memoryCache = mutableMapOf<String, TmdbMovie?>()

    suspend fun findMovie(title: String): TmdbMovie? {
        if (memoryCache.containsKey(title)) {
            return memoryCache[title]
        }

        // Clean title
        var cleanTitle = title
            .replace(Regex("\\.(mp4|mkv|avi|ts|mov|m3u8)", RegexOption.IGNORE_CASE), "")
            .replace(Regex("\\[.*?]"), "")
            .replace(Regex("\\(.*?\\)"), "")
            .replace(Regex("(1080p|720p|4k|uhd|bluray|h264|h265|web-dl|x264|x265)", RegexOption.IGNORE_CASE), " ")
            .replace("_", " ")
            .replace(".", " ")

        // Extract year
        var year: String? = null
        val yearMatch = Regex("(\\d{4})").find(cleanTitle)
        if (yearMatch != null) {
            year = yearMatch.groupValues[1]
            cleanTitle = cleanTitle.replace(year, "").replace(" - ", " ")
        }

        cleanTitle = cleanTitle.replace(Regex("\\s+"), " ").trim()
        
        if (cleanTitle.isEmpty()) return null

        var url = "$baseUrl/search/movie?query=$cleanTitle&language=ckb"
        if (year != null) {
            url += "&primary_release_year=$year"
        }

        val request = Request.Builder()
            .url(url)
            .addHeader("Authorization", "Bearer $readAccessToken")
            .addHeader("accept", "application/json")
            .build()

        return suspendCancellableCoroutine { cont ->
            client.newCall(request).enqueue(object : Callback {
                override fun onFailure(call: Call, e: IOException) {
                    if (cont.isActive) cont.resume(null)
                }

                override fun onResponse(call: Call, response: Response) {
                    if (!response.isSuccessful) {
                        if (cont.isActive) cont.resume(null)
                        return
                    }

                    try {
                        val bodyString = response.body?.string() ?: ""
                        val json = JSONObject(bodyString)
                        val results = json.optJSONArray("results")

                        if (results != null && results.length() > 0) {
                            // Take the first best match
                            val best = results.getJSONObject(0)
                            
                            val posterPath = best.optString("poster_path", "")
                            val backdropPath = best.optString("backdrop_path", "")
                            
                            val movie = TmdbMovie(
                                id = best.optInt("id", 0),
                                title = best.optString("title", ""),
                                overview = best.optString("overview", "No description available."),
                                posterUrl = if (posterPath.isNotEmpty() && posterPath != "null") "$imageBaseUrl$posterPath" else null,
                                backdropUrl = if (backdropPath.isNotEmpty() && backdropPath != "null") "$backdropBaseUrl$backdropPath" else null,
                                rating = best.optDouble("vote_average", 0.0),
                                releaseDate = best.optString("release_date", "")
                            )
                            
                            memoryCache[title] = movie // cache original title
                            if (cont.isActive) cont.resume(movie)
                        } else {
                            memoryCache[title] = null
                            if (cont.isActive) cont.resume(null)
                        }
                    } catch (e: Exception) {
                        e.printStackTrace()
                        if (cont.isActive) cont.resume(null)
                    }
                }
            })
        }
    }
}
