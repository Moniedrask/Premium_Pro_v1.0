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
  String _statusMessage = 'Listo';
  dynamic _currentSession;

  bool get isProcessing => _isProcessing;
  double get progress => _progress;
  String get statusMessage => _statusMessage;

  Future<void> init() async {
    // enableLogs puede fallar en release si el canal nativo no se registró
    // correctamente (MissingPluginException). El fallo de logging NO debe
    // bloquear el arranque de la app: FFmpeg sigue siendo funcional.
    try {
      await FFmpegKitConfig.enableLogs();
      debugPrint('✅ FFmpeg Wrapper inicializado con logging');
    } catch (e) {
      debugPrint('⚠️ FFmpegKitConfig.enableLogs falló (logging desactivado): $e');
      // La app continúa — los comandos FFmpeg funcionan sin logging activo.
    }
  }

  // ========== INFORMACIÓN DEL MEDIO ==========

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
      debugPrint('❌ Error obteniendo duración: $e');
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
      debugPrint('❌ Error obteniendo FPS: $e');
    }
    return null;
  }

  Future<Map<String, int>?> getVideoDimensions(String path) async {
    try {
      final session = await FFprobeKit.getMediaInformation(path);
      final information = await session.getMediaInformation();
      if (information != null) {
        final streams = information.getStreams();
        if (streams != null && streams.isNotEmpty) {
          for (final stream in streams) {
            final w = stream.getWidth();
            final h = stream.getHeight();
            if (w != null && h != null && w > 0 && h > 0) {
              return {'width': w, 'height': h};
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error obteniendo dimensiones: $e');
    }
    return null;
  }

  // ========== PROCESAMIENTO PRINCIPAL ==========

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
    _statusMessage = 'Iniciando...';

    String effectiveInput = inputPath;

    // --- ESTABILIZACIÓN (dos pasos con vidstab) ---
    if (settings.stabilize == true) {
      _statusMessage = 'Analizando movimiento...';
      final dir = await getTemporaryDirectory();
      final trfPath = '${dir.path}/transform.trf';
      final stabilizedPath = '${dir.path}/stabilized_tmp.mp4';

      final analyzeOk = await executeCommandWithArgs([
        '-i', inputPath,
        '-vf', 'vidstabdetect=shakiness=5:accuracy=15:result=$trfPath',
        '-f', 'null', '-',
      ]);

      if (analyzeOk) {
        _statusMessage = 'Aplicando estabilización...';
        final stabilizeOk = await executeCommandWithArgs([
          '-i', inputPath,
          '-vf', 'vidstabtransform=input=$trfPath:zoom=1:smoothing=30',
          '-c:a', 'copy',
          '-y', stabilizedPath,
        ]);
        if (stabilizeOk && await File(stabilizedPath).exists()) {
          effectiveInput = stabilizedPath;
        }
      } else {
        debugPrint('⚠️ vidstabdetect falló, continuando sin estabilización');
      }
    }

    final success = await _runMainExport(
      inputPath: effectiveInput,
      outputPath: outputPath,
      settings: settings,
      totalDurationMicros: totalDurationMicros,
      originalFps: originalFps,
      originalWidth: originalWidth,
      originalHeight: originalHeight,
      onProgress: onProgress,
      onLog: onLog,
    );
    _isProcessing = false;
    return success;
  }

  Future<bool> _runMainExport({
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
    const int defaultDurationMicros = 60 * 1000000;
    final effectiveDuration = totalDurationMicros ?? defaultDurationMicros;

    final List<String> arguments = ['-i', inputPath];
    final List<String> filters = [];

    // --- ESCALADO DE RESOLUCIÓN ---
    if (settings.resolutionUpscale &&
        originalWidth != null &&
        originalHeight != null) {
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
      // Si aiInterpolation+aiEnabled se solicitó IA, avisamos y usamos lanczos (no hay TFLite)
      if (settings.aiInterpolation && settings.aiEnabled) {
        debugPrint('ℹ️ aiUpscale: modelo IA no disponible en runtime, usando lanczos');
      }
      filters.add('scale=${targetW}:${targetH}:flags=lanczos');
    }

    // --- INTERPOLACIÓN DE FRAMES ---
    if (settings.frameInterpolation &&
        originalFps != null &&
        originalFps > 0) {
      int maxTargetFps = originalFps * settings.maxScaleFactor;
      int finalTargetFps =
          settings.targetFps > maxTargetFps ? maxTargetFps : settings.targetFps;
      if (finalTargetFps > originalFps) {
        filters.add(
            'minterpolate=fps=$finalTargetFps:mi_mode=mci:me_mode=bidir:mc_mode=obmc:me=ds');
        debugPrint('📊 Interpolando a ${finalTargetFps}fps');
      }
    }

    // --- EFECTOS DE VIDEO ---
    if (settings.effect != null &&
        settings.effect!.type != VideoEffectType.none) {
      final effectFilter = settings.effect!.ffmpegFilter;
      if (effectFilter.isNotEmpty) filters.add(effectFilter);
    }

    // --- COLOR GRADING (curves FFmpeg, sin LUT) ---
    final gradingFilter = _buildColorGradingFilter(settings.colorGrading);
    if (gradingFilter.isNotEmpty) filters.add(gradingFilter);

    // --- TEXTO ANIMADO (drawtext) ---
    if (settings.enableTextOverlay && settings.textOverlayContent.isNotEmpty) {
      filters.add(_buildDrawtextFilter(settings));
    }

    if (filters.isNotEmpty) {
      arguments.addAll(['-vf', filters.join(',')]);
    }

    // --- CODEC DE VIDEO ---
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

    // --- CODEC DE AUDIO ---
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

    return await _executeAsync(arguments, effectiveDuration, onProgress, onLog);
  }

  // ========== COLOR GRADING SIN LUT ==========

  /// Retorna un filtro FFmpeg `curves` o `eq` para cada preset de color.
  /// No requiere archivos .cube ni modelos externos.
  String _buildColorGradingFilter(ColorGradingPreset preset) {
    switch (preset) {
      case ColorGradingPreset.warm:
        return "curves=red='0/0 0.5/0.6 1/1':blue='0/0 0.5/0.4 1/0.9'";
      case ColorGradingPreset.cold:
        return "curves=red='0/0 0.5/0.4 1/0.9':blue='0/0 0.5/0.6 1/1'";
      case ColorGradingPreset.vintage:
        return "curves=r='0/0.05 0.5/0.58 1/0.95':g='0/0.02 0.5/0.52 1/0.95':b='0/0.02 0.5/0.44 1/0.85'";
      case ColorGradingPreset.highContrast:
        return "curves=all='0/0 0.3/0.15 0.7/0.85 1/1'";
      case ColorGradingPreset.fadedFilm:
        return "curves=all='0/0.08 0.5/0.5 1/0.92'";
      case ColorGradingPreset.teal:
        return "curves=r='0/0 0.4/0.35 0.7/0.75 1/1':g='0/0 0.5/0.48 1/0.97':b='0/0.05 0.4/0.52 0.7/0.38 1/0.85'";
      case ColorGradingPreset.vivid:
        return 'eq=saturation=1.5:contrast=1.1:brightness=0.02';
      case ColorGradingPreset.none:
      default:
        return '';
    }
  }

  // ========== TEXTO ANIMADO (drawtext) ==========

  /// Construye el filtro drawtext con posición relativa, color, tamaño y fade-in opcional.
  String _buildDrawtextFilter(VideoSettings s) {
    final safeText = s.textOverlayContent
        .replaceAll("'", r"\'")
        .replaceAll(':', r'\:');

    final xExpr = '(w-tw)/2+w*${s.textOverlayX}-w/2';
    final yExpr = 'h*${s.textOverlayY}';

    final String alphaExpr;
    if (s.textOverlayFadeIn) {
      final fadeEnd = s.textOverlayStartSec + 0.5;
      alphaExpr =
          "if(lt(t,${s.textOverlayStartSec}),0,if(lt(t,$fadeEnd),(t-${s.textOverlayStartSec})/0.5,if(lt(t,${s.textOverlayEndSec}),1,0)))";
    } else {
      alphaExpr = "between(t,${s.textOverlayStartSec},${s.textOverlayEndSec})";
    }

    return "drawtext=text='$safeText':fontcolor=${s.textOverlayColor}:fontsize=${s.textOverlayFontSize}:x=$xExpr:y=$yExpr:alpha='$alphaExpr'";
  }

  // ========== TRANSICIÓN ENTRE CLIPS (xfade) ==========

  Future<bool> applyTransition({
    required String input1,
    required String input2,
    required String outputPath,
    required TransitionType transitionType,
    double durationSeconds = 0.5,
    double offset = 0.0,
  }) async {
    final xfadeName = _xfadeName(transitionType);
    if (xfadeName.isEmpty) {
      return await executeCommand(
        '-i "$input1" -i "$input2" '
        '-filter_complex "[0:v][1:v]concat=n=2:v=1:a=0[outv];[0:a][1:a]concat=n=2:v=0:a=1[outa]" '
        '-map "[outv]" -map "[outa]" -y "$outputPath"',
      );
    }
    return await executeCommand(
      '-i "$input1" -i "$input2" '
      '-filter_complex "[0:v][1:v]xfade=transition=$xfadeName:duration=$durationSeconds:offset=$offset[outv];'
      '[0:a][1:a]acrossfade=d=$durationSeconds[outa]" '
      '-map "[outv]" -map "[outa]" -c:v libx264 -crf 18 -y "$outputPath"',
    );
  }

  String _xfadeName(TransitionType type) {
    switch (type) {
      case TransitionType.fade:       return 'fade';
      case TransitionType.dissolve:   return 'dissolve';
      case TransitionType.wipeLeft:   return 'wipeleft';
      case TransitionType.wipeRight:  return 'wiperight';
      case TransitionType.slideLeft:  return 'slideleft';
      case TransitionType.slideRight: return 'slideright';
      case TransitionType.none:
      default:                        return '';
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
    _statusMessage = 'Aplicando speed ramp...';

    const int defaultDurationMicros = 60 * 1000000;
    final effectiveDuration = totalDurationMicros ?? defaultDurationMicros;

    // Construir setpts con if() anidados de adentro hacia afuera
    String setptsBody = 'PTS';
    for (int i = segments.length - 1; i >= 0; i--) {
      final seg = segments[i];
      final startSec = seg.start.inMilliseconds / 1000.0;
      final endSec = seg.end.inMilliseconds / 1000.0;
      final speedFactor = 1.0 / seg.speed;
      setptsBody =
          'if(between(T,$startSec,$endSec),PTS*$speedFactor,$setptsBody)';
    }

    final command =
        '-i "$inputPath" -vf "setpts=\'$setptsBody\'" -c:a copy -y "$outputPath"';
    debugPrint('⚙️ Speed ramp: $command');

    try {
      final success =
          await _executeAsync([], effectiveDuration, onProgress, onLog,
              rawCommand: command);
      _isProcessing = false;
      return success;
    } catch (e) {
      _isProcessing = false;
      _statusMessage = '❌ Error: $e';
      debugPrint('❌ Excepción speed ramp: $e');
      return false;
    }
  }

  // ========== AUXILIARES ==========

  Future<bool> executeCommandWithArgs(List<String> arguments) async {
    try {
      final session = await FFmpegKit.executeWithArguments(arguments);
      final returnCode = await session.getReturnCode();
      return ReturnCode.isSuccess(returnCode);
    } catch (e) {
      debugPrint('❌ Error en executeCommandWithArgs: $e');
      return false;
    }
  }

  Future<bool> executeCommand(String command) async {
    try {
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      return ReturnCode.isSuccess(returnCode);
    } catch (e) {
      debugPrint('❌ Error en executeCommand: $e');
      return false;
    }
  }

  void cancel() {
    _currentSession?.cancel();
    _isProcessing = false;
    _currentSession = null;
    _statusMessage = 'Cancelado';
    debugPrint('⛔ Procesamiento cancelado');
  }

  Future<List<String>> getAvailableCodecs() async {
    try {
      final session = await FFmpegKit.execute('-codecs');
      final output = await session.getOutput() ?? '';
      return output
          .split('\n')
          .where((line) => line.contains('V') && line.contains('DEV'))
          .map((line) => line.split(' ').last.trim())
          .toList();
    } catch (e) {
      debugPrint('❌ Error al obtener códecs: $e');
      return [];
    }
  }

  Future<bool> _executeAsync(
    List<String> arguments,
    int effectiveDuration,
    Function(double)? onProgress,
    Function(String)? onLog, {
    String? rawCommand,
  }) async {
    final completer = Completer<bool>();

    try {
      void onComplete(dynamic session) {
        session.getReturnCode().then((returnCode) {
          final success = ReturnCode.isSuccess(returnCode);
          _statusMessage = success ? '✅ Completado' : '❌ Error';
          if (success) {
            _progress = 1.0;
            onProgress?.call(1.0);
          } else {
            session.getOutput().then((o) => debugPrint('❌ FFmpeg output: $o'));
          }
          _currentSession = null;
          completer.complete(success);
        }).catchError((_) {
          _currentSession = null;
          completer.complete(false);
        });
      }

      void onStatistics(Statistics stats) {
        final time = stats.getTime();
        if (time > 0) {
          double p = time / effectiveDuration;
          if (p > 1.0) p = 1.0;
          _progress = p;
          onProgress?.call(p);
        }
      }

      void onLogCallback(dynamic log) {
        final msg = log.getMessage() as String;
        onLog?.call(msg);
      }

      if (rawCommand != null) {
        _currentSession = await FFmpegKit.executeAsync(
            rawCommand, onComplete, onLogCallback, onStatistics);
      } else {
        final command = arguments.join(' ');
        debugPrint('⚙️ Comando FFmpeg: $command');
        _currentSession = await FFmpegKit.executeAsync(
            command, onComplete, onLogCallback, onStatistics);
      }
      return await completer.future;
    } catch (e) {
      _currentSession = null;
      _statusMessage = '❌ Error: $e';
      debugPrint('❌ Excepción: $e');
      return false;
    }
  }
}