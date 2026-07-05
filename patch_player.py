import re

with open(r'android\app\src\main\kotlin\com\kobani4k\app\tv\ui\PlayerScreen.kt', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Update ActiveMenu enum
code = code.replace(
    'enum class ActiveMenu { NONE, QUALITY, AUDIO, SUBTITLES, SETTINGS }',
    'enum class ActiveMenu { NONE, QUALITY, AUDIO, SUBTITLES, SERVERS, SETTINGS }'
)

# 2. Add activeServerIndex & validServers
state_block = '''    var currentLogoUrl     by remember { mutableStateOf(logoUrl) }

    var activeServerIndex  by remember { mutableStateOf(0) }
'''
code = code.replace('    var currentLogoUrl     by remember { mutableStateOf(logoUrl) }\n', state_block)

channels_list_block = '''    var channelsList by remember { mutableStateOf<List<TvChannel>>(emptyList()) }

    val validServers = remember(currentStreamUrl, channelsList) {
        val ch = channelsList.firstOrNull { it.url == currentStreamUrl }
        val servers = mutableListOf<Pair<String, String>>()
        if (ch != null) {
            servers.add(Pair("SERVER 1", ch.url))
            if (!ch.url2.isNullOrEmpty()) {
                val n2 = if (!ch.url2Name.isNullOrEmpty()) ch.url2Name else "SERVER 2"
                servers.add(Pair(n2.uppercase(), ch.url2))
            }
            if (!ch.url3.isNullOrEmpty()) {
                val n3 = if (!ch.url3Name.isNullOrEmpty()) ch.url3Name else "SERVER 3"
                servers.add(Pair(n3.uppercase(), ch.url3))
            }
        } else {
            servers.add(Pair("SERVER 1", currentStreamUrl))
        }
        servers
    }
'''
code = code.replace('    var channelsList by remember { mutableStateOf<List<TvChannel>>(emptyList()) }\n', channels_list_block)

# 3. LaunchedEffect for stream change
old_effect = '''    LaunchedEffect(currentStreamUrl) {
        retryCount = 0
        streamFailed = false
        TvViewerService.joinChannel(currentStreamUrl)
        isBuffering = true
        exoPlayer.stop()
        exoPlayer.clearMediaItems()
        
        val ch = channelsList.firstOrNull { it.url == currentStreamUrl }
        var finalUrl = currentStreamUrl
        var finalDrmScheme = ch?.drmScheme
        var finalDrmLicense = ch?.drmLicense

        if (currentStreamUrl.contains("|drmScheme=")) {
            val parts = currentStreamUrl.split("|")'''

new_effect = '''    LaunchedEffect(currentStreamUrl, activeServerIndex) {
        if (validServers.isEmpty()) return@LaunchedEffect
        if (activeServerIndex >= validServers.size) activeServerIndex = 0
        val playUrl = validServers[activeServerIndex].second
        retryCount = 0
        streamFailed = false
        TvViewerService.joinChannel(playUrl)
        isBuffering = true
        exoPlayer.stop()
        exoPlayer.clearMediaItems()
        
        val ch = channelsList.firstOrNull { it.url == currentStreamUrl }
        var finalUrl = playUrl
        var finalDrmScheme = ch?.drmScheme
        var finalDrmLicense = ch?.drmLicense

        if (finalUrl.contains("|drmScheme=")) {
            val parts = finalUrl.split("|")'''
            
code = code.replace(old_effect, new_effect)

# 4. Fallback in playerListener
old_listener = '''                // Live stream ended (stream server restarted) → reconnect with backoff
                if (state == Media3Player.STATE_ENDED) {
                    if (retryCount < 3) {
                        retryCount++
                        scope.launch {
                            delay(2_000L * retryCount)
                            try {
                                exoPlayer.seekToDefaultPosition()
                                exoPlayer.prepare()
                                exoPlayer.play()
                            } catch (_: Exception) {}
                        }
                    } else {
                        streamFailed = true
                    }
                }
            }
            override fun onPlayerError(error: PlaybackException) {
                isBuffering = false
                // Network / codec error → reconnect with backoff
                if (retryCount < 3) {
                    retryCount++
                    scope.launch {
                        delay(3_000L * retryCount)
                        try {
                            exoPlayer.seekToDefaultPosition()
                            exoPlayer.prepare()
                            exoPlayer.play()
                        } catch (_: Exception) {}
                    }
                } else {
                    streamFailed = true
                }
            }'''
            
new_listener = '''                // Live stream ended (stream server restarted) → reconnect with backoff
                if (state == Media3Player.STATE_ENDED) {
                    if (retryCount < 3) {
                        retryCount++
                        scope.launch {
                            delay(2_000L * retryCount)
                            try {
                                exoPlayer.seekToDefaultPosition()
                                exoPlayer.prepare()
                                exoPlayer.play()
                            } catch (_: Exception) {}
                        }
                    } else {
                        if (activeServerIndex + 1 < validServers.size) {
                            activeServerIndex++
                        } else {
                            streamFailed = true
                        }
                    }
                }
            }
            override fun onPlayerError(error: PlaybackException) {
                isBuffering = false
                // Network / codec error → reconnect with backoff
                if (retryCount < 3) {
                    retryCount++
                    scope.launch {
                        delay(3_000L * retryCount)
                        try {
                            exoPlayer.seekToDefaultPosition()
                            exoPlayer.prepare()
                            exoPlayer.play()
                        } catch (_: Exception) {}
                    }
                } else {
                    if (activeServerIndex + 1 < validServers.size) {
                        activeServerIndex++
                    } else {
                        streamFailed = true
                    }
                }
            }'''
code = code.replace(old_listener, new_listener)

# Reset active server index when quick zapping or changing channel via drawer
# 5. Zap quick
old_zap = '''                                currentStreamUrl   = ch.url
                                currentChannelName = ch.name
                                currentLogoUrl     = ch.logo
                                showControls  = false'''
new_zap = '''                                activeServerIndex  = 0
                                currentStreamUrl   = ch.url
                                currentChannelName = ch.name
                                currentLogoUrl     = ch.logo
                                showControls  = false'''
code = code.replace(old_zap, new_zap)

# 6. Zap drawer
old_drawer = '''                    currentStreamUrl   = ch.url
                    currentChannelName = ch.name
                    currentLogoUrl     = ch.logo
                    showZapList = false'''
new_drawer = '''                    activeServerIndex  = 0
                    currentStreamUrl   = ch.url
                    currentChannelName = ch.name
                    currentLogoUrl     = ch.logo
                    showZapList = false'''
code = code.replace(old_drawer, new_drawer)

# 7. Add Servers button in OsdOverlay
old_overlay = '''                // "?"? Quality "?"?
                OsdIconButton(
                    icon    = Icons.Rounded.HighQuality,
                    label   = "Quality",
                    onWake  = onWake,
                    onClick = { onOpenMenu(ActiveMenu.QUALITY) }
                )'''
new_overlay = '''                // Servers
                OsdIconButton(
                    icon    = Icons.Rounded.Dns,
                    label   = "Servers",
                    onWake  = onWake,
                    onClick = { onOpenMenu(ActiveMenu.SERVERS) }
                )
                
                // "?"? Quality "?"?
                OsdIconButton(
                    icon    = Icons.Rounded.HighQuality,
                    label   = "Quality",
                    onWake  = onWake,
                    onClick = { onOpenMenu(ActiveMenu.QUALITY) }
                )'''
code = code.replace(old_overlay, new_overlay)

# Add validServers and activeServerIndex to OsdOverlay and SubMenuPanel
code = code.replace('    activeMenu: ActiveMenu,', '    activeMenu: ActiveMenu,\n    validServers: List<Pair<String, String>>,\n    activeServerIndex: Int,\n    onSelectServer: (Int) -> Unit,')
code = code.replace('                activeMenu     = activeMenu,', '                activeMenu     = activeMenu,\n                validServers   = validServers,\n                activeServerIndex = activeServerIndex,\n                onSelectServer = { activeServerIndex = it },')

# In SubMenuPanel Header text
code = code.replace('                        ActiveMenu.QUALITY   -> "VIDEO QUALITY"', '                        ActiveMenu.SERVERS   -> "SERVERS"\n                        ActiveMenu.QUALITY   -> "VIDEO QUALITY"')

# SubMenuPanel items
old_submenu_items = '''                val items = when (activeMenu) {
                    ActiveMenu.QUALITY   -> listOf("Auto", "1080p HD", "720p", "480p", "360p")
                    ActiveMenu.AUDIO     -> listOf("Track 1 (Default)", "Track 2", "Track 3")
                    ActiveMenu.SUBTITLES -> listOf("Off", "English", "Arabic", "French", "Spanish")
                    else                 -> emptyList()
                }'''
new_submenu_items = '''                val items = when (activeMenu) {
                    ActiveMenu.SERVERS   -> validServers.map { it.first }
                    ActiveMenu.QUALITY   -> listOf("Auto", "1080p HD", "720p", "480p", "360p")
                    ActiveMenu.AUDIO     -> listOf("Track 1 (Default)", "Track 2", "Track 3")
                    ActiveMenu.SUBTITLES -> listOf("Off", "English", "Arabic", "French", "Spanish")
                    else                 -> emptyList()
                }'''
code = code.replace(old_submenu_items, new_submenu_items)

# TrackOption onClick
old_track = '''                        TrackOption(
                            title      = items[i],
                            isSelected = i == 0,
                            modifier   = if (i == 0) Modifier.focusRequester(menuFocusRequester) else Modifier,
                            onClick    = { onDismiss() }
                        )'''
new_track = '''                        val isSel = if (activeMenu == ActiveMenu.SERVERS) i == activeServerIndex else i == 0
                        TrackOption(
                            title      = items[i],
                            isSelected = isSel,
                            modifier   = if (i == 0) Modifier.focusRequester(menuFocusRequester) else Modifier,
                            onClick    = { 
                                if (activeMenu == ActiveMenu.SERVERS) {
                                    onSelectServer(i)
                                }
                                onDismiss() 
                            }
                        )'''
code = code.replace(old_track, new_track)

with open(r'android\app\src\main\kotlin\com\kobani4k\app\tv\ui\PlayerScreen.kt', 'w', encoding='utf-8') as f:
    f.write(code)

print("done")
