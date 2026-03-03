import 'package:flutter/foundation.dart';
import 'ffmpeg_wrapper.dart';
import '../models/audio_settings.dart';

class AudioProcessor extends ChangeNotifier {
  final FFmpegWrapper _ffmpeg = FFmpegWrapper();
  bool _isProcessing = false;
  double _progress = 0.0;
  String _statusMessage = "Listo";

  bool get isProcessing => _isProcessing;
  double get progress => _progress;
  String get statusMessage => _statusMessage;

  Future<bool> processAudio({
    required String inputPath,
    required String outputPath,
    required AudioSettings settings,
  }) async {
    _isProcessing = true;
    _progress = 0.0;
    _statusMessage = "Procesando audio...";
    notifyListeners();

    final success = await _ffmpeg.processAudio(
      inputPath: inputPath,
      outputPath: outputPath,
      settings: settings,
      onProgress: (progress) {
        _progress = progress;
        _statusMessage = "Procesando ${(progress * 100).toStringAsFixed(0)}%";
        notifyListeners();
      },
    );

    _isProcessing = false;
    _statusMessage = success ? "Completado" : "Error";
    notifyListeners();
    return success;
  }

  void cancel() {
    _ffmpeg.cancel();
    _isProcessing = false;
    _statusMessage = "Cancelado";
    notifyListeners();
  }
}