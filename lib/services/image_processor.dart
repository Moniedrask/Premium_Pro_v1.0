import 'package:flutter/foundation.dart';
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

  Future<void> init() async {
    await _ffmpeg.init();
  }

  Future<bool> processImage({
    required String inputPath,
    required String outputPath,
    required ImageSettings settings,
  }) async {
    _isProcessing = true;
    _progress = 0.0;
    _statusMessage = "Procesando imagen...";
    notifyListeners();

    final List<String> args = [
      '-i', inputPath,
    ];

    // Escalado con interpolación correcta de strings
    if (settings.maxWidth > 0 || settings.maxHeight > 0) {
      String scale;
      if (settings.maxWidth > 0 && settings.maxHeight > 0) {
        scale = 'scale=${settings.maxWidth}:${settings.maxHeight}';
      } else if (settings.maxWidth > 0) {
        scale = 'scale=${settings.maxWidth}:-1';
      } else {
        scale = 'scale=-1:${settings.maxHeight}';
      }
      String swsFlags;
      switch (settings.filter) {
        case 'lanczos':
          swsFlags = 'lanczos';
          break;
        case 'bicubic':
          swsFlags = 'bicubic';
          break;
        default:
          swsFlags = 'fast_bilinear';
      }
      args.addAll(['-vf', '$scale:flags=$swsFlags']);
    }

    // Formato y calidad
    switch (settings.format) {
      case 'jpeg':
        args.addAll(['-c:v', 'mjpeg', '-q:v', settings.quality.toString()]);
        break;
      case 'png':
        args.addAll(['-c:v', 'png', '-compression_level', settings.compressionLevel.toString()]);
        break;
      case 'webp':
        args.addAll(['-c:v', 'libwebp', '-q:v', settings.quality.toString()]);
        break;
      case 'avif':
        args.addAll(['-c:v', 'libaom-av1', '-crf', settings.quality.toString()]);
        break;
    }

    // Metadatos
    if (!settings.preserveMetadata) {
      args.add('-map_metadata');
      args.add('-1');
    }

    // Upscale IA (placeholder)
    if (settings.aiUpscale && settings.aiEnabled) {
      debugPrint('⚠️ IA upscale no implementado, usando escalado estándar');
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

  void cancelProcessing() {
    _ffmpeg.cancel();
    _isProcessing = false;
    _statusMessage = "Cancelado";
    notifyListeners();
  }
}