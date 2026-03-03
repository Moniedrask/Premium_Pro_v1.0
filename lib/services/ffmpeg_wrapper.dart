import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:ffmpeg_kit_flutter/statistics.dart';
import 'package:flutter/foundation.dart';

class FFmpegWrapper {
  static final FFmpegWrapper _instance = FFmpegWrapper._internal();
  factory FFmpegWrapper() => _instance;
  FFmpegWrapper._internal();

  bool _isProcessing = false;
  double _progress = 0.0;
  String _statusMessage = "Listo";
  FFmpegSession? _currentSession;

  bool get isProcessing => _isProcessing;
  double get progress => _progress;
  String get statusMessage => _statusMessage;

  Future<void> init() async {
    // No es necesario habilitar logs explícitamente, pero se puede
    debugPrint('✅ FFmpeg Wrapper inicializado');
  }

  Future<bool> processVideo({
    required String inputPath,
    required String outputPath,
    String codec = 'libx264',
    int bitrate = 2500,
    String preset = 'medium',
    int crf = 23,
    int videoDurationMs = 60000, // Duración estimada para progreso
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

    // Lista de argumentos (segura contra espacios)
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

      _currentSession = await FFmpegKit.executeWithArguments(
        arguments,
        (session) async {
          final returnCode = await session.getReturnCode();
          if (ReturnCode.isSuccess(returnCode)) {
            _statusMessage = "✅ Completado";
            _progress = 1.0;
            onProgress?.call(1.0);
            debugPrint('✅ Procesamiento exitoso: $outputPath');
          } else {
            _statusMessage = "❌ Error en procesamiento";
            final output = await session.getOutput();
            debugPrint('❌ Error FFmpeg: $output');
          }
          _isProcessing = false;
          _currentSession = null;
        },
        (log) {
          debugPrint('📝 FFmpeg log: ${log.getMessage()}');
          onLog?.call(log.getMessage());
        },
        (statistics) {
          // Calcular progreso basado en el tiempo procesado
          final time = statistics.getTime(); // en microsegundos
          if (time > 0 && videoDurationMs > 0) {
            // Convertir microsegundos a milisegundos y estimar
            double estimated = time / 1000.0 / videoDurationMs;
            if (estimated > 1.0) estimated = 1.0;
            _progress = estimated;
            onProgress?.call(_progress);
          }
        },
      );

      await _currentSession?.await();
      return true; // El resultado real se maneja en el callback
    } catch (e) {
      _isProcessing = false;
      _currentSession = null;
      _statusMessage = "❌ Error: $e";
      debugPrint('❌ Excepción: $e');
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
      // Filtrar líneas que contengan 'V' (video) y 'DEV' (codificadores)
      return output.split('\n')
          .where((line) => line.contains('V') && line.contains('DEV'))
          .map((line) {
            // Extraer el nombre del códec (última columna)
            final parts = line.split(RegExp(r'\s+'));
            return parts.isNotEmpty ? parts.last : '';
          })
          .where((name) => name.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('❌ Error al obtener códecs: $e');
      return [];
    }
  }
}