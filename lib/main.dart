import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/media_processor.dart';
import 'services/audio_processor.dart';
import 'services/image_processor.dart';
import 'services/ai_manager.dart';
import 'providers/settings_provider.dart'; // NUEVO
import 'screens/settings_screen.dart';     // NUEVO
import 'widgets/timeline_widget.dart';
import 'widgets/audio_timeline_widget.dart';
import 'widgets/image_editor_widget.dart';

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
        ChangeNotifierProvider(create: (_) => SettingsProvider()), // NUEVO
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
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
            home: const HomeScreen(),
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
        children: _pages,
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
    );
  }
}