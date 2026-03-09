class StabilizationService {
  /// Aplica estabilización de video usando el filtro vidstab de FFmpeg
  static Future<bool> stabilize({
    required String inputPath,
    required String outputPath,
    required dynamic ffmpeg, // FFmpegWrapper
  }) async {
    // Paso 1: analizar movimiento (genera archivo .trf)
    final analyzeArgs = [
      '-i', inputPath,
      '-vf', 'vidstabdetect=shakiness=5:accuracy=15:result=transform.trf',
      '-f', 'null', '-',
    ];
    final analyzeSuccess = await ffmpeg.executeCommandWithArgs(analyzeArgs);
    if (!analyzeSuccess) return false;

    // Paso 2: aplicar estabilización
    final stabilizeArgs = [
      '-i', inputPath,
      '-vf', 'vidstabtransform=input=transform.trf:zoom=1:smoothing=30',
      '-y', outputPath,
    ];
    return await ffmpeg.executeCommandWithArgs(stabilizeArgs);
  }
}