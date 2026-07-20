package com.kobani4k.player

import android.util.Base64
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import java.util.regex.Pattern

object StreamResolver {
    private val client = OkHttpClient()
    private val ATOB_PATTERN = Pattern.compile("atob\\(['\"]([^'\"]+)['\"]\\)")
    private val STREAM_PATTERN = Pattern.compile("(https?://[^\\s'\"]+\\.(?:m3u8|mpd)[^\\s'\"]*)")

    suspend fun resolveIfNeeded(url: String, userAgent: String? = null): String {
        // 1. Check for stalker portal MAC URLs
        if (url.contains("mac=") && url.contains("live.php")) {
            return withContext(Dispatchers.IO) {
                var currentUrl = url
                var redirects = 0
                val ua = userAgent ?: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
                try {
                    val noRedirectClient = client.newBuilder().followRedirects(false).followSslRedirects(false).build()
                    while (redirects < 5) {
                        val request = Request.Builder().url(currentUrl)
                            .header("User-Agent", ua)
                            .build()
                        val response = noRedirectClient.newCall(request).execute()
                        if (response.isRedirect) {
                            val location = response.header("Location")
                            if (location != null) {
                                if (location.startsWith("http")) {
                                    currentUrl = location
                                } else if (location.startsWith("//")) {
                                    currentUrl = "http:$location"
                                } else if (location.startsWith("/")) {
                                    val uri = java.net.URI(currentUrl)
                                    val portStr = if (uri.port != -1) ":${uri.port}" else ""
                                    currentUrl = "${uri.scheme}://${uri.host}$portStr$location"
                                } else {
                                    val uri = java.net.URI(currentUrl)
                                    val path = uri.path.substring(0, uri.path.lastIndexOf('/') + 1)
                                    val portStr = if (uri.port != -1) ":${uri.port}" else ""
                                    currentUrl = "${uri.scheme}://${uri.host}$portStr$path$location"
                                }
                                redirects++
                            } else {
                                break
                            }
                        } else {
                            break
                        }
                    }
                    if (currentUrl != url) {
                        if (url.contains("extension=m3u8") && !currentUrl.contains("m3u8")) {
                            return@withContext "$currentUrl#.m3u8"
                        }
                        return@withContext currentUrl
                    }
                } catch (e: Exception) {
                    // ignore
                }
                url
            }
        }

        if (!url.endsWith("|scrape=true") && !url.endsWith("%7Cscrape=true")) {
            return url
        }

        val targetUrl = url.replace("|scrape=true", "").replace("%7Cscrape=true", "")
        return withContext(Dispatchers.IO) {
            try {
                val requestBuilder = Request.Builder().url(targetUrl)
                val ua = userAgent ?: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
                requestBuilder.header("User-Agent", ua)
                requestBuilder.header("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8")

                val response = client.newCall(requestBuilder.build()).execute()
                val body = response.body?.string() ?: return@withContext targetUrl

                // 1. Check for plain text streams
                val directMatcher = STREAM_PATTERN.matcher(body)
                if (directMatcher.find()) {
                    return@withContext directMatcher.group(1) ?: targetUrl
                }

                // 2. Check for atob base64
                val atobMatcher = ATOB_PATTERN.matcher(body)
                while (atobMatcher.find()) {
                    try {
                        val b64 = atobMatcher.group(1)
                        if (b64 != null) {
                            val decoded = String(Base64.decode(b64, Base64.DEFAULT), Charsets.UTF_8)
                            val streamMatcher = STREAM_PATTERN.matcher(decoded)
                            if (streamMatcher.find()) {
                                return@withContext streamMatcher.group(1) ?: continue
                            }
                        }
                    } catch (e: Exception) {
                        // ignore
                    }
                }

                // 3. Check for iframe embeds
                val iframePattern = Pattern.compile("<iframe[^>]+src=['\"]([^'\"]+)['\"]", Pattern.CASE_INSENSITIVE)
                val iframeMatcher = iframePattern.matcher(body)
                if (iframeMatcher.find()) {
                    var iframeSrc = iframeMatcher.group(1) ?: return@withContext targetUrl
                    if (iframeSrc.startsWith("//")) {
                        iframeSrc = "https:$iframeSrc"
                    } else if (iframeSrc.startsWith("/")) {
                        val uri = java.net.URI(targetUrl)
                        iframeSrc = "${uri.scheme}://${uri.host}$iframeSrc"
                    }

                    try {
                        val iframeRequest = Request.Builder().url(iframeSrc)
                            .header("User-Agent", ua)
                            .header("Referer", targetUrl)
                            .header("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
                            .build()
                        val iframeResponse = client.newCall(iframeRequest).execute()
                        val iframeBody = iframeResponse.body?.string() ?: return@withContext targetUrl

                        val iframeDirectMatcher = STREAM_PATTERN.matcher(iframeBody)
                        if (iframeDirectMatcher.find()) return@withContext iframeDirectMatcher.group(1) ?: targetUrl

                        val iframeAtobMatcher = ATOB_PATTERN.matcher(iframeBody)
                        while (iframeAtobMatcher.find()) {
                            try {
                                val b64 = iframeAtobMatcher.group(1)
                                if (b64 != null) {
                                    val decoded = String(Base64.decode(b64, Base64.DEFAULT), Charsets.UTF_8)
                                    val streamMatcher = STREAM_PATTERN.matcher(decoded)
                                    if (streamMatcher.find()) return@withContext streamMatcher.group(1) ?: continue
                                }
                            } catch (e: Exception) {}
                        }
                    } catch (e: Exception) {}
                }
                
                targetUrl
            } catch (e: Exception) {
                targetUrl
            }
        }
    }
}
