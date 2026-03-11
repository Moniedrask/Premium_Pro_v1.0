import 'package:flutter/material.dart';
import 'video_effect.dart';
import 'speed_segment.dart';

enum BitrateMode { crf, cbr }

/// Tipos de transición entre clips en la línea de tiempo.
enum TransitionType { none, fade, dissolve, wipeLeft, wipeRight, slideLeft, slideRight }

/// Tipos de ajuste de color grading (curvas básicas).
/// Se aplican mediante el filtro curves de FFmpeg sin necesidad de archivo LUT.
enum ColorGradingPreset { none, warm, cold, vintage, highContrast, fadedFilm, teal, vivid }

class VideoSettings {
  String videoCodec;
  BitrateMode bitrateMode;
  int videoBitrate;
  int crf;
  String preset;
  int keyframeInterval;
  String profile;
  int level;
  bool hardwareAcceleration;
  String audioCodec;
  int audioBitrate;
  int audioSampleRate;
  String audioChannels;

  bool frameInterpolation;
  int targetFps;

  bool resolutionUpscale;
  int targetWidth;
  int targetHeight;
  int maxScaleFactor;

  /// Interpolación con modelo IA (Real-ESRGAN / RIFE vía TFLite).
  /// Si el modelo no está descargado se usa minterpolate de FFmpeg.
  bool aiInterpolation;
  int aiTargetFps;
  bool aiStabilization;

  bool preserveMetadata;
  bool aiEnabled;
  bool saveAsDefault;

  List<SpeedSegment>? speedSegments;

  // Efectos
  VideoEffect? effect;
  bool? stabilize;

  // Transición entre clips (se aplica con xfade de FFmpeg)
  TransitionType transitionType;
  double transitionDurationSeconds;

  // Color grading sin LUT (filtro curves de FFmpeg)
  ColorGradingPreset colorGrading;

  // Texto animado sobre video
  bool enableTextOverlay;
  String textOverlayContent;
  int textOverlayFontSize;
  String textOverlayColor;      // hex AARRGGBB para drawtext
  double textOverlayX;          // posición relativa 0.0–1.0
  double textOverlayY;
  double textOverlayStartSec;
  double textOverlayEndSec;
  bool textOverlayFadeIn;

  VideoSettings({
    this.videoCodec = 'libx264',
    this.bitrateMode = BitrateMode.crf,
    this.videoBitrate = 2500,
    this.crf = 23,
    this.preset = 'medium',
    this.keyframeInterval = 48,
    this.profile = 'high',
    this.level = 41,
    this.hardwareAcceleration = true,
    this.audioCodec = 'aac',
    this.audioBitrate = 128,
    this.audioSampleRate = 48000,
    this.audioChannels = 'stereo',
    this.frameInterpolation = false,
    this.targetFps = 60,
    this.resolutionUpscale = false,
    this.targetWidth = 1920,
    this.targetHeight = 1080,
    this.maxScaleFactor = 4,
    this.aiInterpolation = false,
    this.aiTargetFps = 60,
    this.aiStabilization = false,
    this.preserveMetadata = false,
    this.aiEnabled = false,
    this.saveAsDefault = false,
    this.speedSegments,
    this.effect,
    this.stabilize = false,
    this.transitionType = TransitionType.none,
    this.transitionDurationSeconds = 0.5,
    this.colorGrading = ColorGradingPreset.none,
    this.enableTextOverlay = false,
    this.textOverlayContent = '',
    this.textOverlayFontSize = 48,
    this.textOverlayColor = 'white',
    this.textOverlayX = 0.5,
    this.textOverlayY = 0.9,
    this.textOverlayStartSec = 0.0,
    this.textOverlayEndSec = 5.0,
    this.textOverlayFadeIn = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'videoCodec': videoCodec,
      'bitrateMode': bitrateMode.index,
      'videoBitrate': videoBitrate,
      'crf': crf,
      'preset': preset,
      'keyframeInterval': keyframeInterval,
      'profile': profile,
      'level': level,
      'hardwareAcceleration': hardwareAcceleration,
      'audioCodec': audioCodec,
      'audioBitrate': audioBitrate,
      'audioSampleRate': audioSampleRate,
      'audioChannels': audioChannels,
      'frameInterpolation': frameInterpolation,
      'targetFps': targetFps,
      'resolutionUpscale': resolutionUpscale,
      'targetWidth': targetWidth,
      'targetHeight': targetHeight,
      'maxScaleFactor': maxScaleFactor,
      'aiInterpolation': aiInterpolation,
      'aiTargetFps': aiTargetFps,
      'aiStabilization': aiStabilization,
      'preserveMetadata': preserveMetadata,
      'aiEnabled': aiEnabled,
      'speedSegments': speedSegments?.map((s) => s.toJson()).toList(),
      'effect': effect?.toJson(),
      'stabilize': stabilize,
      'transitionType': transitionType.index,
      'transitionDurationSeconds': transitionDurationSeconds,
      'colorGrading': colorGrading.index,
      'enableTextOverlay': enableTextOverlay,
      'textOverlayContent': textOverlayContent,
      'textOverlayFontSize': textOverlayFontSize,
      'textOverlayColor': textOverlayColor,
      'textOverlayX': textOverlayX,
      'textOverlayY': textOverlayY,
      'textOverlayStartSec': textOverlayStartSec,
      'textOverlayEndSec': textOverlayEndSec,
      'textOverlayFadeIn': textOverlayFadeIn,
    };
  }

