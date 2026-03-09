import 'dart:ui';

enum LayerType { video, audio, text, image }

abstract class TimelineLayer {
  String id;
  String name;
  LayerType type;
  Duration start; // inicio en la línea de tiempo
  Duration duration; // duración
  bool muted; // solo para audio/video
  double volume; // solo para audio
  double opacity; // para video/imagen/texto
  Duration fadeIn; // duración del fade in al inicio (ms)
  Duration fadeOut; // duración del fade out al final (ms)

  TimelineLayer({
    required this.id,
    required this.name,
    required this.type,
    required this.start,
    required this.duration,
    this.muted = false,
    this.volume = 1.0,
    this.opacity = 1.0,
    this.fadeIn = Duration.zero,
    this.fadeOut = Duration.zero,
  });

  Map<String, dynamic> toJson();
  factory TimelineLayer.fromJson(Map<String, dynamic> json);
}

class VideoLayer extends TimelineLayer {
  String filePath;
  double speed; // factor de velocidad (0.1 a 16)
  List<VideoEffect> effects; // efectos aplicados

  VideoLayer({
    required super.id,
    required super.name,
    required super.start,
    required super.duration,
    required this.filePath,
    this.speed = 1.0,
    this.effects = const [],
    super.muted = false,
    super.volume = 1.0,
    super.opacity = 1.0,
    super.fadeIn,
    super.fadeOut,
  }) : super(type: LayerType.video);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.index,
        'start': start.inMilliseconds,
        'duration': duration.inMilliseconds,
        'filePath': filePath,
        'speed': speed,
        'effects': effects.map((e) => e.toJson()).toList(),
        'muted': muted,
        'volume': volume,
        'opacity': opacity,
        'fadeIn': fadeIn.inMilliseconds,
        'fadeOut': fadeOut.inMilliseconds,
      };

  static VideoLayer fromJson(Map<String, dynamic> json) {
    return VideoLayer(
      id: json['id'],
      name: json['name'],
      start: Duration(milliseconds: json['start']),
      duration: Duration(milliseconds: json['duration']),
      filePath: json['filePath'],
      speed: json['speed'] ?? 1.0,
      effects: (json['effects'] as List?)?.map((e) => VideoEffect.fromJson(e)).toList() ?? [],
      muted: json['muted'] ?? false,
      volume: json['volume'] ?? 1.0,
      opacity: json['opacity'] ?? 1.0,
      fadeIn: Duration(milliseconds: json['fadeIn'] ?? 0),
      fadeOut: Duration(milliseconds: json['fadeOut'] ?? 0),
    );
  }
}

class AudioLayer extends TimelineLayer {
  String filePath;
  List<AudioEffect> effects; // fade, eq, etc. (por definir)

  AudioLayer({
    required super.id,
    required super.name,
    required super.start,
    required super.duration,
    required this.filePath,
    this.effects = const [],
    super.muted = false,
    super.volume = 1.0,
    super.fadeIn,
    super.fadeOut,
  }) : super(type: LayerType.audio);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.index,
        'start': start.inMilliseconds,
        'duration': duration.inMilliseconds,
        'filePath': filePath,
        'effects': [], // por implementar
        'muted': muted,
        'volume': volume,
        'fadeIn': fadeIn.inMilliseconds,
        'fadeOut': fadeOut.inMilliseconds,
      };

  static AudioLayer fromJson(Map<String, dynamic> json) {
    return AudioLayer(
      id: json['id'],
      name: json['name'],
      start: Duration(milliseconds: json['start']),
      duration: Duration(milliseconds: json['duration']),
      filePath: json['filePath'],
      muted: json['muted'] ?? false,
      volume: json['volume'] ?? 1.0,
      fadeIn: Duration(milliseconds: json['fadeIn'] ?? 0),
      fadeOut: Duration(milliseconds: json['fadeOut'] ?? 0),
    );
  }
}

class TextLayer extends TimelineLayer {
  String text;
  String fontFamily;
  double fontSize;
  Color color;
  Offset position; // posición en el frame (0-1 normalizado)
  double rotation; // grados

  TextLayer({
    required super.id,
    required super.name,
    required super.start,
    required super.duration,
    required this.text,
    this.fontFamily = 'Roboto',
    this.fontSize = 24,
    this.color = Colors.white,
    this.position = Offset.zero,
    this.rotation = 0,
    super.opacity = 1.0,
    super.fadeIn,
    super.fadeOut,
  }) : super(type: LayerType.text);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.index,
        'start': start.inMilliseconds,
        'duration': duration.inMilliseconds,
        'text': text,
        'fontFamily': fontFamily,
        'fontSize': fontSize,
        'color': color.value,
        'positionDx': position.dx,
        'positionDy': position.dy,
        'rotation': rotation,
        'opacity': opacity,
        'fadeIn': fadeIn.inMilliseconds,
        'fadeOut': fadeOut.inMilliseconds,
      };

  static TextLayer fromJson(Map<String, dynamic> json) {
    return TextLayer(
      id: json['id'],
      name: json['name'],
      start: Duration(milliseconds: json['start']),
      duration: Duration(milliseconds: json['duration']),
      text: json['text'],
      fontFamily: json['fontFamily'] ?? 'Roboto',
      fontSize: json['fontSize'] ?? 24,
      color: Color(json['color'] ?? Colors.white.value),
      position: Offset(json['positionDx'] ?? 0, json['positionDy'] ?? 0),
      rotation: json['rotation'] ?? 0,
      opacity: json['opacity'] ?? 1.0,
      fadeIn: Duration(milliseconds: json['fadeIn'] ?? 0),
      fadeOut: Duration(milliseconds: json['fadeOut'] ?? 0),
    );
  }
}

class ImageLayer extends TimelineLayer {
  String filePath;
  Offset position;
  double scale;
  double rotation;

  ImageLayer({
    required super.id,
    required super.name,
    required super.start,
    required super.duration,
    required this.filePath,
    this.position = Offset.zero,
    this.scale = 1.0,
    this.rotation = 0,
    super.opacity = 1.0,
    super.fadeIn,
    super.fadeOut,
  }) : super(type: LayerType.image);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.index,
        'start': start.inMilliseconds,
        'duration': duration.inMilliseconds,
        'filePath': filePath,
        'positionDx': position.dx,
        'positionDy': position.dy,
        'scale': scale,
        'rotation': rotation,
        'opacity': opacity,
        'fadeIn': fadeIn.inMilliseconds,
        'fadeOut': fadeOut.inMilliseconds,
      };

  static ImageLayer fromJson(Map<String, dynamic> json) {
    return ImageLayer(
      id: json['id'],
      name: json['name'],
      start: Duration(milliseconds: json['start']),
      duration: Duration(milliseconds: json['duration']),
      filePath: json['filePath'],
      position: Offset(json['positionDx'] ?? 0, json['positionDy'] ?? 0),
      scale: json['scale'] ?? 1.0,
      rotation: json['rotation'] ?? 0,
      opacity: json['opacity'] ?? 1.0,
      fadeIn: Duration(milliseconds: json['fadeIn'] ?? 0),
      fadeOut: Duration(milliseconds: json['fadeOut'] ?? 0),
    );
  }
}