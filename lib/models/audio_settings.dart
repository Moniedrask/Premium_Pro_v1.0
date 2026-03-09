class AudioSettings {
  String codec;          // aac, mp3, opus, flac, wav
  int bitrate;           // kbps (solo para lossy)
  int sampleRate;        // Hz (22050, 32000, 44100, 48000, 96000, 192000)
  String channels;       // mono, stereo, 5.1, 7.1
  bool normalize;        // normalizar volumen
  double normalizeTarget; // LUFS o pico
  bool removeNoise;      // reducción de ruido (requiere IA)
  bool aiEnabled;        // si IA está activa
  int compressionLevel;  // 0-9 para FLAC
  int bitDepth;          // 16, 24, 32 (para WAV/FLAC)

  AudioSettings({
    this.codec = 'aac',
    this.bitrate = 128,
    this.sampleRate = 48000,
    this.channels = 'stereo',
    this.normalize = false,
    this.normalizeTarget = -16.0,
    this.removeNoise = false,
    this.aiEnabled = false,
    this.compressionLevel = 5,
    this.bitDepth = 16,
  });

  Map<String, dynamic> toJson() {
    return {
      'codec': codec,
      'bitrate': bitrate,
      'sampleRate': sampleRate,
      'channels': channels,
      'normalize': normalize,
      'normalizeTarget': normalizeTarget,
      'removeNoise': removeNoise,
      'aiEnabled': aiEnabled,
      'compressionLevel': compressionLevel,
      'bitDepth': bitDepth,
    };
  }

  factory AudioSettings.fromJson(Map<String, dynamic> json) {
    return AudioSettings(
      codec: json['codec'] ?? 'aac',
      bitrate: json['bitrate'] ?? 128,
      sampleRate: json['sampleRate'] ?? 48000,
      channels: json['channels'] ?? 'stereo',
      normalize: json['normalize'] ?? false,
      normalizeTarget: json['normalizeTarget'] ?? -16.0,
      removeNoise: json['removeNoise'] ?? false,
      aiEnabled: json['aiEnabled'] ?? false,
      compressionLevel: json['compressionLevel'] ?? 5,
      bitDepth: json['bitDepth'] ?? 16,
    );
  }
}