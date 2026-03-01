import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/media_processor.dart';
import 'widgets/timeline_widget.dart';

void main() {
  // Configuración de seguridad y logs
  debugPrint('Iniciando Premium Pro v1.0 - Modo Estable');
  runApp(const PremiumProApp());
}

class PremiumProApp extends StatelessWidget {
  const PremiumProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MediaProcessor()),
      ],
      child: MaterialApp(
        title: 'Premium Pro v1.0',
        debugShowCheckedModeBanner: false,
        // ARQUITECTURA OLED: Fondo negro puro para ahorro de batería
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF000000), // Negro Puro
          primaryColor: const Color(0xFF000000),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF000000),
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          sliderTheme: const SliderThemeData(
            activeTrackColor: Colors.blueAccent,
            inactiveTrackColor: Colors.grey,
            thumbColor: Colors.white,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Color(0xFF111111),
            border: OutlineInputBorder(),
            labelStyle: TextStyle(color: Colors.grey),
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
        title: const Text('Premium Pro v1.0', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(),
            tooltip: 'Ayuda y Tutoriales',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          TimelineWidget(), // Editor Principal
          Center(child: Text('Módulo Audio (En desarrollo v1.0)', style: TextStyle(color: Colors.grey))),
          Center(child: Text('Módulo Imagen (En desarrollo v1.0)', style: TextStyle(color: Colors.grey))),
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

  void _showHelpDialog() {
    showDialog(
      context: context,      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Ayuda Rápida'),
        content: const Text(
          '1. Selecciona un video.\n2. Ajusta parámetros en el panel inferior.\n3. Usa el botón de exportar.\n\nNota: La IA está desactivada por defecto para máxima compatibilidad.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }
}
