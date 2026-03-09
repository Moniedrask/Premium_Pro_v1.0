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

    // Añadir entradas y guardar índices
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

    for (var layer in project.layers) {
      int idx = inputIndices[layer.id] ?? -1;
      if (idx == -1) continue;

      String filter = '';
      if (layer is VideoLayer) {
        filter = '[$idx:v]scale=$project.width:$project.height';
        if (layer.speed != 1.0) {
          filter += ',setpts=PTS/${layer.speed}';
        }
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

    if (filterParts.isNotEmpty) {
      args.addAll(['-filter_complex', filterParts.join(';')]);
      args.addAll(['-map', '[vout]']);
    }

    // Audio: buscar la primera capa de audio no silenciada
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

    try {
      final success = await ffmpeg.executeCommandWithArgs(args);
      return success;
    } catch (e) {
      print('Error exporting timeline: $e');
      return false;
    }
  }
}