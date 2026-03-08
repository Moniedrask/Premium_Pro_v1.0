import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../models/compression_preset.dart';
import '../models/video_settings.dart';
import '../models/audio_settings.dart';
import '../models/image_settings.dart';

class CompressionDialog extends StatefulWidget {
  final Function(CompressionPreset) onApply;

  const CompressionDialog({super.key, required this.onApply});

  @override
  State<CompressionDialog> createState() => _CompressionDialogState();
}

class _CompressionDialogState extends State<CompressionDialog> {
  late CompressionPreset _selectedPreset;
  String _selectedCategory = 'Predefinidos'; // 'Predefinidos' o 'Usuario'

  @override
  void initState() {
    super.initState();
    _selectedPreset = CompressionPreset.defaults.first;
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final userPresets = settingsProvider.userPresets;
    final allPresets = _selectedCategory == 'Predefinidos'
        ? CompressionPreset.defaults
        : userPresets;

    return AlertDialog(
      backgroundColor: const Color(0xFF111111),
      title: const Text(
        'Compresión rápida',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Categoría:', style: TextStyle(color: Colors.white70)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedCategory,
                  dropdownColor: const Color(0xFF111111),
                  items: const [
                    DropdownMenuItem(value: 'Predefinidos', child: Text('Predefinidos')),
                    DropdownMenuItem(value: 'Usuario', child: Text('Usuario')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCategory = val;
                        if (allPresets.isNotEmpty) {
                          _selectedPreset = allPresets.first;
                        }
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: allPresets.length,
                itemBuilder: (ctx, index) {
                  final preset = allPresets[index];
                  return RadioListTile<CompressionPreset>(
                    title: Text(
                      preset.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    value: preset,
                    groupValue: _selectedPreset,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedPreset = val;
                        });
                      }
                    },
                    activeColor: Colors.blueAccent,
                  );
                },
              ),
            ),
            if (_selectedCategory == 'Usuario')
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        _showCreatePresetDialog(context);
                      },
                      icon: const Icon(Icons.add, color: Colors.green),
                      label: const Text('Nuevo preset', style: TextStyle(color: Colors.green)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(_selectedPreset);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          child: const Text('Aplicar'),
        ),
      ],
    );
  }

  void _showCreatePresetDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Nuevo preset', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Nombre del preset',
            labelStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final newPreset = CompressionPreset(
                  name: name,
                  videoSettings: VideoSettings(),
                  audioSettings: AudioSettings(),
                  imageSettings: ImageSettings(),
                );
                final provider = Provider.of<SettingsProvider>(context, listen: false);
                await provider.saveUserPreset(newPreset);
                if (mounted) {
                  Navigator.pop(ctx);
                  setState(() {
                    _selectedCategory = 'Usuario';
                    _selectedPreset = newPreset;
                  });
                }
              }
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }
}