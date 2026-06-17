package com.kobani4k.player

import android.content.Context
import android.view.View
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.common.StandardMessageCodec

/**
 * Factory that creates a PlatformView wrapping the native ExoPlayer PlayerView.
 * Flutter embeds this via AndroidView with viewType = "com.kobani4k/native_player_view".
 */
class NativeExoPlayerViewFactory(
    private val nativeExoPlayer: NativeExoPlayer
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return NativeExoPlayerPlatformView(context, nativeExoPlayer)
    }
}

/**
 * Wraps the native PlayerView as a Flutter PlatformView.
 */
class NativeExoPlayerPlatformView(
    private val context: Context,
    private val nativeExoPlayer: NativeExoPlayer
) : PlatformView {

    private val view: View = nativeExoPlayer.getView()
        ?: nativeExoPlayer.createView(context)

    override fun getView(): View = view

    override fun dispose() {
        // Don't dispose the player here — it's managed by Flutter's OpticPlayer lifecycle
    }
}
