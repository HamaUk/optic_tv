package com.kobani4k.player

import android.content.Context
import android.view.View
import androidx.media3.ui.PlayerView
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.common.StandardMessageCodec

class NativeExoPlayerPlatformView(
    context: Context,
    id: Int,
    creationParams: Map<String?, Any?>?,
    private val nativeExoPlayer: NativeExoPlayer
) : PlatformView {

    private val playerView: PlayerView = PlayerView(context).apply {
        useController = false
        keepScreenOn = true
    }

    init {
        // Detach player from any previous view to prevent ExoPlayer from clearing the surface
        // when the old view is disposed.
        NativeExoPlayerPlatformViewFactory.activeView?.detachPlayer()
        NativeExoPlayerPlatformViewFactory.activeView = this
        
        playerView.player = nativeExoPlayer.getExoPlayerInstance()
    }

    fun detachPlayer() {
        if (playerView.player != null) {
            playerView.player = null
        }
    }

    override fun getView(): View {
        return playerView
    }

    override fun dispose() {
        if (NativeExoPlayerPlatformViewFactory.activeView == this) {
            playerView.player = null
            NativeExoPlayerPlatformViewFactory.activeView = null
        } else {
            // If this is an old view being disposed after a new one took over,
            // DO NOT set player = null, because it would clear the video surface of the new view!
        }
    }
}

class NativeExoPlayerPlatformViewFactory(
    private val nativeExoPlayer: NativeExoPlayer
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    companion object {
        var activeView: NativeExoPlayerPlatformView? = null
    }

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as Map<String?, Any?>?
        return NativeExoPlayerPlatformView(context, viewId, creationParams, nativeExoPlayer)
    }
}
