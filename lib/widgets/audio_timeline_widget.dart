import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/audio_processor.dart';
import '../services/ai_manager.dart';
import '../services/trash_manager.dart';
import '../models/audio_settings.dart';
import '../models/compression_preset.dart';
import '../providers/settings_provider.dart';
import '../models/app_settings.dart';
import 'equalizer_widget.dart';

// ── Modelo interno de pista adicional ─────────────────────────────────────
class _AudioTrack {
  String path;
  String name;
  double volume;   // 0.0-2.0, 1.0 = sin cambio
  int offsetMs;    // retraso en milisegundos
  bool enabled;

  _AudioTrack({
    required this.path,
    required this.name,
    this.volume = 1.0,
    this.offsetMs = 0,
    this.enabled = true,
  });
}

class AudioTimelineWidget extends StatefulWidget {
  const AudioTimelineWidget({super.key});

  @override
  State<AudioTimelineWidget> createState() => AudioTimelineWidgetState();
}

class AudioTimelineWidgetState extends State<AudioTimelineWidget> {
  String? _selectedAudioPath;
  String _selectedAudioName = 'Ninguno';
  late AudioSettings _settings;
  bool _keepOriginalName = false;

  // Ecualizador
  List<double> _equalizerGains = List.filled(10, 0.0);

  // Compresor
  Map<String, double> _compressorParams = {
    'threshold': -20,
    'ratio': 4,
    'attack': 5,
    'release': 50,
    'knee': 0,
  };

  // Fade in/out
  int _fadeInMs = 0;
  int _fadeOutMs = 0;

