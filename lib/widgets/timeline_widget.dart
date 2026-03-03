import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/media_processor.dart';
import '../models/compression_settings.dart';
import '../utils/helpers.dart'; // Para obtener duración del video

class TimelineWidget extends StatefulWidget {
  const TimelineWidget({super.key});

  @override
  State<TimelineWidget> createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> {
  String? _selectedVideoPath;
  String _selectedVideoName = 'Ninguno';
  CompressionSettings _settings = CompressionSettings();
  int? _videoDurationMs; // Duración del video seleccionado

  @override
  Widget build(BuildContext context) {
    final processor = Provider.of<MediaProcessor>(context);

    return Column(
      children: [
        // Visor de previsualización (placeholder)
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

        // Controles y configuración
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF000000),
            child: _buildControls(processor),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingView(MediaProcessor processor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Barra de progreso determinada
        Container(
          width: 200,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: processor.progress,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
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
        const SizedBox(height: 16),
        // Botón de cancelar
        ElevatedButton.icon(
          onPressed: () {
            processor.cancelProcessing();
          },
          icon: const Icon(Icons.cancel),
          label: const Text('CANCELAR'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
          ),
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
        const Text(
          'Selecciona un video para comenzar',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          'Video: $_selectedVideoName',
          style: TextStyle(color: Colors.blueAccent, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildControls(MediaProcessor processor) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "CONFIGURACIÓN DE EXPORTACIÓN",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 10),

          // Selector de Códec
          _buildCodecDropdown(processor),

          const SizedBox(height: 10),

          // Slider de Bitrate
          _buildBitrateSlider(processor),

          const SizedBox(height: 10),

          // Slider CRF
          _buildCRFSlider(processor),

          const SizedBox(height: 10),

          // Selector de Preset
          _buildPresetDropdown(processor),

          const SizedBox(height: 16),

          // Botones de acción
          _buildActionButtons(processor),
        ],
      ),
    );
  }

  Widget _buildCodecDropdown(MediaProcessor processor) {
    return DropdownButtonFormField<String>(
      value: _settings.videoCodec,
      dropdownColor: const Color(0xFF111111),
      items: const [
        DropdownMenuItem(value: 'libx264', child: Text('H.264 (Compatible)', style: TextStyle(color: Colors.white))),
        DropdownMenuItem(value: 'libx265', child: Text('H.265 (Eficiente)', style: TextStyle(color: Colors.white))),
        DropdownMenuItem(value: 'libvpx-vp9', child: Text('VP9 (Web)', style: TextStyle(color: Colors.white))),
      ],
      onChanged: processor.isProcessing ? null : (val) {
        setState(() => _settings.videoCodec = val!);
      },
      decoration: const InputDecoration(
        labelText: 'Códec de Video',
        labelStyle: TextStyle(color: Colors.grey),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildBitrateSlider(MediaProcessor processor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bitrate: ${_settings.videoBitrate} kbps',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Slider(
          value: _settings.videoBitrate.toDouble(),
          min: 500,
          max: 10000,
          divisions: 38,
          activeColor: Colors.blueAccent,
          onChanged: processor.isProcessing ? null : (val) {
            setState(() => _settings.videoBitrate = val.round());
          },
        ),
        const Text('1000= Baja | 2500= Media | 5000+= Alta',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildCRFSlider(MediaProcessor processor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CRF (Calidad): ${_settings.crf}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Slider(
          value: _settings.crf.toDouble(),
          min: 0,
          max: 51,
          divisions: 51,
          activeColor: Colors.blueAccent,
          onChanged: processor.isProcessing ? null : (val) {
            setState(() => _settings.crf = val.round());
          },
        ),
        const Text('18-23= Alta | 24-28= Media | 29-51= Baja',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildPresetDropdown(MediaProcessor processor) {
    return DropdownButtonFormField<String>(
      value: _settings.preset,
      dropdownColor: const Color(0xFF111111),
      items: const [
        DropdownMenuItem(value: 'ultrafast', child: Text('Ultra Rápido', style: TextStyle(color: Colors.white))),
        DropdownMenuItem(value: 'fast', child: Text('Rápido', style: TextStyle(color: Colors.white))),
        DropdownMenuItem(value: 'medium', child: Text('Medio (Recomendado)', style: TextStyle(color: Colors.white))),
        DropdownMenuItem(value: 'slow', child: Text('Lento', style: TextStyle(color: Colors.white))),
        DropdownMenuItem(value: 'veryslow', child: Text('Muy Lento', style: TextStyle(color: Colors.white))),
      ],
      onChanged: processor.isProcessing ? null : (val) {
        setState(() => _settings.preset = val!);
      },
      decoration: const InputDecoration(
        labelText: 'Velocidad de Codificación',
        labelStyle: TextStyle(color: Colors.grey),
        border: OutlineInputBorder(),
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
            label: const Text('CARGAR', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: processor.isProcessing || _selectedVideoPath == null
                ? null
                : () => _exportVideo(processor),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
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
        withData: false,
      );

      if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
        final path = result.files.single.path!;
        // Obtener duración del video (implementar en helpers)
        final duration = await getVideoDuration(path);
        setState(() {
          _selectedVideoPath = path;
          _selectedVideoName = result.files.single.name;
          _videoDurationMs = duration;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Video cargado: $_selectedVideoName'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ No se seleccionó ningún video'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error al seleccionar video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _exportVideo(MediaProcessor processor) async {
    if (_selectedVideoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Primero selecciona un video'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Usar FilePicker para elegir dónde guardar
    String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar video exportado',
      fileName: 'premium_export_${DateTime.now().millisecondsSinceEpoch}.${_getExtensionForCodec(_settings.videoCodec)}',
    );

    if (outputPath == null) {
      return; // Usuario canceló
    }

    try {
      debugPrint('📁 Input: $_selectedVideoPath');
      debugPrint('📁 Output: $outputPath');
      debugPrint('⚙️ Config: ${_settings.videoCodec} | ${_settings.videoBitrate} kbps | ${_settings.preset} | CRF ${_settings.crf}');

      final bool success = await processor.processVideo(
        inputPath: _selectedVideoPath!,
        outputPath: outputPath,
        codec: _settings.videoCodec,
        bitrate: _settings.videoBitrate,
        preset: _settings.preset,
        crf: _settings.crf,
        videoDurationMs: _videoDurationMs ?? 60000,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '✅ Exportación completada' : '❌ Error en exportación'),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      if (success) {
        debugPrint('✅ Exportación exitosa: $outputPath');
        // Opcional: resetear selección
        // setState(() {
        //   _selectedVideoPath = null;
        //   _selectedVideoName = 'Ninguno';
        // });
      }
    } catch (e) {
      debugPrint('❌ Error en exportación: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error crítico: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  String _getExtensionForCodec(String codec) {
    switch (codec) {
      case 'libvpx-vp9':
        return 'webm';
      case 'libx265':
        return 'mp4';
      default:
        return 'mp4';
    }
  }
}