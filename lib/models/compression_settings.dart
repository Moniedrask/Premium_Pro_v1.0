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
    this.aiEnabled = false,
    this.aiModel = 'real-esrgan',
    this.aiScale = 2,
    this.outputFileName = 'premium_pro_export',
    this.outputFolder = '/storage/emulated/0/PremiumPro',
  });

  String toFFmpegVideoCommand(String inputPath, String outputPath) {
    final safeInput = _sanitizePath(inputPath);
    final safeOutput = _sanitizePath(outputPath);
    
    final buffer = StringBuffer();
    
    buffer.write('-i "$safeInput"');
    buffer.write(' -c:v $videoCodec');
    if (videoCodec == 'libx264' || videoCodec == 'libx265') {
      buffer.write(' -preset $preset');
      buffer.write(' -crf $crf');
      buffer.write(' -profile:v $profile');
      buffer.write(' -level $level');
      buffer.write(' -g $keyframeInterval');
    } else {
      buffer.write(' -b:v ${videoBitrate}k');
    }
    
    if (hardwareAcceleration) {
      if (videoCodec == 'libx264') {
        buffer.write(' -c:v h264_mediacodec');
      } else if (videoCodec == 'libx265') {
        buffer.write(' -c:v hevc_mediacodec');
      }
    }
    
    buffer.write(' -c:a $audioCodec');
    if (audioCodec != 'pcm_s16le' && audioCodec != 'flac') {
      buffer.write(' -b:a ${audioBitrate}k');
    }
    buffer.write(' -ar $sampleRate');
    if (audioChannels == 'mono') {
      buffer.write(' -ac 1');
    } else if (audioChannels == 'stereo') {
      buffer.write(' -ac 2');
    }
    
    buffer.write(' -movflags +faststart');
    buffer.write(' -y');
    buffer.write(' "$safeOutput"');
    
    return buffer.toString();
  }

  String toFFmpegImageCommand(String inputPath, String outputPath) {
    final safeInput = _sanitizePath(inputPath);
    final safeOutput = _sanitizePath(outputPath);
    
    final buffer = StringBuffer();
    buffer.write('-i "$safeInput"');
    
    if (maxWidth > 0 || maxHeight > 0) {
      String scale;
      if (maxWidth > 0 && maxHeight > 0) {
        scale = 'scale=$maxWidth:$maxHeight';
      } else if (maxWidth > 0) {
        scale = 'scale=$maxWidth:-1';
      } else {
        scale = 'scale=-1:$maxHeight';
      }
      buffer.write(' -vf "$scale"');
    }
    
    switch (imageFormat) {
      case 'jpeg':
        buffer.write(' -q:v $imageQuality');
        break;
      case 'png':
        buffer.write(' -compression_level $imageQuality');
        break;
      case 'webp':
        buffer.write(' -q:v $imageQuality -lossless 0');
        break;
      case 'avif':
        buffer.write(' -q:v $imageQuality');
        break;
    }
    
    if (stripMetadata) {
      buffer.write(' -map_metadata -1');
    }
    
    buffer.write(' -y "$safeOutput"');
    
    return buffer.toString();
  }

  double estimateOutputSizeMB(int durationSeconds) {
    int totalBitrate = videoBitrate + audioBitrate;
    double sizeBits = totalBitrate * 1000 * durationSeconds;
    double sizeBytes = sizeBits / 8;
    double sizeMB = sizeBytes / (1024 * 1024);
    return sizeMB;
  }

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

  String _sanitizePath(String path) {
    return path.replaceAll(RegExp(r'[;&|`$]'), '');
  }
}