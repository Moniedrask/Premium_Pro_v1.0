class CompressionSettings {
  String videoCodec;
  int videoBitrate;
  String preset;
  int crf;
  int keyframeInterval;
  String profile;
  int level;
  bool hardwareAcceleration;
  String audioCodec;
  int audioBitrate;
  int sampleRate;
  String audioChannels;
  String imageFormat;
  int imageQuality;
  bool stripMetadata;
  int maxWidth;
  int maxHeight;
  bool aiEnabled;
  String aiModel;
  int aiScale;
  String outputFileName;
  String outputFolder;

  CompressionSettings({
    this.videoCodec = 'libx264',
    this.videoBitrate = 2500,
    this.preset = 'medium',
    this.crf = 23,
    this.keyframeInterval = 48,
    this.profile = 'main',
    this.level = 40,
    this.hardwareAcceleration = true,
    this.audioCodec = 'aac',
    this.audioBitrate = 128,
    this.sampleRate = 48000,
    this.audioChannels = 'stereo',
    this.imageFormat = 'jpeg',
    this.imageQuality = 85,
    this.stripMetadata = false,
    this.maxWidth = 0,
    this.maxHeight = 0,
    this.aiEnabled = false, // DESACTIVADO POR DEFECTO
    this.aiModel = 'real-esrgan',
    this.aiScale = 2,
    this.outputFileName = 'premium_pro_export',
    this.outputFolder = '/storage/emulated/0/PremiumPro',
  });

  /// Genera comando FFmpeg para VIDEO
  String toFFmpegVideoCommand(String inputPath, String outputPath) {
    final safeInput = _sanitizePath(inputPath);
    final safeOutput = _sanitizePath(outputPath);

    final cmd = StringBuffer();

    cmd.write('-i "$safeInput"');

    // Video
    cmd.write(' -c:v $videoCodec');
    if (videoCodec == 'libx264' || videoCodec == 'libx265') {
      cmd.write(' -preset $preset');
      cmd.write(' -crf $crf');
      cmd.write(' -profile:v $profile');
      cmd.write(' -level $level');
      cmd.write(' -g $keyframeInterval');
    } else {
      cmd.write(' -b:v ${videoBitrate}k');
    }

    // Aceleración por hardware (Android MediaCodec)
    if (hardwareAcceleration) {
      if (videoCodec == 'libx264') {
        cmd.write(' -c:v h264_mediacodec');
      } else if (videoCodec == 'libx265') {
        cmd.write(' -c:v hevc_mediacodec');
      }
    }

    // Audio
    cmd.write(' -c:a $audioCodec');
    if (audioCodec != 'pcm_s16le' && audioCodec != 'flac') {
      cmd.write(' -b:a ${audioBitrate}k');
    }
    cmd.write(' -ar $sampleRate');
    if (audioChannels == 'mono') {
      cmd.write(' -ac 1');
    } else if (audioChannels == 'stereo') {
      cmd.write(' -ac 2');
    }

    // Optimizaciones para streaming web
    cmd.write(' -movflags +faststart');

    // Sobrescribir sin preguntar
    cmd.write(' -y');

    // Salida
    cmd.write(' "$safeOutput"');

    return cmd.toString();
  }

  /// Genera comando FFmpeg para IMAGEN
  String toFFmpegImageCommand(String inputPath, String outputPath) {
    final safeInput = _sanitizePath(inputPath);
    final safeOutput = _sanitizePath(outputPath);

    final cmd = StringBuffer();
    cmd.write('-i "$safeInput"');

    // Escalado si hay límites
    if (maxWidth > 0 || maxHeight > 0) {
      String scale = '';
      if (maxWidth > 0 && maxHeight > 0) {
        scale = 'scale=$maxWidth:$maxHeight';
      } else if (maxWidth > 0) {
        scale = 'scale=$maxWidth:-1';
      } else {
        scale = 'scale=-1:$maxHeight';
      }
      cmd.write(' -vf "$scale"');
    }

    // Formato y calidad
    switch (imageFormat) {
      case 'jpeg':
        cmd.write(' -q:v $imageQuality');
        break;
      case 'png':
        cmd.write(' -compression_level $imageQuality');
        break;
      case 'webp':
        cmd.write(' -q:v $imageQuality -lossless 0');
        break;
      case 'avif':
        cmd.write(' -q:v $imageQuality');
        break;
    }

    // Metadatos
    if (stripMetadata) {
      cmd.write(' -map_metadata -1');
    }

    cmd.write(' -y "$safeOutput"');

    return cmd.toString();
  }

  /// Calcula estimación de tamaño de salida en MB
  double estimateOutputSizeMB(int durationSeconds) {
    int totalBitrate = videoBitrate + audioBitrate;
    double sizeBits = totalBitrate * 1000 * durationSeconds;
    double sizeBytes = sizeBits / 8;
    double sizeMB = sizeBytes / (1024 * 1024);
    return sizeMB;
  }

  /// Guarda configuración como JSON
  Map<String, dynamic> toJson() {
    return {
      'videoCodec': videoCodec,
      'videoBitrate': videoBitrate,
      'preset': preset,
      'crf': crf,
      'audioCodec': audioCodec,
      'audioBitrate': audioBitrate,
      'sampleRate': sampleRate,
      'imageFormat': imageFormat,
      'imageQuality': imageQuality,
      'aiEnabled': aiEnabled,
    };
  }

  /// Carga configuración desde JSON
  factory CompressionSettings.fromJson(Map<String, dynamic> json) {
    return CompressionSettings(
      videoCodec: json['videoCodec'] ?? 'libx264',
      videoBitrate: json['videoBitrate'] ?? 2500,
      preset: json['preset'] ?? 'medium',
      crf: json['crf'] ?? 23,
      audioCodec: json['audioCodec'] ?? 'aac',
      audioBitrate: json['audioBitrate'] ?? 128,
      sampleRate: json['sampleRate'] ?? 48000,
      imageFormat: json['imageFormat'] ?? 'jpeg',
      imageQuality: json['imageQuality'] ?? 85,
      aiEnabled: json['aiEnabled'] ?? false,
    );
  }

  /// Limpia caracteres peligrosos de rutas
  String _sanitizePath(String path) {
    // Eliminar caracteres que podrían causar inyección de comandos
    return path.replaceAll(RegExp(r'[;&|`$]'), '');
  }
}