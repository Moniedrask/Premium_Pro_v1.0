class ImageSettings {
  String format;          // jpeg, png, webp, avif
  int quality;            // 1-100 (para lossy)
  int compressionLevel;   // 0-9 (para png)
  bool preserveMetadata;  // conservar EXIF
  int maxWidth;           // 0 = original
  int maxHeight;          // 0 = original
  bool aiUpscale;         // usar IA para escalado
  int aiScale;            // 2, 4, 8, 16 (pero limitado a 4 en v1.0)
  String filter;          // 'lanczos', 'bicubic', 'nearest'
  bool aiEnabled;

  ImageSettings({
    this.format = 'jpeg',
    this.quality = 85,
    this.compressionLevel = 6,
    this.preserveMetadata = false,
    this.maxWidth = 0,
    this.maxHeight = 0,
    this.aiUpscale = false,
    this.aiScale = 2,
    this.filter = 'lanczos',
    this.aiEnabled = false,
  }) {
    // Limitar aiScale a un máximo de 4 (según requerimiento)
    if (aiScale > 4) aiScale = 4;
  }

  Map<String, dynamic> toJson() {
    return {
      'format': format,
      'quality': quality,
      'compressionLevel': compressionLevel,
      'preserveMetadata': preserveMetadata,
      'maxWidth': maxWidth,
      'maxHeight': maxHeight,
      'aiUpscale': aiUpscale,
      'aiScale': aiScale,
      'filter': filter,
      'aiEnabled': aiEnabled,
    };
  }

  factory ImageSettings.fromJson(Map<String, dynamic> json) {
    int aiScale = json['aiScale'] ?? 2;
    if (aiScale > 4) aiScale = 4; // Limitar a x4
    return ImageSettings(
      format: json['format'] ?? 'jpeg',
      quality: json['quality'] ?? 85,
      compressionLevel: json['compressionLevel'] ?? 6,
      preserveMetadata: json['preserveMetadata'] ?? false,
      maxWidth: json['maxWidth'] ?? 0,
      maxHeight: json['maxHeight'] ?? 0,
      aiUpscale: json['aiUpscale'] ?? false,
      aiScale: aiScale,
      filter: json['filter'] ?? 'lanczos',
      aiEnabled: json['aiEnabled'] ?? false,
    );
  }
}