import 'package:flutter/foundation.dart';

class AIManager extends ChangeNotifier {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _isModelAvailable = false;

  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  bool get isModelAvailable => _isModelAvailable;

  void toggleAI(bool value) {
    notifyListeners();
  }
}
