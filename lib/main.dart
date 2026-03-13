import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/media_processor.dart';
import 'services/audio_processor.dart';
import 'services/image_processor.dart';
import 'services/ai_manager.dart';
import 'services/ram_monitor.dart';
import 'providers/settings_provider.dart';
import 'screens/settings_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/media_picker_screen.dart';
import 'screens/video_editor_screen.dart';
import 'screens/audio_editor_screen.dart';
import 'screens/image_editor_screen.dart';
import 'widgets/multi_layer_timeline.dart';
import 'widgets/compression_dialog.dart';
import 'models/compression_preset.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final videoProcessor = MediaProcessor();
  final audioProcessor = AudioProcessor();
  final imageProcessor = ImageProcessor();

  String? initError;
  try {
    await Future.wait([
      videoProcessor.init(),
      audioProcessor.init(),
      imageProcessor.init(),
    ]);
  } catch (e, stack) {
    initError = 'Error de inicialización:\n$e\n\n$stack';
    debugPrint(initError);
  }

  runApp(MyApp(
    videoProcessor: videoProcessor,
    audioProcessor: audioProcessor,
    imageProcessor: imageProcessor,
    initError: initError,
  ));
}

class MyApp extends StatelessWidget {
  final MediaProcessor videoProcessor;
  final AudioProcessor audioProcessor;
  final ImageProcessor imageProcessor;
  final String? initError;

  const MyApp({
    super.key,
    required this.videoProcessor,
    required this.audioProcessor,
    required this.imageProcessor,
    this.initError,
  });

