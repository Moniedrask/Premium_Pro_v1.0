import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/media_processor.dart';
import '../models/video_settings.dart';
import '../models/video_effect.dart';
import '../models/speed_segment.dart';
import '../widgets/video_effect_selector.dart';
import '../widgets/speed_ramp_editor.dart';
import '../widgets/tooltip_with_preview.dart';
import '../providers/settings_provider.dart';
import '../services/trash_manager.dart';
import '../models/app_settings.dart';

class TimelineWidget extends StatefulWidget {
  const TimelineWidget({super.key});

  @override
  State<TimelineWidget> createState() => TimelineWidgetState();
}

class TimelineWidgetState extends State<TimelineWidget> {
  String? _selectedVideoPath;
  String _selectedVideoName = 'Ninguno';
  late VideoSettings _settings;
  bool _keepOriginalName = false;

  // ── Reproductor de video interno ──────────────────────────────────────
  VideoPlayerController? _videoController;
  bool _videoInitializing = false;

  // Color actual del texto overlay (para el picker)
  Color _textOverlayColor = Colors.white;

  // Lista de resoluciones predefinidas
  final List<Map<String, dynamic>> _presetResolutions = [
    {'name': '144p',         'width': 256,  'height': 144},
    {'name': '240p',         'width': 426,  'height': 240},
    {'name': '360p',         'width': 640,  'height': 360},
    {'name': '480p',         'width': 854,  'height': 480},
    {'name': '720p (HD)',    'width': 1280, 'height': 720},
    {'name': '1080p (FHD)', 'width': 1920, 'height': 1080},
    {'name': '1440p (2.5K)','width': 2560, 'height': 1440},
    {'name': '4K (UHD)',    'width': 3840, 'height': 2160},
    {'name': '8K',          'width': 7680, 'height': 4320},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    final globalSettings = settingsProvider.settings;
    _settings = VideoSettings.fromJson(globalSettings.videoDefaults);
    _keepOriginalName = globalSettings.keepOriginalName;
    _textOverlayColor = _parseColorFromFFmpeg(_settings.textOverlayColor);
    setState(() {});
  }

  /// Pausa el video (llamado por VideoEditorScreen cuando la app va a background).
  void pauseVideo() {
    _videoController?.pause();
  }

