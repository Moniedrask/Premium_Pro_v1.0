import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../widgets/timeline_widget.dart';
import '../providers/settings_provider.dart';

/// Pantalla completa del editor de video.
/// Recibe la ruta del archivo ya seleccionado, pausa el video cuando la app
/// pasa a segundo plano (WidgetsBindingObserver).
class VideoEditorScreen extends StatefulWidget {
  final String filePath;
  const VideoEditorScreen({super.key, required this.filePath});

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen>
    with WidgetsBindingObserver {
  final _timelineKey = GlobalKey<TimelineWidgetState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Cargar el archivo después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timelineKey.currentState?.loadFile(widget.filePath);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Pausa el video cuando la app va a background o se oculta
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _timelineKey.currentState?.pauseVideo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context).settings;

    return Scaffold(
      // resizeToAvoidBottomInset: false evita el bug de pantalla negra
      // cuando el teclado aparece/desaparece en layouts con Expanded.
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Editor de Video'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: settings.textColor),
            tooltip: 'Ajustes',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: GestureDetector(
        // Toca fuera de un TextField → cierra teclado
        onTap: () {
          FocusScope.of(context).unfocus();
          SystemChannels.textInput.invokeMethod('TextInput.hide');
        },
        behavior: HitTestBehavior.translucent,
        child: TimelineWidget(key: _timelineKey),
      ),
    );
  }
}