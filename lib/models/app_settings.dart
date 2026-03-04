import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  // Colores
  Color accentColor;
  Color textColor;
  
  // Tamaño de texto (en escala)
  double textScaleFactor;
  
  // Opciones por defecto para exportación
  bool keepOriginalName;      // Si se mantiene el nombre original al exportar
  bool saveSettingsAsDefault; // Si la configuración actual se guarda como predeterminada

  // Preferencias de exportación específicas (se pueden expandir)
  Map<String, dynamic> videoDefaults;
  Map<String, dynamic> audioDefaults;
  Map<String, dynamic> imageDefaults;

  AppSettings({
    this.accentColor = Colors.blueAccent,
    this.textColor = Colors.white,
    this.textScaleFactor = 1.0,
    this.keepOriginalName = false,
    this.saveSettingsAsDefault = false,
    Map<String, dynamic>? videoDefaults,
    Map<String, dynamic>? audioDefaults,
    Map<String, dynamic>? imageDefaults,
  })  : videoDefaults = videoDefaults ?? {},
        audioDefaults = audioDefaults ?? {},
        imageDefaults = imageDefaults ?? {};

  // Cargar desde SharedPreferences
  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    
    int? accentColorValue = prefs.getInt('accentColor');
    int? textColorValue = prefs.getInt('textColor');
    double textScale = prefs.getDouble('textScaleFactor') ?? 1.0;
    bool keepName = prefs.getBool('keepOriginalName') ?? false;
    bool saveDefault = prefs.getBool('saveSettingsAsDefault') ?? false;

    // Cargar defaults de video, audio, imagen (como JSON)
    Map<String, dynamic> videoDefaults = {};
    String? videoJson = prefs.getString('videoDefaults');
    if (videoJson != null) {
      videoDefaults = Map<String, dynamic>.from(
          const JsonDecoder().convert(videoJson));
    }

    Map<String, dynamic> audioDefaults = {};
    String? audioJson = prefs.getString('audioDefaults');
    if (audioJson != null) {
      audioDefaults = Map<String, dynamic>.from(
          const JsonDecoder().convert(audioJson));
    }

    Map<String, dynamic> imageDefaults = {};
    String? imageJson = prefs.getString('imageDefaults');
    if (imageJson != null) {
      imageDefaults = Map<String, dynamic>.from(
          const JsonDecoder().convert(imageJson));
    }

    return AppSettings(
      accentColor: accentColorValue != null ? Color(accentColorValue) : Colors.blueAccent,
      textColor: textColorValue != null ? Color(textColorValue) : Colors.white,
      textScaleFactor: textScale,
      keepOriginalName: keepName,
      saveSettingsAsDefault: saveDefault,
      videoDefaults: videoDefaults,
      audioDefaults: audioDefaults,
      imageDefaults: imageDefaults,
    );
  }

  // Guardar en SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setInt('accentColor', accentColor.value);
    await prefs.setInt('textColor', textColor.value);
    await prefs.setDouble('textScaleFactor', textScaleFactor);
    await prefs.setBool('keepOriginalName', keepOriginalName);
    await prefs.setBool('saveSettingsAsDefault', saveSettingsAsDefault);

    // Guardar defaults como JSON
    if (videoDefaults.isNotEmpty) {
      await prefs.setString('videoDefaults', jsonEncode(videoDefaults));
    }
    if (audioDefaults.isNotEmpty) {
      await prefs.setString('audioDefaults', jsonEncode(audioDefaults));
    }
    if (imageDefaults.isNotEmpty) {
      await prefs.setString('imageDefaults', jsonEncode(imageDefaults));
    }
  }
}