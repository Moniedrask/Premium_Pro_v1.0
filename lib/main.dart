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
import 'widgets/multi_layer_timeline.dart';
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
    // Si hay error de inicio, mostrar pantalla de error
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
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          // Cargar presets después del primer frame
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
              '/timeline': (context) => const MultiLayerTimeline(),
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

  final _timelineKey = GlobalKey<TimelineWidgetState>();
  final _audioKey = GlobalKey<AudioTimelineWidgetState>();
  final _imageKey = GlobalKey<ImageEditorWidgetState>();

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
            icon: Icon(Icons.timeline, color: settings.textColor),
            onPressed: () => Navigator.pushNamed(context, '/timeline'),
          ),
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