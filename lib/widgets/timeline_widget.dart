import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/media_processor.dart';

class TimelineWidget extends StatefulWidget {
  const TimelineWidget({super.key});

  @override
  State<TimelineWidget> createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> {
  String? _selectedVideoPath;
  String _codec = 'libx264';

  @override
  Widget build(BuildContext context) {
    final processor = Provider.of<MediaProcessor>(context);

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            color: const Color(0xFF111111),
            child: Center(
              child: processor.isProcessing
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Colors.blueAccent),
                        const SizedBox(height: 20),
                        Text(processor.statusMessage, style: const TextStyle(color: Colors.white)),
                        Text("${(processor.progress * 100).toStringAsFixed(1)}%", style: const TextStyle(color: Colors.grey)),
                      ],
                    )
                  : const Icon(Icons.play_circle_outline, size: 80, color: Colors.grey),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF000000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,              children: [
                const Text("CONFIGURACIÓN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _codec,
                  dropdownColor: const Color(0xFF111111),
                  items: const [
                    DropdownMenuItem(value: 'libx264', child: Text('H.264', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'libx265', child: Text('H.265', style: TextStyle(color: Colors.white))),
                  ],
                  onChanged: (val) => setState(() => _codec = val!),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _selectVideo,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('CARGAR VIDEO'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _selectedVideoPath != null && !processor.isProcessing
                      ? () => _exportVideo(processor)
                      : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  child: const Text('EXPORTAR', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedVideoPath = result.files.single.path);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video cargado'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _exportVideo(MediaProcessor processor) async {
    if (_selectedVideoPath == null) return;
    final directory = await getExternalStorageDirectory();
    final outputFolder = '${directory!.path}/PremiumPro';
    await Directory(outputFolder).create(recursive: true);
    final timestamp = DateTime.now().millisecondsSinceEpoch;    final outputPath = '$outputFolder/export_$timestamp.mp4';

    final success = await processor.processVideo(
      inputPath: _selectedVideoPath!,
      outputPath: outputPath,
      codec: _codec,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Exportación completada' : 'Error en exportación'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}
