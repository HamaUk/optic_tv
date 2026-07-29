package com.kobani4k.player

import androidx.media3.common.audio.AudioProcessor
import androidx.media3.common.audio.AudioProcessor.AudioFormat
import androidx.media3.common.audio.AudioProcessor.UnhandledAudioFormatException
import java.nio.ByteBuffer
import java.nio.ByteOrder

@androidx.media3.common.util.UnstableApi
class VocalIsolationAudioProcessor : AudioProcessor {
    var isEnabled: Boolean = false
        set(value) {
            if (field != value) {
                field = value
                isActive = value
            }
        }

    private var isActive: Boolean = false
    private var pendingAudioFormat = AudioFormat.NOT_SET
    private var audioFormat = AudioFormat.NOT_SET
    private var buffer: ByteBuffer = AudioProcessor.EMPTY_BUFFER
    private var outputBuffer: ByteBuffer = AudioProcessor.EMPTY_BUFFER
    private var inputEnded: Boolean = false

    override fun configure(inputAudioFormat: AudioFormat): AudioFormat {
        if (inputAudioFormat.encoding != androidx.media3.common.C.ENCODING_PCM_16BIT) {
            throw UnhandledAudioFormatException(inputAudioFormat)
        }
        if (inputAudioFormat.channelCount != 2) {
            // Can only do mid/side cancellation on stereo audio
            pendingAudioFormat = AudioFormat.NOT_SET
            return AudioFormat.NOT_SET
        }
        pendingAudioFormat = inputAudioFormat
        return inputAudioFormat
    }

    override fun isActive(): Boolean = isActive && pendingAudioFormat != AudioFormat.NOT_SET

    override fun queueInput(inputBuffer: ByteBuffer) {
        val position = inputBuffer.position()
        val limit = inputBuffer.limit()
        val frameCount = (limit - position) / (2 * 2) // 2 channels, 16-bit
        val capacity = frameCount * 2 * 2
        
        if (buffer.capacity() < capacity) {
            buffer = ByteBuffer.allocateDirect(capacity).order(ByteOrder.nativeOrder())
        } else {
            buffer.clear()
        }

        var p = position
        while (p < limit) {
            val left = inputBuffer.getShort(p)
            val right = inputBuffer.getShort(p + 2)
            
            // Vocal isolation: (L - R) / 2 cancels out center panned audio (commentators/vocals)
            // It leaves only the stereo spread (stadium crowd noise).
            val side = ((left.toInt() - right.toInt()) / 2).toShort()
            
            // Output the isolated side channel to both ears so it's centered but without the vocal
            buffer.putShort(side)
            buffer.putShort(side)
            
            p += 4
        }

        inputBuffer.position(limit)
        buffer.flip()
        outputBuffer = this.buffer
    }

    override fun queueEndOfStream() {
        inputEnded = true
    }

    override fun getOutput(): ByteBuffer {
        val output = outputBuffer
        outputBuffer = AudioProcessor.EMPTY_BUFFER
        return output
    }

    override fun isEnded(): Boolean = inputEnded && outputBuffer === AudioProcessor.EMPTY_BUFFER

    override fun flush() {
        outputBuffer = AudioProcessor.EMPTY_BUFFER
        inputEnded = false
        audioFormat = pendingAudioFormat
    }

    override fun reset() {
        flush()
        buffer = AudioProcessor.EMPTY_BUFFER
        pendingAudioFormat = AudioFormat.NOT_SET
        audioFormat = AudioFormat.NOT_SET
    }
}
