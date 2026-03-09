import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class HdrMergerWidget extends StatefulWidget {
  final Function(List<String>) onImagesSelected;

  const HdrMergerWidget({super.key, required this.onImagesSelected});

  @override
  State<HdrMergerWidget> createState() => _HdrMergerWidgetState();
}

class _HdrMergerWidgetState extends State<HdrMergerWidget> {
  List<String> _selectedPaths = [];

  Future<void> _pickImages() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        _selectedPaths = result.paths.whereType<String>().toList();
      });
      widget.onImagesSelected(_selectedPaths);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.photo_library),
          label: const Text('Seleccionar imágenes (2-3)'),
        ),
        if (_selectedPaths.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('${_selectedPaths.length} imagen(es) seleccionada(s)', style: const TextStyle(color: Colors.white)),
          if (_selectedPaths.length < 2 || _selectedPaths.length > 3)
            const Text('Selecciona entre 2 y 3 imágenes', style: TextStyle(color: Colors.orange)),
        ],
      ],
    );
  }
}