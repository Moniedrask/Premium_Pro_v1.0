import 'dart:async';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_minimal/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_minimal/return_code.dart';
import 'package:ffmpeg_kit_flutter_minimal/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_minimal/statistics.dart';
import 'package:ffmpeg_kit_flutter_minimal/ffprobe_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/video_settings.dart';
import '../models/video_effect.dart';
import '../models/speed_segment.dart';

class FFmpegWrapper {
  static final FFmpegWrapper _instance = FFmpegWrapper._internal();
  factory FFmpegWrapper() => _instance;
  FFmpegWrapper._internal();

  bool _isProcessing = false;
  double _progress = 0.0;
  String _statusMessage = "Listo";
  dynamic _currentSession;

  bool get isProcessing => _isProcessing;
  double get progress => _progress;
  String get statusMessage => _statusMessage;

  Future<void> init() async {
    await FFmpegKitConfig.enableLogs();
    debugPrint('✅ FFmpeg Wrapper inicializado');
  }

  // ========== MÉTODOS PARA OBTENER INFORMACIÓN ==========

  Future<int?> getVideoDuration(String path) async {
    try {
      final session = await FFprobeKit.getMediaInformation(path);
      final information = await session.getMediaInformation();
      if (information != null) {
        final durationStr = information.getDuration();
        if (durationStr != null && durationStr.isNotEmpty) {
          final durationSec = double.tryParse(durationStr);
          if (durationSec != null && durationSec > 0) {
            return (durationSec * 1000000).round();
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error obteniendo duración del video: $e');
    }
    return null;
  }

  Future<int?> getVideoFps(String path) async {
    try {
      final session = await FFprobeKit.getMediaInformation(path);
      final information = await session.getMediaInformation();
      if (information != null) {
        final streams = information.getStreams();
        if (streams != null && streams.isNotEmpty) {
          final fpsStr = streams.first.getStringProperty('r_frame_rate');
          if (fpsStr != null && fpsStr.contains('/')) {
            final parts = fpsStr.split('/');
            final num = int.tryParse(parts[0]);
            final den = int.tryParse(parts[1]);
            if (num != null && den != null && den > 0) {
              return (num / den).round();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error obteniendo FPS del video: $e');
    }
    return null;
  }

  // ========== PROCESAMIENTO DE VIDEO NORMAL ==========

  Future<bool> processVideo({
    required String inputPath,
    required String outputPath,
    required VideoSettings settings,
    int? totalDurationMicros,
    int? originalFps,
    int? originalWidth,
    int? originalHeight,
    Function(double progress)? onProgress,
    Function(String log)? onLog,
  }) async {
    if (_isProcessing) {
      debugPrint('❌ Ya hay un procesamiento en curso');
      return false;
    }

    _isProcessing = true;
    _progress = 0.0;
    _statusMessage = "Iniciando...";

    const int defaultDurationMicros = 60 * 1000000;
    final effectiveDuration = totalDurationMicros ?? defaultDurationMicros;

    if (totalDurationMicros == null) {
      debugPrint('⚠️ No se pudo obtener la duración real del video. Se usará un progreso aproximado.');
    }

    List<String> arguments = [
      '-i', inputPath,
    ];

    List<String> filters = [];

    // Escalado de resolución (limitado a 4x)
    if (settings.resolutionUpscale && originalWidth != null && originalHeight != null) {
      int targetW = settings.targetWidth;
      int targetH = settings.targetHeight;

      if (targetW == 0 && targetH > 0) {
        targetW = (originalWidth * targetH / originalHeight).round();
      } else if (targetH == 0 && targetW > 0) {
        targetH = (originalHeight * targetW / originalWidth).round();
      }

      double scaleW = targetW / originalWidth;
      double scaleH = targetH / originalHeight;
      double scaleFactor = scaleW > scaleH ? scaleW : scaleH;

      if (scaleFactor > settings.maxScaleFactor) {
        scaleFactor = settings.maxScaleFactor.toDouble();
        targetW = (originalWidth * scaleFactor).round();
        targetH = (originalHeight * scaleFactor).round();
        debugPrint('⚠️ Factor de escala limitado a x${settings.maxScaleFactor}');
      }

      filters.add('scale=$targetW:$targetH:flags=lanczos');
    }

    // Interpolación de frames (limitada a 4x FPS original)
    if (settings.frameInterpolation && originalFps != null && originalFps > 0) {
      int maxTargetFps = originalFps * settings.maxScaleFactor;
      int finalTargetFps = settings.targetFps > maxTargetFps ? maxTargetFps : settings.targetFps;

      if (finalTargetFps > originalFps) {
        filters.add('minterpolate=fps=$finalTargetFps:mi_mode=mci:me_mode=bidir:mc_mode=obmc:me=ds');
        debugPrint('📊 Interpolando de ${originalFps}fps a ${finalTargetFps}fps');
      }
    }

    // Efectos de video
    if (settings.effect != null && settings.effect!.type != VideoEffectType.none) {
      final effectFilter = settings.effect!.ffmpegFilter;
      if (effectFilter.isNotEmpty) {
        filters.add(effectFilter);
      }
    }

    if (filters.isNotEmpty) {
      arguments.addAll(['-vf', filters.join(',')]);
    }

    // Configuración de video (bitrate, códec, etc.)
    if (settings.bitrateMode == BitrateMode.cbr) {
      arguments.addAll([
        '-b:v', '${settings.videoBitrate}k',
        '-maxrate', '${settings.videoBitrate}k',
        '-bufsize', '${settings.videoBitrate}k',
      ]);

      if (settings.hardwareAcceleration) {
        if (settings.videoCodec == 'libx264') {
          arguments.addAll(['-c:v', 'h264_mediacodec', '-bitrate_mode', '0']);
        } else if (settings.videoCodec == 'libx265') {
          arguments.addAll(['-c:v', 'hevc_mediacodec', '-bitrate_mode', '0']);
        } else {
          arguments.addAll(['-c:v', settings.videoCodec]);
        }
      } else {
        arguments.addAll(['-c:v', settings.videoCodec]);
      }
    } else {
      arguments.addAll([
        '-c:v', settings.videoCodec,
        '-preset', settings.preset,
        '-crf', settings.crf.toString(),
        '-b:v', '${settings.videoBitrate}k',
      ]);

      if (settings.hardwareAcceleration) {
        if (settings.videoCodec == 'libx264') {
          arguments.addAll(['-c:v', 'h264_mediacodec']);
        } else if (settings.videoCodec == 'libx265') {
          arguments.addAll(['-c:v', 'hevc_mediacodec']);
        }
      }
    }

    // Configuración de audio
    arguments.addAll([
      '-c:a', settings.audioCodec,
      '-b:a', '${settings.audioBitrate}k',
      '-ar', settings.audioSampleRate.toString(),
    ]);

    if (settings.audioChannels == 'mono') {
      arguments.addAll(['-ac', '1']);
    } else if (settings.audioChannels == 'stereo') {
      arguments.addAll(['-ac', '2']);
    }

    if (!settings.preserveMetadata) {
      arguments.addAll(['-map_metadata', '-1']);
    }

    arguments.addAll(['-movflags', '+faststart', '-y', outputPath]);

    String command = arguments.join(' ');

    try {
      debugPrint('⚙️ Comando FFmpeg: $command');

      final completer = Completer<bool>();

      _currentSession = await FFmpegKit.executeAsync(
        command,
        (session) {
          session.getReturnCode().then((returnCode) {
            final success = ReturnCode.isSuccess(returnCode);
            if (success) {
              _statusMessage = "✅ Completado";
              _progress = 1.0;
              onProgress?.call(1.0);
              debugPrint('✅ Procesamiento exitoso: $outputPath');
            } else {
              _statusMessage = "❌ Error en procesamiento";
              session.getOutput().then((output) {
                debugPrint('❌ Error FFmpeg: $output');
              });
            }
            _isProcessing = false;
            _currentSession = null;
            completer.complete(success);
          }).catchError((error) {
            _isProcessing = false;
            _currentSession = null;
            completer.complete(false);
          });
        },
        (log) {
          debugPrint('📝 FFmpeg log: ${log.getMessage()}');
          onLog?.call(log.getMessage());
        },
        (statistics) {
          final time = statistics.getTime();
          if (time > 0) {
            double progress = time / effectiveDuration;
            if (progress > 1.0) progress = 1.0;
            _progress = progress;
            onProgress?.call(_progress);
          }
        },
      );

      return await completer.future;
    } catch (e) {
      _isProcessing = false;
      _currentSession = null;
      _statusMessage = "❌ Error: $e";
      debugPrint('❌ Excepción: $e');
      return false;
    }
  }

  // ========== SPEED RAMP ==========

  Future<bool> processVideoWithSpeedRamp({
    required String inputPath,
    required String outputPath,
    required List<SpeedSegment> segments,
    int? totalDurationMicros,
    Function(double progress)? onProgress,
    Function(String log)? onLog,
  }) async {
    if (_isProcessing) {
      debugPrint('❌ Ya hay un procesamiento en curso');
      return false;
    }

    _isProcessing = true;
    _progress = 0.0;
    _statusMessage = "Aplicando speed ramp...";

    // Construir filtro setpts con condiciones anidadas correctamente
    // Formato correcto: if(between(T,s,e),PTS*f,if(between(T,...),PTS*f,PTS))
    String setptsExpr;
    if (segments.isEmpty) {
      setptsExpr = 'setpts=PTS';
    } else {
      // Construir expresión anidada de adentro hacia afuera
      String inner = 'PTS';
      for (int i = segments.length - 1; i >= 0; i--) {
        final seg = segments[i];
        final startSec = seg.start.inMilliseconds / 1000.0;
        final endSec = seg.end.inMilliseconds / 1000.0;
        final speedFactor = (1.0 / seg.speed).toStringAsFixed(6);
        inner = 'if(between(T,$startSec,$endSec),PTS*$speedFactor,$inner)';
      }
      setptsExpr = 'setpts=\'$inner\'';
    }

    final command = '-i "$inputPath" -vf "$setptsExpr" -c:a copy -y "$outputPath"';

    try {
      debugPrint('⚙️ Speed ramp command: $command');

      final completer = Completer<bool>();

      _currentSession = await FFmpegKit.executeAsync(
        command,
        (session) {
          session.getReturnCode().then((returnCode) {
            final success = ReturnCode.isSuccess(returnCode);
            if (success) {
              _statusMessage = "✅ Completado";
              _progress = 1.0;
              onProgress?.call(1.0);
              debugPrint('✅ Speed ramp exitoso: $outputPath');
            } else {
              _statusMessage = "❌ Error en speed ramp";
              session.getOutput().then((output) {
                debugPrint('❌ Error FFmpeg: $output');
              });
            }
            _isProcessing = false;
            _currentSession = null;
            completer.complete(success);
          }).catchError((error) {
            _isProcessing = false;
            _currentSession = null;
            completer.complete(false);
          });
        },
        (log) {
          debugPrint('📝 FFmpeg log: ${log.getMessage()}');
          onLog?.call(log.getMessage());
        },
        (statistics) {
          // Progreso básico (no disponible sin duración efectiva de salida)
        },
      );

      return await completer.future;
    } catch (e) {
      _isProcessing = false;
      _currentSession = null;
      _statusMessage = "❌ Error: $e";
      debugPrint('❌ Excepción: $e');
      return false;
    }
  }

  // ========== MÉTODOS AUXILIARES ==========

  Future<bool> executeCommandWithArgs(List<String> arguments) async {
    try {
      final session = await FFmpegKit.executeWithArguments(arguments);
      final returnCode = await session.getReturnCode();
      return ReturnCode.isSuccess(returnCode);
    } catch (e) {
      debugPrint('❌ Error en comando con args: $e');
      return false;
    }
  }

  void cancel() {
    _currentSession?.cancel();
    _isProcessing = false;
    _currentSession = null;
    _statusMessage = "Cancelado";
    debugPrint('⛔ Procesamiento cancelado por el usuario');
  }

  Future<bool> executeCommand(String command) async {
    try {
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      return ReturnCode.isSuccess(returnCode);
    } catch (e) {
      debugPrint('❌ Error en comando personalizado: $e');
      return false;
    }
  }

  Future<List<String>> getAvailableCodecs() async {
    try {
      final session = await FFmpegKit.execute('-codecs');
      final output = await session.getOutput() ?? '';
      return output.split('\n')
          .where((line) => line.contains('V') && line.contains('DEV'))
          .map((line) => line.split(' ').last.trim())
          .toList();
    } catch (e) {
      debugPrint('❌ Error al obtener códecs: $e');
      return [];
    }
  }
}