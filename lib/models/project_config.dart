import 'package:shared_preferences/shared_preferences.dart';

class ProjectConfig {
  String language = 'es';
  bool darkMode = true;
  String defaultOutputFolder = '/storage/emulated/0/PremiumPro';

  static Future<ProjectConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final config = ProjectConfig();
    config.language = prefs.getString('language') ?? 'es';
    config.darkMode = prefs.getBool('darkMode') ?? true;
    config.defaultOutputFolder = prefs.getString('outputFolder') ?? '/storage/emulated/0/PremiumPro';
    return config;
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    await prefs.setBool('darkMode', darkMode);
    await prefs.setString('outputFolder', defaultOutputFolder);
  }
}