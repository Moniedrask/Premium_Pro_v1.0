import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/media_processor.dart';
import 'services/audio_processor.dart';      // nuevo
import 'services/image_processor.dart';      // nuevo
import 'services/ai_manager.dart';
import 'widgets/timeline_widget.dart';
import 'widgets/audio_timeline_widget.dart'; // nuevo
import 'widgets/image_editor_widget.dart';   // nuevo

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
      ],
      child: MaterialApp(
        title: 'Premium Pro v1.0',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF000000),
          primaryColor: const Color(0xFF000000),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF000000),
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
          ),
        ),
        home: const HomeScreen(),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Pro v1.0'),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF000000),
        selectedItemColor: Colors.blueAccent,
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