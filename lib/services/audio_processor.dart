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

  Future<bool> processAudio({
    required String inputPath,
    required String outputPath,
    required AudioSettings settings,
  }) async {
    _isProcessing = true;
    _progress = 0.0;
    _statusMessage = "Procesando audio...";
    notifyListeners();

    final List<String> args = [
      '-i', inputPath,
    ];

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

    args.addAll(['-ar', settings.sampleRate.toString()]);

    if (settings.channels == 'mono') {
      args.addAll(['-ac', '1']);
    } else if (settings.channels == 'stereo') {
      args.addAll(['-ac', '2']);
    }

    if (settings.normalize) {
      args.addAll(['-af', 'volume=${settings.normalizeTarget}dB']);
    }

    if (settings.removeNoise && settings.aiEnabled) {
      args.addAll(['-af', 'afftdn']);
    }

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