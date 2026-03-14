import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/image_processor.dart';
import '../services/ai_manager.dart';
import '../services/trash_manager.dart';
import '../services/hdr_service.dart';
import '../models/image_settings.dart';
import '../providers/settings_provider.dart';
import '../models/app_settings.dart';
import '../models/filter_type.dart';
import '../widgets/filter_selector.dart';
import '../widgets/hdr_merger_widget.dart';

class ImageEditorWidget extends StatefulWidget {
  const ImageEditorWidget({super.key});

  @override
  State<ImageEditorWidget> createState() => ImageEditorWidgetState();
}

class ImageEditorWidgetState extends State<ImageEditorWidget> {
  String? _selectedImagePath;
  String _selectedImageName = 'Ninguno';
  late ImageSettings _settings;
  bool _keepOriginalName = false;
  List<String> _hdrImages = [];
  // Color del texto overlay (para el picker libre)
  Color _textOverlayColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final globalSettings = settingsProvider.settings;
    _settings = ImageSettings.fromJson(globalSettings.imageDefaults);
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

  /// Carga una imagen externamente (llamado desde ImageEditorScreen).
  void loadFile(String path) {
    setState(() {
      _selectedImagePath = path;
      _selectedImageName = path.split('/').last;
    });
  }

  void applyPreset(ImageSettings preset) {
    setState(() {
      _settings = ImageSettings(
        format: preset.format,
        quality: preset.quality,
        compressionLevel: preset.compressionLevel,
        preserveMetadata: preset.preserveMetadata,
        maxWidth: preset.maxWidth,
        maxHeight: preset.maxHeight,
        aiUpscale: preset.aiUpscale,
        aiScale: preset.aiScale,
        filter: preset.filter,
        aiEnabled: preset.aiEnabled,
        filterType: preset.filterType,
        filterIntensity: preset.filterIntensity,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preset aplicado a imagen'), backgroundColor: Colors.green),
    );
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
            _selectedImagePath = null;
            _selectedImageName = 'Ninguno';
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
          _selectedImagePath = null;
          _selectedImageName = 'Ninguno';
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
          _selectedImagePath = null;
          _selectedImageName = 'Ninguno';
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
            _selectedImagePath = null;
            _selectedImageName = 'Ninguno';
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

  Future<void> _mergeHDR() async {
    if (_hdrImages.length < 2 || _hdrImages.length > 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona entre 2 y 3 imágenes para HDR'), backgroundColor: Colors.orange),
      );
      return;
    }

    final dir = await getExternalStorageDirectory();
    if (dir == null) return;
    final outputPath = '${dir.path}/PremiumPro/Images/hdr_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await HdrService.mergeImages(_hdrImages, outputPath: outputPath);
    if (result != null && mounted) {
      setState(() {
        _selectedImagePath = result;
        _selectedImageName = result.split('/').last;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Imagen HDR fusionada'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Error al fusionar HDR'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final processor = Provider.of<ImageProcessor>(context);
    final aiManager = Provider.of<AIManager>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final globalSettings = settingsProvider.settings;

    final paddingValue = _getPadding(globalSettings.density);
    final borderRadius = _getBorderRadius(globalSettings.roundness);

    return Column(
      children: [
        // ── Vista de imagen (altura fija — evita bug de pantalla negra con teclado)
        SizedBox(
          height: 220,
          child: Stack(
            children: [
              Container(
                color: const Color(0xFF111111),
                child: Center(
                  child: processor.isProcessing
                      ? _buildProcessingView(processor)
                      : _buildImageView(),
                ),
              ),
              if (_selectedImagePath != null && !processor.isProcessing)
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(Icons.delete, color: globalSettings.accentColor),
                    onPressed: () => _deleteFile(_selectedImagePath!),
                    tooltip: 'Eliminar imagen',
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(paddingValue * 2),
            color: const Color(0xFF000000),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CONFIGURACIÓN DE IMAGEN',
                    style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: _settings.format,
                    items: const [
                      DropdownMenuItem(value: 'jpeg', child: Text('JPEG')),
                      DropdownMenuItem(value: 'png', child: Text('PNG')),
                      DropdownMenuItem(value: 'webp', child: Text('WebP')),
                      DropdownMenuItem(value: 'avif', child: Text('AVIF')),
                    ],
                    onChanged: processor.isProcessing ? null : (val) {
                      setState(() => _settings.format = val!);
                    },
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
                          onChanged: processor.isProcessing ? null : (val) {
                            setState(() => _settings.quality = val.round());
                          },
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
                          onChanged: processor.isProcessing ? null : (val) {
                            setState(() => _settings.compressionLevel = val.round());
                          },
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
                          onChanged: processor.isProcessing ? null : (val) {
                            setState(() => _settings.maxWidth = int.tryParse(val) ?? 0);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Alto máx. (px)'),
                          keyboardType: TextInputType.number,
                          onChanged: processor.isProcessing ? null : (val) {
                            setState(() => _settings.maxHeight = int.tryParse(val) ?? 0);
                          },
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
                    onChanged: processor.isProcessing ? null : (val) {
                      setState(() => _settings.filter = val!);
                    },
                    decoration: const InputDecoration(labelText: 'Algoritmo'),
                  ),

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: _settings.preserveMetadata,
                        onChanged: processor.isProcessing ? null : (val) {
                          setState(() => _settings.preserveMetadata = val!);
                        },
                      ),
                      const Text('Conservar metadatos EXIF', style: TextStyle(color: Colors.white)),
                    ],
                  ),

                  if (aiManager.isModelAvailable)
                    Row(
                      children: [
                        Checkbox(
                          value: _settings.aiUpscale,
                          onChanged: processor.isProcessing ? null : (val) {
                            setState(() => _settings.aiUpscale = val!);
                          },
                        ),
                        const Text('Upscale con IA', style: TextStyle(color: Colors.white)),
                      ],
                    ),

                  const SizedBox(height: 10),
                  const Text(
                    'EFECTOS DE IMAGEN',
                    style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  FilterSelector(
                    currentFilter: _settings.filterType ?? FilterType.none,
                    intensity: _settings.filterIntensity ?? 0.5,
                    onChanged: (type, intensity) {
                      setState(() {
                        _settings.filterType = type;
                        _settings.filterIntensity = intensity;
                      });
                    },
                  ),
                  // ── TEXTO SOBRE IMAGEN ────────────────────────────
                  const SizedBox(height: 10),
                  const Text(
                    'TEXTO SOBRE IMAGEN',
                    style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  CheckboxListTile(
                    title: const Text('Añadir texto a la imagen', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Superpone texto con FFmpeg drawtext',
                        style: TextStyle(color: Colors.grey, fontSize: 11)),
                    value: _settings.enableTextOverlay,
                    onChanged: processor.isProcessing ? null : (val) =>
                        setState(() => _settings.enableTextOverlay = val ?? false),
                    activeColor: globalSettings.accentColor,
                    secondary: const Icon(Icons.title, color: Colors.greenAccent),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  if (_settings.enableTextOverlay) ...[
                    // Campo de texto
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Texto a mostrar',
                        hintText: 'Ej: Mi foto premium',
                        hintStyle: TextStyle(color: Colors.white24),
                      ),
                      style: const TextStyle(color: Colors.white),
                      controller: TextEditingController(text: _settings.textOverlayContent)
                        ..selection = TextSelection.collapsed(offset: _settings.textOverlayContent.length),
                      onChanged: (val) => setState(() => _settings.textOverlayContent = val),
                    ),
                    const SizedBox(height: 8),
                    // Tamaño + Color
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Text('Tamaño: ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                GestureDetector(
                                  onTap: () async {
                                    final ctrl = TextEditingController(text: _settings.textOverlayFontSize.toString());
                                    final val = await showDialog<int>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: const Color(0xFF111111),
                                        title: const Text('Tamaño fuente (px)', style: TextStyle(color: Colors.white)),
                                        content: TextField(
                                          controller: ctrl,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          style: const TextStyle(color: Colors.white, fontSize: 20),
                                          autofocus: true,
                                          decoration: const InputDecoration(hintText: '12–256'),
                                        ),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                                          ElevatedButton(
                                            onPressed: () {
                                              final v = int.tryParse(ctrl.text);
                                              if (v != null && v >= 12 && v <= 256) Navigator.pop(ctx, v);
                                            },
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (val != null) setState(() => _settings.textOverlayFontSize = val);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                                    ),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      Text('${_settings.textOverlayFontSize} px',
                                          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(width: 3),
                                      const Icon(Icons.edit, size: 11, color: Colors.blueAccent),
                                    ]),
                                  ),
                                ),
                              ]),
                              Slider(
                                value: _settings.textOverlayFontSize.toDouble().clamp(12, 256),
                                min: 12,
                                max: 256,
                                divisions: 30,
                                activeColor: globalSettings.accentColor,
                                onChanged: (v) => setState(() => _settings.textOverlayFontSize = v.round()),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(children: [
                          const Text('Color', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => _showImageTextColorPicker(),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _textOverlayColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white30, width: 2),
                              ),
                              child: const Icon(Icons.colorize, size: 22, color: Colors.black54),
                            ),
                          ),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Posición X/Y
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('X: ${(_settings.textOverlayX * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        Slider(
                          value: _settings.textOverlayX, min: 0, max: 1, divisions: 20,
                          onChanged: (v) => setState(() => _settings.textOverlayX = v),
                        ),
                      ])),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Y: ${(_settings.textOverlayY * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        Slider(
                          value: _settings.textOverlayY, min: 0, max: 1, divisions: 20,
                          onChanged: (v) => setState(() => _settings.textOverlayY = v),
                        ),
                      ])),
                    ]),
                  ],
                  // ─────────────────────────────────────────────────────

