import 'package:ffmpeg_kit_flutter_minimal/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_minimal/return_code.dart';
import '../models/timeline_project.dart';
import '../models/timeline_layer.dart';

class TimelineExporter {
  static Future<bool> exportProject(
    TimelineProject project,
    String outputPath, {
    required dynamic ffmpeg,
  }) async {
    List<String> args = [];

    Map<String, int> inputIndices = {};
    int inputIndex = 0;

    // 1. Añadir todas las entradas (archivos)
    for (var layer in project.layers) {
      String? filePath;
      if (layer is VideoLayer) filePath = layer.filePath;
      else if (layer is AudioLayer) filePath = layer.filePath;
      else if (layer is ImageLayer) filePath = layer.filePath;
      else continue;

      if (filePath != null) {
        args.addAll(['-i', filePath]);
        inputIndices[layer.id] = inputIndex;
        inputIndex++;
      }
    }

    List<String> filterParts = [];
    int outputCount = 0;

    // 2. Construir filtros para cada capa (interpolación correcta con ${})
    for (var layer in project.layers) {
      int idx = inputIndices[layer.id] ?? -1;
      if (idx == -1) continue;

      String filter = '';

      if (layer is VideoLayer) {
        // Usar interpolación correcta ${project.width} y ${project.height}
        filter = '[$idx:v]scale=${project.width}:${project.height}';

        // Aplicar efectos de video si existen
        if (layer.effects.isNotEmpty) {
          for (var effect in layer.effects) {
            final effectFilter = effect.ffmpegFilter;
            if (effectFilter.isNotEmpty) {
              filter += ',$effectFilter';
            }
          }
        }

        // Aplicar velocidad
        if (layer.speed != 1.0) {
          filter += ',setpts=PTS/${layer.speed}';
        }

        // Aplicar fades
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
      }
      else if (layer is ImageLayer) {
        filter = '[$idx:v]scale=${project.width}:${project.height},format=rgba';

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
        filter += ',setpts=PTS+${layer.start.inMilliseconds / 1000}/TB[img$outputCount]';
      }
      else if (layer is TextLayer) {
        filter = 'color=c=black@0.0:s=${project.width}x${project.height},format=rgba[bg$outputCount];'
            '[bg$outputCount]drawtext=text=\'${layer.text}\':fontcolor=white@${layer.opacity}:fontsize=${layer.fontSize}:x=${(layer.position.dx * project.width).toInt()}:y=${(layer.position.dy * project.height).toInt()}';

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
    if (outputCount > 1) {
      String current = '[v0]';
      for (int i = 1; i < outputCount; i++) {
        String next = i < outputCount - 1 ? '[vtmp$i]' : '[vout]';
        filterParts.add('$current[v$i]overlay=format=auto:shortest=1$next');
        current = '[vtmp$i]';
      }
    } else if (outputCount == 1) {
      // Si solo hay una capa de video, renombrar a vout
      filterParts.add('[v0]copy[vout]');
    }

    // 4. Aplicar filtro complejo si hay
    if (filterParts.isNotEmpty) {
      args.addAll(['-filter_complex', filterParts.join(';')]);
      args.addAll(['-map', '[vout]']);
    }

    // 5. Manejo de audio
    for (var layer in project.layers) {
      if (layer is AudioLayer && !layer.muted) {
        int idx = inputIndices[layer.id] ?? -1;
        if (idx != -1) {
          List<String> audioFilters = [];

          if (layer.effects.isNotEmpty) {
            for (var effect in layer.effects) {
              final effectFilter = effect.toFFmpegFilter();
              if (effectFilter.isNotEmpty) {
                audioFilters.add(effectFilter);
              }
            }
          }

          if (layer.fadeIn.inMilliseconds > 0) {
            double fadeInSec = layer.fadeIn.inMilliseconds / 1000.0;
            audioFilters.add('afade=t=in:st=0:d=$fadeInSec');
          }
          if (layer.fadeOut.inMilliseconds > 0) {
            double fadeOutSec = layer.fadeOut.inMilliseconds / 1000.0;
            double totalSec = layer.duration.inMilliseconds / 1000.0;
            double startOut = totalSec - fadeOutSec;
            audioFilters.add('afade=t=out:st=$startOut:d=$fadeOutSec');
          }

          if (layer.volume != 1.0) {
            audioFilters.add('volume=${layer.volume}');
          }

          if (audioFilters.isNotEmpty) {
            args.addAll(['-af', audioFilters.join(',')]);
          }

          args.addAll(['-map', '$idx:a']);
          break;
        }
      }
    }

    args.addAll(['-y', outputPath]);

    try {
      final success = await ffmpeg.executeCommandWithArgs(args);
      return success;
    } catch (e) {
      print('Error exporting timeline: $e');
      return false;
    }
  }
}