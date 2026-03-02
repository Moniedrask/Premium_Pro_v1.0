import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'services/media_processor.dart';
import 'services/ai_manager.dart';
import 'widgets/timeline_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FFmpegKitConfig.enableLogs();
  runApp(const PremiumProApp());
}

// ... resto del archivo igual ...
