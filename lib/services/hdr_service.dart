import 'package:ffmpeg_kit_flutter_minimal/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_minimal/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class HdrService {
  /// Fusiona hasta 3 imágenes para crear una imagen HDR.
  /// Utiliza técnicas de mezcla de exposición para un resultado más realista.
  static Future<String?> mergeImages(List<String> imagePaths, {String? outputPath}) async {
    if (imagePaths.length < 2 || imagePaths.length > 3) {
      throw ArgumentError('Se necesitan entre 2 y 3 imágenes');
    }

    final output = outputPath ?? await _getTempOutputPath();

    List<String> args = [];
    for (var path in imagePaths) {
      args.addAll(['-i', path]);
    }

    // Construir filtro según cantidad de imágenes
    String filterComplex;
    if (imagePaths.length == 2) {
      // Para 2 imágenes: fusionar con diferentes pesos de exposición
      // Simula HDR usando merge con ponderación
      filterComplex = '[0:v]format=gbrp10le,setpts=PTS-STARTPTS[base];'
          '[1:v]format=gbrp10le,setpts=PTS-STARTPTS[over];'
          '[base][over]blend=all_mode=addition:all_opacity=0.5[merged]';
    } else {
      // Para 3 imágenes: fusión con pesos decrecientes
      filterComplex = '[0:v]format=gbrp10le,setpts=PTS-STARTPTS[img0];'
          '[1:v]format=gbrp10le,setpts=PTS-STARTPTS[img1];'
          '[2:v]format=gbrp10le,setpts=PTS-STARTPTS[img2];'
          '[img0][img1]blend=all_mode=addition:all_opacity=0.6[tmp];'
          '[tmp][img2]blend=all_mode=addition:all_opacity=0.4[merged]';
    }

    args.addAll(['-filter_complex', filterComplex]);
    args.addAll(['-map', '[merged]']);
    args.addAll(['-frames:v', '1']);
    args.addAll(['-y', output]);

    try {
      final session = await FFmpegKit.executeWithArguments(args);
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        return output;
      } else {
        print('Error en fusión HDR: ${await session.getOutput()}');
        return null;
      }
    } catch (e) {
      print('Excepción en HDR service: $e');
      return null;
    }
  }

  /// Versión alternativa usando hstack para comparación (no HDR real)
  static Future<String?> mergeImagesHStack(List<String> imagePaths, {String? outputPath}) async {
    if (imagePaths.isEmpty) return null;

    final output = outputPath ?? await _getTempOutputPath();

    List<String> args = [];
    for (var path in imagePaths) {
      args.addAll(['-i', path]);
    }

    String filterComplex = '';
    for (int i = 0; i < imagePaths.length; i++) {
      filterComplex += '[$i:v]';
    }
    filterComplex += 'hstack=inputs=${imagePaths.length}[v]';

    args.addAll(['-filter_complex', filterComplex]);
    args.addAll(['-map', '[v]']);
    args.addAll(['-frames:v', '1']);
    args.addAll(['-y', output]);

    try {
      final session = await FFmpegKit.executeWithArguments(args);
      final returnCode = await session.getReturnCode();
      return ReturnCode.isSuccess(returnCode) ? output : null;
    } catch (e) {
      print('Excepción en HDR service: $e');
      return null;
    }
  }

  static Future<String> _getTempOutputPath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/hdr_${DateTime.now().millisecondsSinceEpoch}.jpg';
  }
}