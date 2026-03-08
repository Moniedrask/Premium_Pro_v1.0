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

                  // Selector de modo de bitrate (CRF vs CBR)
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text('Modo de bitrate', style: TextStyle(color: Colors.white)),
                          subtitle: Text(
                            _settings.bitrateMode == BitrateMode.crf ? 'CRF (calidad constante)' : 'CBR (bitrate constante)',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          trailing: DropdownButton<BitrateMode>(
                            value: _settings.bitrateMode,
                            items: const [
                              DropdownMenuItem(value: BitrateMode.crf, child: Text('CRF')),
                              DropdownMenuItem(value: BitrateMode.cbr, child: Text('CBR')),
                            ],
                            onChanged: processor.isProcessing ? null : (val) {
                              setState(() => _settings.bitrateMode = val!);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Sliders según modo
                  if (_settings.bitrateMode == BitrateMode.cbr) ...[
                    _buildBitrateSlider(processor),
                    const Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Text(
                        'CBR mantiene bitrate constante. Útil para streaming.',
                        style: TextStyle(color: Colors.amber, fontSize: 11),
                      ),
                    ),
                  ] else ...[
                    _buildBitrateSlider(processor),
                    _buildCRFSlider(processor),
                  ],

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
                  const SizedBox(height: 10),
                  const Text(
                    'MEJORAS DE CALIDAD',
                    style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  CheckboxListTile(
                    title: const Text('Escalar resolución', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Aumenta resolución hasta 4x (1080p → 4320p, 2K → 8K)',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    value: _settings.resolutionUpscale,
                    onChanged: processor.isProcessing ? null : (val) {
                      setState(() => _settings.resolutionUpscale = val!);
                    },
                    secondary: Icon(Icons.zoom_out_map, color: globalSettings.accentColor),
                    activeColor: globalSettings.accentColor,
                  ),
                  if (_settings.resolutionUpscale)
                    Padding(
                      padding: const EdgeInsets.only(left: