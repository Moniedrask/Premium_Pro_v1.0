// Dentro de la clase FFmpegWrapper

Future<bool> processAudio({
  required String inputPath,
  required String outputPath,
  required AudioSettings settings,
  Function(double progress)? onProgress,
}) async {
  if (_isProcessing) return false;
  _isProcessing = true;
  _progress = 0.0;

  // Construir argumentos
  List<String> args = ['-i', inputPath];

  // Codec
  String codec = settings.codec;
  if (codec == 'aac') args.addAll(['-c:a', 'aac']);
  else if (codec == 'mp3') args.addAll(['-c:a', 'libmp3lame']);
  else if (codec == 'opus') args.addAll(['-c:a', 'libopus']);
  else if (codec == 'flac') args.addAll(['-c:a', 'flac']);
  else if (codec == 'wav') args.addAll(['-c:a', 'pcm_s16le']);

  // Bitrate (si aplica)
  if (codec != 'flac' && codec != 'wav') {
    args.addAll(['-b:a', '${settings.bitrate}k']);
  }

  // Sample rate
  args.addAll(['-ar', settings.sampleRate.toString()]);

  // Canales
  if (settings.channels == 'mono') args.addAll(['-ac', '1']);
  else if (settings.channels == 'stereo') args.addAll(['-ac', '2']);

  // Normalización (usar filtro loudnorm o volume)
  if (settings.normalize) {
    args.addAll(['-af', 'loudnorm=I=-16:LRA=11:TP=-1.5']);
  }

  // Fades
  if (settings.fadeInDuration > 0) {
    args.addAll(['-af', 'fade=t=in:st=0:d=${settings.fadeInDuration}']);
  }
  if (settings.fadeOutDuration > 0) {
    // Nota: necesitaríamos duración total para fade out; se omite por simplicidad
  }

  args.addAll(['-y', outputPath]);

  return _executeWithProgress(args, onProgress);
}

Future<bool> processImage({
  required String inputPath,
  required String outputPath,
  required ImageSettings settings,
  Function(double progress)? onProgress,
}) async {
  if (_isProcessing) return false;
  _isProcessing = true;
  _progress = 0.0;

  List<String> args = ['-i', inputPath];

  // Redimensionar si es necesario
  if (settings.maxWidth > 0 || settings.maxHeight > 0) {
    String scale = '';
    if (settings.maxWidth > 0 && settings.maxHeight > 0) {
      scale = 'scale=$settings.maxWidth:$settings.maxHeight';
    } else if (settings.maxWidth > 0) {
      scale = 'scale=$settings.maxWidth:-1';
    } else {
      scale = 'scale=-1:$settings.maxHeight';
    }
    args.addAll(['-vf', scale]);
  }

  // Formato y calidad
  switch (settings.format) {
    case 'jpeg':
      args.addAll(['-c:v', 'mjpeg', '-q:v', settings.quality.toString()]);
      break;
    case 'png':
      args.addAll(['-c:v', 'png', '-compression_level', settings.quality.toString()]);
      break;
    case 'webp':
      args.addAll(['-c:v', 'libwebp', '-quality', settings.quality.toString()]);
      break;
    case 'avif':
      args.addAll(['-c:v', 'libaom-av1', '-crf', '30']); // simplificado
      break;
  }

  if (settings.stripMetadata) {
    args.addAll(['-map_metadata', '-1']);
  }

  // Ajustes de brillo/contraste/saturación con filtros eq
  if (settings.brightness != 0.0 || settings.contrast != 0.0 || settings.saturation != 0.0) {
    String eq = 'eq=';
    if (settings.brightness != 0.0) eq += 'brightness=${settings.brightness}:';
    if (settings.contrast != 0.0) eq += 'contrast=${1.0 + settings.contrast}:';
    if (settings.saturation != 0.0) eq += 'saturation=${1.0 + settings.saturation}';
    args.addAll(['-vf', eq]);
  }

  args.addAll(['-y', outputPath]);

  return _executeWithProgress(args, onProgress);
}

// Método auxiliar para ejecutar con progreso
Future<bool> _executeWithProgress(List<String> args, Function(double)? onProgress) async {
  try {
    _currentSession = await FFmpegKit.executeWithArguments(
      args,
      (session) async {
        final rc = await session.getReturnCode();
        _isProcessing = false;
        _currentSession = null;
        if (ReturnCode.isSuccess(rc)) {
          _progress = 1.0;
          onProgress?.call(1.0);
        }
      },
      (log) {},
      (statistics) {
        // Estimación simple
        final time = statistics.getTime();
        if (time > 0) {
          double estimated = time / 1000000; // asume 1 segundo por cada 1e6 microseg?
          if (estimated > 1.0) estimated = 1.0;
          _progress = estimated;
          onProgress?.call(_progress);
        }
      },
    );
    await _currentSession?.await();
    return true;
  } catch (e) {
    _isProcessing = false;
    _currentSession = null;
    return false;
  }
}