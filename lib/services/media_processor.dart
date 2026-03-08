import 'package:flutter/foundation.dart';
import 'ffmpeg_wrapper.dart';
import '../models/video_settings.dart';

class MediaProcessor extends ChangeNotifier {
  final FFmpegWrapper _ffmpeg = FFmpegWrapper();
  bool _isProcessing = false;
  double _progress = 0.0;
  String _statusMessage = "Listo";

  bool get isProcessing => _isProcessing;
  double get progress => _progress;
  String get statusMessage => _statusMessage;

  Future<void> init() async {
    await _ffmpeg.init();
  }

  /// Obtiene la duración del video a través del wrapper
  Future<int?> getVideoDuration(String path) async {
    return await _ffmpeg.getVideoDuration(path);
  }

  /// Obtiene los FPS del video a través del wrapper
  Future<int?> getVideoFps(String path) async {
    return await _ffmpeg.getVideoFps(path);
  }

  /// Obtiene las dimensiones del video (ancho y alto)
  /// Por ahora retorna valores predeterminados, pero se puede implementar con FFprobe
  Future<Map<String, int>> getVideoDimensions(String path) async {
    // TODO: Implementar obtención real de dimensiones usando FFprobe
    return {'width': 1920, 'height': 1080};
  }

  Future<bool> processVideo({
    required String inputPath,
    required String outputPath,
    required VideoSettings settings,
    int? totalDurationMicros,
    int? originalFps,
    int? originalWidth,
    int? originalHeight,
  }) async {
    _isProcessing = true;
    _progress = 0.0;
    _statusMessage = "Procesando...";
    notifyListeners();

    final success = await _ffmpeg.processVideo(
      inputPath: inputPath,
      outputPath: outputPath,
      settings: settings,
      totalDurationMicros: totalDurationMicros,
      originalFps: originalFps,
      originalWidth: originalWidth,
      originalHeight: originalHeight,
      onProgress: (progress) {
        _progress = progress;
        _statusMessage = "Procesando ${(progress * 100).toStringAsFixed(0)}%";
        notifyListeners();
      },
    );

    _isProcessing = false;
    if (success) {
      _statusMessage = "Completado";
      _progress = 1.0;
    } else {
      _statusMessage = "Error";
      _progress = 0.0;
    }
    notifyListeners();
    return success;
  }

  void cancelProcessing() {
    if (_isProcessing) {
      _ffmpeg.cancel();
      _isProcessing = false;
      _statusMessage = "Cancelado";
      notifyListeners();
    }
  }
}