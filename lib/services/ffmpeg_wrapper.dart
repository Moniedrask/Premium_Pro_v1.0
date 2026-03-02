// ==================== WRAPPER DE FFMPEG - CAPA DE ABSTRACCIÓN ====================
// Permite cambiar entre implementaciones sin modificar el resto del código

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:flutter/foundation.dart';

class FFmpegWrapper {
  static final FFmpegWrapper _instance = FFmpegWrapper._internal();
  factory FFmpegWrapper() => _instance;
  FFmpegWrapper._internal();

  bool _isProcessing = false;
  double _progress = 0.0;
  String _statusMessage = "Listo";

  bool get isProcessing => _isProcessing;
  double get progress => _progress;
  String get statusMessage => _statusMessage;

  // ==================== INICIALIZACIÓN ====================
  Future<void> init() async {
    await FFmpegKitConfig.enableLogs();
    debugPrint('✅ FFmpeg Wrapper inicializado');
  }

  // ==================== PROCESAMIENTO DE VIDEO ====================
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
    _progress = 0.0;
    _statusMessage = "Iniciando...";
    debugPrint('📹 Iniciando procesamiento: $inputPath');

    String command = '-i "$inputPath" -c:v $codec -preset $preset -crf $crf -c:a aac -movflags +faststart -y "$outputPath"';

    try {
      debugPrint('⚙️ Comando FFmpeg: $command');
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        _statusMessage = "✅ Completado";
        _progress = 1.0;
        debugPrint('✅ Procesamiento exitoso: $outputPath');
        return true;
      } else {
        _statusMessage = "❌ Error en procesamiento";
        debugPrint('❌ Error FFmpeg: ${await session.getOutput()}');
        return false;
      }
    } catch (e) {
      _isProcessing = false;
      _statusMessage = "❌ Error: $e";
      debugPrint('❌ Excepción: $e');
      return false;
    } finally {
      _isProcessing = false;
    }
  }

  // ==================== COMANDOS PERSONALIZADOS ====================
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

  // ==================== VERIFICAR CÓDECS DISPONIBLES ====================
  Future<List<String>> getAvailableCodecs() async {
    try {
      final session = await FFmpegKit.execute('-codecs');
      final output = await session.getOutput();
      // ✅ CORREGIDO: Null safety con ?? para string vacío
      return (output ?? '').split('\n').where((line) => line.contains('V.....')).map((e) => e.trim()).toList();
    } catch (e) {
      debugPrint('❌ Error al obtener códecs: $e');
      return [];
    }
  }
}