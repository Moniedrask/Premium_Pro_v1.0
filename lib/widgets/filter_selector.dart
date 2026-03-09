import 'package:flutter/material.dart';

enum FilterType { none, negative, blackAndWhite, sepia, blur, bokeh }

class FilterSelector extends StatelessWidget {
  final FilterType currentFilter;
  final double intensity;
  final Function(FilterType, double) onChanged;

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
        DropdownButtonFormField<FilterType>(
          value: currentFilter,
          items: const [
            DropdownMenuItem(value: FilterType.none, child: Text('Sin filtro')),
            DropdownMenuItem(value: FilterType.negative, child: Text('Negativo')),
            DropdownMenuItem(value: FilterType.blackAndWhite, child: Text('Blanco y negro')),
            DropdownMenuItem(value: FilterType.sepia, child: Text('Sepia')),
            DropdownMenuItem(value: FilterType.blur, child: Text('Desenfoque')),
            DropdownMenuItem(value: FilterType.bokeh, child: Text('Bokeh')),
          ],
          onChanged: (val) => onChanged(val!, intensity),
          decoration: const InputDecoration(labelText: 'Filtro'),
        ),
        if (currentFilter == FilterType.blur || currentFilter == FilterType.bokeh)
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