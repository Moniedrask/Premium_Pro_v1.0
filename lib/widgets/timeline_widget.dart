import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/media_processor.dart';
import '../models/video_settings.dart';
import '../providers/settings_provider.dart';
import '../services/trash_manager.dart';
import '../models/app_settings.dart';

class TimelineWidget extends StatefulWidget {
  const TimelineWidget({super.key});

  @override
  State<TimelineWidget> createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> {
  String? _selectedVideoPath;
  String _selectedVideoName = 'Ninguno';
  late VideoSettings _settings;
  bool _keepOriginalName = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final globalSettings = settingsProvider.settings;
    _settings = VideoSettings.fromJson(globalSettings.videoDefaults);
    _keepOriginalName = globalSettings.keepOriginalName;
    setState(() {});
  }

  // Métodos para densidad y redondez
  double _getPadding(InterfaceDensity density) {
    switch (density) {
      case InterfaceDensity.compact:
        return 4.0;
      case InterfaceDensity.normal:
        return 8.0;
      case InterfaceDensity.comfortable:
        return 12.0;
    }
  }

  BorderRadius _getBorderRadius(CornerRoundness roundness) {
    switch (roundness) {
      case CornerRoundness.square:
        return BorderRadius.zero;
      case CornerRoundness.light:
        return BorderRadius.circular(8);
      case CornerRoundness.rounded:
        return BorderRadius.circular(16);
    }
  }

  // Lógica de borrado (papelera)
  Future<void> _deleteFile(String filePath) async {
    final trashManager = TrashManager();
    final settings = Provider.of<SettingsProvider>(context, listen: false).settings;

    if (settings.trashEnabled) {
      if (settings.alwaysAskBeforeDelete) {
        bool? confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirmar'),
            content: const Text('¿Mover este archivo a la papelera?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Mover')),
            ],
          ),
        );
        if (confirm == true) {
          await trashManager.moveToTrash(filePath);
          setState(() {
            _selectedVideoPath = null;
            _selectedVideoName = 'Ninguno';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Archivo movido a la papelera'), backgroundColor: Colors.orange),
            );
          }
        }
      } else {
        await trashManager.moveToTrash(filePath);
        setState(() {
          _selectedVideoPath = null;
          _selectedVideoName = 'Ninguno';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Archivo movido a la papelera'), backgroundColor: Colors.orange),
          );
        }
      }
    } else {
      if (settings.dontShowDeleteWarning) {
        File(filePath).delete();
        setState(() {
          _selectedVideoPath = null;
          _selectedVideoName = 'Ninguno';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Archivo eliminado permanentemente'), backgroundColor: Colors.red),
          );
        }
      } else {
        bool? confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirmar'),
            content: const Text('¿Borrar este archivo permanentemente?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Borrar')),
            ],
          ),
        );
        if (confirm == true) {
          File(filePath).delete();
          setState(() {
            _selectedVideoPath = null;
            _selectedVideoName = 'Ninguno';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Archivo eliminado permanentemente'), backgroundColor: Colors.red),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final processor = Provider.of<MediaProcessor>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final globalSettings = settingsProvider.settings;

    final paddingValue = _getPadding(globalSettings.density);
    final borderRadius = _getBorderRadius(globalSettings.roundness);

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                color: const Color(0xFF111111),
                child: Center(
                  child: processor.isProcessing
                      ? _buildProcessingView(processor)
                      : _buildPreviewPlaceholder(),
                ),
              ),
              if (_selectedVideoPath != null && !processor.isProcessing)
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(Icons.delete, color: globalSettings.accentColor),
                    onPressed: () => _deleteFile(_selectedVideoPath!),
                    tooltip: 'Eliminar video',
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            padding: EdgeInsets.all(paddingValue * 2),
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
                  CheckboxListTile(
                    title: const Text('Mantener nombre original', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Si está activado, no se añadirá timestamp', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    value: _keepOriginalName,
                    onChanged: processor.isProcessing ? null : (val) {
                      setState(() => _keepOriginalName = val!);
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
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => processor.cancelProcessing(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: const Text('CANCELAR', style: TextStyle(fontWeight: FontWeight.bold)),
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
        const Text('1000= Baja | 2500= Media | 5000+= Alta', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
        const Text('18-23= Alta | 24-28= Media | 29-51= Baja', style: TextStyle(color: Colors.grey, fontSize: 12)),
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

  Widget _buildHardwareAccelerationSwitch(MediaProcessor processor) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    return Row(
      children: [
        Switch(
          value: _settings.hardwareAcceleration,
          onChanged: processor.isProcessing ? null : (val) {
            setState(() => _settings.hardwareAcceleration = val);
          },
          activeColor: settingsProvider.settings.accentColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Aceleración hardware',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                'Usa GPU/MediaCodec si está disponible',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
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
      // Obtenemos la duración (opcional, no se usa para progreso por ahora)
      // final durationMicros = await processor.getVideoDuration(_selectedVideoPath!);

      final Directory? directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('No se pudo acceder al almacenamiento');
      }

      final String outputFolder = '${directory.path}/PremiumPro';
      await Directory(outputFolder).create(recursive: true);

      final int timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = _getExtensionForCodec(_settings.videoCodec);

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
        // totalDurationMicros ya no se pasa
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