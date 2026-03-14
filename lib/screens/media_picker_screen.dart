import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'settings_screen.dart';

enum MediaPickerType { video, audio, image }

/// Pantalla de selecci贸n de archivo que aparece antes de entrar al editor.
/// Tiene bot贸n de 鈿欙笍 Ajustes en la AppBar.
/// Devuelve la ruta del archivo elegido via [Navigator.pop] o null si se cancela.
class MediaPickerScreen extends StatefulWidget {
  final MediaPickerType type;

  const MediaPickerScreen({super.key, required this.type});

  @override
  State<MediaPickerScreen> createState() => _MediaPickerScreenState();
}

class _MediaPickerScreenState extends State<MediaPickerScreen> {
  bool _picking = false;

  String get _title {
    switch (widget.type) {
      case MediaPickerType.video: return 'Seleccionar Video';
      case MediaPickerType.audio: return 'Seleccionar Audio';
      case MediaPickerType.image: return 'Seleccionar Imagen';
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case MediaPickerType.video: return Icons.videocam_rounded;
      case MediaPickerType.audio: return Icons.music_note_rounded;
      case MediaPickerType.image: return Icons.image_rounded;
    }
  }

  Color get _color {
    switch (widget.type) {
      case MediaPickerType.video: return Colors.blueAccent;
      case MediaPickerType.audio: return Colors.tealAccent;
      case MediaPickerType.image: return Colors.purpleAccent;
    }
  }

  String get _description {
    switch (widget.type) {
      case MediaPickerType.video:
        return 'Abre un video para editarlo: cambiar c贸dec, bitrate, FPS, '
            'aplicar efectos, color grading, texto animado, speed ramp y m谩s.';
      case MediaPickerType.audio:
        return 'Abre un audio para procesarlo: cambiar c贸dec, bitrate, '
            'equalizar, comprimir din谩micamente, mezclar m煤ltiples pistas y m谩s.';
      case MediaPickerType.image:
        return 'Abre una imagen para procesarla: cambiar formato, calidad, '
            'aplicar filtros, escalar, fusionar HDR, a帽adir texto y m谩s.';
    }
  }

  List<String> get _features {
    switch (widget.type) {
      case MediaPickerType.video:
        return [
          '馃幀 H.264 / H.265 / VP9 / AV1',
          '鈿� Aceleraci贸n hardware (MediaCodec)',
          '馃帹 Color grading (7 presets)',
          '馃敜 Texto animado con color libre',
          '馃攣 Interpolaci贸n de frames (hasta 960 fps)',
          '馃敘 Speed ramp por segmentos',
          '馃搻 Escalado hasta 8K',
          '鈻讹笍 Reproductor de video interno',
        ];
      case MediaPickerType.audio:
        return [
          '馃幍 AAC / MP3 / Opus / FLAC / WAV',
          '馃帤锔� Ecualizador de 10 bandas',
          '馃攰 Compresor din谩mico',
          '馃帥锔� Multipista con amix (N pistas)',
          '馃搲 Normalizaci贸n de volumen',
          '鈴憋笍 Fade in/out configurable',
        ];
      case MediaPickerType.image:
        return [
          '馃柤锔� JPEG / PNG / WebP / AVIF',
          '馃帹 Filtros art铆sticos',
          '馃搻 Escalado Lanczos/Bic煤bico',
          '馃寘 Fusi贸n HDR por capas',
          '馃敜 Texto superpuesto con color libre',
          '馃枌锔� Pincel de dibujo libre',
        ];
    }
  }

  FileType get _fileType {
    switch (widget.type) {
      case MediaPickerType.video: return FileType.video;
      case MediaPickerType.audio: return FileType.audio;
      case MediaPickerType.image: return FileType.image;
    }
  }

  Future<void> _pickFile() async {
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: _fileType,
        allowMultiple: false,
        withData: false,
      );
      if (!mounted) return;
      if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
        Navigator.pop(context, result.files.single.path);
      } else {
        setState(() => _picking = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _picking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir archivos: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, null),
        ),
        title: Text(_title, style: const TextStyle(color: Colors.white)),
        elevation: 0,
        // 鈹�鈹� 鈿欙笍 Bot贸n de ajustes en esta pantalla 鈹�鈹�鈹�鈹�鈹�鈹�鈹�鈹�鈹�鈹�鈹�鈹�鈹�鈹�鈹�鈹�鈹�鈹�鈹�鈹�鈹�鈹�
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            tooltip: 'Ajustes',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // 脥cono grande
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: _color.withOpacity(0.4), width: 2),
                  ),
                  child: Icon(_icon, size: 60, color: _color),
                ),
              ),
              const SizedBox(height: 28),

              // T铆tulo
              Text(
                _title,
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Descripci贸n
              Text(
                _description,
                style: const TextStyle(color: Colors.white60, fontSize: 14, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Lista de funciones
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _color.withOpacity(0.2), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Funciones disponibles',
                      style: TextStyle(color: _color, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    ..._features.map((f) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(f, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        )),
                  ],
                ),
              ),

              const Spacer(),

              // Bot贸n principal
              _picking
                  ? Center(
                      child: Column(children: [
                        CircularProgressIndicator(color: _color),
                        const SizedBox(height: 12),
                        const Text('Abriendo selector...', style: TextStyle(color: Colors.white60)),
                      ]),
                    )
                  : ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.folder_open_rounded, size: 22),
                      label: const Text(
                        'Seleccionar desde almacenamiento',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _color,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                    ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text('Cancelar', style: TextStyle(color: _color.withOpacity(0.6), fontSize: 14)),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}