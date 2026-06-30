package com.kobani4k.app

import java.net.Proxy
import java.net.ProxySelector
import java.net.URI
import java.net.SocketAddress
import java.io.IOException

object GlobalProxyBypass {
    fun apply() {
        ProxySelector.setDefault(object : ProxySelector() {
            override fun select(uri: URI?): List<Proxy> {
                // ALWAYS return NO_PROXY to completely ignore system proxy settings
                return listOf(Proxy.NO_PROXY)
            }

            override fun connectFailed(uri: URI?, sa: SocketAddress?, ioe: IOException?) {
                // Ignored
            }
        })
    }
}