                  const SizedBox(height: 10),
                  const Text(
                    'HDR POR CAPAS',
                    style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  HdrMergerWidget(
                    onImagesSelected: (paths) {
                      _hdrImages = paths;
                    },
                  ),
                  if (_hdrImages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ElevatedButton(
                        onPressed: _mergeHDR,
                        child: const Text('Fusionar HDR'),
                      ),
                    ),
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
                    value: _settings.aiEnabled,
                    onChanged: processor.isProcessing ? null : (val) {
                      setState(() => _settings.aiEnabled = val!);
                      if (val == true) {
                        settingsProvider.setImageDefaults(_settings.toJson());
                      }
                    },
                    secondary: Icon(Icons.save, color: globalSettings.accentColor),
                    activeColor: globalSettings.accentColor,
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
            ),
          ),
        ),
      ],
    );
  }

  void _showImageTextColorPicker() {
    Color tempColor = _textOverlayColor;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Color del texto', style: TextStyle(color: Colors.white)),
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
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _textOverlayColor = tempColor;
                _settings.textOverlayColorHex =
                    '#${tempColor.red.toRadixString(16).padLeft(2, '0')}'
                    '${tempColor.green.toRadixString(16).padLeft(2, '0')}'
                    '${tempColor.blue.toRadixString(16).padLeft(2, '0')}';
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
            child: const Text('Aplicar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingView(ImageProcessor processor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: Colors.blueAccent),
        const SizedBox(height: 10),
        Text(processor.statusMessage, style: const TextStyle(color: Colors.white)),
        Text('${(processor.progress * 100).toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.grey, fontSize: 20)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: processor.cancelProcessing,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('CANCELAR'),
        ),
      ],
    );
  }

  // Estado para dibujo libre
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _drawingMode = false;
  Color _brushColor = Colors.red;
  double _brushSize = 4.0;

  Widget _buildImageView() {
    if (_selectedImagePath == null) {
      return const Center(
        child: Text('Selecciona una imagen', style: TextStyle(color: Colors.grey)),
      );
    }
    return Stack(
      children: [
        // Imagen con zoom interactivo (pinch zoom + pan)
        InteractiveViewer(
          minScale: 0.5,
          maxScale: 8.0,
          child: Center(
            child: Image.file(
              File(_selectedImagePath!),
              fit: BoxFit.contain,
              errorBuilder: (ctx, error, stack) =>
                  const Text('Error al cargar imagen', style: TextStyle(color: Colors.red)),
            ),
          ),
        ),
        // Capa de dibujo libre encima de la imagen
        if (_drawingMode)
          Positioned.fill(
            child: GestureDetector(
              onPanStart: (details) {
                setState(() {
                  _currentStroke = [details.localPosition];
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _currentStroke = List.from(_currentStroke)
                    ..add(details.localPosition);
                });
              },
              onPanEnd: (_) {
                setState(() {
                  if (_currentStroke.length > 1) {
                    _strokes.add(List.from(_currentStroke));
                  }
                  _currentStroke = [];
                });
              },
              child: CustomPaint(
                painter: _DrawingPainter(
                  strokes: _strokes,
                  currentStroke: _currentStroke,
                  color: _brushColor,
                  strokeWidth: _brushSize,
                ),
              ),
            ),
          ),
        // Controles del pincel
        if (_drawingMode)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  const Text('Tamaño:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Expanded(
                    child: Slider(
                      value: _brushSize,
                      min: 1,
                      max: 20,
                      onChanged: (val) => setState(() => _brushSize = val),
                    ),
                  ),
                  ...([Colors.red, Colors.white, Colors.yellow, Colors.black]
                      .map((c) => GestureDetector(
                            onTap: () => setState(() => _brushColor = c),
                            child: Container(
                              width: 22,
                              height: 22,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _brushColor == c ? Colors.blueAccent : Colors.transparent,
                                    width: 2),
                              ),
                            ),
                          ))
                      .toList()),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.undo, color: Colors.white70, size: 18),
                    onPressed: () {
                      if (_strokes.isNotEmpty) setState(() => _strokes.removeLast());
                    },
                    tooltip: 'Deshacer trazo',
                  ),
                ],
              ),
            ),
          ),
        // Botón para activar/desactivar modo dibujo
        Positioned(
          top: 8,
          left: 8,
          child: FloatingActionButton.small(
            heroTag: 'draw_fab',
            backgroundColor: _drawingMode ? Colors.blueAccent : Colors.grey[800],
            onPressed: () => setState(() => _drawingMode = !_drawingMode),
            child: Icon(_drawingMode ? Icons.brush : Icons.brush_outlined,
                color: Colors.white),
            tooltip: _drawingMode ? 'Desactivar pincel' : 'Activar pincel',
          ),
        ),
      ],
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

      final int timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = _settings.format;

      String outputPath;
      if (_keepOriginalName) {
        final originalName = _selectedImageName.split('.').first;
        outputPath = '$outputDir/${originalName}_premium.$ext';
      } else {
        outputPath = '$outputDir/image_$timestamp.$ext';
      }

      final success = await processor.processImage(
        inputPath: _selectedImagePath!,
        outputPath: outputPath,
        settings: _settings,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Imagen exportada'), backgroundColor: Colors.green),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Error al exportar'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error exportando imagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

/// Pinta los trazos de pincel libre sobre la imagen.
class _DrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color color;
  final double strokeWidth;

  _DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, paint);
    }
    _drawStroke(canvas, currentStroke, paint);
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DrawingPainter old) =>
      old.strokes != strokes ||
      old.currentStroke != currentStroke ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}