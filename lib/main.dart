import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit_config.dart';
import 'services/media_processor.dart';
import 'services/ai_manager.dart';
import 'widgets/timeline_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FFmpegKitConfig.enableLogs(true);
  runApp(const PremiumProApp());
}

class PremiumProApp extends StatelessWidget {
  const PremiumProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MediaProcessor()),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Pro v1.0'),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          TimelineWidget(),
          Center(child: Text('Audio - Próximamente', style: TextStyle(color: Colors.grey))),
          Center(child: Text('Imagen - Próximamente', style: TextStyle(color: Colors.grey))),
        ],
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
