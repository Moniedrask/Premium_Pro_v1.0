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

  // ── Pista única ────────────────────────────────────────────────────────
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

    List<String> audioFilters = [];

    // Ecualizador
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

    // Compresor
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

    // Reducción de ruido IA
    if (settings.removeNoise && settings.aiEnabled) {
      audioFilters.add('afftdn');
    }

    // Fade in/out
    if (fadeIn != null && fadeIn.inMilliseconds > 0) {
      audioFilters.add('afade=t=in:st=0:d=${fadeIn.inMilliseconds / 1000}');
    }
    if (fadeOut != null && fadeOut.inMilliseconds > 0) {
      // Nota: requiere duración total; aquí se omite
    }

    if (audioFilters.isNotEmpty) {
      args.addAll(['-af', audioFilters.join(',')]);
    }

    // Códec con profundidad de bits
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
        final sampleFmt = settings.bitDepth == 32 ? 's32' : (settings.bitDepth == 24 ? 's24' : 's16');
        args.addAll([
          '-c:a', 'flac',
          '-compression_level', settings.compressionLevel.toString(),
          '-sample_fmt', sampleFmt,
        ]);
        break;
      case 'wav':
        final codec = settings.bitDepth == 32 ? 'pcm_f32le' :
                      settings.bitDepth == 24 ? 'pcm_s24le' : 'pcm_s16le';
        args.addAll(['-c:a', codec]);
        break;
    }

    args.addAll(['-ar', settings.sampleRate.toString()]);

    if (settings.channels == 'mono') {
      args.addAll(['-ac', '1']);
    } else if (settings.channels == 'stereo') {
      args.addAll(['-ac', '2']);
    } else if (settings.channels == '5.1') {
      args.addAll(['-ac', '6']);
    } else if (settings.channels == '7.1') {
      args.addAll(['-ac', '8']);
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

  // ── Multipista ─────────────────────────────────────────────────────────
  ///
  /// Mezcla y exporta varias pistas de audio.
  ///
  /// [tracks] — lista de mapas con las claves:
  ///   - 'path'     (String)  ruta al archivo de audio
  ///   - 'volume'   (double)  ganancia (0.0-2.0, 1.0 = sin cambio)
  ///   - 'offsetMs' (int)     retraso en ms desde el inicio del proyecto
  ///
  /// Si la lista tiene un solo elemento se redirige a [processAudio] normal.
  Future<bool> processMultitrack({
    required List<Map<String, dynamic>> tracks,
    required String outputPath,
    required AudioSettings settings,
  }) async {
    if (tracks.isEmpty) return false;

    // Pista única → flujo normal sin overhead
    if (tracks.length == 1) {
      return processAudio(
        inputPath: tracks[0]['path'] as String,
        outputPath: outputPath,
        settings: settings,
      );
    }

    _isProcessing = true;
    _progress = 0.0;
    _statusMessage = "Mezclando ${tracks.length} pistas...";
    notifyListeners();

    // Construir argumentos de entrada
    final List<String> args = [];
    for (final t in tracks) {
      args.addAll(['-i', t['path'] as String]);
    }

    // filter_complex: adelay + volume por pista, luego amix
    // Formato de adelay: 'delayMs|delayMs' (un valor por canal: L|R)
    final StringBuffer fc = StringBuffer();
    final List<String> labels = [];
    for (int i = 0; i < tracks.length; i++) {
      final int offsetMs = (tracks[i]['offsetMs'] as int?) ?? 0;
      final double volume = (tracks[i]['volume'] as double?) ?? 1.0;
      final label = '[a$i]';
      // adelay con offset, volume para ganancia
      fc.write('[$i:a]adelay=${offsetMs}|${offsetMs},volume=${volume.toStringAsFixed(3)}$label;');
      labels.add(label);
    }
    // amix: normalize=0 para no dividir por número de entradas automáticamente
    fc.write('${labels.join('')}amix=inputs=${tracks.length}:duration=longest:normalize=0[out]');

    args.addAll(['-filter_complex', fc.toString(), '-map', '[out]']);

    // Códec de salida
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
        final sampleFmt = settings.bitDepth == 32 ? 's32' : (settings.bitDepth == 24 ? 's24' : 's16');
        args.addAll(['-c:a', 'flac', '-compression_level', settings.compressionLevel.toString(), '-sample_fmt', sampleFmt]);
        break;
      case 'wav':
        final codec = settings.bitDepth == 32 ? 'pcm_f32le' :
                      settings.bitDepth == 24 ? 'pcm_s24le' : 'pcm_s16le';
        args.addAll(['-c:a', codec]);
        break;
    }

    args.addAll(['-ar', settings.sampleRate.toString()]);
    if (settings.channels == 'mono') {
      args.addAll(['-ac', '1']);
    } else if (settings.channels == 'stereo') {
      args.addAll(['-ac', '2']);
    }

    args.addAll(['-y', outputPath]);

    debugPrint('⚙️ Multipista FFmpeg args: ${args.join(' ')}');

    try {
      final success = await _ffmpeg.executeCommandWithArgs(args);
      _progress = 1.0;
      _statusMessage = success ? "Completado" : "Error";
      return success;
    } catch (e) {
      _statusMessage = "Error: $e";
      debugPrint('❌ processMultitrack: $e');
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