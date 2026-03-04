import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/settings_provider.dart';
import '../models/app_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final settings = settingsProvider.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: Colors.black,
      ),
      body: Container(
        color: Colors.black,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Sección: Apariencia
            _buildSectionTitle('APARIENCIA'),
            _buildColorPickerTile(
              context,
              'Color de acento',
              settings.accentColor,
              (color) => settingsProvider.setAccentColor(color),
            ),
            _buildColorPickerTile(
              context,
              'Color de texto',
              settings.textColor,
              (color) => settingsProvider.setTextColor(color),
            ),
            _buildSliderTile(
              'Tamaño de texto',
              settings.textScaleFactor,
              0.8,
              1.5,
              (val) => settingsProvider.setTextScaleFactor(val),
            ),
            const Divider(height: 32, color: Colors.grey),

            // Sección: Exportación
            _buildSectionTitle('EXPORTACIÓN'),
            SwitchListTile(
              title: const Text('Mantener nombre original'),
              subtitle: const Text('Si está activado, no se añadirá timestamp'),
              value: settings.keepOriginalName,
              onChanged: (val) => settingsProvider.setKeepOriginalName(val),
              activeColor: settings.accentColor,
            ),
            SwitchListTile(
              title: const Text('Guardar configuraciones como predeterminadas'),
              subtitle: const Text('Al marcar, los ajustes actuales se usarán por defecto'),
              value: settings.saveSettingsAsDefault,
              onChanged: (val) => settingsProvider.setSaveSettingsAsDefault(val),
              activeColor: settings.accentColor,
            ),
            const Divider(height: 32, color: Colors.grey),

            // Sección: Acerca de
            _buildSectionTitle('ACERCA DE'),
            ListTile(
              leading: Icon(Icons.info, color: settings.accentColor),
              title: const Text('Versión 1.0.0'),
              subtitle: const Text('Premium Pro - Editor Multimedia'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.blueAccent,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildColorPickerTile(
    BuildContext context,
    String title,
    Color currentColor,
    Function(Color) onColorChanged,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: currentColor,
        radius: 12,
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () => _showColorPicker(context, currentColor, onColorChanged),
    );
  }

  void _showColorPicker(
    BuildContext context,
    Color initialColor,
    Function(Color) onColorChanged,
  ) {
    Color pickedColor = initialColor;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Elige un color', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: initialColor,
            onColorChanged: (color) => pickedColor = color,
            showLabel: true,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              onColorChanged(pickedColor);
              Navigator.pop(ctx);
            },
            child: const Text('Aceptar', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(title, style: const TextStyle(color: Colors.white70)),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: 14,
          activeColor: Colors.blueAccent,
          onChanged: onChanged,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Valor: ${value.toStringAsFixed(1)}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ],
    );
  }
}