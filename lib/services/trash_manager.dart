import 'dart:io';
import 'package:path_provider/path_provider.dart';

class TrashItem {
  final String originalPath;
  final String trashPath;
  final DateTime deletedAt;

  TrashItem({
    required this.originalPath,
    required this.trashPath,
    required this.deletedAt,
  });
}

class TrashManager {
  static final TrashManager _instance = TrashManager._internal();
  factory TrashManager() => _instance;
  TrashManager._internal();

  Future<String> _getTrashDir() async {
    final dir = await getExternalStorageDirectory();
    final trashDir = Directory('${dir?.path}/PremiumPro/.trash');
    if (!await trashDir.exists()) {
      await trashDir.create(recursive: true);
    }
    return trashDir.path;
  }

  /// Mueve un archivo a la papelera
  Future<bool> moveToTrash(String filePath) async {
    try {
      final trashDir = await _getTrashDir();
      final fileName = filePath.split('/').last;
      final destPath = '$trashDir/$fileName';
      final file = File(filePath);
      if (await file.exists()) {
        await file.rename(destPath);
        // Aquí se podría guardar metadatos en una base de datos (ej. usando sqflite)
        return true;
      }
    } catch (e) {
      print('Error moviendo a papelera: $e');
    }
    return false;
  }

  /// Restaura un archivo desde la papelera
  Future<bool> restoreFromTrash(String trashPath, String originalPath) async {
    try {
      final file = File(trashPath);
      if (await file.exists()) {
        await file.rename(originalPath);
        return true;
      }
    } catch (e) {
      print('Error restaurando: $e');
    }
    return false;
  }

  /// Elimina permanentemente un archivo de la papelera
  Future<bool> deletePermanently(String trashPath) async {
    try {
      final file = File(trashPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      print('Error eliminando permanentemente: $e');
    }
    return false;
  }

  /// Vacía la papelera
  Future<void> emptyTrash() async {
    final trashDir = await _getTrashDir();
    final dir = Directory(trashDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create();
    }
  }

  /// Obtiene la lista de archivos en la papelera
  Future<List<File>> listTrash() async {
    final trashDir = await _getTrashDir();
    final dir = Directory(trashDir);
    if (await dir.exists()) {
      return dir.list().whereType<File>().toList();
    }
    return [];
  }
}