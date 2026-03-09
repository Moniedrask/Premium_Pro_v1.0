# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# FFmpegKit y smart-exception
-keep class com.arthenica.ffmpegkit.** { *; }
-keep class com.arthenica.smartexception.java.Exceptions { *; }
-dontwarn com.arthenica.ffmpegkit.**

# Mantener métodos nativos
-keepclasseswithmembernames class * {
    native <methods>;
}

# Mantener enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Eliminar logs en release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}