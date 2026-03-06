import 'dart:async';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:flutter_ffmpeg/flutter_ffprobe.dart';
import 'package:flutter/foundation.dart';

class FFmpegWrapper {
  static final FFmpegWrapper _instance = FFmpegWrapper._internal();
  factory FFmpegWrapper() => _instance;
  FFmpegWrapper._internal();

  final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();
  final FlutterFFprobe _flutterFFprobe = FlutterFFprobe();

  bool _isProcessing = false;
  double _progress = 0.0;
  String _statusMessage = "Listo";
  int? _currentExecutionId;

  bool get isProcessing => _isProcessing;
  double get progress => _progress;
  String get statusMessage => _statusMessage;

  Future<void> init() async {
    debugPrint('✅ FlutterFFmpeg inicializado');
    // No se requiere configuración adicional
  }

  /// Obtiene la duración de un video en microsegundos usando FFprobe
  Future<int?> getVideoDuration(String path) async {
    try {
      final info = await _flutterFFprobe.getMediaInformation(path);
      if (info != null) {
        // La duración viene en segundos (double)
        final durationSec = info.getDuration();
        if (durationSec != null && durationSec > 0) {
          return (durationSec * 1000000).round();
        }
      }
    } catch (e) {
      debugPrint('❌ Error obteniendo duración del video: $e');
    }
    return null;
  }

  Future<bool> processVideo({
    required String inputPath,
    required String outputPath,
    String codec = 'libx264',
    int bitrate = 2500,
    String preset = 'medium',
    int crf = 23,
    int? totalDurationMicros,
    Function(double progress)? onProgress,
    Function(String log)? onLog,
  }) async {
    if (_isProcessing) {
      debugPrint('❌ Ya hay un procesamiento en curso');
      return false;
    }

    _isProcessing = true;
    _progress = 0.0;
    _statusMessage = "Iniciando...";

    // Construir comando FFmpeg
    String command = '-i "$inputPath" -c:v $codec -preset $preset -crf $crf -b:v ${bitrate}k -c:a aac -movflags +faststart -y "$outputPath"';

    try {
      debugPrint('⚙️ Comando FFmpeg: $command');

      final completer = Completer<bool>();

      // Ejecutar comando con callbacks
      _currentExecutionId = await _flutterFFmpeg.executeWithArguments(
        command.split(' '),
        (executionId, returnCode) {
          final success = returnCode == 0;
          if (success) {
            _statusMessage = "✅ Completado";
            _progress = 1.0;
            onProgress?.call(1.0);
            debugPrint('✅ Procesamiento exitoso: $outputPath');
          } else {
            _statusMessage = "❌ Error en procesamiento";
            debugPrint('❌ Error FFmpeg, código: $returnCode');
          }
          _isProcessing = false;
          _currentExecutionId = null;
          completer.complete(success);
        },
        (executionId, log) {
          debugPrint('📝 FFmpeg log: $log');
          onLog?.call(log);
        },
        (executionId, statistics) {
          // Extraer tiempo procesado (puede variar según la compilación)
          final timeMatch = RegExp(r'time=(\d+\.?\d*)').firstMatch(statistics);
          if (timeMatch != null) {
            final timeSec = double.tryParse(timeMatch.group(1) ?? '0');
            if (timeSec != null && timeSec > 0 && totalDurationMicros != null) {
              double progress = (timeSec * 1000000) / totalDurationMicros;
              if (progress > 1.0) progress = 1.0;
              _progress = progress;
              onProgress?.call(_progress);
            }
          }
        },
      );

      return await completer.future;
    } catch (e) {
      _isProcessing = false;
      _currentExecutionId = null;
      _statusMessage = "❌ Error: $e";
      debugPrint('❌ Excepción: $e');
      return false;
    }
  }

  Future<bool> executeCommandWithArgs(List<String> arguments) async {
    try {
      final rc = await _flutterFFmpeg.executeWithArguments(arguments);
      return rc == 0;
    } catch (e) {
      debugPrint('❌ Error en comando con args: $e');
      return false;
    }
  }

  void cancel() {
    if (_currentExecutionId != null) {
      _flutterFFmpeg.cancel();
      _isProcessing = false;
      _currentExecutionId = null;
      _statusMessage = "Cancelado";
      debugPrint('⛔ Procesamiento cancelado por el usuario');
    }
  }

  Future<bool> executeCommand(String command) async {
    try {
      final rc = await _flutterFFmpeg.execute(command);
      return rc == 0;
    } catch (e) {
      debugPrint('❌ Error en comando personalizado: $e');
      return false;
    }
  }

  Future<List<String>> getAvailableCodecs() async {
    // flutter_ffmpeg no tiene un método directo para listar códecs,
    // devolvemos una lista predefinida de códecs comunes
    return [
      'libx264',
      'libx265',
      'libvpx-vp9',
      'aac',
      'mp3',
      'opus',
      'flac',
    ];
  }
}