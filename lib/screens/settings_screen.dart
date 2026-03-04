import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:file_picker/file_picker.dart';
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
            _buildDensitySelector(settingsProvider, settings),
            _buildRoundnessSelector(settingsProvider, settings),
            const Divider(height: 32, color: Colors.grey),

            _buildSectionTitle('EXPORTACIÓN'),
            _buildFolderPicker(settingsProvider, settings),
            _buildFileNameTemplate(settingsProvider, settings),
            _buildQualityPresets(settingsProvider, settings),
            _buildDeleteOriginalSwitch(settingsProvider, settings),
            _buildWarnOverwriteSwitch(settingsProvider, settings),
            const Divider(height: 32, color: Colors.grey),

            _buildSectionTitle('PROYECTO'),
            _buildAutoBackupSwitch(settingsProvider, settings),
            _buildKeepLastFileSwitch(settingsProvider, settings),
            const Divider(height: 32, color: Colors.grey),

            _buildSectionTitle('PAPELERA'),
            _buildTrashEnabledSwitch(settingsProvider, settings),
            if (settings.trashEnabled) ...[
              _buildAlwaysAskSwitch(settingsProvider, settings),
            ] else ...[
              _buildDontShowDeleteWarningSwitch(settingsProvider, settings),
              _buildResetDeleteWarningButton(settingsProvider),
            ],
            const Divider(height: 32, color: Colors.grey),

            _buildSectionTitle('BIENVENIDA'),
            _buildOnboardingCompletedSwitch(settingsProvider, settings),
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

  Widget _buildDensitySelector(SettingsProvider provider, AppSettings settings) {
    return ListTile(
      title: const Text('Densidad de interfaz'),
      subtitle: Text(_densityName(settings.density)),
      trailing: DropdownButton<InterfaceDensity>(
        value: settings.density,
        items: InterfaceDensity.values.map((d) {
          return DropdownMenuItem(
            value: d,
            child: Text(_densityName(d)),
          );
        }).toList(),
        onChanged: (val) => provider.setDensity(val!),
      ),
    );
  }

  String _densityName(InterfaceDensity d) {
    switch (d) {
      case InterfaceDensity.compact:
        return 'Compacto';
      case InterfaceDensity.normal:
        return 'Normal';
      case InterfaceDensity.comfortable:
        return 'Cómodo';
    }
  }

  Widget _buildRoundnessSelector(SettingsProvider provider, AppSettings settings) {
    return ListTile(
      title: const Text('Redondez de bordes'),
      subtitle: Text(_roundnessName(settings.roundness)),
      trailing: DropdownButton<CornerRoundness>(
        value: settings.roundness,
        items: CornerRoundness.values.map((r) {
          return DropdownMenuItem(
            value: r,
            child: Text(_roundnessName(r)),
          );
        }).toList(),
        onChanged: (val) => provider.setRoundness(val!),
      ),
    );
  }

  String _roundnessName(CornerRoundness r) {
    switch (r) {
      case CornerRoundness.square:
        return 'Cuadrado';
      case CornerRoundness.light:
        return 'Ligero';
      case CornerRoundness.rounded:
        return 'Redondeado';
    }
  }

  Widget _buildFolderPicker(SettingsProvider provider, AppSettings settings) {
    return ListTile(
      title: const Text('Carpeta de salida'),
      subtitle: Text(settings.defaultOutputFolder),
      trailing: IconButton(
        icon: const Icon(Icons.folder_open),
        onPressed: () async {
          String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
          if (selectedDirectory != null) {
            provider.setDefaultOutputFolder(selectedDirectory);
          }
        },
      ),
    );
  }

  Widget _buildFileNameTemplate(SettingsProvider provider, AppSettings settings) {
    final controller = TextEditingController(text: settings.fileNameTemplate);
    return ListTile(
      title: const Text('Formato de nombre'),
      subtitle: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: '{name}_premium, {date}, etc.',
          hintStyle: TextStyle(color: Colors.grey),
        ),
        onChanged: (val) => provider.setFileNameTemplate(val),
      ),
    );
  }

  Widget _buildQualityPresets(SettingsProvider provider, AppSettings settings) {
    return Column(
      children: [
        _buildQualityDropdown(
          'Video',
          settings.defaultVideoQuality,
          (val) => provider.setDefaultVideoQuality(val),
        ),
        _buildQualityDropdown(
          'Audio',
          settings.defaultAudioQuality,
          (val) => provider.setDefaultAudioQuality(val),
        ),
        _buildQualityDropdown(
          'Imagen',
          settings.defaultImageQuality,
          (val) => provider.setDefaultImageQuality(val),
        ),
      ],
    );
  }

  Widget _buildQualityDropdown(String label, DefaultQuality current, Function(DefaultQuality) onChanged) {
    return ListTile(
      title: Text('Calidad $label por defecto'),
      trailing: DropdownButton<DefaultQuality>(
        value: current,
        items: DefaultQuality.values.map((q) {
          return DropdownMenuItem(
            value: q,
            child: Text(_qualityName(q)),
          );
        }).toList(),
        onChanged: (val) => onChanged(val!),
      ),
    );
  }

  String _qualityName(DefaultQuality q) {
    switch (q) {
      case DefaultQuality.high:
        return 'Alta';
      case DefaultQuality.medium:
        return 'Media';
      case DefaultQuality.low:
        return 'Baja';
    }
  }

  Widget _buildDeleteOriginalSwitch(SettingsProvider provider, AppSettings settings) {
    return SwitchListTile(
      title: const Text('Eliminar original después de exportar'),
      subtitle: const Text('El archivo fuente se moverá a la papelera si está activada'),
      value: settings.deleteOriginalAfterExport,
      onChanged: (val) => provider.setDeleteOriginalAfterExport(val),
    );
  }

  Widget _buildWarnOverwriteSwitch(SettingsProvider provider, AppSettings settings) {
    return SwitchListTile(
      title: const Text('Advertir antes de sobrescribir'),
      value: settings.warnBeforeOverwrite,
      onChanged: (val) => provider.setWarnBeforeOverwrite(val),
    );
  }

  Widget _buildAutoBackupSwitch(SettingsProvider provider, AppSettings settings) {
    return SwitchListTile(
      title: const Text('Auto-respaldar proyecto'),
      subtitle: const Text('Guarda el estado automáticamente al salir'),
      value: settings.autoBackupProject,
      onChanged: (val) => provider.setAutoBackupProject(val),
    );
  }

  Widget _buildKeepLastFileSwitch(SettingsProvider provider, AppSettings settings) {
    return SwitchListTile(
      title: const Text('Mantener último archivo cargado'),
      subtitle: const Text('Al abrir la app, se cargará el último archivo usado'),
      value: settings.keepLastLoadedFile,
      onChanged: (val) => provider.setKeepLastLoadedFile(val),
    );
  }

  Widget _buildTrashEnabledSwitch(SettingsProvider provider, AppSettings settings) {
    return SwitchListTile(
      title: const Text('Activar papelera'),
      subtitle: const Text('Los archivos eliminados se moverán a la papelera'),
      value: settings.trashEnabled,
      onChanged: (val) => provider.setTrashEnabled(val),
    );
  }

  Widget _buildAlwaysAskSwitch(SettingsProvider provider, AppSettings settings) {
    return SwitchListTile(
      title: const Text('Preguntar siempre antes de mover a papelera'),
      value: settings.alwaysAskBeforeDelete,
      onChanged: (val) => provider.setAlwaysAskBeforeDelete(val),
    );
  }

  Widget _buildDontShowDeleteWarningSwitch(SettingsProvider provider, AppSettings settings) {
    return SwitchListTile(
      title: const Text('No volver a mostrar advertencia de borrado'),
      subtitle: const Text('Los archivos se borrarán directamente sin preguntar'),
      value: settings.dontShowDeleteWarning,
      onChanged: (val) => provider.setDontShowDeleteWarning(val),
    );
  }

  Widget _buildResetDeleteWarningButton(SettingsProvider provider) {
    return TextButton(
      onPressed: () => provider.resetDontShowDeleteWarning(),
      child: const Text('Restablecer advertencias de borrado'),
    );
  }

  Widget _buildOnboardingCompletedSwitch(SettingsProvider provider, AppSettings settings) {
    return SwitchListTile(
      title: const Text('Mostrar bienvenida al inicio'),
      value: !settings.onboardingCompleted,
      onChanged: (val) => provider.setOnboardingCompleted(!val),
    );
  }
}