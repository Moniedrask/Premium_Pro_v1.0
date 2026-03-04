import 'dart:convert'; // 👈 IMPORTANTE: añadir este import
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  Color accentColor;
  Color textColor;
  double textScaleFactor;
  bool keepOriginalName;
  bool saveSettingsAsDefault;

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

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();

    int? accentColorValue = prefs.getInt('accentColor');
    int? textColorValue = prefs.getInt('textColor');
    double textScale = prefs.getDouble('textScaleFactor') ?? 1.0;
    bool keepName = prefs.getBool('keepOriginalName') ?? false;
    bool saveDefault = prefs.getBool('saveSettingsAsDefault') ?? false;

    Map<String, dynamic> videoDefaults = {};
    String? videoJson = prefs.getString('videoDefaults');
    if (videoJson != null) {
      videoDefaults = Map<String, dynamic>.from(jsonDecode(videoJson));
    }

    Map<String, dynamic> audioDefaults = {};
    String? audioJson = prefs.getString('audioDefaults');
    if (audioJson != null) {
      audioDefaults = Map<String, dynamic>.from(jsonDecode(audioJson));
    }

    Map<String, dynamic> imageDefaults = {};
    String? imageJson = prefs.getString('imageDefaults');
    if (imageJson != null) {
      imageDefaults = Map<String, dynamic>.from(jsonDecode(imageJson));
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

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('accentColor', accentColor.value);
    await prefs.setInt('textColor', textColor.value);
    await prefs.setDouble('textScaleFactor', textScaleFactor);
    await prefs.setBool('keepOriginalName', keepOriginalName);
    await prefs.setBool('saveSettingsAsDefault', saveSettingsAsDefault);

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