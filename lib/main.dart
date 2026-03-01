import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'services/media_processor.dart';
import 'services/ai_manager.dart';
import 'widgets/timeline_widget.dart';

void main() async {
  // Asegurar que Flutter esté inicializado antes de usar plugins
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar FFmpeg Kit para logs detallados
  FFmpegKitConfig.enableLogs(true);
  
  debugPrint('🎬 Iniciando Premium Pro v1.0 - Modo Estable');
  debugPrint('📱 Flutter SDK: ${WidgetsFlutterBinding.buildOwner.toString()}');
  
  runApp(const PremiumProApp());
}

class PremiumProApp extends StatelessWidget {
  const PremiumProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider para procesamiento multimedia
        ChangeNotifierProvider(create: (_) => MediaProcessor()),
        
        // Provider para gestión de IA
        ChangeNotifierProvider(create: (_) => AIManager()),
      ],
      child: MaterialApp(
        title: 'Premium Pro v1.0',
        debugShowCheckedModeBanner: false,
        
        // ==================== TEMA OLED PURO ====================
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF000000), // Negro puro OLED
          primaryColor: const Color(0xFF000000),
          
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF000000),
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          
          sliderTheme: const SliderThemeData(
            activeTrackColor: Colors.blueAccent,
            inactiveTrackColor: Colors.grey,
            thumbColor: Colors.white,
            overlayColor: Colors.blueAccent.withOpacity(0.2),
          ),
          
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Color(0xFF111111),
            border: OutlineInputBorder(),
            labelStyle: TextStyle(color: Colors.grey),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
          cardTheme: const CardTheme(
            color: Color(0xFF111111),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
        
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override  State<HomeScreen> createState() => _HomeScreenState();
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
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(),
            tooltip: 'Ayuda y Tutoriales',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(),
            tooltip: 'Configuración',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          TimelineWidget(),
          _PlaceholderScreen(title: 'Módulo Audio', subtitle: 'Próximamente en v1.1'),
          _PlaceholderScreen(title: 'Módulo Imagen', subtitle: 'Próximamente en v1.1'),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF000000),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
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
    showDialog(      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Ayuda Rápida', style: TextStyle(color: Colors.white)),
        content: const Text(
          '1️⃣ Selecciona un video con "Cargar Video"\n'
          '2️⃣ Ajusta parámetros en el panel inferior\n'
          '3️⃣ Presiona "EXPORTAR" para procesar\n\n'
          '💡 Nota: La IA está desactivada por defecto para máxima compatibilidad.',
          style: TextStyle(color: Colors.white70, height: 1.5),
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

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Configuración', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingItem(Icons.info, 'Versión', '1.0.0 Estable'),
            _buildSettingItem(Icons.storage, 'Carpeta de Salida', '/PremiumPro/'),
            _buildSettingItem(Icons.memory, 'RAM Detectada', 'Automático'),
            const Divider(color: Colors.grey),
            const Text(
              '⚠️ Esta es una versión beta. Reporta errores en GitHub.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }
  Widget _buildSettingItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PlaceholderScreen({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 80, color: Colors.grey[700]),
          const SizedBox(height: 24),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
