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

  // Métodos de conveniencia para cada propiedad

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

  Future<void> setDensity(InterfaceDensity density) async {
    _settings.density = density;
    await _settings.save();
    notifyListeners();
  }

  Future<void> setRoundness(CornerRoundness roundness) async {
    _settings.roundness = roundness;
    await _settings.save();
    notifyListeners();
  }

  Future<void> setDefaultOutputFolder(String path) async {
    _settings.defaultOutputFolder = path;
    await _settings.save();
    notifyListeners();
  }

  Future<void> setFileNameTemplate(String template) async {
    _settings.fileNameTemplate = template;
    await _settings.save();
    notifyListeners();
  }

  Future<void> setDefaultVideoQuality(DefaultQuality quality) async {
    _settings.defaultVideoQuality = quality;
    await _settings.save();
    notifyListeners();
  }

  Future<void> setDefaultAudioQuality(DefaultQuality quality) async {
    _settings.defaultAudioQuality = quality;
    await _settings.save();
    notifyListeners();
  }

  Future<void> setDefaultImageQuality(DefaultQuality quality) async {
    _settings.defaultImageQuality = quality;
    await _settings.save();
    notifyListeners();
  }

  Future<void> setDeleteOriginalAfterExport(bool value) async {
    _settings.deleteOriginalAfterExport = value;
    await _settings.save();
    notifyListeners();
  }

  Future<void> setWarnBeforeOverwrite(bool value) async {
    _settings.warnBeforeOverwrite = value;
    await _settings.save();
    notifyListeners();
  }

  Future<void> setAutoBackupProject(bool value) async {
    _settings.autoBackupProject = value;
    await _settings.save();
    notifyListeners();
  }

  Future<void> setKeepLastLoadedFile(bool value) async {
    _settings.keepLastLoadedFile = value;
    await _settings.save();
    notifyListeners();
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    _settings.onboardingCompleted = completed;
    await _settings.save();
    notifyListeners();
  }

  Future<void> setTrashEnabled(bool enabled) async {
    _settings.trashEnabled = enabled;
    await _settings.save();
    notifyListeners();
  }

  Future<void> setAlwaysAskBeforeDelete(bool ask) async {
    _settings.alwaysAskBeforeDelete = ask;
    await _settings.save();
    notifyListeners();
  }

  Future<void> setDontShowDeleteWarning(bool dontShow) async {
    _settings.dontShowDeleteWarning = dontShow;
    await _settings.save();
    notifyListeners();
  }

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

  // Método para resetear la advertencia de borrado
  Future<void> resetDontShowDeleteWarning() async {
    _settings.dontShowDeleteWarning = false;
    await _settings.save();
    notifyListeners();
  }
}