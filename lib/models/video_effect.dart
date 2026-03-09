enum VideoEffectType { none, negative, blackAndWhite, sepia, blur, bokeh }

class VideoEffect {
  final VideoEffectType type;
  final double intensity; // 0.0 a 1.0 para blur/bokeh

  VideoEffect({this.type = VideoEffectType.none, this.intensity = 0.0});

  Map<String, dynamic> toJson() => {
        'type': type.index,
        'intensity': intensity,
      };

  factory VideoEffect.fromJson(Map<String, dynamic> json) {
    return VideoEffect(
      type: VideoEffectType.values[json['type'] ?? 0],
      intensity: json['intensity'] ?? 0.0,
    );
  }

  String get ffmpegFilter {
    switch (type) {
      case VideoEffectType.negative:
        return 'negate';
      case VideoEffectType.blackAndWhite:
        return 'hue=s=0';
      case VideoEffectType.sepia:
        return 'colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131';
      case VideoEffectType.blur:
        return 'boxblur=${intensity * 10}:1';
      case VideoEffectType.bokeh:
        // Simulación básica de bokeh con desenfoque gaussiano
        return 'gblur=sigma=${intensity * 5}';
      default:
        return '';
    }
  }
}