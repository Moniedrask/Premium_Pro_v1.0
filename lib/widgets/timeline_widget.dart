import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/media_processor.dart';
import '../models/video_settings.dart';
import '../providers/settings_provider.dart'; // NUEVO

class TimelineWidget extends StatefulWidget {
  const TimelineWidget({super.key});

  @override
  State<TimelineWidget> createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> {
  String? _selectedVideoPath;
  String _selectedVideoName = 'Ninguno';
  late VideoSettings _settings;
  bool _keepOriginalName = false; // NUEVO

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final globalSettings = settingsProvider.settings;
    // Cargar valores por defecto desde el provider
    final videoDefaults = globalSettings.videoDefaults;
    _settings = VideoSettings.fromJson(videoDefaults);
    _keepOriginalName = globalSettings.keepOriginalName;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final processor = Provider.of<MediaProcessor>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final globalSettings = settingsProvider.settings;

    return Column(
      children: [
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
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF000000),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "CONFIGURACIÓN DE EXPORTACIÓN",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  _buildCodecDropdown(processor),
                  const SizedBox(height: 10),
                  _buildBitrateSlider(processor),
                  const SizedBox(height: 10),
                  _buildCRFSlider(processor),
                  const SizedBox(height: 10),
                  _buildPresetDropdown(processor),
                  const SizedBox(height: 10),
                  _buildHardwareAccelerationSwitch(processor),
                  const SizedBox(height: 10),
                  // NUEVOS CHECKBOXES
                  CheckboxListTile(
                    title: const Text('Mantener nombre original', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Si está activado, no se añadirá timestamp', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    value: _keepOriginalName,
                    onChanged: processor.isProcessing ? null : (val) {
                      setState(() => _keepOriginalName = val!);
                      // También actualizar el provider global si se desea
                      if (globalSettings.keepOriginalName != val) {
                        settingsProvider.setKeepOriginalName(val!);
                      }
                    },
                    secondary: Icon(Icons.label, color: globalSettings.accentColor),
                    activeColor: globalSettings.accentColor,
                  ),
                  CheckboxListTile(
                    title: const Text('Guardar como permanente', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Esta configuración se usará por defecto en futuras exportaciones', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    value: _settings.saveAsDefault,
                    onChanged: processor.isProcessing ? null : (val) {
                      setState(() => _settings.saveAsDefault = val!);
                      // Si se marca, guardar en provider
                      if (val == true) {
                        settingsProvider.setVideoDefaults(_settings.toJson());
                      }
                    },
                    secondary: Icon(Icons.save, color: globalSettings.accentColor),
                    activeColor: globalSettings.accentColor,
                  ),
                  const SizedBox(height: 16),
                  _buildActionButtons(processor),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ... (los métodos de construcción de widgets existentes se mantienen igual,
  // pero usando _settings en lugar de variables locales. Ya los tienes implementados.
  // Asegúrate de que todos los callbacks usen setState para actualizar _settings.)

  String _getExtensionForCodec(String codec) {
    switch (codec) {
      case 'libvpx-vp9':
        return 'webm';
      default:
        return 'mp4';
    }
  }

  Future<void> _selectVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
        withData: false,
      );

      if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
        setState(() {
          _selectedVideoPath = result.files.single.path;
          _selectedVideoName = result.files.single.name;
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

    try {
      final durationMicros = await processor.getVideoDuration(_selectedVideoPath!);

      if (durationMicros == null || durationMicros <= 0) {
        debugPrint('⚠️ No se pudo obtener la duración del video, el progreso será aproximado');
      }

      final Directory? directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('No se pudo acceder al almacenamiento');
      }

      final String outputFolder = '${directory.path}/PremiumPro';
      await Directory(outputFolder).create(recursive: true);

      final int timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = _getExtensionForCodec(_settings.videoCodec);

      // Generar nombre de archivo según preferencia
      String outputPath;
      if (_keepOriginalName) {
        final originalName = _selectedVideoName.split('.').first;
        outputPath = '$outputFolder/${originalName}_premium.$ext';
      } else {
        outputPath = '$outputFolder/premium_export_$timestamp.$ext';
      }

      debugPrint('📁 Input: $_selectedVideoPath');
      debugPrint('📁 Output: $outputPath');
      debugPrint('⚙️ Config: ${_settings.videoCodec} | ${_settings.videoBitrate} kbps | ${_settings.preset} | CRF ${_settings.crf} | HW Accel: ${_settings.hardwareAcceleration}');

      final bool success = await processor.processVideo(
        inputPath: _selectedVideoPath!,
        outputPath: outputPath,
        settings: _settings,
        totalDurationMicros: durationMicros,
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
        // Opcional: no resetear la selección si se desea
        setState(() {
          _selectedVideoPath = null;
          _selectedVideoName = 'Ninguno';
        });
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
}