import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart'; // ← IMPORTANTE
import '../models/timeline_project.dart';
import '../models/timeline_layer.dart';
import '../services/timeline_exporter.dart';
import '../services/ffmpeg_wrapper.dart';
import '../providers/settings_provider.dart';
import 'layer_editor_dialog.dart';

class MultiLayerTimeline extends StatefulWidget {
  const MultiLayerTimeline({super.key});

  @override
  State<MultiLayerTimeline> createState() => _MultiLayerTimelineState();
}

class _MultiLayerTimelineState extends State<MultiLayerTimeline> {
  late TimelineProject _project;
  double _zoom = 1.0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _project = TimelineProject(
      name: 'Nuevo proyecto',
      duration: const Duration(seconds: 60),
    );
  }

  void _addLayer(LayerType type) async {
    FilePickerResult? result;
    if (type == LayerType.video) {
      result = await FilePicker.platform.pickFiles(type: FileType.video);
    } else if (type == LayerType.audio) {
      result = await FilePicker.platform.pickFiles(type: FileType.audio);
    } else if (type == LayerType.image) {
      result = await FilePicker.platform.pickFiles(type: FileType.image);
    } else if (type == LayerType.text) {
      _showTextDialog();
      return;
    }

    if (result != null && result.files.isNotEmpty) {
      final path = result.files.single.path!;
      final name = result.files.single.name;
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      TimelineLayer layer;
      switch (type) {
        case LayerType.video:
          layer = VideoLayer(
            id: id,
            name: name,
            start: Duration.zero,
            duration: const Duration(seconds: 10),
            filePath: path,
          );
          break;
        case LayerType.audio:
          layer = AudioLayer(
            id: id,
            name: name,
            start: Duration.zero,
            duration: const Duration(seconds: 10),
            filePath: path,
          );
          break;
        case LayerType.image:
          layer = ImageLayer(
            id: id,
            name: name,
            start: Duration.zero,
            duration: const Duration(seconds: 5),
            filePath: path,
          );
          break;
        default:
          return;
      }

      setState(() {
        _project.layers = List.from(_project.layers)..add(layer);
      });
    }
  }

  void _showTextDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Añadir texto'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Texto'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final id = DateTime.now().millisecondsSinceEpoch.toString();
              setState(() {
                _project.layers.add(TextLayer(
                  id: id,
                  name: 'Texto',
                  start: Duration.zero,
                  duration: const Duration(seconds: 5),
                  text: controller.text,
                ));
              });
              Navigator.pop(ctx);
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }

  Future<void> _editLayer(TimelineLayer layer) async {
    await showDialog(
      context: context,
      builder: (_) => LayerEditorDialog(
        layer: layer,
        onSave: (updated) {
          setState(() {
            final index = _project.layers.indexWhere((l) => l.id == updated.id);
            if (index != -1) {
              _project.layers[index] = updated;
            }
          });
        },
      ),
    );
  }

  Future<void> _exportProject() async {
    final ffmpeg = FFmpegWrapper();
    final dir = await getExternalStorageDirectory();
    if (dir == null) return;
    final output = '${dir.path}/timeline_export.mp4';

    final success = await TimelineExporter.exportProject(
      _project,
      output,
      ffmpeg: ffmpeg,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Exportado correctamente' : 'Error en exportación'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context).settings;
    final totalPixels = _project.duration.inMilliseconds * _zoom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Línea de tiempo multicapa'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () => setState(() => _zoom *= 1.2),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () => setState(() => _zoom /= 1.2),
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: _exportProject,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 60,
            color: Colors.grey[900],
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildAddButton('Video', Icons.video_library, LayerType.video),
                _buildAddButton('Audio', Icons.audiotrack, LayerType.audio),
                _buildAddButton('Texto', Icons.text_fields, LayerType.text),
                _buildAddButton('Imagen', Icons.image, LayerType.image),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.grey[850],
              child: ListView.builder(
                itemCount: _project.layers.length,
                itemBuilder: (ctx, index) {
                  final layer = _project.layers[index];
                  return GestureDetector(
                    onTap: () => _editLayer(layer),
                    child: _buildLayerRow(layer, index),
                  );
                },
              ),
            ),
          ),
          Container(
            height: 40,
            color: Colors.grey[900],
            child: ListView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              children: [
                SizedBox(
                  width: totalPixels,
                  child: CustomPaint(
                    painter: TimelineRulerPainter(
                      duration: _project.duration,
                      zoom: _zoom,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(String label, IconData icon, LayerType type) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton.icon(
        onPressed: () => _addLayer(type),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }

  Widget _buildLayerRow(TimelineLayer layer, int index) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Stack(
        children: [
          Positioned(
            left: layer.start.inMilliseconds * _zoom,
            width: layer.duration.inMilliseconds * _zoom,
            child: Container(
              color: _layerColor(layer.type).withOpacity(0.5),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(
                        layer.name,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (layer.fadeIn.inMilliseconds > 0)
                    const Icon(Icons.keyboard_arrow_right, size: 16, color: Colors.white70),
                  if (layer.fadeOut.inMilliseconds > 0)
                    const Icon(Icons.keyboard_arrow_left, size: 16, color: Colors.white70),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16, color: Colors.white70),
                    onPressed: () => _editLayer(layer),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _project.layers.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _layerColor(LayerType type) {
    switch (type) {
      case LayerType.video:
        return Colors.blue;
      case LayerType.audio:
        return Colors.green;
      case LayerType.text:
        return Colors.orange;
      case LayerType.image:
        return Colors.purple;
    }
  }
}

class TimelineRulerPainter extends CustomPainter {
  final Duration duration;
  final double zoom;

  TimelineRulerPainter({required this.duration, required this.zoom});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    for (int sec = 0; sec <= duration.inSeconds; sec++) {
      final x = sec * 1000 * zoom;
      if (x > size.width) break;

      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);

      final textSpan = TextSpan(
        text: '$sec s',
        style: const TextStyle(color: Colors.white, fontSize: 10),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x + 2, 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}