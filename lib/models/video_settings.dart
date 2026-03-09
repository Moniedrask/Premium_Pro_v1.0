import 'package:flutter/material.dart';
import 'video_effect.dart';

enum BitrateMode { crf, cbr }

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
  
  bool aiInterpolation;
  int aiTargetFps;
  bool aiStabilization;
  
  bool preserveMetadata;
  bool aiEnabled;
  bool saveAsDefault;

  // Nuevos campos
  VideoEffect? effect;
  bool? stabilize;

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
    this.effect,
    this.stabilize = false,
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
      'effect': effect?.toJson(),
      'stabilize': stabilize,
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
      effect: json['effect'] != null ? VideoEffect.fromJson(json['effect']) : null,
      stabilize: json['stabilize'] ?? false,
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