  // ── Reproductor de la pista principal ─────────────────────────────────
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // ── Pistas adicionales (multipista) ──────────────────────────────────
  final List<_AudioTrack> _extraTracks = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _player.onDurationChanged.listen((d) => setState(() => _duration = d));
    _player.onPositionChanged.listen((p) => setState(() => _position = p));
    _player.onPlayerComplete.listen((_) => setState(() => _isPlaying = false));
  }

  Future<void> _loadSettings() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final globalSettings = settingsProvider.settings;
    _settings = AudioSettings.fromJson(globalSettings.audioDefaults);
    _keepOriginalName = globalSettings.keepOriginalName;
    setState(() {});
  }

  /// Carga un archivo de audio externamente (llamado desde AudioEditorScreen).
  Future<void> loadFile(String path) async {
    final name = path.split('/').last;
    setState(() {
      _selectedAudioPath = path;
      _selectedAudioName = name;
    });
    try {
      await _player.setSourceDeviceFile(path);
    } catch (e) {
      debugPrint('❌ Error cargando audio: $e');
    }
  }

  /// Pausa la reproducción (llamado por AudioEditorScreen cuando app va a background).
  void pausePlayback() {
    if (_isPlaying) {
      _player.pause();
      setState(() => _isPlaying = false);
    }
  }

  void applyPreset(AudioSettings preset) {
    setState(() {
      _settings = AudioSettings(
        codec: preset.codec,
        bitrate: preset.bitrate,
        sampleRate: preset.sampleRate,
        channels: preset.channels,
        normalize: preset.normalize,
        removeNoise: preset.removeNoise,
        compressionLevel: preset.compressionLevel,
        aiEnabled: preset.aiEnabled,
        bitDepth: preset.bitDepth,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preset aplicado a audio'), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  double _getPadding(InterfaceDensity density) {
    switch (density) {
      case InterfaceDensity.compact:    return 4.0;
      case InterfaceDensity.normal:     return 8.0;
      case InterfaceDensity.comfortable: return 12.0;
    }
  }

  BorderRadius _getBorderRadius(CornerRoundness roundness) {
    switch (roundness) {
      case CornerRoundness.square:  return BorderRadius.zero;
      case CornerRoundness.light:   return BorderRadius.circular(8);
      case CornerRoundness.rounded: return BorderRadius.circular(16);
    }
  }

  Future<void> _deleteFile(String filePath) async {
    final trashManager = TrashManager();
    final settings = Provider.of<SettingsProvider>(context, listen: false).settings;

    if (settings.trashEnabled) {
      if (settings.alwaysAskBeforeDelete) {
        bool? confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirmar'),
            content: const Text('¿Mover este archivo a la papelera?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Mover')),
            ],
          ),
        );
        if (confirm == true) {
          await trashManager.moveToTrash(filePath);
          setState(() {
            _selectedAudioPath = null;
            _selectedAudioName = 'Ninguno';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Archivo movido a la papelera'), backgroundColor: Colors.orange),
            );
          }
        }
      } else {
        await trashManager.moveToTrash(filePath);
        setState(() {
          _selectedAudioPath = null;
          _selectedAudioName = 'Ninguno';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Archivo movido a la papelera'), backgroundColor: Colors.orange),
          );
        }
      }
    } else {
      if (settings.dontShowDeleteWarning) {
        File(filePath).delete();
        setState(() {
          _selectedAudioPath = null;
          _selectedAudioName = 'Ninguno';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Archivo eliminado permanentemente'), backgroundColor: Colors.red),
          );
        }
      } else {
        bool? confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirmar'),
            content: const Text('¿Borrar este archivo permanentemente?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Borrar')),
            ],
          ),
        );
        if (confirm == true) {
          File(filePath).delete();
          setState(() {
            _selectedAudioPath = null;
            _selectedAudioName = 'Ninguno';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Archivo eliminado permanentemente'), backgroundColor: Colors.red),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final processor = Provider.of<AudioProcessor>(context);
    final aiManager = Provider.of<AIManager>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final globalSettings = settingsProvider.settings;

    final paddingValue = _getPadding(globalSettings.density);
    // ignore: unused_local_variable
    final borderRadius = _getBorderRadius(globalSettings.roundness);

    return Column(
      children: [
        // ── Reproductor de audio (altura fija — evita bug de pantalla negra con teclado)
        SizedBox(
          height: 180,
          child: Stack(
            children: [
              Container(
                color: const Color(0xFF111111),
                child: Center(
                  child: processor.isProcessing
                      ? _buildProcessingView(processor)
                      : _buildWaveform(),
                ),
              ),
              if (_selectedAudioPath != null && !processor.isProcessing)
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(Icons.delete, color: globalSettings.accentColor),
                    onPressed: () => _deleteFile(_selectedAudioPath!),
                    tooltip: 'Eliminar audio',
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(paddingValue * 2),
            color: const Color(0xFF000000),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CONFIGURACIÓN DE AUDIO',
                    style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),

                  // Selector de códec
                  DropdownButtonFormField<String>(
                    value: _settings.codec,
                    items: const [
                      DropdownMenuItem(value: 'aac',  child: Text('AAC')),
                      DropdownMenuItem(value: 'mp3',  child: Text('MP3')),
                      DropdownMenuItem(value: 'opus', child: Text('Opus')),
                      DropdownMenuItem(value: 'flac', child: Text('FLAC')),
                      DropdownMenuItem(value: 'wav',  child: Text('WAV')),
                    ],
                    onChanged: processor.isProcessing ? null : (val) {
                      setState(() => _settings.codec = val!);
                    },
                    decoration: const InputDecoration(labelText: 'Códec'),
                  ),

                  // Profundidad de bits (solo FLAC y WAV)
                  if (_settings.codec == 'flac' || _settings.codec == 'wav')
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          const Text('Profundidad: ', style: TextStyle(color: Colors.white)),
                          const SizedBox(width: 10),
                          DropdownButton<int>(
                            value: _settings.bitDepth,
                            dropdownColor: const Color(0xFF111111),
                            items: const [
                              DropdownMenuItem(value: 16, child: Text('16 bits')),
                              DropdownMenuItem(value: 24, child: Text('24 bits')),
                              DropdownMenuItem(value: 32, child: Text('32 bits')),
                            ],
                            onChanged: processor.isProcessing ? null : (val) {
                              setState(() => _settings.bitDepth = val!);
                            },
                          ),
                        ],
                      ),
                    ),

                  // Bitrate (solo códecs con pérdida)
                  if (_settings.codec != 'flac' && _settings.codec != 'wav')
                    Column(
                      children: [
                        const SizedBox(height: 10),
                        Text('Bitrate: ${_settings.bitrate} kbps'),
                        Slider(
                          value: _settings.bitrate.toDouble(),
                          min: 32,
                          max: 320,
                          divisions: 36,
                          onChanged: processor.isProcessing ? null : (val) {
                            setState(() => _settings.bitrate = val.round());
                          },
                        ),
                      ],
                    ),

                  // Compresión FLAC
                  if (_settings.codec == 'flac')
                    Column(
                      children: [
                        const SizedBox(height: 10),
                        Text('Nivel de compresión: ${_settings.compressionLevel}'),
                        Slider(
                          value: _settings.compressionLevel.toDouble(),
                          min: 0,
                          max: 9,
                          divisions: 9,
                          onChanged: processor.isProcessing ? null : (val) {
                            setState(() => _settings.compressionLevel = val.round());
                          },
                        ),
                      ],
                    ),

                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: _settings.sampleRate,
                    items: const [
                      DropdownMenuItem(value: 22050,  child: Text('22.05 kHz')),
                      DropdownMenuItem(value: 32000,  child: Text('32 kHz')),
                      DropdownMenuItem(value: 44100,  child: Text('44.1 kHz')),
                      DropdownMenuItem(value: 48000,  child: Text('48 kHz')),
                      DropdownMenuItem(value: 96000,  child: Text('96 kHz')),
                      DropdownMenuItem(value: 192000, child: Text('192 kHz')),
                    ],
                    onChanged: processor.isProcessing ? null : (val) {
                      setState(() => _settings.sampleRate = val!);
                    },
                    decoration: const InputDecoration(labelText: 'Frecuencia'),
                  ),

                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _settings.channels,
                    items: const [
                      DropdownMenuItem(value: 'mono',   child: Text('Mono')),
                      DropdownMenuItem(value: 'stereo', child: Text('Estéreo')),
                    ],
                    onChanged: processor.isProcessing ? null : (val) {
                      setState(() => _settings.channels = val!);
                    },
                    decoration: const InputDecoration(labelText: 'Canales'),
                  ),

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: _settings.normalize,
                        onChanged: processor.isProcessing ? null : (val) {
                          setState(() => _settings.normalize = val!);
                        },
                      ),
                      const Text('Normalizar volumen', style: TextStyle(color: Colors.white)),
                    ],
                  ),

                  if (aiManager.isModelAvailable)
                    Row(
                      children: [
                        Checkbox(
                          value: _settings.removeNoise,
                          onChanged: processor.isProcessing ? null : (val) {
                            setState(() => _settings.removeNoise = val!);
                          },
                        ),
                        const Text('Reducción de ruido (IA)', style: TextStyle(color: Colors.white)),
                      ],
                    ),

                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: processor.isProcessing ? null : () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: const Color(0xFF111111),
                          title: const Text('Ecualizador de 10 bandas', style: TextStyle(color: Colors.white)),
                          content: EqualizerWidget(
                            gains: _equalizerGains,
                            onChanged: (gains) => setState(() => _equalizerGains = gains),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cerrar', style: TextStyle(color: Colors.blueAccent)),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.equalizer),
                    label: const Text('Abrir ecualizador'),
                  ),

                  const SizedBox(height: 10),
                  ExpansionTile(
                    title: const Text('Compresor dinámico', style: TextStyle(color: Colors.white)),
                    children: [
                      _buildCompressorSlider('Umbral (dB)', 'threshold', -60, 0),
                      _buildCompressorSlider('Ratio', 'ratio', 1, 20, isInt: false),
                      _buildCompressorSlider('Attack (ms)', 'attack', 0, 100, isInt: false),
                      _buildCompressorSlider('Release (ms)', 'release', 0, 500, isInt: false),
                      _buildCompressorSlider('Knee (dB)', 'knee', 0, 12, isInt: false),
                    ],
                  ),

                  const SizedBox(height: 10),
                  const Text(
                    'FADE IN/OUT',
                    style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Fade in (ms)'),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => _fadeInMs = int.tryParse(val) ?? 0,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Fade out (ms)'),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => _fadeOutMs = int.tryParse(val) ?? 0,
                        ),
                      ),
                    ],
                  ),

                  // ── PISTAS DE AUDIO (multipista) ─────────────────────────
                  const SizedBox(height: 16),
                  _buildMultitrackSection(processor),
                  // ─────────────────────────────────────────────────────────

                  const SizedBox(height: 10),
                  CheckboxListTile(
                    title: const Text('Mantener nombre original', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Si está activado, no se añadirá timestamp', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    value: _keepOriginalName,
                    onChanged: processor.isProcessing ? null : (val) {
                      setState(() => _keepOriginalName = val!);
                      if (globalSettings.keepOriginalName != val) {
                        settingsProvider.setKeepOriginalName(val!);
                      }
                    },
                    secondary: Icon(Icons.label, color: globalSettings.accentColor),
                    activeColor: globalSettings.accentColor,
                  ),

                  CheckboxListTile(
                    title: const Text('Guardar como permanente', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Esta configuración se usará por defecto en futuras exportaciones', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    value: _settings.aiEnabled,
                    onChanged: processor.isProcessing ? null : (val) {
                      setState(() => _settings.aiEnabled = val!);
                      if (val == true) {
                        settingsProvider.setAudioDefaults(_settings.toJson());
                      }
                    },
                    secondary: Icon(Icons.save, color: globalSettings.accentColor),
                    activeColor: globalSettings.accentColor,
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: processor.isProcessing ? null : _selectAudio,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('CARGAR'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: processor.isProcessing || _selectedAudioPath == null
                              ? null
                              : () => _exportAudio(processor),
                          child: Text(_extraTracks.any((t) => t.enabled)
                              ? 'MEZCLAR Y EXPORTAR'
                              : 'EXPORTAR'),
                        ),
                      ),
                    ],
                  ),
                  if (processor.isProcessing)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ElevatedButton(
                        onPressed: processor.cancelProcessing,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('CANCELAR'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Sección de multipista ────────────────────────────────────────────────
  Widget _buildMultitrackSection(AudioProcessor processor) {
    final hasExtra = _extraTracks.isNotEmpty;
    return ExpansionTile(
      initiallyExpanded: hasExtra,
      leading: const Icon(Icons.layers, color: Colors.tealAccent),
      title: Row(
        children: [
          const Text('PISTAS DE AUDIO', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 8),
          if (hasExtra)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.tealAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_extraTracks.length + 1} pistas',
                style: const TextStyle(color: Colors.tealAccent, fontSize: 11),
              ),
            ),
        ],
      ),
      children: [
        // Pista principal (siempre presente)
        if (_selectedAudioPath != null)
          _buildTrackTile(
            index: 0,
            name: _selectedAudioName,
            isMain: true,
            volume: 1.0,      // La pista principal no tiene slider de volumen aquí (se controla con el reproductor)
            offsetMs: 0,
            enabled: true,
            onVolumeChange: null,
            onOffsetChange: null,
            onToggle: null,
            onRemove: null,
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Carga un audio principal primero', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),

        // Pistas adicionales
        ...List.generate(_extraTracks.length, (i) {
          final track = _extraTracks[i];
          return _buildTrackTile(
            index: i + 1,
            name: track.name,
            isMain: false,
            volume: track.volume,
            offsetMs: track.offsetMs,
            enabled: track.enabled,
            onVolumeChange: processor.isProcessing ? null : (v) => setState(() => track.volume = v),
            onOffsetChange: processor.isProcessing ? null : (ms) => setState(() => track.offsetMs = ms),
            onToggle: processor.isProcessing ? null : (v) => setState(() => track.enabled = v),
            onRemove: processor.isProcessing ? null : () => setState(() => _extraTracks.removeAt(i)),
          );
        }),

        // Botón añadir pista
        if (_selectedAudioPath != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: processor.isProcessing ? null : _addExtraTrack,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Añadir pista'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A2A1A),
                foregroundColor: Colors.tealAccent,
                side: const BorderSide(color: Colors.tealAccent, width: 1),
              ),
            ),
          ),

        if (hasExtra)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'ℹ️  Las pistas se mezclan con FFmpeg amix. El offset desplaza la pista hacia adelante.',
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _buildTrackTile({
    required int index,
    required String name,
    required bool isMain,
    required double volume,
    required int offsetMs,
    required bool enabled,
    required void Function(double)? onVolumeChange,
    required void Function(int)? onOffsetChange,
    required void Function(bool)? onToggle,
    required VoidCallback? onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isMain ? const Color(0xFF0A1A2A) : const Color(0xFF0A1A0A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMain ? Colors.blueAccent.withOpacity(0.4) : Colors.tealAccent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera de la pista
          Row(
            children: [
              Icon(
                isMain ? Icons.star : Icons.music_note,
                size: 14,
                color: isMain ? Colors.blueAccent : Colors.tealAccent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Pista ${index + 1}${isMain ? ' (principal)' : ''}: $name',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Toggle habilitado/deshabilitado (solo pistas adicionales)
              if (!isMain && onToggle != null)
                Switch(
                  value: enabled,
                  onChanged: onToggle,
                  activeColor: Colors.tealAccent,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              // Eliminar pista
              if (!isMain && onRemove != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
                  tooltip: 'Eliminar pista',
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
            ],
          ),

          // Controles de volumen y offset (solo pistas adicionales habilitadas)
          if (!isMain && enabled) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const SizedBox(width: 4),
                const Icon(Icons.volume_up, size: 14, color: Colors.white54),
                const SizedBox(width: 6),
                Expanded(
                  child: Slider(
                    value: volume,
                    min: 0.0,
                    max: 2.0,
                    divisions: 40,
                    activeColor: Colors.tealAccent,
                    inactiveColor: Colors.tealAccent.withOpacity(0.2),
                    onChanged: onVolumeChange,
                  ),
                ),
                SizedBox(
                  width: 38,
                  child: Text(
                    '${(volume * 100).round()}%',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const SizedBox(width: 4),
                const Icon(Icons.timer, size: 14, color: Colors.white54),
                const SizedBox(width: 6),
                const Text('Offset:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  height: 36,
                  child: TextField(
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '$offsetMs ms',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (val) {
                      final ms = int.tryParse(val);
                      if (ms != null && ms >= 0 && onOffsetChange != null) {
                        onOffsetChange(ms);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 6),
                const Text('ms', style: TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addExtraTrack() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _extraTracks.add(_AudioTrack(
            path: result.files.single.path!,
            name: result.files.single.name,
          ));
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Pista añadida: ${result.files.single.name}'),
              backgroundColor: Colors.teal,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error añadiendo pista: $e');
    }
  }
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildProcessingView(AudioProcessor processor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: Colors.blueAccent),
        const SizedBox(height: 10),
        Text(processor.statusMessage, style: const TextStyle(color: Colors.white)),
        Text('${(processor.progress * 100).toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.grey, fontSize: 20)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: processor.cancelProcessing,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('CANCELAR'),
        ),
      ],
    );
  }

  Widget _buildWaveform() {
    if (_selectedAudioPath == null) {
      return const Center(
        child: Text('Carga un archivo de audio', style: TextStyle(color: Colors.grey)),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_selectedAudioName,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CustomPaint(
              painter: _WaveformPainter(
                progress: _duration.inMilliseconds > 0
                    ? _position.inMilliseconds / _duration.inMilliseconds
                    : 0.0,
              ),
              child: Container(),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.blueAccent, size: 40),
              onPressed: _togglePlayback,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: _position.inMilliseconds.toDouble().clamp(
                  0.0, _duration.inMilliseconds.toDouble().clamp(1.0, double.infinity)),
              min: 0.0,
              max: _duration.inMilliseconds.toDouble().clamp(1.0, double.infinity),
              onChanged: (val) =>
                  _player.seek(Duration(milliseconds: val.round())),
            ),
          ),
        ),
        Text(
          '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildCompressorSlider(String label, String key, double min, double max, {bool isInt = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.white70))),
          Expanded(
            child: Slider(
              value: _compressorParams[key]!.clamp(min, max),
              min: min,
              max: max,
              divisions: isInt ? (max - min).round() : 100,
              onChanged: (val) {
                setState(() {
                  _compressorParams[key] = val;
                });
              },
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              _compressorParams[key]!.toStringAsFixed(isInt ? 0 : 1),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedAudioPath = result.files.single.path;
          _selectedAudioName = result.files.single.name;
        });
        await _player.setSourceDeviceFile(_selectedAudioPath!);
      }
    } catch (e) {
      debugPrint('Error seleccionando audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportAudio(AudioProcessor processor) async {
    if (_selectedAudioPath == null) return;

    try {
      final dir = await getExternalStorageDirectory();
      if (dir == null) throw Exception('No se pudo acceder al almacenamiento');
      final outputDir = '${dir.path}/PremiumPro/Audio';
      await Directory(outputDir).create(recursive: true);

      final int timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = _settings.codec == 'aac' ? 'm4a' : _settings.codec;

      String outputPath;
      if (_keepOriginalName) {
        final originalName = _selectedAudioName.split('.').first;
        outputPath = '$outputDir/${originalName}_premium.$ext';
      } else {
        outputPath = '$outputDir/audio_$timestamp.$ext';
      }

      // Pistas adicionales habilitadas
      final enabledExtra = _extraTracks.where((t) => t.enabled).toList();

      final bool success;

      if (enabledExtra.isEmpty) {
        // ── Pista única — flujo normal ──────────────────────────────
        success = await processor.processAudio(
          inputPath: _selectedAudioPath!,
          outputPath: outputPath,
          settings: _settings,
          equalizerGains: _equalizerGains,
          compressorParams: _compressorParams,
          fadeIn: _fadeInMs > 0 ? Duration(milliseconds: _fadeInMs) : null,
          fadeOut: _fadeOutMs > 0 ? Duration(milliseconds: _fadeOutMs) : null,
        );
      } else {
        // ── Multipista — mezcla con amix ─────────────────────────────
        final List<Map<String, dynamic>> tracks = [
          // Pista principal: volumen 1.0, offset 0
          {'path': _selectedAudioPath!, 'volume': 1.0, 'offsetMs': 0},
          // Pistas adicionales
          ...enabledExtra.map((t) => {
            'path': t.path,
            'volume': t.volume,
            'offsetMs': t.offsetMs,
          }),
        ];
        success = await processor.processMultitrack(
          tracks: tracks,
          outputPath: outputPath,
          settings: _settings,
        );
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Audio exportado'), backgroundColor: Colors.green),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Error al exportar'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error exportando audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _togglePlayback() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.resume();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

/// Dibuja una forma de onda simulada (barras de amplitud variable)
/// que avanza con la reproducción. La amplitud se genera con una
/// función senoidal combinada para dar aspecto natural de onda de audio.
class _WaveformPainter extends CustomPainter {
  final double progress; // 0.0 a 1.0

  _WaveformPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final int barCount = (size.width / 4).floor();
    final double barWidth = 2.0;
    final double gap = (size.width - barWidth * barCount) / barCount;

    final paintPlayed = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = barWidth
      ..strokeCap = StrokeCap.round;

    final paintUnplayed = Paint()
      ..color = Colors.blueGrey.withOpacity(0.5)
      ..strokeWidth = barWidth
      ..strokeCap = StrokeCap.round;

    final double midY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final double t = i / barCount;
      final double amp = (0.3 +
              0.35 * (0.5 + 0.5 * _sin(t * 31.4)) +
              0.2 * (0.5 + 0.5 * _sin(t * 17.7 + 1.1)) +
              0.15 * (0.5 + 0.5 * _sin(t * 53.2 + 2.3))) *
          size.height *
          0.45;

      final double x = i * (barWidth + gap) + barWidth / 2;
      final paint = (i / barCount) < progress ? paintPlayed : paintUnplayed;
      canvas.drawLine(Offset(x, midY - amp), Offset(x, midY + amp), paint);
    }
  }

  double _sin(double x) {
    return (x % (2 * 3.14159265358979323846)).abs() < 0.001
        ? 0
        : _sinImpl(x);
  }

  double _sinImpl(double x) {
    double v = x % (2 * 3.14159265358979);
    if (v > 3.14159265358979) v -= 2 * 3.14159265358979;
    double v2 = v * v;
    return v * (1 - v2 / 6 * (1 - v2 / 20 * (1 - v2 / 42)));
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => old.progress != progress;
}