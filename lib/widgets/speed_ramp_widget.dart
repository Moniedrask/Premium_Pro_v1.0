import 'package:flutter/material.dart';
import 'dart:ui';

/// Representa un segmento de velocidad en la línea de tiempo
class SpeedSegment {
  Duration start;
  Duration end;
  double speed; // 0.1 a 16.0
  Color color;

  SpeedSegment({
    required this.start,
    required this.end,
    this.speed = 1.0,
    this.color = Colors.blueAccent,
  });
}

class SpeedRampWidget extends StatefulWidget {
  final Duration totalDuration;
  final List<SpeedSegment> initialSegments;
  final Function(List<SpeedSegment>) onChanged;

  const SpeedRampWidget({
    super.key,
    required this.totalDuration,
    required this.initialSegments,
    required this.onChanged,
  });

  @override
  State<SpeedRampWidget> createState() => _SpeedRampWidgetState();
}

class _SpeedRampWidgetState extends State<SpeedRampWidget> {
  late List<SpeedSegment> _segments;
  final ScrollController _scrollController = ScrollController();
  double _zoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    _segments = List.from(widget.initialSegments);
    if (_segments.isEmpty) {
      _segments.add(SpeedSegment(
        start: Duration.zero,
        end: widget.totalDuration,
        speed: 1.0,
      ));
    }
  }

  void _addSegment() {
    // Añadir un segmento al final
    final last = _segments.last;
    final newStart = last.end;
    final newEnd = widget.totalDuration;
    if (newStart < newEnd) {
      setState(() {
        _segments.add(SpeedSegment(
          start: newStart,
          end: newEnd,
          speed: 1.0,
        ));
      });
      widget.onChanged(_segments);
    }
  }

  void _removeSegment(int index) {
    if (_segments.length > 1) {
      setState(() {
        _segments.removeAt(index);
      });
      widget.onChanged(_segments);
    }
  }

  void _updateSegment(int index, SpeedSegment updated) {
    setState(() {
      _segments[index] = updated;
    });
    widget.onChanged(_segments);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Controles de zoom y añadir
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.zoom_in),
              onPressed: () {
                setState(() {
                  _zoomLevel = (_zoomLevel * 1.2).clamp(1.0, 10.0);
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              onPressed: () {
                setState(() {
                  _zoomLevel = (_zoomLevel / 1.2).clamp(1.0, 10.0);
                });
              },
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _addSegment,
              icon: const Icon(Icons.add),
              label: const Text('Añadir segmento'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Línea de tiempo con zoom
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CustomPaint(
              painter: _SpeedRampPainter(
                segments: _segments,
                totalDuration: widget.totalDuration,
                zoomLevel: _zoomLevel,
                scrollOffset: _scrollController.hasClients ? _scrollController.offset : 0,
              ),
              size: Size(widget.totalDuration.inMilliseconds * _zoomLevel, 80),
            ),
          ),
        ),
        // Scrollbar
        Container(
          height: 20,
          child: Scrollbar(
            controller: _scrollController,
            child: ListView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              children: [
                Container(
                  width: widget.totalDuration.inMilliseconds * _zoomLevel,
                  height: 20,
                  color: Colors.transparent,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Lista de segmentos con controles
        ..._segments.asMap().entries.map((entry) {
          int idx = entry.key;
          SpeedSegment seg = entry.value;
          return Card(
            color: Colors.grey[850],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Segmento ${idx + 1}'),
                      ),
                      if (_segments.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeSegment(idx),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Inicio (ms)'),
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(
                              text: seg.start.inMilliseconds.toString()),
                          onChanged: (val) {
                            final ms = int.tryParse(val) ?? 0;
                            _updateSegment(idx, SpeedSegment(
                              start: Duration(milliseconds: ms),
                              end: seg.end,
                              speed: seg.speed,
                            ));
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Fin (ms)'),
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(
                              text: seg.end.inMilliseconds.toString()),
                          onChanged: (val) {
                            final ms = int.tryParse(val) ?? 0;
                            _updateSegment(idx, SpeedSegment(
                              start: seg.start,
                              end: Duration(milliseconds: ms),
                              speed: seg.speed,
                            ));
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Velocidad: ${seg.speed.toStringAsFixed(2)}x'),
                      ),
                      Expanded(
                        child: Slider(
                          value: seg.speed,
                          min: 0.1,
                          max: 16.0,
                          divisions: 159,
                          onChanged: (val) {
                            _updateSegment(idx, SpeedSegment(
                              start: seg.start,
                              end: seg.end,
                              speed: val,
                            ));
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

class _SpeedRampPainter extends CustomPainter {
  final List<SpeedSegment> segments;
  final Duration totalDuration;
  final double zoomLevel;
  final double scrollOffset;

  _SpeedRampPainter({
    required this.segments,
    required this.totalDuration,
    required this.zoomLevel,
    required this.scrollOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var seg in segments) {
      final startX = seg.start.inMilliseconds * zoomLevel - scrollOffset;
      final endX = seg.end.inMilliseconds * zoomLevel - scrollOffset;
      final width = endX - startX;

      paint.color = seg.color.withOpacity(0.3);
      canvas.drawRect(Rect.fromLTWH(startX, 0, width, size.height), paint);

      // Dibujar texto de velocidad
      final textSpan = TextSpan(
        text: '${seg.speed.toStringAsFixed(1)}x',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(startX + 4, 4));
    }

    // Dibujar línea de tiempo base
    paint.color = Colors.grey;
    paint.style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height - 1), Offset(size.width, size.height - 1), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}