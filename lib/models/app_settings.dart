import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum InterfaceDensity { compact, normal, comfortable }
enum CornerRoundness { square, light, rounded }
enum DefaultQuality { high, medium, low }

class AppSettings {
  // Apariencia
  Color accentColor;
  Color textColor;
  double textScaleFactor;
  InterfaceDensity density;
  CornerRoundness roundness;

  // Exportación
  String defaultOutputFolder;
  String fileNameTemplate;
  DefaultQuality defaultVideoQuality;
  DefaultQuality defaultAudioQuality;
  DefaultQuality defaultImageQuality;
  bool deleteOriginalAfterExport;
  bool warnBeforeOverwrite;
  bool keepOriginalName; // <-- AÑADIDO

  // Proyecto
  bool autoBackupProject;
  bool keepLastLoadedFile;

  // Onboarding
  bool onboardingCompleted;

  // Papelera
  bool trashEnabled;
  bool alwaysAskBeforeDelete;
  bool dontShowDeleteWarning;

  // Defaults específicos
  Map<String, dynamic> videoDefaults;
  Map<String, dynamic> audioDefaults;
  Map<String, dynamic> imageDefaults;

  AppSettings({
    // Apariencia
    this.accentColor = Colors.blueAccent,
    this.textColor = Colors.white,
    this.textScaleFactor = 1.0,
    this.density = InterfaceDensity.normal,
    this.roundness = CornerRoundness.light,

    // Exportación
    this.defaultOutputFolder = '/storage/emulated/0/PremiumPro',
    this.fileNameTemplate = '{name}_premium',
    this.defaultVideoQuality = DefaultQuality.medium,
    this.defaultAudioQuality = DefaultQuality.medium,
    this.defaultImageQuality = DefaultQuality.medium,
    this.deleteOriginalAfterExport = false,
    this.warnBeforeOverwrite = true,
    this.keepOriginalName = false, // <-- AÑADIDO

    // Proyecto
    this.autoBackupProject = true,
    this.keepLastLoadedFile = false,

    // Onboarding
    this.onboardingCompleted = false,

    // Papelera
    this.trashEnabled = true,
    this.alwaysAskBeforeDelete = true,
    this.dontShowDeleteWarning = false,

    // Defaults
    Map<String, dynamic>? videoDefaults,
    Map<String, dynamic>? audioDefaults,
    Map<String, dynamic>? imageDefaults,
  })  : videoDefaults = videoDefaults ?? {},
        audioDefaults = audioDefaults ?? {},
        imageDefaults = imageDefaults ?? {};

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();

    return AppSettings(
      accentColor: Color(prefs.getInt('accentColor') ?? Colors.blueAccent.value),
      textColor: Color(prefs.getInt('textColor') ?? Colors.white.value),
      textScaleFactor: prefs.getDouble('textScaleFactor') ?? 1.0,
      density: InterfaceDensity.values[prefs.getInt('density') ?? 1],
      roundness: CornerRoundness.values[prefs.getInt('roundness') ?? 1],

      defaultOutputFolder: prefs.getString('defaultOutputFolder') ?? '/storage/emulated/0/PremiumPro',
      fileNameTemplate: prefs.getString('fileNameTemplate') ?? '{name}_premium',
      defaultVideoQuality: DefaultQuality.values[prefs.getInt('defaultVideoQuality') ?? 1],
      defaultAudioQuality: DefaultQuality.values[prefs.getInt('defaultAudioQuality') ?? 1],
      defaultImageQuality: DefaultQuality.values[prefs.getInt('defaultImageQuality') ?? 1],
      deleteOriginalAfterExport: prefs.getBool('deleteOriginalAfterExport') ?? false,
      warnBeforeOverwrite: prefs.getBool('warnBeforeOverwrite') ?? true,
      keepOriginalName: prefs.getBool('keepOriginalName') ?? false, // <-- AÑADIDO

      autoBackupProject: prefs.getBool('autoBackupProject') ?? true,
      keepLastLoadedFile: prefs.getBool('keepLastLoadedFile') ?? false,

      onboardingCompleted: prefs.getBool('onboardingCompleted') ?? false,

      trashEnabled: prefs.getBool('trashEnabled') ?? true,
      alwaysAskBeforeDelete: prefs.getBool('alwaysAskBeforeDelete') ?? true,
      dontShowDeleteWarning: prefs.getBool('dontShowDeleteWarning') ?? false,

      videoDefaults: Map.from(jsonDecode(prefs.getString('videoDefaults') ?? '{}')),
      audioDefaults: Map.from(jsonDecode(prefs.getString('audioDefaults') ?? '{}')),
      imageDefaults: Map.from(jsonDecode(prefs.getString('imageDefaults') ?? '{}')),
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('accentColor', accentColor.value);
    await prefs.setInt('textColor', textColor.value);
    await prefs.setDouble('textScaleFactor', textScaleFactor);
    await prefs.setInt('density', density.index);
    await prefs.setInt('roundness', roundness.index);

    await prefs.setString('defaultOutputFolder', defaultOutputFolder);
    await prefs.setString('fileNameTemplate', fileNameTemplate);
    await prefs.setInt('defaultVideoQuality', defaultVideoQuality.index);
    await prefs.setInt('defaultAudioQuality', defaultAudioQuality.index);
    await prefs.setInt('defaultImageQuality', defaultImageQuality.index);
    await prefs.setBool('deleteOriginalAfterExport', deleteOriginalAfterExport);
    await prefs.setBool('warnBeforeOverwrite', warnBeforeOverwrite);
    await prefs.setBool('keepOriginalName', keepOriginalName); // <-- AÑADIDO

    await prefs.setBool('autoBackupProject', autoBackupProject);
    await prefs.setBool('keepLastLoadedFile', keepLastLoadedFile);

    await prefs.setBool('onboardingCompleted', onboardingCompleted);

    await prefs.setBool('trashEnabled', trashEnabled);
    await prefs.setBool('alwaysAskBeforeDelete', alwaysAskBeforeDelete);
    await prefs.setBool('dontShowDeleteWarning', dontShowDeleteWarning);

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