  /// Carga un archivo externamente (llamado desde VideoEditorScreen).
  Future<void> loadFile(String path) async {
    setState(() {
      _selectedVideoPath = path;
      _selectedVideoName = path.split('/').last;
    });
    await _initVideoController(path);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initVideoController(String path) async {
    setState(() => _videoInitializing = true);
    final old = _videoController;
    _videoController = null;
    await old?.dispose();
    try {
      final controller = VideoPlayerController.file(File(path));
      await controller.initialize();
      controller.addListener(() {
        if (mounted) setState(() {});
      });
      if (mounted) {
        setState(() {
          _videoController = controller;
          _videoInitializing = false;
        });
      } else {
        await controller.dispose();
      }
    } catch (e) {
      debugPrint('❌ Error inicializando video player: $e');
      if (mounted) setState(() => _videoInitializing = false);
    }
  }

  // ── Color helpers ─────────────────────────────────────────────────────
  Color _parseColorFromFFmpeg(String c) {
    switch (c.toLowerCase()) {
      case 'white':  return Colors.white;
      case 'yellow': return Colors.yellow;
      case 'red':    return Colors.red;
      case 'cyan':   return Colors.cyan;
      case 'black':  return Colors.black;
      case 'green':  return Colors.green;
      default:
        final hex = c.replaceAll('#', '').replaceAll('0x', '');
        if (hex.length == 6) {
          return Color(int.parse('FF$hex', radix: 16));
        }
        return Colors.white;
    }
  }

  String _colorToFFmpeg(Color color) =>
      '#${color.red.toRadixString(16).padLeft(2, '0')}'
      '${color.green.toRadixString(16).padLeft(2, '0')}'
      '${color.blue.toRadixString(16).padLeft(2, '0')}';

  // ── Helpers de UI ─────────────────────────────────────────────────────
  double _getPadding(InterfaceDensity density) {
    switch (density) {
      case InterfaceDensity.compact:     return 4.0;
      case InterfaceDensity.normal:      return 8.0;
      case InterfaceDensity.comfortable: return 12.0;
    }
  }

  BorderRadius _getBorderRadius(CornerRoundness roundness) {
    switch (roundness) {
      case CornerRoundness.square:  return BorderRadius.zero;
      case CornerRoundness.light:   return BorderRadius.circular(8);
      case CornerRoundness.rounded: return BorderRadius.circular(16);
    }
  }

  Future<void> _deleteFile(String filePath) async {
    final trashManager = TrashManager();
    final settings =
        Provider.of<SettingsProvider>(context, listen: false).settings;
    final bool toTrash = settings.trashEnabled;
    final bool needsConfirm = toTrash
        ? settings.alwaysAskBeforeDelete
        : !settings.dontShowDeleteWarning;

    if (needsConfirm) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirmar'),
          content: Text(toTrash
              ? '¿Mover este archivo a la papelera?'
              : '¿Borrar este archivo permanentemente?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirmar')),
          ],
        ),
      );
      if (ok != true) return;
    }

    await _videoController?.pause();
    if (toTrash) {
      await trashManager.moveToTrash(filePath);
    } else {
      try { File(filePath).delete(); } catch (_) {}
    }
    await _videoController?.dispose();
    _videoController = null;
    if (mounted) {
      setState(() {
        _selectedVideoPath = null;
        _selectedVideoName = 'Ninguno';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(toTrash
            ? 'Archivo movido a la papelera'
            : 'Archivo eliminado permanentemente'),
        backgroundColor: toTrash ? Colors.orange : Colors.red,
      ));
    }
  }

  void applyPreset(VideoSettings preset) {
    setState(() {
      _settings = VideoSettings(
        videoCodec: preset.videoCodec,
        videoBitrate: preset.videoBitrate,
        crf: preset.crf,
        preset: preset.preset,
        hardwareAcceleration: preset.hardwareAcceleration,
        audioCodec: preset.audioCodec,
        audioBitrate: preset.audioBitrate,
        audioSampleRate: preset.audioSampleRate,
        audioChannels: preset.audioChannels,
        frameInterpolation: preset.frameInterpolation,
        targetFps: preset.targetFps,
        resolutionUpscale: preset.resolutionUpscale,
        targetWidth: preset.targetWidth,
        targetHeight: preset.targetHeight,
        maxScaleFactor: preset.maxScaleFactor,
        aiInterpolation: preset.aiInterpolation,
        aiTargetFps: preset.aiTargetFps,
        aiStabilization: preset.aiStabilization,
        preserveMetadata: preset.preserveMetadata,
        aiEnabled: preset.aiEnabled,
        saveAsDefault: preset.saveAsDefault,
        effect: preset.effect,
        stabilize: preset.stabilize,
        speedSegments: preset.speedSegments,
      );
      _textOverlayColor = _parseColorFromFFmpeg(_settings.textOverlayColor);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Preset aplicado a video'),
          backgroundColor: Colors.green),
    );
  }

  // ── Diálogo para editar un número ─────────────────────────────────────
  Future<void> _showNumberEditDialog({
    required String title,
    required String hint,
    required int current,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) async {
    final controller = TextEditingController(text: current.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: Colors.white, fontSize: 22),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            labelText: 'Rango: $min – $max',
            labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val >= min && val <= max) {
                Navigator.pop(ctx, val);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text('Valor fuera de rango ($min – $max)'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 2),
                ));
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('OK',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (result != null) onChanged(result);
  }

  /// Chip azul tappable que muestra el valor actual y permite editarlo.
  Widget _tappableValue({
    required String value,
    required VoidCallback onTap,
    bool disabled = false,
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: disabled
              ? Colors.grey.withOpacity(0.1)
              : Colors.blueAccent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: disabled
                ? Colors.grey.withOpacity(0.3)
                : Colors.blueAccent.withOpacity(0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style: TextStyle(
                  color: disabled ? Colors.grey : Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                )),
            const SizedBox(width: 4),
            Icon(Icons.edit,
                size: 12,
                color: disabled
                    ? Colors.grey
                    : Colors.blueAccent.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }

  // ── Color picker dialog ───────────────────────────────────────────────
  void _showColorPicker() {
    Color tempColor = _textOverlayColor;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title:
            const Text('Color del texto', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: tempColor,
            onColorChanged: (c) => tempColor = c,
            enableAlpha: false,
            pickerAreaHeightPercent: 0.7,
            labelTypes: const [ColorLabelType.hex, ColorLabelType.rgb],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _textOverlayColor = tempColor;
                _settings.textOverlayColor = _colorToFFmpeg(tempColor);
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent),
            child: const Text('Aplicar',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final processor = Provider.of<MediaProcessor>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final globalSettings = settingsProvider.settings;
    final paddingValue = _getPadding(globalSettings.density);
    // ignore: unused_local_variable
    final borderRadius = _getBorderRadius(globalSettings.roundness);

    return Column(
      children: [
        // ── Reproductor (altura fija 240px — evita bug de pantalla negra con teclado)
        SizedBox(
          height: 240,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                color: const Color(0xFF111111),
                child: Center(
                  child: processor.isProcessing
                      ? _buildProcessingView(processor)
                      : _buildVideoPlayer(),
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

        // ── CARGAR + EXPORTAR fijos arriba del scroll ─────────────────
        Container(
          color: const Color(0xFF050505),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      processor.isProcessing ? null : _selectVideo,
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: const Text('CARGAR',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: processor.isProcessing ||
                          _selectedVideoPath == null
                      ? null
                      : () => _exportVideo(processor),
                  icon: const Icon(Icons.upload_rounded, size: 18),
                  label: const Text('EXPORTAR',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    disabledBackgroundColor:
                        Colors.blueAccent.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Panel de configuración (scrollable) ──────────────────────
        Expanded(
          child: Container(
            color: const Color(0xFF000000),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(paddingValue * 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CONFIGURACIÓN DE EXPORTACIÓN',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                        fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  _buildCodecDropdown(processor),
                  const SizedBox(height: 10),
                  _buildBitrateModeSelector(processor),
                  const SizedBox(height: 5),
                  if (_settings.bitrateMode == BitrateMode.cbr) ...[
                    _buildBitrateSlider(processor),
                    const Padding(
                      padding: EdgeInsets.only(left: 8, top: 4),
                      child: Text(
                        'CBR mantiene bitrate constante. Ideal para streaming.',
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

                  // ── Resolución ───────────────────────────────────────
                  TooltipWithPreview(
                    title: 'Resolución de salida',
                    description:
                        'Selecciona una resolución predefinida o escribe manualmente '
                        'el ancho y alto en píxeles. Activa "Escalar resolución" para que se aplique.',
                    child: const Text('Resolución de salida',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _presetResolutions.firstWhere(
                      (r) =>
                          r['width'] == _settings.targetWidth &&
                          r['height'] == _settings.targetHeight,
                      orElse: () => {
                        'name': 'Personalizada',
                        'width': _settings.targetWidth,
                        'height': _settings.targetHeight,
                      },
                    ),
                    items: _presetResolutions.map((res) {
                      return DropdownMenuItem(
                        value: res,
                        child: Text(res['name']!,
                            style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _settings.targetWidth = val['width']!;
                          _settings.targetHeight = val['height']!;
                        });
                      }
                    },
                    decoration: const InputDecoration(
                        labelText: 'Preset de resolución'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration:
                              const InputDecoration(labelText: 'Ancho (px)'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          controller: TextEditingController(
                              text: _settings.targetWidth.toString()),
                          style: const TextStyle(color: Colors.white),
                          onChanged: (val) => setState(() =>
                              _settings.targetWidth =
                                  int.tryParse(val) ?? 1920),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          decoration:
                              const InputDecoration(labelText: 'Alto (px)'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          controller: TextEditingController(
                              text: _settings.targetHeight.toString()),
                          style: const TextStyle(color: Colors.white),
                          onChanged: (val) => setState(() =>
                              _settings.targetHeight =
                                  int.tryParse(val) ?? 1080),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── Speed ramp ───────────────────────────────────────
                  ElevatedButton.icon(
                    onPressed: _selectedVideoPath == null ||
                            processor.isProcessing
                        ? null
                        : () async {
                            final durationMicros = await processor
                                .getVideoDuration(_selectedVideoPath!);
                            if (durationMicros == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('No se pudo obtener la duración'),
                                    backgroundColor: Colors.red),
                              );
                              return;
                            }
                            final duration =
                                Duration(microseconds: durationMicros);
                            await showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: const Color(0xFF111111),
                                title: const Text('Speed Ramp',
                                    style: TextStyle(color: Colors.white)),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  child: SpeedRampEditor(
                                    totalDuration: duration,
                                    initialSegments:
                                        _settings.speedSegments ?? [],
                                    onChanged: (segs) => setState(
                                        () => _settings.speedSegments = segs),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cerrar',
                                        style: TextStyle(
                                            color: Colors.blueAccent)),
                                  ),
                                ],
                              ),
                            );
                          },
                    icon: const Icon(Icons.speed),
                    label: const Text('Configurar Speed Ramp'),
                  ),
                  if (_settings.speedSegments != null &&
                      _settings.speedSegments!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: Text(
                        '${_settings.speedSegments!.length} segmento(s) configurado(s)',
                        style:
                            const TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 10),

                  // ── Opciones generales ───────────────────────────────
                  CheckboxListTile(
                    title: const Text('Mantener nombre original',
                        style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Sin timestamp en el nombre del archivo',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    value: _keepOriginalName,
                    onChanged: processor.isProcessing
                        ? null
                        : (val) {
                            setState(() => _keepOriginalName = val!);
                            if (globalSettings.keepOriginalName != val) {
                              settingsProvider.setKeepOriginalName(val!);
                            }
                          },
                    secondary:
                        Icon(Icons.label, color: globalSettings.accentColor),
                    activeColor: globalSettings.accentColor,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: const Text('Guardar como predeterminado',
                        style: TextStyle(color: Colors.white)),
                    subtitle: const Text(
                        'Configuración por defecto en futuras exportaciones',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    value: _settings.saveAsDefault,
                    onChanged: processor.isProcessing
                        ? null
                        : (val) {
                            setState(() => _settings.saveAsDefault = val!);
                            if (val == true) {
                              settingsProvider
                                  .setVideoDefaults(_settings.toJson());
                            }
                          },
                    secondary:
                        Icon(Icons.save, color: globalSettings.accentColor),
                    activeColor: globalSettings.accentColor,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 10),

                  // ── Mejoras de calidad ───────────────────────────────
                  const Text('MEJORAS DE CALIDAD',
                      style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                  const SizedBox(height: 5),

                  TooltipWithPreview(
                    title: 'Escalar resolución',
                    description:
                        'Aumenta la resolución usando el algoritmo Lanczos (alta calidad). '
                        'Escala hasta 4x el tamaño original: 1080p → 4K, 2K → 8K. '
                        'Si el modelo IA no está disponible, se usa Lanczos como fallback.',
                    child: CheckboxListTile(
                      title: const Text('Escalar resolución',
                          style: TextStyle(color: Colors.white)),
                      subtitle: const Text('Hasta 4x (1080p→4K, 2K→8K)',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      value: _settings.resolutionUpscale,
                      onChanged: processor.isProcessing
                          ? null
                          : (val) => setState(
                              () => _settings.resolutionUpscale = val!),
                      secondary: Icon(Icons.zoom_out_map,
                          color: globalSettings.accentColor),
                      activeColor: globalSettings.accentColor,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                  const SizedBox(height: 5),

                  TooltipWithPreview(
                    title: 'Interpolación de frames',
                    description:
                        'Aumenta el FPS usando minterpolate de FFmpeg en modo MCI '
                        '(Motion Compensated Interpolation). Puede multiplicar hasta '
                        '4x el FPS original. Valores comunes: 60, 90, 120, 240, 480 fps. '
                        'Toca el valor de FPS para escribir un número exacto.',
                    child: CheckboxListTile(
                      title: const Text('Interpolar frames',
                          style: TextStyle(color: Colors.white)),
                      subtitle: const Text('Aumenta FPS hasta 4x',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      value: _settings.frameInterpolation,
                      onChanged: processor.isProcessing
                          ? null
                          : (val) => setState(
                              () => _settings.frameInterpolation = val!),
                      secondary:
                          Icon(Icons.speed, color: globalSettings.accentColor),
                      activeColor: globalSettings.accentColor,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                  if (_settings.frameInterpolation)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('FPS objetivo:',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                              const SizedBox(width: 8),
                              _tappableValue(
                                value: '${_settings.targetFps} fps',
                                disabled: processor.isProcessing,
                                onTap: () => _showNumberEditDialog(
                                  title: 'FPS objetivo',
                                  hint: 'Ej: 120',
                                  current: _settings.targetFps,
                                  min: 24,
                                  max: 960,
                                  onChanged: (v) =>
                                      setState(() => _settings.targetFps = v),
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _settings.targetFps
                                .toDouble()
                                .clamp(24.0, 480.0),
                            min: 24,
                            max: 480,
                            divisions: 19,
                            activeColor: globalSettings.accentColor,
                            onChanged: processor.isProcessing
                                ? null
                                : (val) => setState(
                                    () => _settings.targetFps = val.round()),
                          ),
                          const Text(
                              'Comunes: 60 · 90 · 120 · 240 · 480',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),

                  // ── Efectos de video ─────────────────────────────────
                  const Text('EFECTOS DE VIDEO',
                      style: TextStyle(
                          color: Colors.purpleAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                  VideoEffectSelector(
                    currentFilter:
                        _settings.effect?.type ?? VideoEffectType.none,
                    intensity: _settings.effect?.intensity ?? 0.5,
                    onChanged: (type, intensity) {
                      setState(() {
                        _settings.effect =
                            VideoEffect(type: type, intensity: intensity);
                      });
                    },
                  ),
                  const SizedBox(height: 5),
                  TooltipWithPreview(
                    title: 'Estabilización vidstab',
                    description:
                        'Usa el filtro vidstab de FFmpeg en dos pasos: '
                        '1) analiza el movimiento de cámara (vidstabdetect), '
                        '2) aplica compensación suave (vidstabtransform). '
                        'Útil para videos con temblor de mano.',
                    child: CheckboxListTile(
                      title: const Text('Estabilizar video',
                          style: TextStyle(color: Colors.white)),
                      value: _settings.stabilize ?? false,
                      onChanged: (val) =>
                          setState(() => _settings.stabilize = val ?? false),
                      secondary: Icon(Icons.video_stable,
                          color: globalSettings.accentColor),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Transición entre clips ────────────────────────────
                  const Text('TRANSICIÓN ENTRE CLIPS',
                      style: TextStyle(
                          color: Colors.tealAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                  const SizedBox(height: 4),
                  TooltipWithPreview(
                    title: 'Transición entre clips',
                    description:
                        'Aplica una transición visual entre dos clips usando xfade de FFmpeg. '
                        'Selecciona el tipo y la duración. Se aplica al exportar '
                        'desde la pantalla Línea de tiempo multicapa.',
                    child: DropdownButtonFormField<TransitionType>(
                      value: _settings.transitionType,
                      dropdownColor: const Color(0xFF111111),
                      items: const [
                        DropdownMenuItem(
                            value: TransitionType.none,
                            child: Text('Sin transición',
                                style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(
                            value: TransitionType.fade,
                            child: Text('Fade (fundido)',
                                style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(
                            value: TransitionType.dissolve,
                            child: Text('Dissolve',
                                style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(
                            value: TransitionType.wipeLeft,
                            child: Text('Wipe izquierda',
                                style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(
                            value: TransitionType.wipeRight,
                            child: Text('Wipe derecha',
                                style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(
                            value: TransitionType.slideLeft,
                            child: Text('Slide izquierda',
                                style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(
                            value: TransitionType.slideRight,
                            child: Text('Slide derecha',
                                style: TextStyle(color: Colors.white))),
                      ],
                      onChanged: processor.isProcessing
                          ? null
                          : (val) => setState(() =>
                              _settings.transitionType =
                                  val ?? TransitionType.none),
                      decoration: const InputDecoration(
                          labelText: 'Tipo de transición'),
                    ),
                  ),
                  if (_settings.transitionType != TransitionType.none)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Text('Duración:',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            const SizedBox(width: 8),
                            _tappableValue(
                              value:
                                  '${_settings.transitionDurationSeconds.toStringAsFixed(1)} s',
                              disabled: processor.isProcessing,
                              onTap: () async {
                                final ctrl = TextEditingController(
                                    text: _settings
                                        .transitionDurationSeconds
                                        .toStringAsFixed(1));
                                final val = await showDialog<double>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: const Color(0xFF111111),
                                    title: const Text(
                                        'Duración de transición',
                                        style:
                                            TextStyle(color: Colors.white)),
                                    content: TextField(
                                      controller: ctrl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      style: const TextStyle(
                                          color: Colors.white),
                                      decoration: const InputDecoration(
                                        labelText: 'Segundos (0.1 – 3.0)',
                                        labelStyle:
                                            TextStyle(color: Colors.grey),
                                        suffixText: 's',
                                      ),
                                      autofocus: true,
                                    ),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx),
                                          child:
                                              const Text('Cancelar')),
                                      ElevatedButton(
                                          onPressed: () {
                                            final d = double.tryParse(
                                                ctrl.text);
                                            if (d != null &&
                                                d >= 0.1 &&
                                                d <= 3.0) {
                                              Navigator.pop(ctx, d);
                                            }
                                          },
                                          child: const Text('OK')),
                                    ],
                                  ),
                                );
                                if (val != null) {
                                  setState(() => _settings
                                      .transitionDurationSeconds = val);
                                }
                              },
                            ),
                          ],
                        ),
                        Slider(
                          value: _settings.transitionDurationSeconds,
                          min: 0.1,
                          max: 3.0,
                          divisions: 29,
                          onChanged: processor.isProcessing
                              ? null
                              : (val) => setState(() =>
                                  _settings.transitionDurationSeconds =
                                      val),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),

                  // ── Color grading ────────────────────────────────────
                  const Text('COLOR GRADING',
                      style: TextStyle(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                  const SizedBox(height: 4),
                  TooltipWithPreview(
                    title: 'Color Grading',
                    description:
                        'Aplica corrección de color usando el filtro curves de FFmpeg. '
                        'No requiere archivos LUT externos. '
                        'Warm=rojos, Cold=azules, Vintage=aspecto envejecido, '
                        'Teal & Orange=look cinematográfico, Vivid=saturación+contraste.',
                    child: DropdownButtonFormField<ColorGradingPreset>(
                      value: _settings.colorGrading,
                      dropdownColor: const Color(0xFF111111),
                      items: const [
                        DropdownMenuItem(
                            value: ColorGradingPreset.none,
                            child: Text('Sin corrección',
                                style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(
                            value: ColorGradingPreset.warm,
                            child: Text('Cálido (Warm)',
                                style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(
                            value: ColorGradingPreset.cold,
                            child: Text('Frío (Cold)',
                                style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(
                            value: ColorGradingPreset.vintage,
                            child: Text('Vintage',
                                style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(
                            value: ColorGradingPreset.highContrast,
                            child: Text('Alto contraste',
                                style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(
                            value: ColorGradingPreset.fadedFilm,
                            child: Text('Faded Film',
                                style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(
                            value: ColorGradingPreset.teal,
                            child: Text('Teal & Orange',
                                style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(
                            value: ColorGradingPreset.vivid,
                            child: Text('Vivid',
                                style: TextStyle(color: Colors.white))),
                      ],
                      onChanged: processor.isProcessing
                          ? null
                          : (val) => setState(() =>
                              _settings.colorGrading =
                                  val ?? ColorGradingPreset.none),
                      decoration: const InputDecoration(
                          labelText: 'Preset de color'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Texto animado sobre video ─────────────────────────
                  const Text('TEXTO ANIMADO',
                      style: TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                  const SizedBox(height: 4),
                  CheckboxListTile(
                    title: TooltipWithPreview(
                      title: 'Texto animado sobre video',
                      description:
                          'Superpone texto usando el filtro drawtext de FFmpeg. '
                          'Configura contenido, tamaño, color (picker libre), '
                          'posición X/Y y el intervalo de tiempo. '
                          'Fade in: el texto aparece gradualmente en 0.5 s.',
                      child: const Text('Activar texto sobre video',
                          style: TextStyle(color: Colors.white)),
                    ),
                    value: _settings.enableTextOverlay,
                    onChanged: processor.isProcessing
                        ? null
                        : (val) => setState(
                            () => _settings.enableTextOverlay = val ?? false),
                    activeColor: globalSettings.accentColor,
                    secondary: Icon(Icons.title,
                        color: globalSettings.accentColor),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                  if (_settings.enableTextOverlay) ...[
                    // Campo de texto
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Texto a mostrar',
                        labelStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(),
                        hintText: 'Ej: Mi video premium',
                        hintStyle: TextStyle(color: Colors.white24),
                      ),
                      style: const TextStyle(color: Colors.white),
                      controller: TextEditingController(
                          text: _settings.textOverlayContent)
                        ..selection = TextSelection.collapsed(
                            offset:
                                _settings.textOverlayContent.length),
                      onChanged: (val) => setState(
                          () => _settings.textOverlayContent = val),
                    ),
                    const SizedBox(height: 10),

                    // Tamaño de fuente + selector de color
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('Tamaño: ',
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12)),
                                  _tappableValue(
                                    value:
                                        '${_settings.textOverlayFontSize} px',
                                    disabled: processor.isProcessing,
                                    onTap: () => _showNumberEditDialog(
                                      title: 'Tamaño de fuente',
                                      hint: 'px',
                                      current:
                                          _settings.textOverlayFontSize,
                                      min: 12,
                                      max: 256,
                                      onChanged: (v) => setState(() =>
                                          _settings.textOverlayFontSize =
                                              v),
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: _settings.textOverlayFontSize
                                    .toDouble()
                                    .clamp(12.0, 256.0),
                                min: 12,
                                max: 256,
                                divisions: 30,
                                activeColor: globalSettings.accentColor,
                                onChanged: (val) => setState(() =>
                                    _settings.textOverlayFontSize =
                                        val.round()),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Picker de color
                        Column(
                          children: [
                            const Text('Color',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: _showColorPicker,
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _textOverlayColor,
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.white30, width: 2),
                                ),
                                child: const Icon(Icons.colorize,
                                    size: 22,
                                    color: Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Posición X / Y
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'X: ${(_settings.textOverlayX * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                              Slider(
                                value: _settings.textOverlayX,
                                min: 0,
                                max: 1,
                                divisions: 20,
                                onChanged: (val) => setState(
                                    () => _settings.textOverlayX = val),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Y: ${(_settings.textOverlayY * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                              Slider(
                                value: _settings.textOverlayY,
                                min: 0,
                                max: 1,
                                divisions: 20,
                                onChanged: (val) => setState(
                                    () => _settings.textOverlayY = val),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Inicio y fin
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                                labelText: 'Inicio (seg)'),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            style: const TextStyle(color: Colors.white),
                            controller: TextEditingController(
                                text: _settings.textOverlayStartSec
                                    .toStringAsFixed(1)),
                            onChanged: (val) => setState(() =>
                                _settings.textOverlayStartSec =
                                    double.tryParse(val) ?? 0.0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                                labelText: 'Fin (seg)'),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            style: const TextStyle(color: Colors.white),
                            controller: TextEditingController(
                                text: _settings.textOverlayEndSec
                                    .toStringAsFixed(1)),
                            onChanged: (val) => setState(() =>
                                _settings.textOverlayEndSec =
                                    double.tryParse(val) ?? 5.0),
                          ),
                        ),
                      ],
                    ),
                    CheckboxListTile(
                      title: const Text('Fade in del texto',
                          style: TextStyle(color: Colors.white)),
                      value: _settings.textOverlayFadeIn,
                      onChanged: (val) => setState(() =>
                          _settings.textOverlayFadeIn = val ?? false),
                      activeColor: globalSettings.accentColor,
                      secondary: const Icon(Icons.animation,
                          color: Colors.greenAccent),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],

                  const SizedBox(height: 24),
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
        Text(processor.statusMessage,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          '${(processor.progress * 100).toStringAsFixed(1)}%',
          style: const TextStyle(
              color: Colors.grey,
              fontSize: 24,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => processor.cancelProcessing(),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 12)),
          child: const Text('CANCELAR',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // ── Reproductor de video interno ──────────────────────────────────────
  Widget _buildVideoPlayer() {
    if (_selectedVideoPath == null) {
      return GestureDetector(
        onTap: _selectVideo,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 72, color: Colors.grey[700]),
            const SizedBox(height: 16),
            const Text('Toca para seleccionar un video',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 6),
            const Text('o usa el botón CARGAR',
                style: TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
      );
    }

    if (_videoInitializing ||
        _videoController == null ||
        !_videoController!.value.isInitialized) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.blueAccent),
          const SizedBox(height: 12),
          Text(_selectedVideoName,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 13),
              overflow: TextOverflow.ellipsis),
        ],
      );
    }

    final ctrl = _videoController!;
    final value = ctrl.value;
    final pos = value.position;
    final dur = value.duration;
    final maxMs =
        dur.inMilliseconds.toDouble().clamp(1, double.infinity);

    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio:
                  value.aspectRatio > 0 ? value.aspectRatio : 16 / 9,
              child: VideoPlayer(ctrl),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(_selectedVideoName,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 11),
              overflow: TextOverflow.ellipsis),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2.5,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: pos.inMilliseconds.toDouble().clamp(0.0, maxMs),
              min: 0,
              max: maxMs,
              activeColor: Colors.blueAccent,
              inactiveColor: Colors.blueGrey.withOpacity(0.4),
              onChanged: (ms) =>
                  ctrl.seekTo(Duration(milliseconds: ms.round())),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(pos),
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 11)),
              Text(_formatDuration(dur),
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.replay_5,
                  color: Colors.white70, size: 28),
              tooltip: 'Retroceder 5s',
              onPressed: () =>
                  ctrl.seekTo(pos - const Duration(seconds: 5)),
            ),
            IconButton(
              icon: Icon(
                value.isPlaying
                    ? Icons.pause_circle
                    : Icons.play_circle,
                color: Colors.blueAccent,
                size: 44,
              ),
              onPressed: () =>
                  value.isPlaying ? ctrl.pause() : ctrl.play(),
            ),
            IconButton(
              icon: const Icon(Icons.forward_5,
                  color: Colors.white70, size: 28),
              tooltip: 'Adelantar 5s',
              onPressed: () =>
                  ctrl.seekTo(pos + const Duration(seconds: 5)),
            ),
            IconButton(
              icon: Icon(
                value.volume > 0 ? Icons.volume_up : Icons.volume_off,
                color: Colors.white70,
                size: 24,
              ),
              tooltip: value.volume > 0 ? 'Silenciar' : 'Activar sonido',
              onPressed: () =>
                  ctrl.setVolume(value.volume > 0 ? 0.0 : 1.0),
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  // ── Widgets de configuración ──────────────────────────────────────────

  Widget _buildCodecDropdown(MediaProcessor processor) {
    return TooltipWithPreview(
      title: 'Códec de video',
      description:
          'H.264: máxima compatibilidad, rápido. '
          'H.265: 50% más eficiente que H.264, mismo nivel visual. '
          'VP9: para WebM/web, código abierto. '
          'AV1: el más eficiente disponible, codificación muy lenta '
          '(recomendado solo si tienes tiempo y potencia).',
      child: DropdownButtonFormField<String>(
        value: _settings.videoCodec,
        dropdownColor: const Color(0xFF111111),
        items: const [
          DropdownMenuItem(
              value: 'libx264',
              child: Text('H.264 (Compatible)',
                  style: TextStyle(color: Colors.white))),
          DropdownMenuItem(
              value: 'libx265',
              child: Text('H.265 (Eficiente)',
                  style: TextStyle(color: Colors.white))),
          DropdownMenuItem(
              value: 'libvpx-vp9',
              child: Text('VP9 (Web)',
                  style: TextStyle(color: Colors.white))),
          DropdownMenuItem(
              value: 'libaom-av1',
              child: Text('AV1 (Máx. eficiencia)',
                  style: TextStyle(color: Colors.white))),
        ],
        onChanged: processor.isProcessing
            ? null
            : (val) => setState(() => _settings.videoCodec = val!),
        decoration: const InputDecoration(
          labelText: 'Códec de Video',
          labelStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildBitrateModeSelector(MediaProcessor processor) {
    return TooltipWithPreview(
      title: 'Modo de bitrate',
      description:
          'CRF (Calidad constante): el codificador ajusta el bitrate para mantener '
          'la calidad definida. Recomendado para archivos locales. '
          'CBR (Bitrate constante): mantiene bitrate fijo. '
          'Útil para streaming donde se requiere tamaño predecible.',
      child: Row(
        children: [
          Expanded(
            child: ListTile(
              title: const Text('Modo de bitrate',
                  style: TextStyle(color: Colors.white)),
              subtitle: Text(
                _settings.bitrateMode == BitrateMode.crf
                    ? 'CRF (calidad constante)'
                    : 'CBR (bitrate constante)',
                style:
                    const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              trailing: DropdownButton<BitrateMode>(
                value: _settings.bitrateMode,
                dropdownColor: const Color(0xFF111111),
                items: const [
                  DropdownMenuItem(
                      value: BitrateMode.crf, child: Text('CRF')),
                  DropdownMenuItem(
                      value: BitrateMode.cbr, child: Text('CBR')),
                ],
                onChanged: processor.isProcessing
                    ? null
                    : (val) {
                        if (val != null) {
                          setState(() => _settings.bitrateMode = val);
                        }
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBitrateSlider(MediaProcessor processor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Bitrate video: ',
                style: TextStyle(color: Colors.white70)),
            _tappableValue(
              value: '${_settings.videoBitrate} kbps',
              disabled: processor.isProcessing,
              onTap: () => _showNumberEditDialog(
                title: 'Bitrate de video',
                hint: 'Ej: 5383',
                current: _settings.videoBitrate,
                min: 50,
                max: 80000,
                onChanged: (v) =>
                    setState(() => _settings.videoBitrate = v),
              ),
            ),
          ],
        ),
        Slider(
          value: _settings.videoBitrate.toDouble().clamp(50.0, 15000.0),
          min: 50,
          max: 15000,
          divisions: 149,
          activeColor: Colors.blueAccent,
          onChanged: processor.isProcessing
              ? null
              : (val) =>
                  setState(() => _settings.videoBitrate = val.round()),
        ),
        const Text(
          '50–500 kbps=Baja · 1000–2500=Media · 5000+=Alta',
          style: TextStyle(color: Colors.grey, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildCRFSlider(MediaProcessor processor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TooltipWithPreview(
              title: 'CRF (Calidad constante)',
              description:
                  'Constant Rate Factor. Valores más bajos = mayor calidad y mayor tamaño. '
                  '0 = sin pérdida. 18–23 = calidad alta (recomendado). '
                  '24–28 = calidad media. 29–51 = baja calidad.',
              child: const Text('CRF: ',
                  style: TextStyle(color: Colors.white70)),
            ),
            _tappableValue(
              value: '${_settings.crf}',
              disabled: processor.isProcessing,
              onTap: () => _showNumberEditDialog(
                title: 'Valor CRF',
                hint: 'Ej: 18',
                current: _settings.crf,
                min: 0,
                max: 51,
                onChanged: (v) => setState(() => _settings.crf = v),
              ),
            ),
          ],
        ),
        Slider(
          value: _settings.crf.toDouble(),
          min: 0,
          max: 51,
          divisions: 51,
          activeColor: Colors.blueAccent,
          onChanged: processor.isProcessing
              ? null
              : (val) => setState(() => _settings.crf = val.round()),
        ),
        const Text(
            '0=sin pérdida · 18–23=alta · 24–28=media · 29+=baja',
            style: TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _buildPresetDropdown(MediaProcessor processor) {
    return TooltipWithPreview(
      title: 'Velocidad de codificación',
      description:
          'Controla la velocidad vs calidad de compresión. '
          'Preset más lento = mejor compresión (mismo CRF, archivo más pequeño). '
          'Ultra Rápido es útil para pruebas. Medio es el balance recomendado.',
      child: DropdownButtonFormField<String>(
        value: _settings.preset,
        dropdownColor: const Color(0xFF111111),
        items: const [
          DropdownMenuItem(
              value: 'ultrafast',
              child: Text('Ultra Rápido',
                  style: TextStyle(color: Colors.white))),
          DropdownMenuItem(
              value: 'fast',
              child:
                  Text('Rápido', style: TextStyle(color: Colors.white))),
          DropdownMenuItem(
              value: 'medium',
              child: Text('Medio (Recomendado)',
                  style: TextStyle(color: Colors.white))),
          DropdownMenuItem(
              value: 'slow',
              child: Text('Lento',
                  style: TextStyle(color: Colors.white))),
          DropdownMenuItem(
              value: 'veryslow',
              child: Text('Muy Lento',
                  style: TextStyle(color: Colors.white))),
        ],
        onChanged: processor.isProcessing
            ? null
            : (val) => setState(() => _settings.preset = val!),
        decoration: const InputDecoration(
          labelText: 'Velocidad de Codificación',
          labelStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildHardwareAccelerationSwitch(MediaProcessor processor) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    return TooltipWithPreview(
      title: 'Aceleración hardware',
      description:
          'Usa el chip MediaCodec del dispositivo (GPU/DSP) para codificar H.264 '
          'o H.265 más rápido. Si no está disponible en el dispositivo, cae back '
          'a software automáticamente. No disponible para VP9 ni AV1.',
      child: Row(
        children: [
          Switch(
            value: _settings.hardwareAcceleration,
            onChanged: processor.isProcessing
                ? null
                : (val) =>
                    setState(() => _settings.hardwareAcceleration = val),
            activeColor: settingsProvider.settings.accentColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Aceleración hardware',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                Text('GPU/MediaCodec — H.264 y H.265',
                    style: TextStyle(
                        color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getExtensionForCodec(String codec) {
    switch (codec) {
      case 'libvpx-vp9': return 'webm';
      case 'libaom-av1': return 'mkv';
      default:           return 'mp4';
    }
  }

  Future<void> _selectVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
        withData: false,
      );
      if (result != null &&
          result.files.isNotEmpty &&
          result.files.single.path != null) {
        await loadFile(result.files.single.path!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('✅ Video cargado: $_selectedVideoName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No se seleccionó ningún video'),
            backgroundColor: Colors.orange,
          ));
        }
      }
    } catch (e) {
      debugPrint('❌ Error al seleccionar video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _exportVideo(MediaProcessor processor) async {
    if (_selectedVideoPath == null) return;
    await _videoController?.pause();

    try {
      final durationMicros =
          await processor.getVideoDuration(_selectedVideoPath!);
      final originalFps =
          await processor.getVideoFps(_selectedVideoPath!);

      const int originalWidth = 1920;
      const int originalHeight = 1080;

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

      final bool success;
      if (_settings.speedSegments != null &&
          _settings.speedSegments!.isNotEmpty) {
        success = await processor.processVideoWithSpeedRamp(
          inputPath: _selectedVideoPath!,
          outputPath: outputPath,
          segments: _settings.speedSegments!,
          totalDurationMicros: durationMicros,
        );
      } else {
        success = await processor.processVideo(
          inputPath: _selectedVideoPath!,
          outputPath: outputPath,
          settings: _settings,
          totalDurationMicros: durationMicros,
          originalFps: originalFps,
          originalWidth: originalWidth,
          originalHeight: originalHeight,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? '✅ Exportación completada'
              : '❌ Error en exportación'),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ));
      }

      if (success) {
        setState(() {
          _selectedVideoPath = null;
          _selectedVideoName = 'Ninguno';
        });
        await _videoController?.dispose();
        _videoController = null;
      }
    } catch (e) {
      debugPrint('❌ Error en exportación: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Error crítico: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ));
      }
    }
  }
}