import 'package:flutter/foundation.dart';
import 'ffmpeg_wrapper.dart';
import '../models/video_settings.dart';
import '../models/speed_segment.dart';

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

  Future<int?> getVideoDuration(String path) async {
    return await _ffmpeg.getVideoDuration(path);
  }

  Future<int?> getVideoFps(String path) async {
    return await _ffmpeg.getVideoFps(path);
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

  // ========== SPEED RAMP ==========
  Future<bool> processVideoWithSpeedRamp({
    required String inputPath,
    required String outputPath,
    required List<SpeedSegment> segments,
    int? totalDurationMicros,
  }) async {
    _isProcessing = true;
    _progress = 0.0;
    _statusMessage = "Aplicando speed ramp...";
    notifyListeners();

    final success = await _ffmpeg.processVideoWithSpeedRamp(
      inputPath: inputPath,
      outputPath: outputPath,
      segments: segments,
      totalDurationMicros: totalDurationMicros,
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