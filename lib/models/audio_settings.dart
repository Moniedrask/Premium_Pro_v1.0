class AudioSettings {
  String codec;           // aac, mp3, opus, flac, wav
  int bitrate;            // kbps (excepto flac/wav)
  int sampleRate;         // Hz
  String channels;        // mono, stereo
  bool normalize;         // aplicar normalización de pico
  double fadeInDuration;  // segundos
  double fadeOutDuration; // segundos
  bool reduceNoise;       // placeholder (requiere IA)

  AudioSettings({
    this.codec = 'aac',
    this.bitrate = 128,
    this.sampleRate = 48000,
    this.channels = 'stereo',
    this.normalize = false,
    this.fadeInDuration = 0.0,
    this.fadeOutDuration = 0.0,
    this.reduceNoise = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'codec': codec,
      'bitrate': bitrate,
      'sampleRate': sampleRate,
      'channels': channels,
      'normalize': normalize,
      'fadeIn': fadeInDuration,
      'fadeOut': fadeOutDuration,
      'reduceNoise': reduceNoise,
    };
  }

  factory AudioSettings.fromJson(Map<String, dynamic> json) {
    return AudioSettings(
      codec: json['codec'] ?? 'aac',
      bitrate: json['bitrate'] ?? 128,
      sampleRate: json['sampleRate'] ?? 48000,
      channels: json['channels'] ?? 'stereo',
      normalize: json['normalize'] ?? false,
      fadeInDuration: json['fadeIn']?.toDouble() ?? 0.0,
      fadeOutDuration: json['fadeOut']?.toDouble() ?? 0.0,
      reduceNoise: json['reduceNoise'] ?? false,
    );
  }
}