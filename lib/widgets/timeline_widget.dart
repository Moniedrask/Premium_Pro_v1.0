// Dentro de _TimelineWidgetState, añadir:

String _getExtensionForCodec(String codec) {
  switch (codec) {
    case 'libvpx-vp9':
      return 'webm';
    case 'libx265':
      return 'mp4'; // HEVC también usa .mp4
    default:
      return 'mp4';
  }
}

// Modificar _exportVideo para usar la extensión correcta:

final ext = _getExtensionForCodec(_codec);
final String outputPath = '$outputFolder/premium_export_$timestamp.$ext';

// Añadir botón de cancelar en _buildControls (justo después de los botones existentes o dentro de _buildActionButtons):

if (processor.isProcessing) {
  return Row(
    children: [
      Expanded(
        child: ElevatedButton(
          onPressed: processor.cancelProcessing,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('CANCELAR', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    ],
  );
} else {
  // el Row original con CARGAR y EXPORTAR
}

// También asegurar que el método cancelProcessing exista en MediaProcessor (ya lo añadimos).