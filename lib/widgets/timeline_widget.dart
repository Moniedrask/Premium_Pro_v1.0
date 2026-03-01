import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../services/media_processor.dart';
import '../models/compression_settings.dart';

class TimelineWidget extends StatefulWidget {
  const TimelineWidget({super.key});

  @override
  State<TimelineWidget> createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> {
  String? _selectedVideoPath;
  String _codec = 'libx264';
  int _bitrate = 2500;
  String _preset = 'medium';
  int _crf = 23;

  @override
  Widget build(BuildContext context) {
    final processor = Provider.of<MediaProcessor>(context);

    return Column(
      children: [
        // ==================== VISOR DE PREVISUALIZACIÓN ====================
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            color: const Color(0xFF111111),
            child: Center(
              child: processor.isProcessing
                  ? _buildProcessingView(processor)
                  : _buildPreviewPlaceholder(),
            ),
          ),
        ),
        
        // ==================== CONTROLES Y CONFIGURACIÓN ====================
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF000000),
            child: _buildControls(processor),
          ),
        ),      ],
    );
  }

  Widget _buildProcessingView(MediaProcessor processor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: Colors.blueAccent),
        const SizedBox(height: 20),
        Text(
          processor.statusMessage,
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "${(processor.progress * 100).toStringAsFixed(1)}%",
          style: const TextStyle(color: Colors.grey, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        if (processor.processingTime != null)
          Text(
            'Tiempo: ${processor.processingTime!.inSeconds}s',
            style: const TextStyle(color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildPreviewPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.play_circle_outline, size: 80, color: Colors.grey[700]),
        const SizedBox(height: 16),
        Text(
          'Selecciona un video para comenzar',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
        if (_selectedVideoPath != null) ...[
          const SizedBox(height: 8),
          Text(
            'Video cargado',
            style: const TextStyle(color: Colors.green, fontSize: 14),
          ),
        ],
      ],
    );
  }
  Widget _buildControls(MediaProcessor processor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "CONFIGURACIÓN DE EXPORTACIÓN",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 10),
        
        // Selector de Códec
        _buildCodecDropdown(),
        
        const SizedBox(height: 10),
        
        // Slider de Bitrate
        _buildBitrateSlider(),
        
        const SizedBox(height: 10),
        
        // Slider CRF
        _buildCRFSlider(),
        
        const SizedBox(height: 10),
        
        // Selector de Preset
        _buildPresetDropdown(),
        
        const Spacer(),
        
        // Botones de acción
        _buildActionButtons(processor),
      ],
    );
  }

  Widget _buildCodecDropdown() {
    return DropdownButtonFormField<String>(
      value: _codec,
      dropdownColor: const Color(0xFF111111),
      items: const [
        DropdownMenuItem(value: 'libx264', child: Text('H.264 (Compatible)', style: TextStyle(color: Colors.white))),
        DropdownMenuItem(value: 'libx265', child: Text('H.265 (Eficiente)', style: TextStyle(color: Colors.white))),
        DropdownMenuItem(value: 'libvpx-vp9', child: Text('VP9 (Web)', style: TextStyle(color: Colors.white))),
      ],
      onChanged: processor.isProcessing ? null : (val) => setState(() => _codec = val!),
      decoration: const InputDecoration(
        labelText: 'Códec de Video',
        labelStyle: TextStyle(color: Colors.grey),
      ),    );
  }

  Widget _buildBitrateSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bitrate: $_bitrate kbps', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Slider(
          value: _bitrate.toDouble(),
          min: 500,
          max: 10000,
          divisions: 38,
          activeColor: Colors.blueAccent,
          onChanged: processor.isProcessing ? null : (val) => setState(() => _bitrate = val.round()),
        ),
      ],
    );
  }

  Widget _buildCRFSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CRF (Calidad): $_crf', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Slider(
          value: _crf.toDouble(),
          min: 0,
          max: 51,
          divisions: 51,
          activeColor: Colors.blueAccent,
          onChanged: processor.isProcessing ? null : (val) => setState(() => _crf = val.round()),
        ),
        const Text('18-23: Alta calidad | 24-28: Media', style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildPresetDropdown() {
    return DropdownButtonFormField<String>(
      value: _preset,
      dropdownColor: const Color(0xFF111111),
      items: const [
        DropdownMenuItem(value: 'ultrafast', child: Text('Ultra Rápido', style: TextStyle(color: Colors.white))),
        DropdownMenuItem(value: 'fast', child: Text('Rápido', style: TextStyle(color: Colors.white))),
        DropdownMenuItem(value: 'medium', child: Text('Medio (Recomendado)', style: TextStyle(color: Colors.white))),
        DropdownMenuItem(value: 'slow', child: Text('Lento', style: TextStyle(color: Colors.white))),
        DropdownMenuItem(value: 'veryslow', child: Text('Muy Lento', style: TextStyle(color: Colors.white))),
      ],
      onChanged: processor.isProcessing ? null : (val) => setState(() => _preset = val!),      decoration: const InputDecoration(
        labelText: 'Velocidad de Codificación',
        labelStyle: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildActionButtons(MediaProcessor processor) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: processor.isProcessing ? null : _selectVideo,
            icon: const Icon(Icons.folder_open),
            label: const Text('CARGAR'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: processor.isProcessing || _selectedVideoPath == null
                ? null
                : () => _exportVideo(processor),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('EXPORTAR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Future<void> _selectVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedVideoPath = result.files.single.path;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Video cargado: ${result.files.single.name}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportVideo(MediaProcessor processor) async {
    if (_selectedVideoPath == null) return;

    try {
      // Obtener carpeta de salida
      final directory = await getExternalStorageDirectory();
      final outputFolder = '${directory!.path}/PremiumPro';
      
      // Crear carpeta si no existe
      await Directory(outputFolder).create(recursive: true);
      
      // Generar nombre de archivo de salida
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '$outputFolder/premium_export_$timestamp.mp4';
      
      debugPrint('📁 Input: $_selectedVideoPath');
      debugPrint('📁 Output: $outputPath');
      
      // Iniciar procesamiento
      final success = await processor.processVideo(
        inputPath: _selectedVideoPath!,
        outputPath: outputPath,
        codec: _codec,
        bitrate: _bitrate,
        preset: _preset,
        crf: _crf,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '✅ Exportación completada' : '❌ Error en exportación'),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error en exportación: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error crítico: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
