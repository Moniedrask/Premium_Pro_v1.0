import 'package:flutter/material.dart';
import '../models/app_settings.dart';

class SettingsProvider extends ChangeNotifier {
  late AppSettings _settings;

  SettingsProvider() {
    _loadSettings();
  }

  AppSettings get settings => _settings;

  Future<void> _loadSettings() async {
    _settings = await AppSettings.load();
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await _settings.save();
    notifyListeners();
  }

  // Métodos de conveniencia para actualizar propiedades individuales
  Future<void> setAccentColor(Color color) async {
    _settings.accentColor = color;
    await _settings.save();
    notifyListeners();
  }

  Future<void> setTextColor(Color color) async {
    _settings.textColor = color;
    await _settings.save();
    notifyListeners();
  }

  Future<void> setTextScaleFactor(double scale) async {
    _settings.textScaleFactor = scale;
    await _settings.save();
    notifyListeners();
  }

  Future<void> setKeepOriginalName(bool value) async {
    _settings.keepOriginalName = value;
    await _settings.save();
    notifyListeners();
  }

  Future<void> setSaveSettingsAsDefault(bool value) async {
    _settings.saveSettingsAsDefault = value;
    await _settings.save();
    notifyListeners();
  }

  // Guardar defaults específicos
  Future<void> setVideoDefaults(Map<String, dynamic> defaults) async {
    _settings.videoDefaults = defaults;
    await _settings.save();
    notifyListeners();
  }

  Future<void> setAudioDefaults(Map<String, dynamic> defaults) async {
    _settings.audioDefaults = defaults;
    await _settings.save();
    notifyListeners();
  }

  Future<void> setImageDefaults(Map<String, dynamic> defaults) async {
    _settings.imageDefaults = defaults;
    await _settings.save();
    notifyListeners();
  }
}