package com.kobani4k.app.tv.data

import com.hivemq.client.mqtt.MqttClient
import com.hivemq.client.mqtt.mqtt3.Mqtt3AsyncClient
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.UUID

class MqttViewerService {

    private var client: Mqtt3AsyncClient? = null
    private val scope = CoroutineScope(Dispatchers.IO)
    private var isConnected = false

    init {
        val clientId = "tv_viewer_${UUID.randomUUID()}"
        client = MqttClient.builder()
            .useMqttVersion3()
            .identifier(clientId)
            .serverHost("145.241.248.219")
            .serverPort(1883)
            .buildAsync()

        client?.connect()?.whenComplete { _, throwable ->
            if (throwable == null) {
                isConnected = true
            }
        }
    }

    fun publishJoin(channelName: String) {
        if (channelName.isBlank()) return
        scope.launch {
            if (!isConnected) return@launch
            val topic = "optic/viewers/$channelName/join"
            client?.publishWith()
                ?.topic(topic)
                ?.payload("1".toByteArray())
                ?.send()
        }
    }

    fun publishLeave(channelName: String) {
        if (channelName.isBlank()) return
        scope.launch {
            if (!isConnected) return@launch
            val topic = "optic/viewers/$channelName/leave"
            client?.publishWith()
                ?.topic(topic)
                ?.payload("1".toByteArray())
                ?.send()
        }
    }

    fun disconnect() {
        if (isConnected) {
            client?.disconnect()
            isConnected = false
        }
    }
}
