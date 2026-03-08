// Selector de modo de bitrate (CRF vs CBR)
const SizedBox(height: 10),
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

// Si es CBR, mostramos solo el slider de bitrate (sin CRF)
if (_settings.bitrateMode == BitrateMode.cbr) ...[
  const SizedBox(height: 5),
  _buildBitrateSlider(processor),
  // Añadir hint sobre valores típicos CBR
  const Padding(
    padding: EdgeInsets.only(left: 16),
    child: Text(
      'CBR mantiene bitrate constante. Útil para streaming.',
      style: TextStyle(color: Colors.amber, fontSize: 11),
    ),
  ),
] else ...[
  // CRF: mostramos bitrate y CRF (como antes)
  _buildBitrateSlider(processor),
  _buildCRFSlider(processor),
],