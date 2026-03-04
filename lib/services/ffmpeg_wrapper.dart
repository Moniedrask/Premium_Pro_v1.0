import 'dart:async';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter/statistics.dart';
import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';
import 'package:flutter/foundation.dart';

class FFmpegWrapper {
  static final FFmpegWrapper _instance = FFmpegWrapper._internal();
  factory FFmpegWrapper() => _instance;
  FFmpegWrapper._internal();

  bool _isProcessing = false;
  double _progress = 0.0;
  String _statusMessage = "Listo";
  dynamic _currentSession;

  bool get isProcessing => _isProcessing;
  double get progress => _progress;
  String get statusMessage => _statusMessage;

  Future<void> init() async {
    await FFmpegKitConfig.enableLogs();
    debugPrint('✅ FFmpeg Wrapper inicializado');
  }

  /// Obtiene la duración de un video en microsegundos usando FFprobe
  Future<int?> getVideoDuration(String path) async {
    try {
      final session = await FFprobeKit.getMediaInformation(path);
      final information = await session.getMediaInformation();
      if (information != null) {
        final durationStr = information.getDuration();
        if (durationStr != null && durationStr.isNotEmpty) {
          final durationSec = double.tryParse(durationStr);
          if (durationSec != null && durationSec > 0) {
            return (durationSec * 1000000).round();
          }
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

    const int defaultDurationMicros = 60 * 1000000;
    final effectiveDuration = totalDurationMicros ?? defaultDurationMicros;

    if (totalDurationMicros == null) {
      debugPrint('⚠️ No se pudo obtener la duración real del video. Se usará un progreso aproximado basado en 60 segundos.');
    }

    List<String> arguments = [
      '-i', inputPath,
      '-c:v', codec,
      '-preset', preset,
      '-crf', crf.toString(),
      '-b:v', '${bitrate}k',
      '-c:a', 'aac',
      '-movflags', '+faststart',
      '-y', outputPath,
    ];

    try {
      debugPrint('⚙️ Comando FFmpeg: ffmpeg ${arguments.join(' ')}');

      final completer = Completer<bool>();

      // ✅ Usar parámetros con nombre para los callbacks
      _currentSession = await FFmpegKit.executeWithArguments(
        arguments,
        completeCallback: (session) {
          session.getReturnCode().then((returnCode) {
            final success = ReturnCode.isSuccess(returnCode);
            if (success) {
              _statusMessage = "✅ Completado";
              _progress = 1.0;
              onProgress?.call(1.0);
              debugPrint('✅ Procesamiento exitoso: $outputPath');
            } else {
              _statusMessage = "❌ Error en procesamiento";
              session.getOutput().then((output) {
                debugPrint('❌ Error FFmpeg: $output');
              });
            }
            _isProcessing = false;
            _currentSession = null;
            completer.complete(success);
          }).catchError((error) {
            _isProcessing = false;
            _currentSession = null;
            completer.complete(false);
          });
        },
        logCallback: (log) {
          debugPrint('📝 FFmpeg log: ${log.getMessage()}');
          onLog?.call(log.getMessage());
        },
        statisticsCallback: (statistics) {
          final time = statistics.getTime();
          if (time > 0) {
            double progress = time / effectiveDuration;
            if (progress > 1.0) progress = 1.0;
            _progress = progress;
            onProgress?.call(_progress);
          }
        },
      );

      return await completer.future;
    } catch (e) {
      _isProcessing = false;
      _currentSession = null;
      _statusMessage = "❌ Error: $e";
      debugPrint('❌ Excepción: $e');
      return false;
    }
  }

  Future<bool> executeCommandWithArgs(List<String> arguments) async {
    try {
      final session = await FFmpegKit.executeWithArguments(arguments);
      final returnCode = await session.getReturnCode();
      return ReturnCode.isSuccess(returnCode);
    } catch (e) {
      debugPrint('❌ Error en comando con args: $e');
      return false;
    }
  }

  void cancel() {
    _currentSession?.cancel();
    _isProcessing = false;
    _currentSession = null;
    _statusMessage = "Cancelado";
    debugPrint('⛔ Procesamiento cancelado por el usuario');
  }

  Future<bool> executeCommand(String command) async {
    try {
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      return ReturnCode.isSuccess(returnCode);
    } catch (e) {
      debugPrint('❌ Error en comando personalizado: $e');
      return false;
    }
  }

  Future<List<String>> getAvailableCodecs() async {
    try {
      final session = await FFmpegKit.execute('-codecs');
      final output = await session.getOutput() ?? '';
      return output.split('\n')
          .where((line) => line.contains('V') && line.contains('DEV'))
          .map((line) => line.split(' ').last.trim())
          .toList();
    } catch (e) {
      debugPrint('❌ Error al obtener códecs: $e');
      return [];
    }
  }
}