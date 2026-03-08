// ... después de _buildHardwareAccelerationSwitch(processor)

const SizedBox(height: 10),
const Text('MEJORAS DE CALIDAD', 
    style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),

// Escalado de resolución
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
    padding: const EdgeInsets.only(left: 16, right: 16),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            decoration: const InputDecoration(labelText: 'Ancho objetivo (px)'),
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: _settings.targetWidth.toString()),
            onChanged: (val) => setState(() => _settings.targetWidth = int.tryParse(val) ?? 1920),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            decoration: const InputDecoration(labelText: 'Alto objetivo (px)'),
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: _settings.targetHeight.toString()),
            onChanged: (val) => setState(() => _settings.targetHeight = int.tryParse(val) ?? 1080),
          ),
        ),
      ],
    ),
  ),

const SizedBox(height: 10),

// Interpolación de frames
CheckboxListTile(
  title: const Text('Interpolar frames', style: TextStyle(color: Colors.white)),
  subtitle: const Text('Aumenta FPS hasta 4x (ej: 120fps → 480fps)', 
      style: TextStyle(color: Colors.grey, fontSize: 12)),
  value: _settings.frameInterpolation,
  onChanged: processor.isProcessing ? null : (val) {
    setState(() => _settings.frameInterpolation = val!);
  },
  secondary: Icon(Icons.speed, color: globalSettings.accentColor),
  activeColor: globalSettings.accentColor,
),

if (_settings.frameInterpolation)
  Padding(
    padding: const EdgeInsets.only(left: 16, right: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FPS objetivo: ${_settings.targetFps}', 
            style: const TextStyle(color: Colors.white)),
        Slider(
          value: _settings.targetFps.toDouble(),
          min: 24,
          max: 480,
          divisions: 19,
          activeColor: globalSettings.accentColor,
          onChanged: processor.isProcessing ? null : (val) {
            setState(() => _settings.targetFps = val.round());
          },
        ),
        const Text('Valores comunes: 60, 120, 240, 480', 
            style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    ),
  ),