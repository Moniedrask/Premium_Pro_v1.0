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

  Future<void> init() async {
    await _ffmpeg.init();
  }

  /// Procesa un archivo de audio según configuración
  Future<bool> processAudio({
    required String inputPath,
    required String outputPath,
    required AudioSettings settings,
  }) async {
    _isProcessing = true;
    _progress = 0.0;
    _statusMessage = "Procesando audio...";
    notifyListeners();

    // Construir comando FFmpeg
    final List<String> args = [
      '-i', inputPath,
    ];

    // Codec de audio
    switch (settings.codec) {
      case 'aac':
        args.addAll(['-c:a', 'aac', '-b:a', '${settings.bitrate}k']);
        break;
      case 'mp3':
        args.addAll(['-c:a', 'libmp3lame', '-b:a', '${settings.bitrate}k']);
        break;
      case 'opus':
        args.addAll(['-c:a', 'libopus', '-b:a', '${settings.bitrate}k']);
        break;
      case 'flac':
        args.addAll(['-c:a', 'flac', '-compression_level', settings.compressionLevel.toString()]);
        break;
      case 'wav':
        args.addAll(['-c:a', 'pcm_s16le']);
        break;
    }

    // Frecuencia de muestreo
    args.addAll(['-ar', settings.sampleRate.toString()]);

    // Canales
    if (settings.channels == 'mono') {
      args.addAll(['-ac', '1']);
    } else if (settings.channels == 'stereo') {
      args.addAll(['-ac', '2']);
    } // 5.1 y 7.1 requerirían filtros complejos, se omiten en v1.0

    // Normalización (simple: peak)
    if (settings.normalize) {
      args.addAll(['-af', 'volume=${settings.normalizeTarget}dB']);
    }

    // Reducción de ruido (solo si IA activa)
    if (settings.removeNoise && settings.aiEnabled) {
      // Placeholder: usar filtro afftdn de FFmpeg
      args.addAll(['-af', 'afftdn']);
    }

    // Sobrescribir
    args.add('-y');
    args.add(outputPath);

    try {
      final success = await _ffmpeg.executeCommandWithArgs(args);
      _progress = 1.0;
      _statusMessage = success ? "Completado" : "Error";
      return success;
    } catch (e) {
      _statusMessage = "Error: $e";
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void cancelProcessing() {
    _ffmpeg.cancel();
    _isProcessing = false;
    _statusMessage = "Cancelado";
    notifyListeners();
  }
}