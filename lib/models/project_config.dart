import 'package:shared_preferences/shared_preferences.dart';

class ProjectConfig {
  String language = 'es';
  bool darkMode = true;
  String defaultOutputFolder = '/storage/emulated/0/PremiumPro';

  static Future<ProjectConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ProjectConfig();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
  }
}
