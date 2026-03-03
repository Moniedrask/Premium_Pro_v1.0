import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

  // Stub para evitar crash en UI
  Future<void> downloadModel(String modelName, BuildContext context) async {
    // Mostrar un mensaje informativo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Descarga de modelos no disponible en esta versión.'),
        backgroundColor: Colors.orange,
      ),
    );
    debugPrint('Descarga de modelo no implementada en v1.0');
  }
}