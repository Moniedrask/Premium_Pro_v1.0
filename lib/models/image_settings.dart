class ImageSettings {
  String format;          // jpeg, png, webp, avif
  int quality;            // 1-100 (para lossy)
  int maxWidth;           // 0 = original
  int maxHeight;          // 0 = original
  bool stripMetadata;     // eliminar EXIF
  double brightness;      // -1.0 a 1.0
  double contrast;        // -1.0 a 1.0
  double saturation;      // -1.0 a 1.0
  bool autoEnhance;       // placeholder

  ImageSettings({
    this.format = 'jpeg',
    this.quality = 85,
    this.maxWidth = 0,
    this.maxHeight = 0,
    this.stripMetadata = false,
    this.brightness = 0.0,
    this.contrast = 0.0,
    this.saturation = 0.0,
    this.autoEnhance = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'format': format,
      'quality': quality,
      'maxWidth': maxWidth,
      'maxHeight': maxHeight,
      'stripMetadata': stripMetadata,
      'brightness': brightness,
      'contrast': contrast,
      'saturation': saturation,
      'autoEnhance': autoEnhance,
    };
  }

  factory ImageSettings.fromJson(Map<String, dynamic> json) {
    return ImageSettings(
      format: json['format'] ?? 'jpeg',
      quality: json['quality'] ?? 85,
      maxWidth: json['maxWidth'] ?? 0,
      maxHeight: json['maxHeight'] ?? 0,
      stripMetadata: json['stripMetadata'] ?? false,
      brightness: json['brightness']?.toDouble() ?? 0.0,
      contrast: json['contrast']?.toDouble() ?? 0.0,
      saturation: json['saturation']?.toDouble() ?? 0.0,
      autoEnhance: json['autoEnhance'] ?? false,
    );
  }
}