import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../widgets/audio_timeline_widget.dart';
import '../providers/settings_provider.dart';

/// Pantalla completa del editor de audio.
/// Recibe la ruta del archivo ya seleccionado, pausa el audio cuando la app
/// pasa a segundo plano (WidgetsBindingObserver).
class AudioEditorScreen extends StatefulWidget {
  final String filePath;
  const AudioEditorScreen({super.key, required this.filePath});

  @override
  State<AudioEditorScreen> createState() => _AudioEditorScreenState();
}

class _AudioEditorScreenState extends State<AudioEditorScreen>
    with WidgetsBindingObserver {
  final _audioKey = GlobalKey<AudioTimelineWidgetState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _audioKey.currentState?.loadFile(widget.filePath);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _audioKey.currentState?.pausePlayback();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context).settings;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Editor de Audio'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: settings.textColor),
            tooltip: 'Ajustes',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          SystemChannels.textInput.invokeMethod('TextInput.hide');
        },
        behavior: HitTestBehavior.translucent,
        child: AudioTimelineWidget(key: _audioKey),
      ),
    );
  }
}