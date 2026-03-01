import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Configuración persistente del proyecto y preferencias del usuario
/// Se guarda en SharedPreferences (Android) / Registry (Windows)
class ProjectConfig {
  // ==================== PREFERENCIAS GENERALES ====================
  String language;              // 'es', 'en', 'pt'
  bool darkMode;                // Siempre true para OLED
  bool keepScreenOn;            // Mantener pantalla activa durante procesamiento
  int maxMemoryUsage;           // MB límite de uso de RAM (auto si 0)
  
  // ==================== PREFERENCIAS DE EXPORTACIÓN ====================
  String defaultOutputFolder;   // Carpeta predeterminada
  bool askBeforeOverwrite;      // Preguntar antes de sobrescribir
  bool deleteOriginalAfter;     // Eliminar original después de exportar
  bool saveLogs;                // Guardar logs de procesamiento
  
  // ==================== PRESETS GUARDADOS ====================
  List<Preset> savedPresets;    // Lista de presets del usuario
  String defaultPresetId;       // ID del preset predeterminado
  
  // ==================== IA ====================
  bool aiModelsDownloaded;      // ¿Modelos IA descargados?
  String aiModelPath;           // Ruta a modelos IA
  int aiModelSize;              // 1GB, 4GB, 8GB
  
  // ==================== ESTADÍSTICAS ====================
  int totalExports;             // Total de exportaciones realizadas
  int totalProcessingTime;      // Segundos totales procesando
  DateTime lastAppOpen;         // Última vez que se abrió la app

  /// Constructor con valores predeterminados
  ProjectConfig({
    this.language = 'es',
    this.darkMode = true,
    this.keepScreenOn = true,
    this.maxMemoryUsage = 0,  // 0 = automático
    this.defaultOutputFolder = '/storage/emulated/0/PremiumPro',
    this.askBeforeOverwrite = true,
    this.deleteOriginalAfter = false,
    this.saveLogs = true,
    this.savedPresets = const [],
    this.defaultPresetId = 'default',
    this.aiModelsDownloaded = false,
    this.aiModelPath = '',
    this.aiModelSize = 0,
    this.totalExports = 0,
    this.totalProcessingTime = 0,
  });
  /// Carga configuración desde SharedPreferences
  static Future<ProjectConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    
    return ProjectConfig(
      language: prefs.getString('language') ?? 'es',
      darkMode: prefs.getBool('darkMode') ?? true,
      keepScreenOn: prefs.getBool('keepScreenOn') ?? true,
      maxMemoryUsage: prefs.getInt('maxMemoryUsage') ?? 0,
      defaultOutputFolder: prefs.getString('defaultOutputFolder') ?? 
          '/storage/emulated/0/PremiumPro',
      askBeforeOverwrite: prefs.getBool('askBeforeOverwrite') ?? true,
      deleteOriginalAfter: prefs.getBool('deleteOriginalAfter') ?? false,
      saveLogs: prefs.getBool('saveLogs') ?? true,
      aiModelsDownloaded: prefs.getBool('aiModelsDownloaded') ?? false,
      aiModelPath: prefs.getString('aiModelPath') ?? '',
      aiModelSize: prefs.getInt('aiModelSize') ?? 0,
      totalExports: prefs.getInt('totalExports') ?? 0,
      totalProcessingTime: prefs.getInt('totalProcessingTime') ?? 0,
    );
  }

  /// Guarda configuración en SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('language', language);
    await prefs.setBool('darkMode', darkMode);
    await prefs.setBool('keepScreenOn', keepScreenOn);
    await prefs.setInt('maxMemoryUsage', maxMemoryUsage);
    await prefs.setString('defaultOutputFolder', defaultOutputFolder);
    await prefs.setBool('askBeforeOverwrite', askBeforeOverwrite);
    await prefs.setBool('deleteOriginalAfter', deleteOriginalAfter);
    await prefs.setBool('saveLogs', saveLogs);
    await prefs.setBool('aiModelsDownloaded', aiModelsDownloaded);
    await prefs.setString('aiModelPath', aiModelPath);
    await prefs.setInt('aiModelSize', aiModelSize);
    await prefs.setInt('totalExports', totalExports);
    await prefs.setInt('totalProcessingTime', totalProcessingTime);
  }

  /// Marca configuración actual como predeterminada
  Future<void> setAsDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDefaultConfig', true);
    await save();
  }

  /// Verifica si la configuración es predeterminada  static Future<bool> isDefault() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isDefaultConfig') ?? false;
  }

  /// Agrega un preset guardado
  void addPreset(Preset preset) {
    savedPresets.add(preset);
  }

  /// Elimina un preset por ID
  void removePreset(String presetId) {
    savedPresets.removeWhere((p) => p.id == presetId);
  }

  /// Exporta presets a JSON para compartir
  String exportPresetsToJson() {
    return jsonEncode(savedPresets.map((p) => p.toJson()).toList());
  }

  /// Importa presets desde JSON
  void importPresetsFromJson(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString);
    savedPresets = jsonList.map((j) => Preset.fromJson(j)).toList();
  }

  /// Incrementa estadísticas de uso
  Future<void> incrementStats(int processingSeconds) async {
    totalExports++;
    totalProcessingTime += processingSeconds;
    await save();
  }
}

/// Modelo de Preset guardado por el usuario
class Preset {
  String id;
  String name;
  String category;       // 'Redes Sociales', 'Cine', 'Archivado', 'Web'
  Map<String, dynamic> settings;  // Configuración de compresión
  DateTime createdAt;

  Preset({
    required this.id,
    required this.name,
    required this.category,
    required this.settings,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'settings': settings,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Preset.fromJson(Map<String, dynamic> json) {
    return Preset(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      settings: json['settings'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

/// Categorías predefinidas de presets
class PresetCategories {
  static const String socialMedia = 'Redes Sociales';
  static const String cinema = 'Cine';
  static const String archive = 'Archivado';
  static const String web = 'Web';
  static const String custom = 'Personalizado';
}