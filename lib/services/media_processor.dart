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

  Future<bool> processVideo({
    required String inputPath,
    required String outputPath,
    required VideoSettings settings,
    // totalDurationMicros ELIMINADO porque ya no se usa en el wrapper
  }) async {
    _isProcessing = true;
    _progress = 0.0;
    _statusMessage = "Procesando...";
    notifyListeners();

    final success = await _ffmpeg.processVideo(
      inputPath: inputPath,
      outputPath: outputPath,
      codec: settings.videoCodec,
      bitrate: settings.videoBitrate,
      preset: settings.preset,
      crf: settings.crf,
      // totalDurationMicros ya no se pasa
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