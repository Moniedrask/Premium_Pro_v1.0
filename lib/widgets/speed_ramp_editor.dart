import 'package:flutter/material.dart';
import '../services/speed_ramp.dart';

class SpeedRampEditor extends StatefulWidget {
  final Duration totalDuration;
  final List<SpeedSegment> initialSegments;
  final Function(List<SpeedSegment>) onChanged;

  const SpeedRampEditor({
    super.key,
    required this.totalDuration,
    required this.initialSegments,
    required this.onChanged,
  });

  @override
  State<SpeedRampEditor> createState() => _SpeedRampEditorState();
}

class _SpeedRampEditorState extends State<SpeedRampEditor> {
  late List<SpeedSegment> _segments;

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
        Row(
          children: [
            const Text('Segmentos de velocidad', style: TextStyle(color: Colors.white)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.green),
              onPressed: _addSegment,
            ),
          ],
        ),
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
                        child: Text('Segmento ${idx + 1}', style: const TextStyle(color: Colors.white)),
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
                          controller: TextEditingController(text: seg.start.inMilliseconds.toString()),
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
                          controller: TextEditingController(text: seg.end.inMilliseconds.toString()),
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