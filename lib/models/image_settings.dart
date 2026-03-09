import '../widgets/filter_selector.dart';

class ImageSettings {
  String format;
  int quality;
  int compressionLevel;
  bool preserveMetadata;
  int maxWidth;
  int maxHeight;
  bool aiUpscale;
  int aiScale;
  String filter;
  bool aiEnabled;

  // Nuevos campos
  FilterType? filterType;
  double? filterIntensity;

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
    this.filterType = FilterType.none,
    this.filterIntensity = 0.5,
  });

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
      'filterType': filterType?.index,
      'filterIntensity': filterIntensity,
    };
  }

  factory ImageSettings.fromJson(Map<String, dynamic> json) {
    return ImageSettings(
      format: json['format'] ?? 'jpeg',
      quality: json['quality'] ?? 85,
      compressionLevel: json['compressionLevel'] ?? 6,
      preserveMetadata: json['preserveMetadata'] ?? false,
      maxWidth: json['maxWidth'] ?? 0,
      maxHeight: json['maxHeight'] ?? 0,
      aiUpscale: json['aiUpscale'] ?? false,
      aiScale: json['aiScale'] ?? 2,
      filter: json['filter'] ?? 'lanczos',
      aiEnabled: json['aiEnabled'] ?? false,
      filterType: json['filterType'] != null ? FilterType.values[json['filterType']] : FilterType.none,
      filterIntensity: json['filterIntensity'] ?? 0.5,
    );
  }
}