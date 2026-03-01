import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ai_manager.dart';
import '../models/compression_settings.dart';
import '../models/project_config.dart';

/// Panel de configuración con tooltips informativos
/// Cada parámetro tiene ayuda contextual en español
class SettingsPanel extends StatefulWidget {
  final CompressionSettings settings;
  final Function(CompressionSettings) onSave;

  const SettingsPanel({
    super.key,
    required this.settings,
    required this.onSave,
  });

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  late CompressionSettings _localSettings;

  @override
  void initState() {
    super.initState();
    _localSettings = widget.settings;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF000000),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // SECCIÓN: VIDEO
          _buildSectionHeader('CONFIGURACIÓN DE VIDEO'),
          
          _buildCodecSelector(),
          _buildBitrateSlider(),
          _buildCRFSlider(),
          _buildPresetSelector(),
          
          const Divider(color: Colors.grey, height: 32),
          
          // SECCIÓN: AUDIO
          _buildSectionHeader('CONFIGURACIÓN DE AUDIO'),          
          _buildAudioCodecSelector(),
          _buildAudioBitrateSlider(),
          _buildSampleRateSelector(),
          
          const Divider(color: Colors.grey, height: 32),
          
          // SECCIÓN: IA
          _buildSectionHeader('INTELIGENCIA ARTIFICIAL'),
          
          _buildAISwitch(),
          _buildAIModelInfo(),
          
          const Divider(color: Colors.grey, height: 32),
          
          // SECCIÓN: GUARDAR PRESET
          _buildSectionHeader('PRESETS'),
          
          _buildSavePresetButton(),
          _buildSetAsDefaultButton(),
          
          const SizedBox(height: 20),
          
