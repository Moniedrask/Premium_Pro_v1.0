import 'package:flutter/material.dart';
import '../models/timeline_layer.dart';

class LayerEditorDialog extends StatefulWidget {
  final TimelineLayer layer;
  final Function(TimelineLayer) onSave;

  const LayerEditorDialog({super.key, required this.layer, required this.onSave});

  @override
  State<LayerEditorDialog> createState() => _LayerEditorDialogState();
}

class _LayerEditorDialogState extends State<LayerEditorDialog> {
  late TextEditingController _startController;
  late TextEditingController _durationController;
  late TextEditingController _volumeController;

  @override
  void initState() {
    super.initState();
    _startController = TextEditingController(text: widget.layer.start.inMilliseconds.toString());
    _durationController = TextEditingController(text: widget.layer.duration.inMilliseconds.toString());
    _volumeController = TextEditingController(text: widget.layer.volume.toString());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editar capa: ${widget.layer.name}'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _startController,
              decoration: const InputDecoration(labelText: 'Inicio (ms)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(labelText: 'Duración (ms)'),
              keyboardType: TextInputType.number,
            ),
            if (widget.layer.type == LayerType.audio || widget.layer.type == LayerType.video)
              TextField(
                controller: _volumeController,
                decoration: const InputDecoration(labelText: 'Volumen (0-2)'),
                keyboardType: TextInputType.number,
              ),
            // Otros campos según tipo...
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            widget.layer.start = Duration(milliseconds: int.tryParse(_startController.text) ?? 0);
            widget.layer.duration = Duration(milliseconds: int.tryParse(_durationController.text) ?? 0);
            if (widget.layer.type == LayerType.audio || widget.layer.type == LayerType.video) {
              widget.layer.volume = double.tryParse(_volumeController.text) ?? 1.0;
            }
            widget.onSave(widget.layer);
            Navigator.pop(context);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}