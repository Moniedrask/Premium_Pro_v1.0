import 'package:flutter/material.dart';

/// Representa un segmento de velocidad en la línea de tiempo (para speed ramp)
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