if (!aiManager.isDownloading && !aiManager.isModelAvailable)
  const Text(
    'Funciones IA no disponibles en esta versión',
    style: TextStyle(color: Colors.grey),
  ),
// (eliminar el TextButton que llamaba a downloadModel)