  @override
  Widget build(BuildContext context) {
    if (initError != null) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                initError!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MediaProcessor>.value(value: videoProcessor),
        ChangeNotifierProvider<AudioProcessor>.value(value: audioProcessor),
        ChangeNotifierProvider<ImageProcessor>.value(value: imageProcessor),
        ChangeNotifierProvider(create: (_) => AIManager()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => RamMonitor()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            settingsProvider.loadUserPresets();
          });
          final settings = settingsProvider.settings;
          return MaterialApp(
            title: 'Premium Pro v1.0',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF000000),
              primaryColor: const Color(0xFF000000),
              colorScheme: ColorScheme.dark(
                primary: settings.accentColor,
                secondary: settings.accentColor,
                surface: Colors.black,
                background: Colors.black,
                error: Colors.red,
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: const Color(0xFF000000),
                elevation: 0,
                iconTheme: IconThemeData(color: settings.textColor),
                titleTextStyle: TextStyle(
                  color: settings.textColor,
                  fontSize: 20 * settings.textScaleFactor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              textTheme: TextTheme(
                bodyLarge: TextStyle(color: settings.textColor, fontSize: 16 * settings.textScaleFactor),
                bodyMedium: TextStyle(color: settings.textColor, fontSize: 14 * settings.textScaleFactor),
                labelLarge: TextStyle(color: settings.textColor, fontSize: 14 * settings.textScaleFactor),
              ),
              inputDecorationTheme: const InputDecorationTheme(
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF333333))),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                border: OutlineInputBorder(),
              ),
            ),
            home: settings.onboardingCompleted
                ? const LaunchScreen()
                : const OnboardingScreen(),
            routes: {
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA DE LANZAMIENTO (reemplaza HomeScreen)
// ─────────────────────────────────────────────────────────────────────────────

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});
  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RamMonitor>(context, listen: false).startMonitoring();
    });
  }

  // Navega a MediaPickerScreen → si hay ruta → EditorScreen correspondiente
  Future<void> _openEditor(MediaPickerType type) async {
    final String? path = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => MediaPickerScreen(type: type)),
    );
    if (!mounted || path == null) return;

    switch (type) {
      case MediaPickerType.video:
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => VideoEditorScreen(filePath: path)));
        break;
      case MediaPickerType.audio:
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => AudioEditorScreen(filePath: path)));
        break;
      case MediaPickerType.image:
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => ImageEditorScreen(filePath: path)));
        break;
    }
  }

  void _openCompress() {
    showDialog(
      context: context,
      builder: (_) => CompressionDialog(
        onApply: (CompressionPreset preset) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Preset "${preset.name}" listo — abre un archivo para aplicarlo'),
            backgroundColor: Colors.green,
          ));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context).settings;
    final ram = Provider.of<RamMonitor>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Row(children: [
          Icon(Icons.auto_awesome, color: settings.accentColor, size: 22),
          const SizedBox(width: 8),
          const Text('Premium Pro'),
        ]),
        actions: [
          if (ram.totalMB > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: GestureDetector(
                onTap: () => _showRamDialog(context, ram),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: ram.statusColor.withOpacity(0.15),
                    border: Border.all(color: ram.statusColor, width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.memory, size: 14, color: ram.statusColor),
                    const SizedBox(width: 4),
                    Text(ram.statusLabel,
                        style: TextStyle(color: ram.statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.settings, color: settings.textColor),
            tooltip: 'Ajustes',
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Qué deseas editar hoy?',
                style: TextStyle(color: settings.textColor.withOpacity(0.55), fontSize: 13),
              ),
              const SizedBox(height: 16),

              // ── Grid 2×2 ─────────────────────────────────────────────
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.05,
                children: [
                  _FeatureCard(
                    icon: Icons.videocam_rounded,
                    label: 'Editor de Video',
                    subtitle: 'H.264 · H.265 · VP9 · AV1',
                    color: Colors.blueAccent,
                    onTap: () => _openEditor(MediaPickerType.video),
                  ),
                  _FeatureCard(
                    icon: Icons.music_note_rounded,
                    label: 'Editor de Audio',
                    subtitle: 'AAC · MP3 · Opus · FLAC',
                    color: Colors.tealAccent,
                    onTap: () => _openEditor(MediaPickerType.audio),
                  ),
                  _FeatureCard(
                    icon: Icons.image_rounded,
                    label: 'Editor de Imagen',
                    subtitle: 'JPEG · PNG · WebP · AVIF',
                    color: Colors.purpleAccent,
                    onTap: () => _openEditor(MediaPickerType.image),
                  ),
                  _FeatureCard(
                    icon: Icons.compress_rounded,
                    label: 'Comprimir Media',
                    subtitle: 'Reducir tamaño de archivo',
                    color: Colors.orangeAccent,
                    onTap: _openCompress,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Línea de tiempo multicapa ──────────────────────────
              _WideButton(
                icon: Icons.movie_filter_rounded,
                label: 'Línea de Tiempo Multicapa',
                subtitle: 'Combina clips, transiciones y efectos',
                color: Colors.amberAccent,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MultiLayerTimeline())),
              ),

              const Spacer(),

              // ── Alerta RAM baja ────────────────────────────────────
              if (ram.isLow)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: ram.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ram.statusColor.withOpacity(0.4)),
                  ),
                  child: Row(children: [
                    Icon(Icons.warning_amber_rounded, color: ram.statusColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ram.isCritical
                            ? '⚠️ RAM crítica: cierra otras apps antes de procesar'
                            : '⚠️ RAM baja: el procesamiento puede ser más lento',
                        style: TextStyle(color: ram.statusColor, fontSize: 12),
                      ),
                    ),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRamDialog(BuildContext context, RamMonitor ram) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Uso de RAM', style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _ramRow('Total', ram.totalMB),
          _ramRow('En uso', ram.usedMB),
          _ramRow('Disponible', ram.availableMB),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ram.usedPercent.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(ram.statusColor),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 6),
          Text('${(ram.usedPercent * 100).toStringAsFixed(1)}% ocupado',
              style: TextStyle(color: ram.statusColor, fontSize: 13)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  Widget _ramRow(String label, int mb) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
        Text('$mb MB', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENTES REUTILIZABLES DE LA LAUNCH SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 10),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: color.withOpacity(0.65), fontSize: 10)),
          ),
        ]),
      ),
    );
  }
}

class _WideButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _WideButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              Text(subtitle, style: TextStyle(color: color.withOpacity(0.65), fontSize: 11)),
            ]),
          ),
          Icon(Icons.chevron_right, color: color.withOpacity(0.5)),
        ]),
      ),
    );
  }
}