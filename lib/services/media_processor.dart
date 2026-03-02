import 
'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';

class MediaProcessor extends ChangeNotifier {
  bool _isProcessing = false;
  double _progress = 0.0;
  String _statusMessage = "Listo";

  bool get isProcessing => _isProcessing;
  double get progress => _progress;
  String get statusMessage => _statusMessage;

  Future<bool> processVideo({
    required String inputPath,
    required String outputPath,
    String codec = 'libx264',
    int bitrate = 2500,
    String preset = 'medium',
    int crf = 23,
  }) async {
    if (_isProcessing) return false;

    _isProcessing = true;
    _progress = 0.0;
    _statusMessage = "Iniciando...";
    notifyListeners();

    String command = '-i "$inputPath" -c:v $codec -preset $preset -crf $crf -c:a aac -movflags +faststart -y "$outputPath"';

    try {
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        _statusMessage = "Completado";
        _progress = 1.0;
        notifyListeners();
        return true;
      } else {
        _statusMessage = "Error en procesamiento";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isProcessing = false;
      _statusMessage = "Error: $e";
      notifyListeners();
      return false;
    }
  }
}
