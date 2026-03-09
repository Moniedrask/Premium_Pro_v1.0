import 'package:ffmpeg_kit_flutter_minimal/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_minimal/return_code.dart';

class HdrService {
  /// Fusiona hasta 3 imágenes en una sola usando el filtro 'mergeplanes'
  static Future<String?> mergeImages(List<String> imagePaths, {String? outputPath}) async {
    if (imagePaths.length < 2 || imagePaths.length > 3) {
      throw ArgumentError('Se necesitan entre 2 y 3 imágenes');
    }

    final output = outputPath ?? '${imagePaths.first}_hdr.jpg';
    List<String> args = [];
    for (var path in imagePaths) {
      args.addAll(['-i', path]);
    }

    // Construir filtro mergeplanes (simplificado)
    String filter = '';
    if (imagePaths.length == 2) {
      filter = '[0][1]blend=all_mode=addition';
    } else {
      filter = '[0][1][2]blend=all_mode=addition,format=gbrp10le';
    }

    args.addAll(['-filter_complex', filter, '-y', output]);

    final session = await FFmpegKit.executeWithArguments(args);
    final returnCode = await session.getReturnCode();
    return ReturnCode.isSuccess(returnCode) ? output : null;
  }
}