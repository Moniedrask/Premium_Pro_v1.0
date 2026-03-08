class VideoSettings {
  String videoCodec;
  int videoBitrate;
  int crf;
  String preset;
  int keyframeInterval;
  String profile;
  int level;
  bool hardwareAcceleration;
  String audioCodec;
  int audioBitrate;
  int audioSampleRate;
  String audioChannels;
  
  // Interpolación de frames (sin IA)
  bool frameInterpolation;
  int targetFps;           // FPS objetivo (máximo 4x el original)
  
  // Escalado de resolución (sin IA)
  bool resolutionUpscale;
  int targetWidth;          // Ancho objetivo (0 = mantener proporción)
  int targetHeight;         // Alto objetivo (0 = mantener proporción)
  int maxScaleFactor;       // Factor máximo de escala (4x)
  
  // IA (opcional, para futuras versiones)
  bool aiInterpolation;
  int aiTargetFps;
  bool aiStabilization;
  
  bool preserveMetadata;
  bool aiEnabled;
  bool saveAsDefault;

  VideoSettings({
    this.videoCodec = 'libx264',
    this.videoBitrate = 2500,
    this.crf = 23,
    this.preset = 'medium',
    this.keyframeInterval = 48,
    this.profile = 'high',
    this.level = 41,
    this.hardwareAcceleration = true,
    this.audioCodec = 'aac',
    this.audioBitrate = 128,
    this.audioSampleRate = 48000,
    this.audioChannels = 'stereo',
    
    // Interpolación
    this.frameInterpolation = false,
    this.targetFps = 60,
    
    // Escalado
    this.resolutionUpscale = false,
    this.targetWidth = 1920,
    this.targetHeight = 1080,
    this.maxScaleFactor = 4,  // Límite x4
    
    // IA
    this.aiInterpolation = false,
    this.aiTargetFps = 60,
    this.aiStabilization = false,
    
    this.preserveMetadata = false,
    this.aiEnabled = false,
    this.saveAsDefault = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'videoCodec': videoCodec,
      'videoBitrate': videoBitrate,
      'crf': crf,
      'preset': preset,
      'keyframeInterval': keyframeInterval,
      'profile': profile,
      'level': level,
      'hardwareAcceleration': hardwareAcceleration,
      'audioCodec': audioCodec,
      'audioBitrate': audioBitrate,
      'audioSampleRate': audioSampleRate,
      'audioChannels': audioChannels,
      'frameInterpolation': frameInterpolation,
      'targetFps': targetFps,
      'resolutionUpscale': resolutionUpscale,
      'targetWidth': targetWidth,
      'targetHeight': targetHeight,
      'maxScaleFactor': maxScaleFactor,
      'aiInterpolation': aiInterpolation,
      'aiTargetFps': aiTargetFps,
      'aiStabilization': aiStabilization,
      'preserveMetadata': preserveMetadata,
      'aiEnabled': aiEnabled,
    };
  }

  factory VideoSettings.fromJson(Map<String, dynamic> json) {
    return VideoSettings(
      videoCodec: json['videoCodec'] ?? 'libx264',
      videoBitrate: json['videoBitrate'] ?? 2500,
      crf: json['crf'] ?? 23,
      preset: json['preset'] ?? 'medium',
      keyframeInterval: json['keyframeInterval'] ?? 48,
      profile: json['profile'] ?? 'high',
      level: json['level'] ?? 41,
      hardwareAcceleration: json['hardwareAcceleration'] ?? true,
      audioCodec: json['audioCodec'] ?? 'aac',
      audioBitrate: json['audioBitrate'] ?? 128,
      audioSampleRate: json['audioSampleRate'] ?? 48000,
      audioChannels: json['audioChannels'] ?? 'stereo',
      frameInterpolation: json['frameInterpolation'] ?? false,
      targetFps: json['targetFps'] ?? 60,
      resolutionUpscale: json['resolutionUpscale'] ?? false,
      targetWidth: json['targetWidth'] ?? 1920,
      targetHeight: json['targetHeight'] ?? 1080,
      maxScaleFactor: json['maxScaleFactor'] ?? 4,
      aiInterpolation: json['aiInterpolation'] ?? false,
      aiTargetFps: json['aiTargetFps'] ?? 60,
      aiStabilization: json['aiStabilization'] ?? false,
      preserveMetadata: json['preserveMetadata'] ?? false,
      aiEnabled: json['aiEnabled'] ?? false,
    );
  }

  String get fileExtension {
    switch (videoCodec) {
      case 'libvpx-vp9':
        return 'webm';
      default:
        return 'mp4';
    }
  }
}