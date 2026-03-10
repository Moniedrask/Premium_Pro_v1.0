📄 README.md (Markdown)

```markdown
# 🎬 Premium Pro v1.0 - Editor Multimedia Profesional

**Editor y compresor profesional de Video, Audio e Imagen.**  
Optimizado para dispositivos de bajos recursos, sin publicidad, gratuito y 100% en español.

[![Build Status](https://github.com/tu-usuario/Premium_Pro_v1.0/actions/workflows/build.yml/badge.svg)](https://github.com/tu-usuario/Premium_Pro_v1.0/actions)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

---

## ✨ Características Principales

| Módulo | Funciones |
|--------|-----------|
| 🎥 **Video** | Corte preciso, Speed Ramp (0.1x–16x), Color Grading, LUTs, Estabilización, Texto animado, Transiciones, Interpolación de frames (IA opcional), **Aceleración hardware activable (MediaCodec)**. Presets de resolución: 144p, 240p, 360p, 480p, 720p, 1080p, 1440p, 4K, 8K. |
| 🎵 **Audio** | Waveform OpenGL, Ecualizador paramétrico de 10 bandas, Compresor, Normalización (LUFS), Reducción de ruido (IA opcional), Edición multipista, Fades, profundidad de bits 16/24/32 para FLAC/WAV, frecuencias de 22.05 a 192 kHz. |
| 🖼️ **Imagen** | HDR por capas (hasta 5 exposiciones), Escalado Lanczos4, Filtros profesionales (negativo, sepia, blanco y negro, desenfoque, bokeh), Ajustes precisos (brillo, contraste, saturación, etc.), Pincel básico, Upscaling IA (opcional) hasta 4x. |
| 🗜️ **Compresión** | H.264/H.265/VP9/AV1, Control CRF, Bitrate constante (CBR), Presets de velocidad (ultrafast a veryslow), **Aceleración hardware (MediaCodec)**. Bitrate de 50 a 15,000 kbps. |

- ✅ **Modo Oscuro OLED** (#000000 puro) para máximo ahorro energético.
- ✅ **Sin Publicidad** – Software libre y gratuito.
- ✅ **Sin IA por defecto** – Funciona offline sin descargas adicionales.
- ✅ **FFmpeg integrado** (vía AAR local) con soporte nativo para los códecs más modernos.
- ✅ **Gestor de presets** – Guarda y carga configuraciones personalizadas.
- ✅ **Papelera configurable** – Preguntar siempre o no al eliminar archivos.
- ✅ **Onboarding** – Pantalla de bienvenida con opción "No volver a mostrar".

---

## 📋 Requisitos del Sistema

### 🤖 Android

| Componente | Mínimo | Recomendado |
|------------|--------|-------------|
| **Sistema Operativo** | Android 8.0 (API 26) | Android 11+ (API 30+) |
| **RAM** | 2 GB | 4 GB o más |
| **Almacenamiento** | 250 MB libres + espacio para proyectos | 500 MB libres |
| **Procesador** | ARMv7 o ARM64 | Octa-core 2.0 GHz+ |
| **Pantalla** | 720p | 1080p+ |

---

## 🔐 Permisos Requeridos

- Android 12 o inferior: `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`
- Android 13+: `READ_MEDIA_VIDEO`, `READ_MEDIA_AUDIO`, `READ_MEDIA_IMAGES`
- `INTERNET` (solo para descarga opcional de modelos IA)
- `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_DATA_PROCESSING`

---

## 📁 Estructura del Proyecto (Principales carpetas y archivos)

```

Premium_Pro_v1.0/
├── .github/workflows/build.yml
├── android/
├── assets/ (fuentes, iconos, LUTs, modelos IA opcionales)
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── app_settings.dart
│   │   ├── video_settings.dart
│   │   ├── audio_settings.dart
│   │   ├── image_settings.dart
│   │   ├── compression_preset.dart
│   │   ├── timeline_layer.dart
│   │   └── ...
│   ├── providers/
│   │   └── settings_provider.dart
│   ├── services/
│   │   ├── ffmpeg_wrapper.dart
│   │   ├── media_processor.dart
│   │   ├── audio_processor.dart
│   │   ├── image_processor.dart
│   │   ├── ai_manager.dart
│   │   ├── hdr_service.dart
│   │   ├── stabilization.dart
│   │   └── trash_manager.dart
│   ├── widgets/
│   │   ├── timeline_widget.dart
│   │   ├── audio_timeline_widget.dart
│   │   ├── image_editor_widget.dart
│   │   ├── multi_layer_timeline.dart
│   │   ├── compression_dialog.dart
│   │   ├── equalizer_widget.dart
│   │   ├── filter_selector.dart
│   │   ├── video_effect_selector.dart
│   │   ├── hdr_merger_widget.dart
│   │   └── ...
│   └── screens/
│       ├── home_screen.dart
│       ├── settings_screen.dart
│       └── onboarding_screen.dart
├── pubspec.yaml
└── README.md