  factory VideoSettings.fromJson(Map<String, dynamic> json) {
    return VideoSettings(
      videoCodec: json['videoCodec'] ?? 'libx264',
      bitrateMode: BitrateMode.values[json['bitrateMode'] ?? 0],
      videoBitrate: json['videoBitrate'] ?? 2500,
      crf: json['crf'] ?? 23,
      preset: json['preset'] ?? 'medium',
      keyframeInterval: json['keyframeInterval'] ?? 48,
      profile: json['profile'] ?? 'high',
      level: json['level'] ?? 41,
      hardwareAcceleration: json['hardwareAcceleration'] ?? true,
      audioCodec: json['audioCodec'] ?? 'aac',
      audioBitrate: json['audioBitrate'] ?? 128,
      audioSampleRate: json['audioSampleRate'] ?? 48000,
      audioChannels: json['audioChannels'] ?? 'stereo',
      frameInterpolation: json['frameInterpolation'] ?? false,
      targetFps: json['targetFps'] ?? 60,
      resolutionUpscale: json['resolutionUpscale'] ?? false,
      targetWidth: json['targetWidth'] ?? 1920,
      targetHeight: json['targetHeight'] ?? 1080,
      maxScaleFactor: json['maxScaleFactor'] ?? 4,
      aiInterpolation: json['aiInterpolation'] ?? false,
      aiTargetFps: json['aiTargetFps'] ?? 60,
      aiStabilization: json['aiStabilization'] ?? false,
      preserveMetadata: json['preserveMetadata'] ?? false,
      aiEnabled: json['aiEnabled'] ?? false,
      speedSegments: (json['speedSegments'] as List?)
          ?.map((s) => SpeedSegment.fromJson(s))
          .toList(),
      effect: json['effect'] != null ? VideoEffect.fromJson(json['effect']) : null,
      stabilize: json['stabilize'] ?? false,
      transitionType: TransitionType.values[json['transitionType'] ?? 0],
      transitionDurationSeconds: (json['transitionDurationSeconds'] ?? 0.5).toDouble(),
      colorGrading: ColorGradingPreset.values[json['colorGrading'] ?? 0],
      enableTextOverlay: json['enableTextOverlay'] ?? false,
      textOverlayContent: json['textOverlayContent'] ?? '',
      textOverlayFontSize: json['textOverlayFontSize'] ?? 48,
      textOverlayColor: json['textOverlayColor'] ?? 'white',
      textOverlayX: (json['textOverlayX'] ?? 0.5).toDouble(),
      textOverlayY: (json['textOverlayY'] ?? 0.9).toDouble(),
      textOverlayStartSec: (json['textOverlayStartSec'] ?? 0.0).toDouble(),
      textOverlayEndSec: (json['textOverlayEndSec'] ?? 5.0).toDouble(),
      textOverlayFadeIn: json['textOverlayFadeIn'] ?? false,
    );
  }

  String get fileExtension {
    switch (videoCodec) {
      case 'libvpx-vp9':
        return 'webm';
      default:
        return 'mp4';
    }
  }
}