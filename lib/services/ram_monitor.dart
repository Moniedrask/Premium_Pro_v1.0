import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Monitorea el uso de RAM del dispositivo leyendo /proc/meminfo en Android.
/// Actualiza cada 3 segundos mientras esté activo.
class RamMonitor extends ChangeNotifier {
  int _totalMB = 0;
  int _availableMB = 0;
  int _usedMB = 0;
  Timer? _timer;

  int get totalMB => _totalMB;
  int get availableMB => _availableMB;
  int get usedMB => _usedMB;

  /// Fracción usada (0.0 – 1.0)
  double get usedPercent => _totalMB > 0 ? _usedMB / _totalMB : 0.0;

  /// RAM baja: más del 85 % ocupado
  bool get isLow => usedPercent > 0.85;

  /// RAM crítica: más del 95 % ocupado
  bool get isCritical => usedPercent > 0.95;

  Color get statusColor {
    if (isCritical) return const Color(0xFFFF3D00); // rojo
    if (isLow) return const Color(0xFFFFAB00);      // ámbar
    return const Color(0xFF00E676);                  // verde
  }

  String get statusLabel {
    if (_totalMB == 0) return 'RAM: —';
    return 'RAM $_usedMB/${_totalMB}MB';
  }

  /// Inicia el monitoreo periódico.
  void startMonitoring() {
    _readMemInfo();
    _timer ??= Timer.periodic(const Duration(seconds: 3), (_) => _readMemInfo());
  }

  /// Detiene el monitoreo.
  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _readMemInfo() async {
    if (!Platform.isAndroid) return;
    try {
      final content = await File('/proc/meminfo').readAsString();
      int? totalKb, availKb;
      for (final line in content.split('\n')) {
        final parts = line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
        if (parts.length >= 2) {
          if (parts[0] == 'MemTotal:') {
            totalKb = int.tryParse(parts[1]);
          } else if (parts[0] == 'MemAvailable:') {
            availKb = int.tryParse(parts[1]);
          }
        }
        if (totalKb != null && availKb != null) break;
      }
      if (totalKb != null && availKb != null) {
        _totalMB = totalKb ~/ 1024;
        _availableMB = availKb ~/ 1024;
        _usedMB = _totalMB - _availableMB;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('RamMonitor error: $e');
    }
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}