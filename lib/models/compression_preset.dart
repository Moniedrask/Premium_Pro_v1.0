import 'package:flutter/material.dart';
import 'video_settings.dart';
import 'audio_settings.dart';
import 'image_settings.dart';

/// Representa un preset de compresión que puede aplicarse a video, audio e imagen
class CompressionPreset {
  final String name;
  final VideoSettings videoSettings;
  final AudioSettings audioSettings;
  final ImageSettings imageSettings;
  final bool isDefault; // si es un preset precargado

  CompressionPreset({
    required this.name,
    required this.videoSettings,
    required this.audioSettings,
    required this.imageSettings,
    this.isDefault = false,
  });

  /// Presets por defecto (Alta calidad, Media, Baja)
  static final List<CompressionPreset> defaults = [
    CompressionPreset(
      name: 'Alta calidad',
      isDefault: true,
      videoSettings: VideoSettings(
        crf: 18,
        videoBitrate: 5000,
        preset: 'slow',
      ),
      audioSettings: AudioSettings(
        codec: 'aac',
        bitrate: 320,
        sampleRate: 48000,
      ),
      imageSettings: ImageSettings(
        quality: 95,
        format: 'jpeg',
      ),
    ),
    CompressionPreset(
      name: 'Media calidad',
      isDefault: true,
      videoSettings: VideoSettings(
        crf: 23,
        videoBitrate: 2500,
        preset: 'medium',
      ),
      audioSettings: AudioSettings(
        codec: 'aac',
        bitrate: 192,
        sampleRate: 48000,
      ),
      imageSettings: ImageSettings(
        quality: 85,
        format: 'jpeg',
      ),
    ),
    CompressionPreset(
      name: 'Baja calidad (tamaño pequeño)',
      isDefault: true,
      videoSettings: VideoSettings(
        crf: 28,
        videoBitrate: 1000,
        preset: 'fast',
      ),
      audioSettings: AudioSettings(
        codec: 'mp3',
        bitrate: 128,
        sampleRate: 44100,
      ),
      imageSettings: ImageSettings(
        quality: 70,
        format: 'jpeg',
      ),
    ),
  ];

  Map<String, dynamic> toJson() => {
    'name': name,
    'videoSettings': videoSettings.toJson(),
    'audioSettings': audioSettings.toJson(),
    'imageSettings': imageSettings.toJson(),
  };

  factory CompressionPreset.fromJson(Map<String, dynamic> json) {
    return CompressionPreset(
      name: json['name'],
      videoSettings: VideoSettings.fromJson(json['videoSettings']),
      audioSettings: AudioSettings.fromJson(json['audioSettings']),
      imageSettings: ImageSettings.fromJson(json['imageSettings']),
    );
  }
}