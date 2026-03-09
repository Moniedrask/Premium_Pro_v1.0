import 'timeline_layer.dart';

class TimelineProject {
  String name;
  Duration duration; // duración total del proyecto
  int width; // resolución de salida
  int height;
  double fps; // fotogramas por segundo
  List<TimelineLayer> layers;

  TimelineProject({
    required this.name,
    required this.duration,
    this.width = 1920,
    this.height = 1080,
    this.fps = 30,
    this.layers = const [],
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'duration': duration.inMilliseconds,
        'width': width,
        'height': height,
        'fps': fps,
        'layers': layers.map((l) => l.toJson()).toList(),
      };

  factory TimelineProject.fromJson(Map<String, dynamic> json) {
    return TimelineProject(
      name: json['name'],
      duration: Duration(milliseconds: json['duration']),
      width: json['width'] ?? 1920,
      height: json['height'] ?? 1080,
      fps: json['fps'] ?? 30,
      layers: (json['layers'] as List)
          .map((l) {
            switch (l['type']) {
              case 0:
                return VideoLayer.fromJson(l);
              case 1:
                return AudioLayer.fromJson(l);
              case 2:
                return TextLayer.fromJson(l);
              case 3:
                return ImageLayer.fromJson(l);
              default:
                return null;
            }
          })
          .whereType<TimelineLayer>()
          .toList(),
    );
  }
}