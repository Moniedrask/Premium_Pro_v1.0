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
    List<double>? equalizerGains,
    Map<String, double>? compressorParams,
    Duration? fadeIn,
    Duration? fadeOut,
  }) async {
    _isProcessing = true;
    _progress = 0.0;
    _statusMessage = "Procesando audio...";
    notifyListeners();

    final List<String> args = [
      '-i', inputPath,
    ];

    // Construir lista de filtros de audio
    List<String> audioFilters = [];

    // Ecualizador paramétrico de 10 bandas
    if (equalizerGains != null && equalizerGains.length == 10) {
      const freqs = [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];
      const q = 1.0;
      String eqCommand = '';
      for (int i = 0; i < 10; i++) {
        if (equalizerGains[i] != 0) {
          eqCommand += 'equalizer=f=${freqs[i]}:width_type=q:width=$q:g=${equalizerGains[i]},';
        }
      }
      if (eqCommand.isNotEmpty) {
        audioFilters.add(eqCommand.substring(0, eqCommand.length - 1));
      }
    }

    // Compresor dinámico
    if (compressorParams != null) {
      final threshold = compressorParams['threshold'] ?? -20;
      final ratio = compressorParams['ratio'] ?? 4;
      final attack = compressorParams['attack'] ?? 5;
      final release = compressorParams['release'] ?? 50;
      final knee = compressorParams['knee'] ?? 0;
      audioFilters.add('acompressor=threshold=${threshold}dB:ratio=$ratio:attack=${attack}ms:release=${release}ms:knee=$knee');
    }

    // Normalización
    if (settings.normalize) {
      audioFilters.add('volume=${settings.normalizeTarget}dB');
    }

    // Reducción de ruido con IA
    if (settings.removeNoise && settings.aiEnabled) {
      audioFilters.add('afftdn');
    }

    // Fade in/out
    if (fadeIn != null && fadeIn.inMilliseconds > 0) {
      audioFilters.add('afade=t=in:st=0:d=${fadeIn.inMilliseconds / 1000}');
    }
    if (fadeOut != null && fadeOut.inMilliseconds > 0) {
      // Nota: para fade out se necesita la duración total del audio.
      // Aquí se omite por simplicidad; se podría pasar como parámetro adicional.
      // audioFilters.add('afade=t=out:st=${totalDuration - fadeOut.inMilliseconds / 1000}:d=${fadeOut.inMilliseconds / 1000}');
    }

    // Aplicar todos los filtros de una vez
    if (audioFilters.isNotEmpty) {
      args.addAll(['-af', audioFilters.join(',')]);
    }

    // Configuración del códec de audio
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

    // Configuración de canales
    if (settings.channels == 'mono') {
      args.addAll(['-ac', '1']);
    } else if (settings.channels == 'stereo') {
      args.addAll(['-ac', '2']);
    } else if (settings.channels == '5.1') {
      args.addAll(['-ac', '6']);
    } else if (settings.channels == '7.1') {
      args.addAll(['-ac', '8']);
    }

    // Sobrescribir sin preguntar
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