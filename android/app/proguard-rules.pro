# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# ─── OkHttp / Okio (critical for PocketBase networking) ───
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase
-dontwarn javax.annotation.**

# ─── ExoPlayer / Media3 (critical for IPTV playback) ───
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**
# Keep DRM classes used via reflection
-keep class androidx.media3.exoplayer.drm.** { *; }
-keep class androidx.media3.datasource.** { *; }
# FFmpeg decoder (Jellyfin) must not be stripped
-keep class org.jellyfin.media3.** { *; }
-dontwarn org.jellyfin.media3.**

# ─── Coil image loading ───
-keep class coil.** { *; }
-dontwarn coil.**

# ─── HiveMQ MQTT & Netty dependencies ───
-keep class io.netty.** { *; }
-dontwarn io.netty.**
-dontwarn org.slf4j.**
-dontwarn org.apache.log4j.**
-dontwarn org.apache.logging.log4j.**
-dontwarn org.eclipse.jetty.**
-dontwarn reactor.blockhound.**
-keep class com.hivemq.** { *; }
-dontwarn com.hivemq.**
-keep class io.reactivex.** { *; }
-dontwarn io.reactivex.**
-keep class io.reactivex.rxjava3.** { *; }
-dontwarn io.reactivex.rxjava3.**
-keep class org.reactivestreams.** { *; }
-dontwarn org.reactivestreams.**
-keep class dagger.** { *; }
-dontwarn dagger.**
-keep class javax.inject.** { *; }
-keep class org.jctools.** { *; }
-dontwarn org.jctools.**

# Force keep concurrency fields accessed via reflection
-keepclassmembers class * {
    long consumerIndex;
    long producerIndex;
    long p*;
}

# ─── JSON (org.json is built-in, keep for safety) ───
-keep class org.json.** { *; }

# ─── Kotlin coroutines ───
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-dontwarn kotlinx.coroutines.**

# ─── Lottie animations ───
-keep class com.airbnb.lottie.** { *; }
-dontwarn com.airbnb.lottie.**

# ─── Keep crypto classes used for DRM ───
-keep class javax.crypto.** { *; }
-keep class javax.crypto.spec.** { *; }

# ─── App-specific classes ───
-keep class com.kobani4k.** { *; }
