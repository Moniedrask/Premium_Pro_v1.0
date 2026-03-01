import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

/// Gestor de Inteligencia Artificial
/// Diseñado para funcionar SIN IA por defecto (fallback a algoritmos matemáticos)
class AIManager extends ChangeNotifier {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _isModelAvailable = false;
  String _currentModel = '';
  String _errorMessage = '';

  // Modelos disponibles (URLs verificadas)
  static const Map<String, AIModelInfo> availableModels = {
    'real-esrgan-x2': AIModelInfo(
      name: 'Real-ESRGAN 2x',
      description: 'Upscaling de imagen 2x',
      sizeMB: 67,
      type: AIModelType.upscaling,
      url: 'https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x2plus.pth',
    ),
  };

  // Getters
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  bool get isModelAvailable => _isModelAvailable;
  String get currentModel => _currentModel;
  String get errorMessage => _errorMessage;

  /// Obtener ruta de almacenamiento de modelos
  Future<String> getModelStoragePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final modelPath = Directory('${directory.path}/ai_models');
    
    if (!await modelPath.exists()) {
      await modelPath.create(recursive: true);
    }
    
    return modelPath.path;
  }

  /// Verificar si un modelo está descargado
  Future<bool> isModelDownloaded(String modelId) async {
    try {
      final storagePath = await getModelStoragePath();
      final modelFile = File('$storagePath/$modelId.bin');
      return await modelFile.exists();    } catch (e) {
      return false;
    }
  }

  /// Iniciar descarga de modelo IA
  Future<bool> downloadModel(String modelId) async {
    if (!availableModels.containsKey(modelId)) {
      _errorMessage = 'Modelo no encontrado: $modelId';
      notifyListeners();
      return false;
    }

    final modelInfo = availableModels[modelId]!;
    
    _isDownloading = true;
    _downloadProgress = 0.0;
    _errorMessage = '';
    notifyListeners();

    try {
      final storagePath = await getModelStoragePath();
      final filePath = '$storagePath/$modelId.bin';
      final file = File(filePath);
      
      debugPrint('🤖 Descargando modelo: ${modelInfo.name} (${modelInfo.sizeMB}MB)');
      
      final request = http.Request('GET', Uri.parse(modelInfo.url));
      final response = await http.Client().send(request);
      
      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;
      
      final sink = file.openWrite();
      
      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        
        if (totalBytes > 0) {
          _downloadProgress = receivedBytes / totalBytes;
          notifyListeners();
        }
      }
      
      await sink.close();
      
      if (await file.exists()) {
        final fileSize = await file.length();
        if (fileSize > 0) {          _isModelAvailable = true;
          _currentModel = modelId;
          _isDownloading = false;
          _downloadProgress = 1.0;
          debugPrint('✅ Modelo descargado exitosamente');
          notifyListeners();
          return true;
        }
      }
      
      throw Exception('Archivo descargado está vacío o corrupto');
      
    } catch (e) {
      _isDownloading = false;
      _errorMessage = 'Error en descarga: ${e.toString()}';
      debugPrint('❌ Error descarga: $e');
      notifyListeners();
      
      // Limpiar archivo corrupto
      try {
        final storagePath = await getModelStoragePath();
        final file = File('$storagePath/$modelId.bin');
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
      
      return false;
    }
  }

  /// Eliminar modelo descargado
  Future<bool> deleteModel(String modelId) async {
    try {
      final storagePath = await getModelStoragePath();
      final file = File('$storagePath/$modelId.bin');
      
      if (await file.exists()) {
        await file.delete();
        if (_currentModel == modelId) {
          _isModelAvailable = false;
          _currentModel = '';
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Error al eliminar: ${e.toString()}';
      notifyListeners();      return false;
    }
  }

  /// Obtener comando fallback (sin IA)
  String getFallbackCommand(String inputPath, String outputPath, String task) {
    switch (task) {
      case 'upscale_2x':
        return '-i "$inputPath" -vf scale=iw*2:ih*2:flags=lanczos -y "$outputPath"';
      case 'upscale_4x':
        return '-i "$inputPath" -vf scale=iw*4:ih*4:flags=lanczos -y "$outputPath"';
      case 'interpolate_frames':
        return '-i "$inputPath" -vf minterpolate=fps=60:mi_mode=mci -y "$outputPath"';
      default:
        return '-i "$inputPath" -y "$outputPath"';
    }
  }

  /// Verificar estado de todos los modelos
  Future<Map<String, bool>> checkAllModelsStatus() async {
    final status = <String, bool>{};
    
    for (final modelId in availableModels.keys) {
      status[modelId] = await isModelDownloaded(modelId);
    }
    
    return status;
  }

  /// Obtener espacio usado por modelos
  Future<int> getStorageUsedMB() async {
    try {
      final storagePath = await getModelStoragePath();
      final directory = Directory(storagePath);
      
      if (!await directory.exists()) {
        return 0;
      }
      
      int totalBytes = 0;
      await for (final file in directory.list(recursive: true)) {
        if (file is File) {
          totalBytes += await file.length();
        }
      }
      
      return (totalBytes / (1024 * 1024)).round();
    } catch (e) {
      return 0;
    }  }
}

/// Información de modelo IA
class AIModelInfo {
  final String name;
  final String description;
  final int sizeMB;
  final AIModelType type;
  final String url;

  const AIModelInfo({
    required this.name,
    required this.description,
    required this.sizeMB,
    required this.type,
    required this.url,
  });
}

/// Tipos de modelos IA
enum AIModelType {
  upscaling,
  interpolation,
  denoising,
  colorization,
}
