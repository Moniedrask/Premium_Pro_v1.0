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

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

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
      case InterfaceDensity.compact:
        return 4.0;
      case InterfaceDensity.normal:
        return 8.0;
      case InterfaceDensity.comfortable:
        return 12.0;
    }
  }

  BorderRadius _getBorderRadius(CornerRoundness roundness) {
    switch (roundness) {
      case CornerRoundness.square:
        return BorderRadius.zero;
      case CornerRoundness.light:
        return BorderRadius.circular(8);
      case CornerRoundness.rounded:
        return BorderRadius.circular(16);
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
    final borderRadius = _getBorderRadius(globalSettings.roundness);

    return Column(
      children: [
        Expanded(
          flex: 2,
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
          flex: 3,
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

                  DropdownButtonFormField<String>(
                    value: _settings.codec,
                    items: const [
                      DropdownMenuItem(value: 'aac', child: Text('AAC')),
                      DropdownMenuItem(value: 'mp3', child: Text('MP3')),
                      DropdownMenuItem(value: 'opus', child: Text('Opus')),
                      DropdownMenuItem(value: 'flac', child: Text('FLAC')),
                      DropdownMenuItem(value: 'wav', child: Text('WAV')),
                    ],
                    onChanged: processor.isProcessing ? null : (val) {
                      setState(() => _settings.codec = val!);
                    },
                    decoration: const InputDecoration(labelText: 'Códec'),
                  ),

                  if (_settings.codec != 'flac' && _settings.codec != 'wav')
                    Column(
                      children: [
                        const SizedBox(height: 10),
                        Text('Bitrate: ${_settings.bitrate} kbps'),
                        Slider(
                          value: _settings.bitrate.toDouble(),
                          min: 32,
                          max: 