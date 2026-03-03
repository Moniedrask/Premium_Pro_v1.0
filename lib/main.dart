import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/media_processor.dart';
import 'services/ai_manager.dart';
import 'widgets/timeline_widget.dart';
import 'screens/settings_screen.dart'; // Para acceso a configuración (nuevo)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Crear UNA SOLA instancia e inicializarla
  final processor = MediaProcessor();
  await processor.init();

  runApp(PremiumProApp(processor: processor));
}

class PremiumProApp extends StatelessWidget {
  final MediaProcessor processor;
  const PremiumProApp({super.key, required this.processor});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MediaProcessor>.value(value: processor),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
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