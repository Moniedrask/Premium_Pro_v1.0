import 'package:flutter/material.dart';

/// Muestra un ícono "?" que al pulsarse abre un diálogo con el título
/// y una descripción de texto de para qué sirve la función.
class TooltipWithPreview extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;

  const TooltipWithPreview({
    super.key,
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF111111),
                title: Text(title, style: const TextStyle(color: Colors.white)),
                content: Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cerrar', style: TextStyle(color: Colors.blueAccent)),
                  ),
                ],
              ),
            );
          },
          child: const Icon(Icons.help_outline, size: 18, color: Colors.grey),
        ),
      ],
    );
  }
}