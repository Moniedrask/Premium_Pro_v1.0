import 'package:flutter/material.dart';

class TooltipWithPreview extends StatelessWidget {
  final String title;
  final String description;
  final Widget beforeImage;
  final Widget afterImage;
  final Widget child;

  const TooltipWithPreview({
    super.key,
    required this.title,
    required this.description,
    required this.beforeImage,
    required this.afterImage,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF111111),
            title: Text(title, style: const TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(description, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Antes', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          beforeImage,
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Después', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          afterImage,
                        ],
                      ),
                    ),
                  ],
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
      },
      child: Tooltip(
        message: description,
        child: child,
      ),
    );
  }
}