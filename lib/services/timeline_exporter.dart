import 'package:ffmpeg_kit_flutter_minimal/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_minimal/return_code.dart';
import '../models/timeline_project.dart';
import '../models/timeline_layer.dart';

class TimelineExporter {
  /// Exporta un proyecto de línea de tiempo a un archivo de video.
  /// Requiere que todas las capas tengan rutas de archivo válidas.
  /// Nota: Esta implementación es simplificada. Para un exportador real,
  /// se necesitaría sincronización precisa de tiempos, manejo de múltiples pistas de audio,
  /// y composición avanzada. Los efectos de video en las capas no se aplican aquí.
  static Future<bool> exportProject(
    TimelineProject project,
    String outputPath, {
    required dynamic ffmpeg, // FFmpegWrapper
  }) async {
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
    List<String> filterParts = [];
    int outputCount = 0;

    for (var layer in project.layers) {
      int idx = inputIndices[layer.id] ?? -1;
      if (idx == -1) continue;

      String filter = '';
      if (layer is VideoLayer) {
        // Escalar al tamaño del proyecto
        filter = '[$idx:v]scale=$project.width:$project.height';
        // Aplicar speed
        if (layer.speed != 1.0) {
          filter += ',setpts=PTS/${layer.speed}';
        }
        // Aplicar fades (usando la duración del layer)
        if (layer.fadeIn.inMilliseconds > 0) {
          double fadeInSec = layer.fadeIn.inMilliseconds / 1000.0;
          filter += ',fade=t=in:st=0:d=$fadeInSec';
        }
        if (layer.fadeOut.inMilliseconds > 0) {
          double fadeOutSec = layer.fadeOut.inMilliseconds / 1000.0;
          double totalSec = layer.duration.inMilliseconds / 1000.0;
          double startOut = totalSec - fadeOutSec;
          filter += ',fade=t=out:st=$startOut:d=$fadeOutSec';
        }
        filter += '[v$outputCount]';
      } else if (layer is ImageLayer) {
        filter = '[$idx:v]scale=$project.width:$project.height,format=rgba';
        if (layer.fadeIn.inMilliseconds > 0) {
          double fadeInSec = layer.fadeIn.inMilliseconds / 1000.0;
          filter += ',fade=t=in:st=0:d=$fadeInSec';
        }
        if (layer.fadeOut.inMilliseconds > 0) {
          double fadeOutSec = layer.fadeOut.inMilliseconds / 1000.0;
          double totalSec = layer.duration.inMilliseconds / 1000.0;
          double startOut = totalSec - fadeOutSec;
          filter += ',fade=t=out:st=$startOut:d=$fadeOutSec';
        }
        filter += ',setpts=PTS+${layer.start.inMilliseconds/1000}/TB[img$outputCount]';
      } else if (layer is TextLayer) {
        // Los textos se generan con drawtext
        filter = 'color=c=black@0.0:s=${project.width}x${project.height},format=rgba[bg$outputCount];'
            '[bg$outputCount]drawtext=text=\'${layer.text}\':fontcolor=white@${layer.opacity}:fontsize=${layer.fontSize}:x=${layer.position.dx * project.width}:y=${layer.position.dy * project.height}:fontfile=${layer.fontFamily}';
        if (layer.fadeIn.inMilliseconds > 0) {
          double fadeInSec = layer.fadeIn.inMilliseconds / 1000.0;
          filter += ',fade=t=in:st=0:d=$fadeInSec';
        }
        if (layer.fadeOut.inMilliseconds > 0) {
          double fadeOutSec = layer.fadeOut.inMilliseconds / 1000.0;
          double totalSec = layer.duration.inMilliseconds / 1000.0;
          double startOut = totalSec - fadeOutSec;
          filter += ',fade=t=out:st=$startOut:d=$fadeOutSec';
        }
        filter += '[txt$outputCount]';
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
        String label = (i == 0) ? 'v$i' : '[v$i]'; // los labels pueden ser v0, v1, etc.
        // pero necesitamos saber qué labels se generaron realmente
        // simplificamos: asumimos que los labels son v0, v1...
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

    // 5. Configuración de audio (simplificado: tomar el primer audio, con fades)
    for (var layer in project.layers) {
      if (layer is AudioLayer && !layer.muted) {
        int idx = inputIndices[layer.id] ?? -1;
        if (idx != -1) {
          String audioFilter = '';
          if (layer.fadeIn.inMilliseconds > 0) {
            double fadeInSec = layer.fadeIn.inMilliseconds / 1000.0;
            audioFilter += 'afade=t=in:st=0:d=$fadeInSec';
          }
          if (layer.fadeOut.inMilliseconds > 0) {
            double fadeOutSec = layer.fadeOut.inMilliseconds / 1000.0;
            double totalSec = layer.duration.inMilliseconds / 1000.0;
            double startOut = totalSec - fadeOutSec;
            if (audioFilter.isNotEmpty) audioFilter += ',';
            audioFilter += 'afade=t=out:st=$startOut:d=$fadeOutSec';
          }
          if (audioFilter.isNotEmpty) {
            args.addAll(['-af', audioFilter]);
          }
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