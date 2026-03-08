Future<void> _exportVideo(MediaProcessor processor) async {
  if (_selectedVideoPath == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('❌ Primero selecciona un video'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  try {
    // Obtener información del video original
    final durationMicros = await processor.getVideoDuration(_selectedVideoPath!);
    final originalFps = await processor.getVideoFps(_selectedVideoPath!);
    
    // Para dimensiones, necesitaríamos FFprobe o un paquete externo
    // Simulamos valores comunes por ahora (esto debería mejorarse)
    int originalWidth = 1920;
    int originalHeight = 1080;

    if (durationMicros == null || durationMicros <= 0) {
      debugPrint('⚠️ No se pudo obtener la duración del video, el progreso será aproximado');
    }

    if (originalFps == null || originalFps <= 0) {
      debugPrint('⚠️ No se pudo obtener el FPS original');
    }

    final Directory? directory = await getExternalStorageDirectory();
    if (directory == null) {
      throw Exception('No se pudo acceder al almacenamiento');
    }

    final String outputFolder = '${directory.path}/PremiumPro';
    await Directory(outputFolder).create(recursive: true);

    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = _getExtensionForCodec(_settings.videoCodec);

    String outputPath;
    if (_keepOriginalName) {
      final originalName = _selectedVideoName.split('.').first;
      outputPath = '$outputFolder/${originalName}_premium.$ext';
    } else {
      outputPath = '$outputFolder/premium_export_$timestamp.$ext';
    }

    debugPrint('📁 Input: $_selectedVideoPath');
    debugPrint('📁 Output: $outputPath');
    debugPrint('⚙️ Config: ${_settings.videoCodec} | ${_settings.videoBitrate} kbps | ${_settings.preset} | CRF ${_settings.crf} | HW Accel: ${_settings.hardwareAcceleration}');
    debugPrint('📊 Escalado: ${_settings.resolutionUpscale ? "${_settings.targetWidth}x${_settings.targetHeight}" : "No"}');
    debugPrint('📊 Interpolación: ${_settings.frameInterpolation ? "${_settings.targetFps}fps" : "No"} (original: ${originalFps ?? "?"}fps)');

    final bool success = await processor.processVideo(
      inputPath: _selectedVideoPath!,
      outputPath: outputPath,
      settings: _settings,
      totalDurationMicros: durationMicros,
      originalFps: originalFps,
      originalWidth: originalWidth,
      originalHeight: originalHeight,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✅ Exportación completada' : '❌ Error en exportación'),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    if (success) {
      debugPrint('✅ Exportación exitosa: $outputPath');
      setState(() {
        _selectedVideoPath = null;
        _selectedVideoName = 'Ninguno';
      });
    }
  } catch (e) {
    debugPrint('❌ Error en exportación: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error crítico: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}