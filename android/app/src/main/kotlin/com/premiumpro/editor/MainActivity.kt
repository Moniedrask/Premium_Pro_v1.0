package com.premiumpro.editor

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.arthenica.ffmpegkit.flutter.FFmpegKitFlutterPlugin

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Registro manual del plugin FFmpegKit
        FFmpegKitFlutterPlugin(flutterEngine.dartExecutor.binaryMessenger)
    }
}