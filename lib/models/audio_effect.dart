import 'dart:convert';

enum AudioEffectType { none, fadeIn, fadeOut, volume, normalize, equalizer, compressor, reverb }

class AudioEffect {
  final AudioEffectType type;
  final Map<String, dynamic> parameters;

  AudioEffect({required this.type, this.parameters = const {}});

  // Convierte el efecto a un filtro de FFmpeg
  String toFFmpegFilter() {
    switch (type) {
      case AudioEffectType.fadeIn:
        final duration = parameters['duration'] ?? 2.0; // segundos
        return 'afade=t=in:st=0:d=$duration';
      case AudioEffectType.fadeOut:
        final duration = parameters['duration'] ?? 2.0;
        final start = parameters['start'] ?? 0.0;
        return 'afade=t=out:st=$start:d=$duration';
      case AudioEffectType.volume:
        final factor = parameters['factor'] ?? 1.0;
        return 'volume=$factor';
      case AudioEffectType.normalize:
        final target = parameters['target'] ?? -16.0; // LUFS
        return 'loudnorm=I=$target';
      case AudioEffectType.equalizer:
        final frequency = parameters['frequency'] ?? 1000;
        final gain = parameters['gain'] ?? 0;
        final width = parameters['width'] ?? 1.0;
        return 'equalizer=f=$frequency:width_type=o:width=$width:g=$gain';
      case AudioEffectType.compressor:
        final threshold = parameters['threshold'] ?? -20;
        final ratio = parameters['ratio'] ?? 4;
        final attack = parameters['attack'] ?? 5;
        final release = parameters['release'] ?? 50;
        final knee = parameters['knee'] ?? 0;
        return 'acompressor=threshold=${threshold}dB:ratio=$ratio:attack=${attack}ms:release=${release}ms:knee=$knee';
      case AudioEffectType.reverb:
        final reverberance = parameters['reverberance'] ?? 50;
        return 'aecho=in_gain=0.8:out_gain=0.6:delays=500:decays=0.5';
      default:
        return '';
    }
  }

  Map<String, dynamic> toJson() => {
        'type': type.index,
        'parameters': parameters,
      };

  factory AudioEffect.fromJson(Map<String, dynamic> json) {
    return AudioEffect(
      type: AudioEffectType.values[json['type'] ?? 0],
      parameters: json['parameters'] ?? {},
    );
  }
}