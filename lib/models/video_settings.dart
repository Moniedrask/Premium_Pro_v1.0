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
  bool aiInterpolation;
  int aiTargetFps;
  bool aiStabilization;
  bool preserveMetadata;
  bool aiEnabled;
  bool saveAsDefault; // NUEVO

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
    this.aiInterpolation = false,
    this.aiTargetFps = 60,
    this.aiStabilization = false,
    this.preserveMetadata = false,
    this.aiEnabled = false,
    this.saveAsDefault = false, // NUEVO
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
      'aiInterpolation': aiInterpolation,
      'aiTargetFps': aiTargetFps,
      'aiStabilization': aiStabilization,
      'preserveMetadata': preserveMetadata,
      'aiEnabled': aiEnabled,
      // 'saveAsDefault' no se guarda en JSON porque es temporal
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