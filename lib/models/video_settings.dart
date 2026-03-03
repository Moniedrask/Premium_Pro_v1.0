/// Configuración para procesamiento de video
/// Todos los valores tienen defaults seguros para la versión 1.0
class VideoSettings {
  // Códec de video
  String videoCodec;        // libx264, libx265, libvpx-vp9, av1
  
  // Control de calidad/bitrate
  int videoBitrate;         // kbps (usado en códecs sin CRF)
  int crf;                  // 0-51 (usado en x264/x265)
  String preset;            // ultrafast, fast, medium, slow, veryslow
  
  // Parámetros avanzados
  int keyframeInterval;     // GOP size (frames)
  String profile;           // baseline, main, high (para H.264)
  int level;                // 3.0, 3.1, 4.0, 4.1, etc. (multiplicado por 10: 30, 31, 40, 41)
  bool hardwareAcceleration; // usar MediaCodec en Android
  
  // Audio asociado
  String audioCodec;        // aac, mp3, opus, flac, copy
  int audioBitrate;         // kbps
  int audioSampleRate;      // Hz
  String audioChannels;     // mono, stereo
  
  // IA (opcional)
  bool aiInterpolation;     // interpolación de frames con IA
  int aiTargetFps;          // 30, 60, 120, 240, 480
  bool aiStabilization;     // estabilización con IA
  
  // Metadatos
  bool preserveMetadata;    // conservar metadatos del video
  
  // Flags internos (no editables por usuario directamente)
  bool aiEnabled;           // si IA está activa globalmente

  VideoSettings({
    // Video
    this.videoCodec = 'libx264',
    this.videoBitrate = 2500,
    this.crf = 23,
    this.preset = 'medium',
    this.keyframeInterval = 48,
    this.profile = 'high',
    this.level = 41,
    this.hardwareAcceleration = true,
    
    // Audio
    this.audioCodec = 'aac',
    this.audioBitrate = 128,
    this.audioSampleRate = 48000,
    this.audioChannels = 'stereo',
    
    // IA
    this.aiInterpolation = false,
    this.aiTargetFps = 60,
    this.aiStabilization = false,
    
    // Metadatos
    this.preserveMetadata = false,
    
    // Estado IA
    this.aiEnabled = false,
  });

  /// Convierte a JSON para guardar presets
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
      'aiInterpolation': aiInterpolation,
      'aiTargetFps': aiTargetFps,
      'aiStabilization': aiStabilization,
      'preserveMetadata': preserveMetadata,
      'aiEnabled': aiEnabled,
    };
  }

  /// Carga desde JSON
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
      aiInterpolation: json['aiInterpolation'] ?? false,
      aiTargetFps: json['aiTargetFps'] ?? 60,
      aiStabilization: json['aiStabilization'] ?? false,
      preserveMetadata: json['preserveMetadata'] ?? false,
      aiEnabled: json['aiEnabled'] ?? false,
    );
  }

  /// Genera extensión de archivo según códec
  String get fileExtension {
    switch (videoCodec) {
      case 'libx264':
        return 'mp4';
      case 'libx265':
        return 'mp4';
      case 'libvpx-vp9':
        return 'webm';
      case 'av1':
        return 'mp4';
      default:
        return 'mp4';
    }
  }
}