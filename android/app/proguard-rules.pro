# ─────────────────────────────────────────────────────────────
# Flutter embedding (CRÍTICO)
# Sin esto R8 elimina io.flutter.embedding.engine.plugins.FlutterPlugin
# y todos los plugins (ffmpeg_kit, file_picker, shared_preferences, etc.)
# producen MissingPluginException en release.
# ─────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }

# ─────────────────────────────────────────────────────────────
# CRÍTICO: Preservar TODAS las implementaciones de FlutterPlugin.
# R8 elimina las clases concretas que implementan esta interfaz
# porque no ve referencias directas desde Java (se instancian
# por reflexión desde GeneratedPluginRegistrant).
# ─────────────────────────────────────────────────────────────
-keep class * extends io.flutter.embedding.engine.plugins.FlutterPlugin { *; }
-keep class * implements io.flutter.embedding.engine.plugins.FlutterPlugin { *; }

# ─────────────────────────────────────────────────────────────
# GeneratedPluginRegistrant — generado por Flutter, registra
# todos los plugins. No debe ofuscarse ni eliminarse.
# ─────────────────────────────────────────────────────────────
-keep class **.GeneratedPluginRegistrant { *; }

# ─────────────────────────────────────────────────────────────
# Kotlin Metadata
# ─────────────────────────────────────────────────────────────
-keepattributes *Annotation*
-keepattributes RuntimeVisibleAnnotations
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes Signature

# ─────────────────────────────────────────────────────────────
# FFmpegKit — canal flutter.arthenica.com/ffmpeg_kit
# ─────────────────────────────────────────────────────────────
-keep class com.arthenica.ffmpegkit.** { *; }
-keep class com.arthenica.smartexception.** { *; }
-dontwarn com.arthenica.ffmpegkit.**

# ─────────────────────────────────────────────────────────────
# App propia
# ─────────────────────────────────────────────────────────────
-keep class com.premiumpro.editor.** { *; }

# ─────────────────────────────────────────────────────────────
# AndroidX
# ─────────────────────────────────────────────────────────────
-dontwarn com.google.android.play.core.**
-keep class androidx.** { *; }
-dontwarn androidx.**

# ─────────────────────────────────────────────────────────────
# Métodos nativos JNI
# ─────────────────────────────────────────────────────────────
-keepclasseswithmembernames class * {
    native <methods>;
}

# ─────────────────────────────────────────────────────────────
# Enums
# ─────────────────────────────────────────────────────────────
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ─────────────────────────────────────────────────────────────
# R.class
# ─────────────────────────────────────────────────────────────
-keepclassmembers class **.R$* {
    public static <fields>;
}

# ─────────────────────────────────────────────────────────────
# Eliminar logs en release
# ─────────────────────────────────────────────────────────────
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}
