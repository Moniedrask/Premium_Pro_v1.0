import 'package:flutter/material.dart';
import '../models/video_effect.dart'; // Reutilizar el mismo enum

class FilterSelector extends StatelessWidget {
  final VideoEffectType currentFilter;
  final double intensity;
  final Function(VideoEffectType, double) onChanged;

  const FilterSelector({
    super.key,
    required this.currentFilter,
    required this.intensity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<VideoEffectType>(
          value: currentFilter,
          items: const [
            DropdownMenuItem(value: VideoEffectType.none, child: Text('Sin filtro')),
            DropdownMenuItem(value: VideoEffectType.negative, child: Text('Negativo')),
            DropdownMenuItem(value: VideoEffectType.blackAndWhite, child: Text('Blanco y negro')),
            DropdownMenuItem(value: VideoEffectType.sepia, child: Text('Sepia')),
            DropdownMenuItem(value: VideoEffectType.blur, child: Text('Desenfoque')),
            DropdownMenuItem(value: VideoEffectType.bokeh, child: Text('Bokeh')),
          ],
          onChanged: (val) => onChanged(val!, intensity),
          decoration: const InputDecoration(labelText: 'Filtro'),
        ),
        if (currentFilter == VideoEffectType.blur || currentFilter == VideoEffectType.bokeh)
          Column(
            children: [
              Text('Intensidad: ${intensity.toStringAsFixed(1)}'),
              Slider(
                value: intensity,
                min: 0.0,
                max: 1.0,
                onChanged: (val) => onChanged(currentFilter, val),
              ),
            ],
          ),
      ],
    );
  }
}