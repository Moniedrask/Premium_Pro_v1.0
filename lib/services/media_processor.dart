import 'dart:async';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:ffmpeg_kit_flutter/statistics.dart';
import 'package:flutter/foundation.dart';

/// Gestor principal de procesamiento multimedia
/// Diseñado para estabilidad en dispositivos con <4GB RAM
class MediaProcessor extends ChangeNotifier {
  bool _isProcessing = false;
  double _progress = 0.0;
  String _statusMessage = "Listo";
  bool _aiEnabled = false;
  String? _lastError;
  DateTime? _startTime;
  DateTime? _endTime;

  // Getters
  bool get isProcessing => _isProcessing;
  double get progress => _progress;
  String get statusMessage => _statusMessage;
  bool get aiEnabled => _aiEnabled;
  String? get lastError => _lastError;
  Duration? get processingTime => 
      (_startTime != null && _endTime != null) 
          ? _endTime!.difference(_startTime!) 
          : null;

  /// Alternar estado de IA
  void toggleAI(bool value) {
    _aiEnabled = value;
    notifyListeners();
  }

  /// Procesar video usando FFmpeg
  Future<bool> processVideo({
    required String inputPath,
    required String outputPath,
    String codec = 'libx264',
    int bitrate = 2500,
    String preset = 'medium',
    int crf = 23,
  }) async {
    if (_isProcessing) {
      _lastError = "Ya hay un proceso en ejecución";
      notifyListeners();
      return false;
    }
    _isProcessing = true;
    _progress = 0.0;
    _statusMessage = "Iniciando motor de renderizado...";
    _lastError = null;
    _startTime = DateTime.now();
    _endTime = null;
    notifyListeners();

    // Construir comando FFmpeg seguro
    String command = _buildFFmpegCommand(
      inputPath: inputPath,
      outputPath: outputPath,
      codec: codec,
      bitrate: bitrate,
      preset: preset,
      crf: crf,
    );

    debugPrint('🎬 Comando FFmpeg: $command');

    try {
      // Ejecutar FFmpeg con sesión completa
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      _endTime = DateTime.now();

      if (ReturnCode.isSuccess(returnCode)) {
        _statusMessage = "✅ Exportación completada con éxito";
        _progress = 1.0;
        debugPrint('✅ Procesamiento completado en ${processingTime?.inSeconds}s');
        notifyListeners();
        return true;
      } else if (ReturnCode.isCancel(returnCode)) {
        _statusMessage = "❌ Proceso cancelado por el usuario";
        _lastError = "Cancelado";
        debugPrint('❌ Proceso cancelado');
        notifyListeners();
        return false;
      } else {
        _statusMessage = "❌ Error en el procesamiento";
        _lastError = await session.getOutput();
        debugPrint('❌ Error FFmpeg: ${_lastError}');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isProcessing = false;
      _endTime = DateTime.now();
      _statusMessage = "❌ Error crítico: $e";      _lastError = e.toString();
      debugPrint('❌ Excepción: $e');
      notifyListeners();
      return false;
    }
  }

  /// Construir comando FFmpeg seguro y validado
  String _buildFFmpegCommand({
    required String inputPath,
    required String outputPath,
    required String codec,
    required int bitrate,
    required String preset,
    required int crf,
  }) {
    // Sanitizar rutas para evitar inyección de comandos
    final safeInput = _sanitizePath(inputPath);
    final safeOutput = _sanitizePath(outputPath);

    final StringBuffer cmd = StringBuffer();
    
    // Entrada
    cmd.write('-i "$safeInput"');
    
    // Video
    cmd.write(' -c:v $codec');
    
    if (codec == 'libx264' || codec == 'libx265') {
      cmd.write(' -preset $preset');
      cmd.write(' -crf $crf');
    } else {
      cmd.write(' -b:v ${bitrate}k');
    }
    
    // Audio (AAC por defecto)
    cmd.write(' -c:a aac -b:a 128k');
    
    // Optimizaciones
    cmd.write(' -movflags +faststart'); // Streaming web
    cmd.write(' -y'); // Sobrescribir sin preguntar
    
    // Salida
    cmd.write(' "$safeOutput"');
    
    return cmd.toString();
  }

  /// Limpiar ruta para evitar inyección de comandos
  String _sanitizePath(String path) {    // Eliminar caracteres peligrosos
    return path.replaceAll(RegExp(r'[;&|`$\\]'), '');
  }

  /// Cancelar proceso actual
  Future<void> cancel() async {
    if (_isProcessing) {
      await FFmpegKit.cancel();
      _statusMessage = "Proceso cancelado";
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Obtener estadísticas de procesamiento
  Map<String, dynamic> getStats() {
    return {
      'isProcessing': _isProcessing,
      'progress': _progress,
      'statusMessage': _statusMessage,
      'processingTime': processingTime?.inSeconds ?? 0,
      'aiEnabled': _aiEnabled,
    };
  }
}
