import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/audio_processor.dart';
import '../services/ai_manager.dart';
import '../models/audio_settings.dart';

class AudioTimelineWidget extends StatefulWidget {
  const AudioTimelineWidget({super.key});

  @override
  State<AudioTimelineWidget> createState() => _AudioTimelineWidgetState();
}

class _AudioTimelineWidgetState extends State<AudioTimelineWidget> {
  String? _selectedAudioPath;
  String _selectedAudioName = 'Ninguno';
  AudioSettings _settings = AudioSettings();
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onDurationChanged.listen((d) => setState(() => _duration = d));
    _player.onPositionChanged.listen((p) => setState(() => _position = p));
    _player.onPlayerComplete.listen((_) => setState(() => _isPlaying = false));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final processor = Provider.of<AudioProcessor>(context);
    final aiManager = Provider.of<AIManager>(context);

    return Column(
      children: [
        // Waveform / visualizador
        Expanded(
          flex: 2,
          child: Container(
            color: const Color(0xFF111111),
            child: _buildWaveform(processor),
          ),
        ),
        // Controles y configuración
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF000000),
            child: _buildControls(processor, aiManager),
          ),
        ),
      ],
    );
  }

  Widget _buildWaveform(AudioProcessor processor) {
    if (_selectedAudioPath == null) {
      return const Center(
        child: Text('Carga un archivo de audio', style: TextStyle(color: Colors.grey)),
      );
    }
    if (processor.isProcessing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.blueAccent),
            const SizedBox(height: 10),
            Text(processor.statusMessage, style: const TextStyle(color: Colors.white)),
            Text('${(processor.progress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.grey, fontSize: 20)),
          ],
        ),
      );
    }
    // Placeholder de waveform (mejorar con paquete real)
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_selectedAudioName, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.blueAccent, size: 48),
              onPressed: _togglePlayback,
            ),
          ],
        ),
        Slider(
          value: _position.inMilliseconds.toDouble(),
          min: 0,
          max: _duration.inMilliseconds.toDouble(),
          onChanged: (val) => _player.seek(Duration(milliseconds: val.round())),
        ),
        Text('${_formatDuration(_position)} / ${_formatDuration(_duration)}',
            style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildControls(AudioProcessor processor, AIManager aiManager) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CONFIGURACIÓN DE AUDIO',
              style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          // Selector de códec
          DropdownButtonFormField<String>(
            value: _settings.codec,
            items: const [
              DropdownMenuItem(value: 'aac', child: Text('AAC')),
              DropdownMenuItem(value: 'mp3', child: Text('MP3')),
              DropdownMenuItem(value: 'opus', child: Text('Opus')),
              DropdownMenuItem(value: 'flac', child: Text('FLAC')),
              DropdownMenuItem(value: 'wav', child: Text('WAV')),
            ],
            onChanged: (val) => setState(() => _settings.codec = val!),
            decoration: const InputDecoration(labelText: 'Códec'),
          ),

          // Bitrate (si aplica)
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
                  onChanged: (val) => setState(() => _settings.bitrate = val.round()),
                ),
              ],
            ),

          const SizedBox(height: 10),
          // Frecuencia de muestreo
          DropdownButtonFormField<int>(
            value: _settings.sampleRate,
            items: const [
              DropdownMenuItem(value: 44100, child: Text('44.1 kHz')),
              DropdownMenuItem(value: 48000, child: Text('48 kHz')),
              DropdownMenuItem(value: 96000, child: Text('96 kHz')),
              DropdownMenuItem(value: 192000, child: Text('192 kHz')),
            ],
            onChanged: (val) => setState(() => _settings.sampleRate = val!),
            decoration: const InputDecoration(labelText: 'Frecuencia'),
          ),

          const SizedBox(height: 10),
          // Canales
          DropdownButtonFormField<String>(
            value: _settings.channels,
            items: const [
              DropdownMenuItem(value: 'mono', child: Text('Mono')),
              DropdownMenuItem(value: 'stereo', child: Text('Estéreo')),
            ],
            onChanged: (val) => setState(() => _settings.channels = val!),
            decoration: const InputDecoration(labelText: 'Canales'),
          ),

          const SizedBox(height: 10),
          // Normalización
          Row(
            children: [
              Checkbox(
                value: _settings.normalize,
                onChanged: (val) => setState(() => _settings.normalize = val!),
              ),
              const Text('Normalizar volumen', style: TextStyle(color: Colors.white)),
            ],
          ),

          // Reducción de ruido (solo si IA disponible)
          if (aiManager.isModelAvailable)
            Row(
              children: [
                Checkbox(
                  value: _settings.removeNoise,
                  onChanged: (val) => setState(() => _settings.removeNoise = val!),
                ),
                const Text('Reducción de ruido (IA)', style: TextStyle(color: Colors.white)),
              ],
            ),

          const SizedBox(height: 20),
          // Botones de acción
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
                  child: const Text('EXPORTAR'),
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
        _player.setSourceDeviceFile(_selectedAudioPath!);
      }
    } catch (e) {
      debugPrint('Error seleccionando audio: $e');
    }
  }

  Future<void> _exportAudio(AudioProcessor processor) async {
    if (_selectedAudioPath == null) return;

    try {
      final dir = await getExternalStorageDirectory();
      if (dir == null) throw Exception('No storage');
      final outputDir = '${dir.path}/PremiumPro/Audio';
      await Directory(outputDir).create(recursive: true);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = _settings.codec == 'aac' ? 'm4a' : _settings.codec;
      final outputPath = '$outputDir/audio_$timestamp.$ext';

      final success = await processor.processAudio(
        inputPath: _selectedAudioPath!,
        outputPath: outputPath,
        settings: _settings,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Audio exportado'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Error exportando audio: $e');
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