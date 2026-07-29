package com.kobani4k.app.tv.data

import android.content.Context
import kotlinx.coroutines.suspendCancellableCoroutine
import okhttp3.Cache
import okhttp3.Call
import okhttp3.Callback
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import org.json.JSONObject
import java.io.File
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
    companion object {
        // Singleton HTTP client with 10MB on-disk cache (24h TTL).
        // After the first app launch all TMDB responses are served from disk —
        // zero network needed for subsequent sessions.
        @Volatile private var _client: OkHttpClient? = null

        fun getClient(context: Context): OkHttpClient {
            return _client ?: synchronized(this) {
                _client ?: OkHttpClient.Builder()
                    .cache(
                        Cache(
                            directory = File(context.cacheDir, "tmdb_cache"),
                            maxSize   = 10L * 1024 * 1024 // 10 MB
                        )
                    )
                    .addNetworkInterceptor { chain ->
                        // Force cache for 24 hours regardless of server headers.
                        val response = chain.proceed(chain.request())
                        response.newBuilder()
                            .header("Cache-Control", "public, max-age=86400")
                            .build()
                    }
                    .build()
                    .also { _client = it }
            }
        }

        // In-memory cache on top of the disk cache — instant for repeated
        // lookups within the same session (e.g., scrolling back to same card).
        private val memoryCache = mutableMapOf<String, TmdbMovie?>()
    }

    private lateinit var client: OkHttpClient
    private val baseUrl        = "https://api.themoviedb.org/3"
    private val imageBaseUrl   = "https://image.tmdb.org/t/p/w500"
    private val backdropBaseUrl= "https://image.tmdb.org/t/p/w1280"
    private val readAccessToken = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI4MGFiN2UxNzgxMDkzMGEwM2JjYWViYTZjOThhYTY1NiIsIm5iZiI6MTc3NTkzNTI1NS42ODksInN1YiI6IjY5ZGE5ZjE3OTA4MTdjYjk3MzAyNmRjNSIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.DEgqhdxcwvDTo_a0gL6514ZdZX7Rt_3rB7zbRHDsiQM"

    /** Must call before [findMovie]. Call from a Composable using LocalContext. */
    fun init(context: Context): TmdbService {
        client = getClient(context.applicationContext)
        return this
    }

    suspend fun findMovie(title: String): TmdbMovie? {
        // 1. Memory cache (same session, instant)
        if (memoryCache.containsKey(title)) return memoryCache[title]

        // 2. Clean title
        var cleanTitle = title
            .replace(Regex("\\.(mp4|mkv|avi|ts|mov|m3u8)", RegexOption.IGNORE_CASE), "")
            .replace(Regex("\\[.*?]"), "")
            .replace(Regex("\\(.*?\\)"), "")
            .replace(Regex("(1080p|720p|4k|uhd|bluray|h264|h265|web-dl|x264|x265)", RegexOption.IGNORE_CASE), " ")
            .replace("_", " ")
            .replace(".", " ")

        // 3. Extract year — restrict to 1900-2099 so resolution codes (1080,
        //    2160, 4096) are not mistaken for years.
        var year: String? = null
        val yearMatch = Regex("((?:19|20)\\d{2})").find(cleanTitle)
        if (yearMatch != null) {
            year = yearMatch.groupValues[1]
            cleanTitle = cleanTitle.replace(year, "").replace(" - ", " ")
        }

        cleanTitle = cleanTitle.replace(Regex("\\s+"), " ").trim()
        if (cleanTitle.isEmpty()) return null

        // TMDB does not support 'ckb'. Use 'en' for consistent results.
        var url = "$baseUrl/search/movie?query=${java.net.URLEncoder.encode(cleanTitle, "UTF-8")}&language=en"
        if (year != null) url += "&primary_release_year=$year"

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
                        val json    = JSONObject(bodyString)
                        val results = json.optJSONArray("results")

                        if (results != null && results.length() > 0) {
                            val best        = results.getJSONObject(0)
                            val posterPath  = best.optString("poster_path", "")
                            val backdropPath= best.optString("backdrop_path", "")

                            val movie = TmdbMovie(
                                id          = best.optInt("id", 0),
                                title       = best.optString("title", ""),
                                overview    = best.optString("overview", "No description available."),
                                posterUrl   = if (posterPath.isNotEmpty()   && posterPath   != "null") "$imageBaseUrl$posterPath"    else null,
                                backdropUrl = if (backdropPath.isNotEmpty() && backdropPath != "null") "$backdropBaseUrl$backdropPath" else null,
                                rating      = best.optDouble("vote_average", 0.0),
                                releaseDate = best.optString("release_date", "")
                            )

                            memoryCache[title] = movie
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