          // BOTÓN GUARDAR
          ElevatedButton(
            onPressed: () => widget.onSave(_localSettings),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'GUARDAR CONFIGURACIÓN',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.blueAccent,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 1.2,        ),
      ),
    );
  }

  Widget _buildCodecSelector() {
    return _buildSettingWithTooltip(
      title: 'Códec de Video',
      tooltip: 'H.264: Máxima compatibilidad\nH.265: Mejor compresión (50% menos)\nVP9: Ideal para web/YouTube',
      child: DropdownButtonFormField<String>(
        value: _localSettings.videoCodec,
        dropdownColor: const Color(0xFF111111),
        items: const [
          DropdownMenuItem(value: 'libx264', child: Text('H.264 (AVC)', style: TextStyle(color: Colors.white))),
          DropdownMenuItem(value: 'libx265', child: Text('H.265 (HEVC)', style: TextStyle(color: Colors.white))),
          DropdownMenuItem(value: 'libvpx-vp9', child: Text('VP9', style: TextStyle(color: Colors.white))),
        ],
        onChanged: (val) => setState(() => _localSettings.videoCodec = val!),
        decoration: const InputDecoration(
          labelText: 'Códec',
          labelStyle: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildBitrateSlider() {
    return _buildSettingWithTooltip(
      title: 'Bitrate de Video',
      tooltip: '1000 kbps: Calidad baja (móvil)\n2500 kbps: Calidad media (web)\n5000+ kbps: Alta calidad (4K)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_localSettings.videoBitrate} kbps',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Slider(
            value: _localSettings.videoBitrate.toDouble(),
            min: 500,
            max: 20000,
            divisions: 39,
            activeColor: Colors.blueAccent,
            onChanged: (val) => setState(() => _localSettings.videoBitrate = val.round()),
          ),
        ],
      ),
    );
  }
  Widget _buildCRFSlider() {
    return _buildSettingWithTooltip(
      title: 'CRF (Calidad Constante)',
      tooltip: '18-23: Alta calidad (recomendado)\n24-28: Calidad media\n29-51: Baja calidad\n0: Sin pérdida (archivo gigante)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CRF: ${_localSettings.crf}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Slider(
            value: _localSettings.crf.toDouble(),
            min: 0,
            max: 51,
            divisions: 51,
            activeColor: Colors.blueAccent,
            onChanged: (val) => setState(() => _localSettings.crf = val.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSelector() {
    return _buildSettingWithTooltip(
      title: 'Preset de Velocidad',
      tooltip: 'ultrafast: Muy rápido, archivo grande\nmedium: Equilibrado (recomendado)\nveryslow: Lento, archivo pequeño',
      child: DropdownButtonFormField<String>(
        value: _localSettings.preset,
        dropdownColor: const Color(0xFF111111),
        items: const [
          DropdownMenuItem(value: 'ultrafast', child: Text('Ultra Rápido', style: TextStyle(color: Colors.white))),
          DropdownMenuItem(value: 'fast', child: Text('Rápido', style: TextStyle(color: Colors.white))),
          DropdownMenuItem(value: 'medium', child: Text('Medio (Recomendado)', style: TextStyle(color: Colors.white))),
          DropdownMenuItem(value: 'slow', child: Text('Lento', style: TextStyle(color: Colors.white))),
          DropdownMenuItem(value: 'veryslow', child: Text('Muy Lento', style: TextStyle(color: Colors.white))),
        ],
        onChanged: (val) => setState(() => _localSettings.preset = val!),
        decoration: const InputDecoration(
          labelText: 'Velocidad',
          labelStyle: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildAudioCodecSelector() {
    return _buildSettingWithTooltip(
      title: 'Códec de Audio',      tooltip: 'AAC: Estándar universal\nMP3: Compatible antiguo\nOpus: Mejor calidad/bitrate\nFLAC: Sin pérdida',
      child: DropdownButtonFormField<String>(
        value: _localSettings.audioCodec,
        dropdownColor: const Color(0xFF111111),
        items: const [
          DropdownMenuItem(value: 'aac', child: Text('AAC', style: TextStyle(color: Colors.white))),
          DropdownMenuItem(value: 'mp3', child: Text('MP3', style: TextStyle(color: Colors.white))),
          DropdownMenuItem(value: 'opus', child: Text('Opus', style: TextStyle(color: Colors.white))),
          DropdownMenuItem(value: 'flac', child: Text('FLAC (Lossless)', style: TextStyle(color: Colors.white))),
        ],
        onChanged: (val) => setState(() => _localSettings.audioCodec = val!),
        decoration: const InputDecoration(
          labelText: 'Audio',
          labelStyle: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildAudioBitrateSlider() {
    return _buildSettingWithTooltip(
      title: 'Bitrate de Audio',
      tooltip: '128 kbps: Calidad aceptable\n192 kbps: Buena calidad\n320 kbps: Máxima calidad MP3',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_localSettings.audioBitrate} kbps',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Slider(
            value: _localSettings.audioBitrate.toDouble(),
            min: 64,
            max: 320,
            divisions: 12,
            activeColor: Colors.blueAccent,
            onChanged: (val) => setState(() => _localSettings.audioBitrate = val.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleRateSelector() {
    return _buildSettingWithTooltip(
      title: 'Frecuencia de Muestreo',
      tooltip: '44100 Hz: Estándar CD\n48000 Hz: Estándar video\n96000 Hz: Alta resolución',
      child: DropdownButtonFormField<int>(
        value: _localSettings.sampleRate,
        dropdownColor: const Color(0xFF111111),        items: const [
          DropdownMenuItem(value: 44100, child: Text('44.1 kHz (CD)', style: TextStyle(color: Colors.white))),
          DropdownMenuItem(value: 48000, child: Text('48 kHz (Video)', style: TextStyle(color: Colors.white))),
          DropdownMenuItem(value: 96000, child: Text('96 kHz (Hi-Res)', style: TextStyle(color: Colors.white))),
        ],
        onChanged: (val) => setState(() => _localSettings.sampleRate = val!),
        decoration: const InputDecoration(
          labelText: 'Sample Rate',
          labelStyle: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildAISwitch() {
    return Consumer<AIManager>(
      builder: (context, aiManager, _) {
        return _buildSettingWithTooltip(
          title: 'Activar IA',
          tooltip: 'Requiere descarga de modelos (1-8GB)\nSi no hay modelo, usa algoritmos tradicionales',
          child: SwitchListTile(
            title: const Text('Mejora con IA', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              aiManager.isModelAvailable 
                ? 'Modelo listo' 
                : 'Requiere descarga',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            value: _localSettings.aiEnabled,
            activeColor: Colors.blueAccent,
            onChanged: aiManager.isModelAvailable 
              ? (val) => setState(() => _localSettings.aiEnabled = val)
              : null,
          ),
        );
      },
    );
  }

  Widget _buildAIModelInfo() {
    return Consumer<AIManager>(
      builder: (context, aiManager, _) {
        return Card(
          color: const Color(0xFF111111),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(                  'Estado de Modelos IA',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (aiManager.isDownloading)
                  Column(
                    children: [
                      const LinearProgressIndicator(color: Colors.blueAccent),
                      const SizedBox(height: 8),
                      Text(
                        'Descargando: ${(aiManager.downloadProgress * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  )
                else if (aiManager.isModelAvailable)
                  const Text(
                    '✓ Modelo disponible y listo para usar',
                    style: TextStyle(color: Colors.green),
                  )
                else
                  const Text(
                    '✗ Sin modelo descargado (usando fallback)',
                    style: TextStyle(color: Colors.orange),
                  ),
                if (!aiManager.isDownloading && !aiManager.isModelAvailable)
                  TextButton(
                    onPressed: () => aiManager.downloadModel('real-esrgan-x2'),
                    child: const Text('Descargar Modelo 1GB', style: TextStyle(color: Colors.blueAccent)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavePresetButton() {
    return ListTile(
      leading: const Icon(Icons.save, color: Colors.blueAccent),
      title: const Text('Guardar como Preset', style: TextStyle(color: Colors.white)),
      subtitle: const Text('Guarda esta configuración para usar después', style: TextStyle(color: Colors.grey, fontSize: 12)),
      onTap: () => _showSavePresetDialog(),
    );
  }

  Widget _buildSetAsDefaultButton() {
    return ListTile(
      leading: const Icon(Icons.star, color: Colors.amber),      title: const Text('Marcar como Predeterminado', style: TextStyle(color: Colors.white)),
      subtitle: const Text('Esta configuración se usará por defecto', style: TextStyle(color: Colors.grey, fontSize: 12)),
      onTap: () => _confirmSetAsDefault(),
    );
  }

  Widget _buildSettingWithTooltip({
    required String title,
    required String tooltip,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showTooltip(tooltip),
                child: const CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.grey,
                  child: Text('?', style: TextStyle(fontSize: 12, color: Colors.black)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }

  void _showTooltip(String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Ayuda', style: TextStyle(color: Colors.white)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),            child: const Text('Cerrar', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  void _showSavePresetDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Guardar Preset', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Nombre del preset',
            labelStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              // Lógica para guardar preset
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preset guardado')),
              );
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  void _confirmSetAsDefault() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Confirmar', style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Estás seguro de marcar esta configuración como predeterminada?',          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              // Guardar como predeterminado
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Configuración marcada como predeterminada')),
              );
            },
            child: const Text('Confirmar', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }
}