import 'package:flutter/material.dart';

class SpeedSegment {
  final Duration start;
  final Duration end;
  final double speed; // 0.1 a 16.0
  final Color color;

  SpeedSegment({
    required this.start,
    required this.end,
    this.speed = 1.0,
    this.color = Colors.blueAccent,
  });

  Map<String, dynamic> toJson() => {
        'start': start.inMilliseconds,
        'end': end.inMilliseconds,
        'speed': speed,
      };

  factory SpeedSegment.fromJson(Map<String, dynamic> json) {
    return SpeedSegment(
      start: Duration(milliseconds: json['start']),
      end: Duration(milliseconds: json['end']),
      speed: json['speed'] ?? 1.0,
    );
  }
}

class SpeedRampService {
  /// Genera el filtro setpts para FFmpeg a partir de una lista de segmentos
  static String buildSetptsFilter(List<SpeedSegment> segments, Duration totalDuration) {
    if (segments.isEmpty) return 'setpts=PTS';

    String expr = 'setpts=\'';
    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final startSec = seg.start.inMilliseconds / 1000.0;
      final endSec = seg.end.inMilliseconds / 1000.0;
      final speedFactor = 1.0 / seg.speed; // setpts usa el inverso
      if (i > 0) expr += ':';
      expr += 'if(between(T,$startSec,$endSec),PTS*$speedFactor';
    }
    expr += ',PTS' + ')' * segments.length + '\'';
    return expr;
  }
}