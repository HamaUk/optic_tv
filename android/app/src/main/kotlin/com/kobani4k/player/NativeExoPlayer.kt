package com.kobani4k.player

import android.content.Context
import android.graphics.SurfaceTexture
import android.os.Handler
import android.os.Looper
import android.view.Surface
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.VideoSize
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.SeekParameters
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry

/**
 * Native Kotlin ExoPlayer engine — Ghosten-level IPTV optimizations.
 *
 * Uses Texture-based rendering: ExoPlayer renders frames into a SurfaceTexture
 * provided by Flutter's TextureRegistry. Flutter displays it anywhere via
 * Texture(textureId). This allows the same video to appear on ANY page
 * (inline, fullscreen, PiP) without re-parenting issues.
 *
 * Key performance features (identical to Ghosten Player):
 * 1. forceEnableMediaCodecAsynchronousQueueing() — async HW decoder pipeline
 * 2. DefaultMediaSourceFactory + DefaultHttpDataSource — custom UA, cross-protocol redirects
 * 3. SeekParameters(3_000_000) — fast seeks on live streams
 * 4. HLS + RTSP + RTMP — all IPTV protocols natively supported
 */
@UnstableApi
class NativeExoPlayer(
    private val context: Context,
    private val methodChannel: MethodChannel,
    private val textureRegistry: TextureRegistry,
) : Player.Listener {

    private val handler = Handler(Looper.getMainLooper())
    private var player: ExoPlayer
    private var textureEntry: TextureRegistry.SurfaceTextureEntry? = null
    private var surface: Surface? = null

    /** The Flutter texture ID — Dart reads this to create Texture(textureId) */
    var textureId: Long = -1
        private set

    // Ghosten-identical HTTP factory: cross-protocol redirects + custom User-Agent
    private val httpDataSourceFactory = DefaultHttpDataSource.Factory()
        .setAllowCrossProtocolRedirects(true)
        .setConnectTimeoutMs(8_000)
        .setReadTimeoutMs(8_000)

    init {
        player = buildPlayer()
        setupTexture()
        startPositionPolling()
    }

    /**
     * Builds the ExoPlayer with all Ghosten-level optimizations.
     */
    private fun buildPlayer(): ExoPlayer {
        val renderersFactory = DefaultRenderersFactory(context)
            .setEnableDecoderFallback(true)
            .setExtensionRendererMode(DefaultRenderersFactory.EXTENSION_RENDERER_MODE_ON)
            .forceEnableMediaCodecAsynchronousQueueing() // ← KEY: async MediaCodec pipeline

        val mediaSourceFactory = DefaultMediaSourceFactory(context)
            .setDataSourceFactory(
                DefaultDataSource.Factory(context, httpDataSourceFactory)
            )

        val exo = ExoPlayer.Builder(context)
            .setRenderersFactory(renderersFactory)
            .setMediaSourceFactory(mediaSourceFactory)
            .setSeekParameters(SeekParameters(3_000_000, 3_000_000)) // Fast seeks for live
            .build()

        exo.addListener(this)

        // Default track params: start with SD for fastest first frame, auto-upgrades to HD
        exo.trackSelectionParameters = exo.trackSelectionParameters
            .buildUpon()
            .setMaxVideoSizeSd()
            .build()

        return exo
    }

    /**
     * Creates a Flutter SurfaceTexture and connects ExoPlayer's video output to it.
     * Flutter can then display this texture anywhere via Texture(textureId: id).
     */
    private fun setupTexture() {
        val entry = textureRegistry.createSurfaceTexture()
        textureEntry = entry
        textureId = entry.id()

        val surfaceTexture: SurfaceTexture = entry.surfaceTexture()
        surface = Surface(surfaceTexture)
        player.setVideoSurface(surface)
    }

    // ─── MethodChannel Command Handler ───────────────────────────────────

    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "init" -> {
                // Return the texture ID so Flutter can display it
                result.success(textureId)
            }
            "open" -> {
                val url = call.argument<String>("url") ?: run {
                    result.error("MISSING_URL", "url is required", null)
                    return
                }
                val headers = call.argument<Map<String, String>>("headers") ?: emptyMap()
                open(url, headers)
                result.success(null)
            }
            "play" -> {
                play()
                result.success(null)
            }
            "pause" -> {
                pause()
                result.success(null)
            }
            "seekTo" -> {
                val positionMs = call.argument<Number>("position")?.toLong() ?: 0L
                seekTo(positionMs)
                result.success(null)
            }
            "setVolume" -> {
                val volume = call.argument<Number>("volume")?.toFloat() ?: 1.0f
                player.volume = volume
                result.success(null)
            }
            "setSpeed" -> {
                val speed = call.argument<Number>("speed")?.toFloat() ?: 1.0f
                player.setPlaybackSpeed(speed)
                result.success(null)
            }
            "stop" -> {
                player.stop()
                result.success(null)
            }
            "dispose" -> {
                dispose()
                result.success(null)
            }
            "getPosition" -> {
                result.success(player.currentPosition)
            }
            "getDuration" -> {
                val dur = if (player.duration == C.TIME_UNSET) 0L else player.duration
                result.success(dur)
            }
            "setMaxResolution" -> {
                val maxHeight = call.argument<Number>("maxHeight")?.toInt() ?: 0
                if (maxHeight <= 0) {
                    // Auto — remove resolution cap
                    player.trackSelectionParameters = player.trackSelectionParameters
                        .buildUpon()
                        .clearVideoSizeConstraints()
                        .build()
                } else {
                    // Cap to specific height (e.g. 480, 720, 1080)
                    val maxWidth = (maxHeight * 16 / 9) // Assume 16:9
                    player.trackSelectionParameters = player.trackSelectionParameters
                        .buildUpon()
                        .setMaxVideoSize(maxWidth, maxHeight)
                        .build()
                }
                result.success(null)
            }
            "getVideoSize" -> {
                val w = player.videoSize.width
                val h = player.videoSize.height
                result.success(mapOf("width" to w, "height" to h))
            }
            "getTracks" -> {
                val videoTracks = mutableListOf<Map<String, Any>>()
                for (group in player.currentTracks.groups) {
                    if (group.type == C.TRACK_TYPE_VIDEO) {
                        val trackGroup = group.mediaTrackGroup
                        for (i in 0 until trackGroup.length) {
                            val format = trackGroup.getFormat(i)
                            val width = format.width
                            val height = format.height
                            val bitrate = format.bitrate
                            val codecs = format.codecs ?: ""
                            if (width > 0 && height > 0) {
                                videoTracks.add(mapOf(
                                    "width" to width,
                                    "height" to height,
                                    "bitrate" to bitrate,
                                    "codecs" to codecs
                                ))
                            }
                        }
                    }
                }
                result.success(videoTracks)
            }
            else -> result.notImplemented()
        }
    }

    // ─── Player Operations ───────────────────────────────────────────────

    private fun open(url: String, headers: Map<String, String>) {
        // Apply custom User-Agent from headers
        val userAgent = headers["User-Agent"] ?: "SmartIPTV"
        httpDataSourceFactory.setUserAgent(userAgent)

        // Set custom headers
        if (headers.isNotEmpty()) {
            httpDataSourceFactory.setDefaultRequestProperties(headers)
        }

        val mediaItem = MediaItem.Builder()
            .setUri(url)
            .build()

        player.setMediaItem(mediaItem)
        player.playWhenReady = true
        player.prepare()
    }

    private fun play() {
        when (player.playbackState) {
            Player.STATE_IDLE -> {
                player.prepare()
                player.play()
            }
            Player.STATE_ENDED -> {
                player.seekTo(0)
                player.play()
            }
            else -> player.play()
        }
    }

    private fun pause() {
        player.pause()
    }

    private fun seekTo(positionMs: Long) {
        player.seekTo(positionMs)
    }

    fun dispose() {
        handler.removeCallbacksAndMessages(null)
        player.removeListener(this)
        player.setVideoSurface(null)
        player.release()
        surface?.release()
        surface = null
        textureEntry?.release()
        textureEntry = null
    }

    // ─── Player.Listener callbacks → Flutter Events ──────────────────────

    override fun onIsPlayingChanged(isPlaying: Boolean) {
        if (player.playbackState == Player.STATE_BUFFERING) return
        sendEvent("onPlayingChanged", isPlaying)
    }

    override fun onPlaybackStateChanged(playbackState: Int) {
        when (playbackState) {
            Player.STATE_BUFFERING -> {
                sendEvent("onBufferingChanged", true)
            }
            Player.STATE_READY -> {
                sendEvent("onBufferingChanged", false)
                sendEvent("onPlayingChanged", player.isPlaying)
                val dur = if (player.duration == C.TIME_UNSET) 0L else player.duration
                sendEvent("onDurationChanged", dur)
            }
            Player.STATE_ENDED -> {
                sendEvent("onPlayingChanged", false)
                sendEvent("onCompleted", true)
            }
            Player.STATE_IDLE -> {
                sendEvent("onBufferingChanged", false)
            }
        }
    }

    override fun onVideoSizeChanged(videoSize: VideoSize) {
        // Multiply by pixelWidthHeightRatio to handle anamorphic widescreen correctly
        val ratio = if (videoSize.pixelWidthHeightRatio > 0) videoSize.pixelWidthHeightRatio else 1.0f
        val displayWidth = (videoSize.width * ratio).toInt()
        
        // Ensure the native Flutter SurfaceTexture receives the correct buffer dimensions
        // to prevent hardware squishing before the Texture widget renders it
        textureEntry?.surfaceTexture()?.setDefaultBufferSize(displayWidth, videoSize.height)

        sendEvent("onVideoSizeChanged", mapOf(
            "width" to displayWidth,
            "height" to videoSize.height
        ))
    }

    override fun onPlayerError(error: PlaybackException) {
        sendEvent("onError", error.message ?: "Unknown playback error")
    }

    // ─── Position Polling (matches Ghosten's 1-second interval) ──────────

    private fun startPositionPolling() {
        handler.postDelayed(object : Runnable {
            override fun run() {
                if (player.isPlaying) {
                    sendEvent("onPositionChanged", player.currentPosition)
                    sendEvent("onBufferPositionChanged", player.bufferedPosition)
                }
                handler.postDelayed(this, 500) // 500ms for smooth scrubber
            }
        }, 500)
    }

    // ─── Event Sending ───────────────────────────────────────────────────

    private fun sendEvent(event: String, data: Any?) {
        handler.post {
            methodChannel.invokeMethod(event, data)
        }
    }
}
