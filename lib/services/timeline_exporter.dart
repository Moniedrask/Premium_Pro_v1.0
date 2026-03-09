import 'package:ffmpeg_kit_flutter_minimal/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_minimal/return_code.dart';
import '../models/timeline_project.dart';
import '../models/timeline_layer.dart';

class TimelineExporter {
  /// Exporta un proyecto de línea de tiempo a un archivo de video.
  /// Requiere que todas las capas tengan rutas de archivo válidas.
  static Future<bool> exportProject(
    TimelineProject project,
    String outputPath, {
    required dynamic ffmpeg, // FFmpegWrapper
  }) async {
    // Construir un comando FFmpeg complejo con múltiples entradas y filtros
    List<String> args = [];

    // 1. Añadir todas las entradas (archivos)
    Map<String, int> inputIndices = {};
    int inputIndex = 0;
    for (var layer in project.layers) {
      if (layer is VideoLayer || layer is AudioLayer || layer is ImageLayer) {
        args.addAll(['-i', layer.filePath]);
        inputIndices[layer.id] = inputIndex;
        inputIndex++;
      }
    }

    // 2. Construir filtro complejo para superponer capas
    // Esto es extremadamente simplificado; en realidad necesitarías
    // un sistema de composición más avanzado.
    List<String> filterParts = [];
    int outputCount = 0;

    for (var layer in project.layers) {
      int idx = inputIndices[layer.id] ?? -1;
      if (idx == -1) continue;

      String filter = '';
      if (layer is VideoLayer) {
        // Escalar al tamaño del proyecto y posicionar
        filter = '[$idx:v]scale=$project.width:$project.height,setpts=PTS/${layer.speed}[v$outputCount]';
      } else if (layer is ImageLayer) {
        filter = '[$idx:v]scale=$project.width:$project.height,format=rgba,setpts=PTS+${layer.start.inMilliseconds/1000}/TB[img$outputCount]';
      } else if (layer is TextLayer) {
        // Los textos se generan con drawtext
        filter = 'color=c=black@0.0:s=${project.width}x${project.height},format=rgba[bg$outputCount];'
            '[bg$outputCount]drawtext=text=\'${layer.text}\':fontcolor=white@${layer.opacity}:fontsize=${layer.fontSize}:x=${layer.position.dx * project.width}:y=${layer.position.dy * project.height}:fontfile=${layer.fontFamily}[txt$outputCount]';
      }
      if (filter.isNotEmpty) {
        filterParts.add(filter);
        outputCount++;
      }
    }

    // 3. Mezclar todas las capas (overlay)
    if (outputCount > 0) {
      String overlay = '';
      for (int i = 0; i < outputCount; i++) {
        if (i == 0) {
          overlay = '[v0]';
        } else {
          overlay = '[$overlay][v$i]overlay=format=auto:shortest=1[vout]';
        }
      }
      filterParts.add(overlay);
    }

    // 4. Aplicar filtro complejo
    if (filterParts.isNotEmpty) {
      args.addAll(['-filter_complex', filterParts.join(';')]);
      args.addAll(['-map', '[vout]']);
    }

    // 5. Configuración de audio (simplificado: tomar el primer audio)
    for (var layer in project.layers) {
      if (layer is AudioLayer && !layer.muted) {
        int idx = inputIndices[layer.id] ?? -1;
        if (idx != -1) {
          args.addAll(['-map', '$idx:a']);
          break;
        }
      }
    }

    args.addAll(['-y', outputPath]);

    // Ejecutar comando
    try {
      final success = await ffmpeg.executeCommandWithArgs(args);
      return success;
    } catch (e) {
      print('Error exporting timeline: $e');
      return false;
    }
  }
}