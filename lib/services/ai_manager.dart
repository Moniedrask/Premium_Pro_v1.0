import 'package:flutter/foundation.dart';

class AIManager extends ChangeNotifier {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _isModelAvailable = false;

  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  bool get isModelAvailable => _isModelAvailable;

  void toggleAI(bool value) {
    // No implementado en v1.0
    notifyListeners();
  }

  // Método stub para evitar crash en UI
  Future<void> downloadModel(String modelName) async {
    debugPrint('Descarga de modelo no implementada en v1.0');
    // En el futuro, aquí se implementará la descarga real.
  }
}