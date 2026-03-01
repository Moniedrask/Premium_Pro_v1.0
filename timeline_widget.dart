import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/media_processor.dart';
import 'package:file_picker/file_picker.dart';

class TimelineWidget extends StatelessWidget {
  const TimelineWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final processor = Provider.of<MediaProcessor>(context);

    return Column(
      children: [
        // VISOR DE PREVISUALIZACIÓN
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            color: const Color(0xFF111111),
            child: Center(
              child: processor.isProcessing
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Colors.blueAccent),
                        const SizedBox(height: 20),
                        Text(processor.statusMessage, style: const TextStyle(color: Colors.white)),
                        Text("${(processor.progress * 100).toStringAsFixed(1)}%", style: const TextStyle(color: Colors.grey)),
                      ],
                    )
                  : const Icon(Icons.play_circle_outline, size: 80, color: Colors.grey),
            ),
          ),
        ),
        
        // CONTROLES Y TIMELINE
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF000000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("CONFIGURACIÓN DE EXPORTACIÓN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 10),
                
                // Selector de Códec
                DropdownButtonFormField<String>(                  value: 'libx264',
                  dropdownColor: const Color(0xFF111111),
                  items: const [
                    DropdownMenuItem(value: 'libx264', child: Text('H.264 (Compatible)', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'libx265', child: Text('H.265 (Eficiente)', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'libvpx-vp9', child: Text('VP9 (Web)', style: TextStyle(color: Colors.white))),
                  ],
                  onChanged: (val) {}, // Lógica de estado pendiente
                  decoration: const InputDecoration(labelText: 'Códec de Video'),
                ),
                
                const SizedBox(height: 10),
                
                // Slider de Calidad/Bitrate
                const Text('Bitrate (Calidad): 2500 kbps', style: TextStyle(color: Colors.white)),
                Slider(
                  value: 2500,
                  min: 500,
                  max: 10000,
                  divisions: 20,
                  activeColor: Colors.blueAccent,
                  onChanged: (val) {},
                ),

                // Switch IA
                SwitchListTile(
                  title: const Text('Activar Mejora IA (Experimental)', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Requiere descarga de modelos (Opcional)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  value: processor.aiEnabled,
                  activeColor: Colors.blueAccent,
                  onChanged: processor.toggleAI,
                ),

                const Spacer(),

                // BOTONES DE ACCIÓN
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // Lógica para seleccionar archivo
                          FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
                          if (result != null) {
                             // Aquí se llamaría a processor.processVideo
                             // Para demo, solo mostramos mensaje
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Archivo seleccionado. Listo para procesar.'))
                             );
                          }                        },
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Cargar Video'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: processor.isProcessing 
                          ? null 
                          : () {
                              // Iniciar proceso
                              processor.processVideo(
                                inputPath: '/sdcard/input.mp4', // Ejemplo
                                outputPath: '/sdcard/output.mp4',
                                codec: 'libx264',
                                bitrate: 2500,
                                preset: 'medium'
                              );
                            },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                        child: const Text('EXPORTAR', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ],
    );
    }
}