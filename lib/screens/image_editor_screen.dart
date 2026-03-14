import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../widgets/image_editor_widget.dart';
import '../providers/settings_provider.dart';

/// Pantalla completa del editor de imagen.
/// Recibe la ruta del archivo ya seleccionado.
class ImageEditorScreen extends StatefulWidget {
  final String filePath;
  const ImageEditorScreen({super.key, required this.filePath});

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  final _imageKey = GlobalKey<ImageEditorWidgetState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _imageKey.currentState?.loadFile(widget.filePath);
    });
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
        title: const Text('Editor de Imagen'),
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
        child: ImageEditorWidget(key: _imageKey),
      ),
    );
  }
}