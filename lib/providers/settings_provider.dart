import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../models/compression_preset.dart';

class SettingsProvider extends ChangeNotifier {
  late AppSettings _settings;
  List<CompressionPreset> _userPresets = [];

  SettingsProvider() {
    _loadSettings();
    _loadUserPresets();
  }

  AppSettings get settings => _settings;
  List<CompressionPreset> get userPresets => _userPresets;

  Future<void> _loadSettings() async {
    _settings = await AppSettings.load();
    notifyListeners();
  }

  Future<void> _loadUserPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final String? presetsJson = prefs.getString('userPresets');
    if (presetsJson != null) {
      final List<dynamic> jsonList = jsonDecode(presetsJson);
      _userPresets = jsonList.map((j) => CompressionPreset.fromJson(j)).toList();
    } else {
      _userPresets = [];
    }
    notifyListeners();
  }

  Future<void> saveUserPreset(CompressionPreset preset) async {
    _userPresets.add(preset);
    await _saveUserPresets();
    notifyListeners();
  }

  Future<void> deleteUserPreset(String name) async {
    _userPresets.removeWhere((p) => p.name == name);
    await _saveUserPresets();
    notifyListeners();
  }

  Future<void> _saveUserPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _userPresets.map((p) => p.toJson()).toList();
    await prefs.setString('userPresets', jsonEncode(jsonList));
  }

  // ... resto de métodos existentes (setAccentColor, setDensity, etc.)
  // (mantener todo lo que ya tenías)
}