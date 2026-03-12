# ─────────────────────────────────────────────────────────────
# Flutter embedding (CRÍTICO – sin esto R8 elimina FlutterPlugin
# y aparece MissingPluginException en release)
# ─────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }

# ─────────────────────────────────────────────────────────────
# Kotlin Metadata (necesario para reflexión de Kotlin en runtime)
# ─────────────────────────────────────────────────────────────
-keepattributes *Annotation*
-keepattributes RuntimeVisibleAnnotations
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes Signature

# ─────────────────────────────────────────────────────────────
# FFmpegKit – canal nativo flutter.arthenica.com/ffmpeg_kit
# ─────────────────────────────────────────────────────────────
-keep class com.arthenica.ffmpegkit.** { *; }
-keep class com.arthenica.smartexception.** { *; }
-dontwarn com.arthenica.ffmpegkit.**

# ─────────────────────────────────────────────────────────────
# App propia
# ─────────────────────────────────────────────────────────────
-keep class com.premiumpro.editor.** { *; }

# ─────────────────────────────────────────────────────────────
# AndroidX y Google Play
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
# Enums (serialización)
# ─────────────────────────────────────────────────────────────
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ─────────────────────────────────────────────────────────────
# R.class (recursos)
# ─────────────────────────────────────────────────────────────
-keepclassmembers class **.R$* {
    public static <fields>;
}

# ─────────────────────────────────────────────────────────────
# Eliminar logs en release (no eliminar en debug para no romper
# el tracing de Flutter)
# ─────────────────────────────────────────────────────────────
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}
