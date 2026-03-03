import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../services/image_processor.dart';
import '../services/ai_manager.dart';
import '../models/image_settings.dart';

class ImageEditorWidget extends StatefulWidget {
  const ImageEditorWidget({super.key});

  @override
  State<ImageEditorWidget> createState() => _ImageEditorWidgetState();
}

class _ImageEditorWidgetState extends State<ImageEditorWidget> {
  String? _selectedImagePath;
  String _selectedImageName = 'Ninguno';
  ImageSettings _settings = ImageSettings();

  @override
  Widget build(BuildContext context) {
    final processor = Provider.of<ImageProcessor>(context);
    final aiManager = Provider.of<AIManager>(context);

    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            color: const Color(0xFF111111),
            child: _buildImageView(processor),
          ),
        ),
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

  Widget _buildImageView(ImageProcessor processor) {
    if (_selectedImagePath == null) {
      return const Center(
        child: Text('Selecciona una imagen', style: TextStyle(color: Colors.grey)),
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
    return Center(
      child: Image.file(
        File(_selectedImagePath!),
        fit: BoxFit.contain,
        errorBuilder: (ctx, error, stack) => const Text('Error al cargar imagen'),
      ),
    );
  }

  Widget _buildControls(ImageProcessor processor, AIManager aiManager) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CONFIGURACIÓN DE IMAGEN',
              style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          DropdownButtonFormField<String>(
            value: _settings.format,
            items: const [
              DropdownMenuItem(value: 'jpeg', child: Text('JPEG')),
              DropdownMenuItem(value: 'png', child: Text('PNG')),
              DropdownMenuItem(value: 'webp', child: Text('WebP')),
              DropdownMenuItem(value: 'avif', child: Text('AVIF')),
            ],
            onChanged: (val) => setState(() => _settings.format = val!),
            decoration: const InputDecoration(labelText: 'Formato'),
          ),

          const SizedBox(height: 10),
          if (_settings.format == 'jpeg' || _settings.format == 'webp')
            Column(
              children: [
                Text('Calidad: ${_settings.quality}'),
                Slider(
                  value: _settings.quality.toDouble(),
                  min: 1,
                  max: 100,
                  divisions: 99,
                  onChanged: (val) => setState(() => _settings.quality = val.round()),
                ),
              ],
            ),

          if (_settings.format == 'png')
            Column(
              children: [
                Text('Nivel de compresión: ${_settings.compressionLevel}'),
                Slider(
                  value: _settings.compressionLevel.toDouble(),
                  min: 0,
                  max: 9,
                  divisions: 9,
                  onChanged: (val) => setState(() => _settings.compressionLevel = val.round()),
                ),
              ],
            ),

          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Ancho máx. (px)'),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => _settings.maxWidth = int.tryParse(val) ?? 0,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Alto máx. (px)'),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => _settings.maxHeight = int.tryParse(val) ?? 0,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _settings.filter,
            items: const [
              DropdownMenuItem(value: 'lanczos', child: Text('Lanczos (alta calidad)')),
              DropdownMenuItem(value: 'bicubic', child: Text('Bicúbico')),
              DropdownMenuItem(value: 'bilinear', child: Text('Bilineal (rápido)')),
            ],
            onChanged: (val) => setState(() => _settings.filter = val!),
            decoration: const InputDecoration(labelText: 'Algoritmo'),
          ),

          const SizedBox(height: 10),
          Row(
            children: [
              Checkbox(
                value: _settings.preserveMetadata,
                onChanged: (val) => setState(() => _settings.preserveMetadata = val!),
              ),
              const Text('Conservar metadatos EXIF', style: TextStyle(color: Colors.white)),
            ],
          ),

          if (aiManager.isModelAvailable)
            Row(
              children: [
                Checkbox(
                  value: _settings.aiUpscale,
                  onChanged: (val) => setState(() => _settings.aiUpscale = val!),
                ),
                const Text('Upscale con IA', style: TextStyle(color: Colors.white)),
              ],
            ),

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: processor.isProcessing ? null : _selectImage,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('CARGAR'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: processor.isProcessing || _selectedImagePath == null
                      ? null
                      : () => _exportImage(processor),
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

  Future<void> _selectImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedImagePath = result.files.single.path;
          _selectedImageName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint('Error seleccionando imagen: $e');
    }
  }

  Future<void> _exportImage(ImageProcessor processor) async {
    if (_selectedImagePath == null) return;

    try {
      final dir = await getExternalStorageDirectory();
      if (dir == null) throw Exception('No storage');
      final outputDir = '${dir.path}/PremiumPro/Images';
      await Directory(outputDir).create(recursive: true);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = _settings.format;
      final outputPath = '$outputDir/image_$timestamp.$ext';

      final success = await processor.processImage(
        inputPath: _selectedImagePath!,
        outputPath: outputPath,
        settings: _settings,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Imagen exportada'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Error exportando imagen: $e');
    }
  }
}