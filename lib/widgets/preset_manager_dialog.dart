import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PresetManagerDialog extends StatefulWidget {
  final String type; // 'video', 'audio', 'image'
  final Function(Map<String, dynamic>) onLoadPreset;

  const PresetManagerDialog({
    super.key,
    required this.type,
    required this.onLoadPreset,
  });

  @override
  State<PresetManagerDialog> createState() => _PresetManagerDialogState();
}

class _PresetManagerDialogState extends State<PresetManagerDialog> {
  List<FileSystemEntity> _presetFiles = [];
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    final dir = await getApplicationDocumentsDirectory();
    final presetDir = Directory('${dir.path}/presets/${widget.type}');
    if (!await presetDir.exists()) {
      await presetDir.create(recursive: true);
    }
    setState(() {
      _presetFiles = presetDir.listSync().whereType<File>().toList();
    });
  }

  Future<void> _saveCurrentPreset() async {
    if (_nameController.text.isEmpty) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/presets/${widget.type}/${_nameController.text}.json');
    // Aquí deberías obtener el JSON de la configuración actual desde el provider
    // Este es un ejemplo:
    final json = {'example': 'data'};
    await file.writeAsString(jsonEncode(json));
    _loadPresets();
    _nameController.clear();
  }

  Future<void> _deletePreset(File file) async {
    await file.delete();
    _loadPresets();
  }

  void _loadPreset(File file) async {
    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    widget.onLoadPreset(json);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF111111),
      title: Text('Gestor de presets - ${widget.type}', style: const TextStyle(color: Colors.white)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Nombre del preset',
                      labelStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.save, color: Colors.green),
                  onPressed: _saveCurrentPreset,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _presetFiles.length,
                itemBuilder: (ctx, i) {
                  final file = _presetFiles[i];
                  final name = file.path.split('/').last.replaceAll('.json', '');
                  return ListTile(
                    title: Text(name, style: const TextStyle(color: Colors.white)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.file_open, color: Colors.blue),
                          onPressed: () => _loadPreset(file as File),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deletePreset(file as File),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar', style: TextStyle(color: Colors.blueAccent)),
        ),
      ],
    );
  }
}