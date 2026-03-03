import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AIManager extends ChangeNotifier {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _isModelAvailable = false;
  String _modelPath = '';

  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  bool get isModelAvailable => _isModelAvailable;
  String get modelPath => _modelPath;

  /// Verifica si el modelo ya existe en almacenamiento
  Future<void> checkModel() async {
    final dir = await getApplicationDocumentsDirectory();
    final modelFile = File('${dir.path}/models/real-esrgan-x2.tflite');
    if (await modelFile.exists()) {
      _isModelAvailable = true;
      _modelPath = modelFile.path;
    } else {
      _isModelAvailable = false;
      _modelPath = '';
    }
    notifyListeners();
  }

  /// Descarga un modelo desde una URL (ejemplo)
  Future<void> downloadModel(String modelName) async {
    if (_isDownloading) return;

    _isDownloading = true;
    _downloadProgress = 0.0;
    notifyListeners();

    try {
      // URL de ejemplo (reemplazar con una real)
      final url = Uri.parse('https://example.com/models/$modelName.tflite');
      final request = http.Request('GET', url);
      final response = await request.send();

      if (response.statusCode != 200) {
        throw Exception('Error al descargar: ${response.statusCode}');
      }

      final dir = await getApplicationDocumentsDirectory();
      final modelDir = Directory('${dir.path}/models');
      if (!await modelDir.exists()) await modelDir.create(recursive: true);
      final file = File('${modelDir.path}/$modelName.tflite');
      final sink = file.openWrite();

      int bytesDownloaded = 0;
      final contentLength = response.contentLength ?? 0;

      await for (var chunk in response.stream) {
        sink.add(chunk);
        bytesDownloaded += chunk.length;
        if (contentLength > 0) {
          _downloadProgress = bytesDownloaded / contentLength;
          notifyListeners();
        }
      }
      await sink.flush();
      await sink.close();

      _isModelAvailable = true;
      _modelPath = file.path;
      _downloadProgress = 1.0;
    } catch (e) {
      debugPrint('Error descargando modelo: $e');
      _isModelAvailable = false;
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }

  void toggleAI(bool value) {
    // No implementado en v1.0
    notifyListeners();
  }
}