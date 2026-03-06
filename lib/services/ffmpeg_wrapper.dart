import 'dart:async';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
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
  }

  /// Obtiene la duración de un video en microsegundos usando FFprobe
  /// La duración viene en formato String: "HH:MM:SS.microseconds" [citation:2]
  Future<int?> getVideoDuration(String path) async {
    try {
      final info = await _flutterFFprobe.getMediaInformation(path);
      if (info != null) {
        // Obtener el mapa de propiedades [citation:3]
        final properties = info.getMediaProperties();
        final durationStr = properties?['duration'] as String?;
        
        if (durationStr != null && durationStr.isNotEmpty) {
          // Parsear duración desde formato "HH:MM:SS.micros" a microsegundos
          return _parseDurationToMicros(durationStr);
        }
      }
    } catch (e) {
      debugPrint('❌ Error obteniendo duración del video: $e');
    }
    return null;
  }

  /// Parsea duración en formato "HH:MM:SS.micros" a microsegundos [citation:3]
  int _parseDurationToMicros(String durationStr) {
    int hours = 0;
    int minutes = 0;
    double seconds = 0.0;
    
    List<String> parts = durationStr.split(':');
    if (parts.length == 3) {
      hours = int.parse(parts[0]);
      minutes = int.parse(parts[1]);
      seconds = double.parse(parts[2]);
    } else if (parts.length == 2) {
      minutes = int.parse(parts[0]);
      seconds = double.parse(parts[1]);
    } else {
      seconds = double.parse(durationStr);
    }
    
    return ((hours * 3600 + minutes * 60 + seconds) * 1000000).round();
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

      // ✅ API CORRECTA: executeWithArguments acepta 1 argumento (List<String>) y devuelve Future<int>
      _currentExecutionId = await _flutterFFmpeg.executeWithArguments(
        command.split(' '),
      ).then((returnCode) {
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
        return null; // Para evitar warning
      }).catchError((error) {
        _isProcessing = false;
        _currentExecutionId = null;
        _statusMessage = "❌ Error: $error";
        debugPrint('❌ Excepción: $error');
        completer.complete(false);
      });

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