---
---

## 🛠️ Tecnologías Utilizadas

- **Framework:** Flutter 3.35.1 (Dart 3.5+)
- **Motor Multimedia:** `ffmpeg_kit_flutter_minimal` + AAR local (FFmpeg 6.0)
- **Gestión de Estado:** Provider
- **Renderizado de Audio:** OpenGL/Vulkan (vía FFmpeg)
- **Almacenamiento de Preferencias:** SharedPreferences
- **Selección de Archivos:** FilePicker
- **Reproducción de Audio:** audioplayers
- **Descarga de Modelos IA:** http + path_provider

---
---

## 🚀 Instalación

### Desde GitHub Actions (Recomendado)

1. Ve a la pestaña **Actions** de este repositorio.
2. Selecciona el último workflow exitoso (con check verde).
3. En **Artifacts**, descarga el archivo `premium-pro-apk.zip`.
4. Extrae y elige el APK correspondiente a tu dispositivo:

| Archivo | Arquitectura | Tamaño aprox. | Uso recomendado |
|---------|--------------|---------------|-----------------|
| `app-armeabi-v7a-release.apk` | ARMv7 (32 bits) | ~40 MB | Dispositivos muy antiguos |
| `app-arm64-v8a-release.apk` | ARM64 (64 bits) | **~21 MB** | **La mayoría de teléfonos modernos** |
| `app-x86_64-release.apk` | x86_64 (64 bits) | ~48 MB | Emuladores o dispositivos Intel (Chromebooks) |

5. Instala en tu dispositivo (permitir **fuentes desconocidas** si es necesario).

### Compilación Local

```bash
# Clona el repositorio
git clone https://github.com/tu-usuario/Premium_Pro_v1.0.git
cd Premium_Pro_v1.0

# Obtén dependencias
flutter pub get

# Compila APK release (dividido por ABI)
flutter build apk --release --split-per-abi

---
---

⚙️ Configuración

Ajustes Globales

Desde la pantalla principal, toca el icono de ⚙️ Ajustes para acceder a las opciones globales:

· Color de acento y color de texto personalizables.
· Densidad de interfaz (Compacto, Normal, Cómodo).
· Redondez de bordes (Cuadrado, Ligero, Redondeado).
· Carpeta de salida, formato de nombre de archivo, calidad por defecto.
· Papelera configurable (preguntar siempre, no preguntar).
· Onboarding (mostrar bienvenida al inicio).

Modo Sin IA (Por Defecto)

La aplicación funciona completamente sin descargar modelos de IA para garantizar:

· ✅ Compatibilidad universal
· ✅ Sin descargas adicionales
· ✅ Máxima estabilidad

Activar IA (Opcional)

1. Ve a Ajustes > Inteligencia Artificial.
2. Descarga el modelo deseado (1 GB – 8 GB).
3. Activa "Mejora IA" en exportación.

Aceleración Hardware (MediaCodec)

· En la pantalla de edición de video encontrarás un interruptor "Aceleración hardware".
· Activado por defecto: usa la GPU/MediaCodec del dispositivo para codificar más rápido y con menor consumo.
· Puedes desactivarlo si prefieres usar software.

Opciones en Exportación (Video, Audio, Imagen)

Cada editor incluye:

· Mantener nombre original (evita añadir timestamp).
· Guardar como permanente – Guarda la configuración actual como predeterminada.
· Presets de compresión (acceso rápido desde el botón flotante).

---

🧪 Códecs y Formatos Soportados

Tipo Códecs / Formatos Notas
Video H.264 (libx264), H.265 (libx265), VP9 CRF o CBR, bitrate 50-15000 kbps, presets de velocidad
Audio AAC, MP3, Opus, FLAC, WAV Profundidad de bits 16/24/32 para FLAC/WAV; frecuencias: 22.05, 32, 44.1, 48, 96, 192 kHz
Imagen JPEG, PNG, WebP, AVIF Calidad 1-100, compresión PNG 0-9, metadatos EXIF opcionales

---

⚠️ Limitaciones Conocidas

· Android <2 GB RAM: IA desactivada automáticamente (por estabilidad).
· Android 7.0 o inferior: No compatible (requiere API 26+).
· Sin conexión a Internet: IA requiere descarga previa; la app base funciona 100% offline.
· Dispositivos sin MediaCodec: Codificación por software (más lenta).

---

📄 Licencia

GPL-3.0 - Software libre y gratuito. Sin publicidad.
