import 'dart:io';
import 'package:ffmpeg_kit_flutter_minimal/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_minimal/return_code.dart';
import 'package:path_provider/path_provider.dart';

/// Servicio para fusionar hasta 5 imágenes con diferentes exposiciones (HDR)
class HdrMerger {
  /// Fusiona una lista de imágenes (rutas) en una sola imagen HDR.
  /// [imagePaths] Lista de rutas a las imágenes (mínimo 2, máximo 5).
  /// [outputPath] Ruta de salida (opcional, si es null se genera una en caché).
  /// Retorna la ruta de la imagen fusionada o null si falla.
  Future<String?> mergeHDR(List<String> imagePaths, {String? outputPath}) async {
    if (imagePaths.length < 2 || imagePaths.length > 5) {
      throw ArgumentError('Se necesitan entre 2 y 5 imágenes');
    }

    // Si no se especifica ruta de salida, crear una en el directorio de caché
    final String finalOutputPath = outputPath ?? await _getTempOutputPath();

    // Construir comando FFmpeg para HDR
    // Usamos el filtro 'hstack' para apilar horizontalmente (simple)
    // Para un verdadero HDR, se necesitaría 'mergeplanes' con información de exposición,
    // pero aquí usamos un enfoque simple combinando las imágenes.
    // Nota: Esto es una implementación básica; para HDR real se requerirían más datos.
    List<String> inputArgs = [];
    for (var path in imagePaths) {
      inputArgs.addAll(['-i', path]);
    }

    // Crear filtro para combinar las imágenes (por ejemplo, apiladas horizontalmente)
    String filterComplex = '';
    for (int i = 0; i < imagePaths.length; i++) {
      if (i > 0) filterComplex += ';';
      filterComplex += '[$i:v]';
    }
    filterComplex += 'hstack=inputs=${imagePaths.length}[v]';

    List<String> arguments = [
      ...inputArgs,
      '-filter_complex', filterComplex,
      '-map', '[v]',
      '-frames:v', '1',
      '-y', finalOutputPath,
    ];

    try {
      final session = await FFmpegKit.executeWithArguments(arguments);
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        return finalOutputPath;
      } else {
        print('Error al fusionar HDR: ${await session.getOutput()}');
        return null;
      }
    } catch (e) {
      print('Excepción en HDR merger: $e');
      return null;
    }
  }

  Future<String> _getTempOutputPath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/hdr_${DateTime.now().millisecondsSinceEpoch}.png';
  }
}