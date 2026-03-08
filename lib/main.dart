import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/media_processor.dart';
import 'services/audio_processor.dart';
import 'services/image_processor.dart';
import 'services/ai_manager.dart';
import 'providers/settings_provider.dart';
import 'screens/settings_screen.dart';
import 'screens/onboarding_screen.dart';
import 'widgets/timeline_widget.dart';
import 'widgets/audio_timeline_widget.dart';
import 'widgets/image_editor_widget.dart';
import 'widgets/compression_dialog.dart';
import 'models/compression_preset.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final videoProcessor = MediaProcessor();
  final audioProcessor = AudioProcessor();
  final imageProcessor = ImageProcessor();

  await Future.wait([
    videoProcessor.init(),
    audioProcessor.init(),
    imageProcessor.init(),
  ]);

  runApp(PremiumProApp(
    videoProcessor: videoProcessor,
    audioProcessor: audioProcessor,
    imageProcessor: imageProcessor,
  ));
}

class PremiumProApp extends StatelessWidget {
  final MediaProcessor videoProcessor;
  final AudioProcessor audioProcessor;
  final ImageProcessor imageProcessor;

  const PremiumProApp({
    super.key,
    required this.videoProcessor,
    required this.audioProcessor,
    required this.imageProcessor,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MediaProcessor>.value(value: videoProcessor),
        ChangeNotifierProvider<AudioProcessor>.value(value: audioProcessor),
        ChangeNotifierProvider<ImageProcessor>.value(value: imageProcessor),
        ChangeNotifierProvider(create: (_) => AIManager()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          // Cargar presets de usuario al inicio
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
            ),
            routes: {
              '/home': (context) => const HomeScreen(),
            },
            home: settings.onboardingCompleted
                ? const HomeScreen()
                : const OnboardingScreen(),
          );
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    TimelineWidget(),
    AudioTimelineWidget(),
    ImageEditorWidget(),
  ];

  // Claves para acceder a los estados de los widgets
  final _timelineKey = GlobalKey<_TimelineWidgetState>();
  final _audioKey = GlobalKey<_AudioTimelineWidgetState>();
  final _imageKey = GlobalKey<_ImageEditorWidgetState>();

  void _applyCompressionPreset(CompressionPreset preset) {
    switch (_currentIndex) {
      case 0:
        _timelineKey.currentState?.applyPreset(preset.videoSettings);
        break;
      case 1:
        _audioKey.currentState?.applyPreset(preset.audioSettings);
        break;
      case 2:
        _imageKey.currentState?.applyPreset(preset.imageSettings);
        break;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Preset "${preset.name}" aplicado'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context).settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Pro v1.0'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: settings.textColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          TimelineWidget(key: _timelineKey),
          AudioTimelineWidget(key: _audioKey),
          ImageEditorWidget(key: _imageKey),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF000000),
        selectedItemColor: settings.accentColor,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'Video'),
          BottomNavigationBarItem(icon: Icon(Icons.music_note), label: 'Audio'),
          BottomNavigationBarItem(icon: Icon(Icons.image), label: 'Imagen'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => CompressionDialog(
              onApply: _applyCompressionPreset,
            ),
          );
        },
        child: const Icon(Icons.compress),
      ),
    );
  }
}