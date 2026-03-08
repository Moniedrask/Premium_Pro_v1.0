import 'package:flutter/material.dart';

class EqualizerWidget extends StatefulWidget {
  final List<double> gains; // 10 valores en dB, típicamente -12 a +12
  final Function(List<double>) onChanged;

  const EqualizerWidget({
    super.key,
    required this.gains,
    required this.onChanged,
  });

  @override
  State<EqualizerWidget> createState() => _EqualizerWidgetState();
}

class _EqualizerWidgetState extends State<EqualizerWidget> {
  late List<double> _gains;

  @override
  void initState() {
    super.initState();
    _gains = List.from(widget.gains);
    if (_gains.length != 10) {
      _gains = List.filled(10, 0.0);
    }
  }

  void _updateGain(int index, double value) {
    setState(() {
      _gains[index] = value;
    });
    widget.onChanged(_gains);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> freqLabels = ['32', '64', '125', '250', '500', '1k', '2k', '4k', '8k', '16k'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ecualizador de 10 bandas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(10, (index) {
              return Container(
                width: 60,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  children: [
                    RotatedBox(
                      quarterTurns: 3,
                      child: SizedBox(
                        height: 200,
                        child: Slider(
                          value: _gains[index],
                          min: -12,
                          max: 12,
                          divisions: 24,
                          onChanged: (val) => _updateGain(index, val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      freqLabels[index],
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                    Text(
                      '${_gains[index].toStringAsFixed(1)} dB',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}