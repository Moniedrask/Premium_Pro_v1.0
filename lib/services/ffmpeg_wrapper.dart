import 'dart:async';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';
import 'package:flutter/foundation.dart';

class FFmpegWrapper {
  static final FFmpegWrapper _instance = FFmpegWrapper._internal();
  factory FFmpegWrapper() => _instance;
  FFmpegWrapper._internal();

  bool _isProcessing = false;
  String _statusMessage = "Listo";
  dynamic _currentSession; // Cambiado de FFmpegSession? a dynamic

  bool get isProcessing => _isProcessing;
  String get statusMessage => _statusMessage;

  Future<void> init() async {
    debugPrint('✅ FFmpeg Wrapper inicializado');
  }

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
      debugPrint('❌ Error obteniendo duración: $e');
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
  }) async {
    if (_isProcessing) {
      debugPrint('❌ Ya hay un procesamiento en curso');
      return false;
    }

    _isProcessing = true;
    _statusMessage = "Procesando...";

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
      debugPrint('⚙️ Comando: ffmpeg ${arguments.join(' ')}');

      final session = await FFmpegKit.executeWithArguments(arguments);
      _currentSession = session;

      final returnCode = await session.getReturnCode();
      final success = ReturnCode.isSuccess(returnCode);

      if (success) {
        _statusMessage = "✅ Completado";
        debugPrint('✅ Procesamiento exitoso: $outputPath');
      } else {
        _statusMessage = "❌ Error";
        final output = await session.getOutput();
        debugPrint('❌ Error FFmpeg: $output');
      }

      _isProcessing = false;
      _currentSession = null;
      return success;
    } catch (e) {
      _isProcessing = false;
      _currentSession = null;
      _statusMessage = "❌ Error: $e";
      debugPrint('❌ Excepción: $e');
      return false;
    }
  }

  /// Método genérico para ejecutar cualquier comando FFmpeg con argumentos.
  /// Utilizado por [AudioProcessor] y [ImageProcessor].
  Future<bool> executeCommandWithArgs(List<String> args) async {
    if (_isProcessing) {
      debugPrint('❌ Ya hay un procesamiento en curso');
      return false;
    }

    _isProcessing = true;
    _statusMessage = "Procesando...";

    try {
      debugPrint('⚙️ Comando: ffmpeg ${args.join(' ')}');

      final session = await FFmpegKit.executeWithArguments(args);
      _currentSession = session;

      final returnCode = await session.getReturnCode();
      final success = ReturnCode.isSuccess(returnCode);

      if (success) {
        _statusMessage = "✅ Completado";
        debugPrint('✅ Procesamiento exitoso');
      } else {
        _statusMessage = "❌ Error";
        final output = await session.getOutput();
        debugPrint('❌ Error FFmpeg: $output');
      }

      _isProcessing = false;
      _currentSession = null;
      return success;
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
    debugPrint('⛔ Procesamiento cancelado');
  }
}