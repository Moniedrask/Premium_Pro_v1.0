import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;  // dependencia opcional
import 'ffmpeg_wrapper.dart';
import '../models/image_settings.dart';

class ImageProcessor extends ChangeNotifier {
  final FFmpegWrapper _ffmpeg = FFmpegWrapper();
  bool _isProcessing = false;
  double _progress = 0.0;
  String _statusMessage = "Listo";

  bool get isProcessing => _isProcessing;
  double get progress => _progress;
  String get statusMessage => _statusMessage;

  /// Procesa imagen usando FFmpeg (para formato/calidad/redimensionado)
  Future<bool> processImage({
    required String inputPath,
    required String outputPath,
    required ImageSettings settings,
  }) async {
    _isProcessing = true;
    _progress = 0.0;
    _statusMessage = "Procesando imagen...";
    notifyListeners();

    // Si hay ajustes de brillo/contraste/saturación, usar el paquete image
    // (simplificado: solo redimensionado y cambio de formato por ahora)
    final success = await _ffmpeg.processImage(
      inputPath: inputPath,
      outputPath: outputPath,
      settings: settings,
      onProgress: (progress) {
        _progress = progress;
        _statusMessage = "Procesando ${(progress * 100).toStringAsFixed(0)}%";
        notifyListeners();
      },
    );

    _isProcessing = false;
    _statusMessage = success ? "Completado" : "Error";
    notifyListeners();
    return success;
  }

  void cancel() {
    _ffmpeg.cancel();
    _isProcessing = false;
    _statusMessage = "Cancelado";
    notifyListeners();
  }
}