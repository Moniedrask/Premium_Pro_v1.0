# 🎬 Premium Pro v1.0 - Editor Multimedia Profesional

**Editor y compresor profesional de Video, Audio e Imagen.**  
Optimizado para dispositivos de bajos recursos, sin publicidad, gratuito y 100% en español.

[![Build Status](https://github.com/tu-usuario/Premium_Pro_v1.0/actions/workflows/build.yml/badge.svg)](https://github.com/tu-usuario/Premium_Pro_v1.0/actions)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

---

## ✨ Características Principales

| Módulo | Funciones |
|--------|-----------|
| 🎥 **Video** | Corte preciso (ms), Speed Ramp (0.1x–16x), Color Grading (curvas, ruedas, LUTs .cube), Estabilización, Texto animado, Transiciones, Interpolación de frames (IA opcional), **Aceleración hardware activable (MediaCodec)** |
| 🎵 **Audio** | Waveform OpenGL, Ecualizador paramétrico de 10 bandas, Compresor, Normalización (LUFS), Reducción de ruido (IA opcional), Edición multipista, Fades |
| 🖼️ **Imagen** | HDR por capas (hasta 5 exposiciones), Escalado Lanczos4, Filtros profesionales, Ajustes precisos, Pincel básico, Upscaling IA (opcional) |
| 🗜️ **Compresión** | H.264/H.265/VP9/AV1, Control CRF, Bitrate, Presets, **Aceleración hardware (MediaCodec) con interruptor** |
| ⚙️ **Ajustes Globales** | Personalización de color de acento, color de texto, tamaño de interfaz, opciones de exportación predeterminadas (mantener nombre original, guardar configuraciones como permanentes) |

- ✅ **Modo Oscuro OLED** (#000000 puro) inalterable (fondo negro fijo).
- ✅ **Sin Publicidad** – Software libre y gratuito.
- ✅ **Sin IA por defecto** (funciona 100% offline, modelos opcionales).
- ✅ **FFmpeg integrado** vía AAR local (sin dependencia de servidores externos).

---

## 📋 Requisitos del Sistema

### 🤖 ANDROID

| Componente | Mínimo | Recomendado |
|------------|--------|-------------|
| **Sistema Operativo** | Android 8.0 (API 26) o superior | Android 11+ (API 30+) |
| **RAM** | 2 GB mínimo | 4 GB o más |
| **Almacenamiento** | 250 MB libres + espacio para proyectos | 500 MB libres + espacio |
| **Procesador** | ARMv7 (armeabi-v7a) o ARM64 (arm64-v8a) | Octa-core 2.0 GHz+ |
| **Pantalla** | Resolución mínima 720p | 1080p+ |

### 🖥️ WINDOWS (Cuando esté disponible)

| Componente | Mínimo | Recomendado |
|------------|--------|-------------|
| **SO** | Windows 10 64-bit (1903+) | Windows 11 64-bit |
| **RAM** | 4 GB mínimo | 8 GB o más |
| **Procesador** | Intel Core i3 (4ª gen) | Intel Core i5/i7 (8ª gen+) |
| **Gráficos** | DirectX 11 compatible | GPU dedicada con 2 GB VRAM |
| **Pantalla** | 1280x720 | 1920x1080 |

---

## 🔐 Permisos Requeridos (Android)

- Android 12 o inferior: `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`
- Android 13+: `READ_MEDIA_VIDEO`, `READ_MEDIA_AUDIO`, `READ_MEDIA_IMAGES`
- `INTERNET` (solo para descarga opcional de modelos IA)
- `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_DATA_PROCESSING`

---

## 📁 Estructura del Proyecto (Archivos Principales)

```

Premium_Pro_v1.0/
│
├── 📄 pubspec.yaml                                    # Dependencias (ffmpeg_kit_flutter 6.0.3, provider, etc.)
├── 📄 README.md                                       # Este archivo
├── 📄 .gitignore
├── 📄 analysis_options.yaml
│
├── 📁 .github/
│   └── 📁 workflows/
│       └── 📄 build.yml                               # Workflow: descarga AAR, compila APKs separados + universal
│
├── 📁 android/                                        # Configuración nativa (Gradle, manifiesto, AAR local)
│   ├── 📄 build.gradle
│   ├── 📄 settings.gradle
│   ├── 📄 gradle.properties
│   ├── 📁 gradle/wrapper/
│   └── 📁 app/
│       ├── 📄 build.gradle                            # Dependencias locales + resolución de FFmpeg
│       ├── 📁 libs/                                    # Contiene ffmpeg-kit-fix.aar (descargado en CI)
│       └── 📁 src/main/
│           ├── 📄 AndroidManifest.xml
│           ├── 📁 kotlin/com/premiumpro/editor/MainActivity.kt
│           └── 📁 res/                                 # Recursos (estilos, imágenes, etc.)
│
├── 📁 assets/                                          # Recursos estáticos (iconos, LUTs, modelos IA)
│   ├── 📁 fonts/
│   ├── 📁 icons/
│   ├── 📁 luts/
│   └── 📁 models/
│
├── 📁 lib/
│   ├── 📄 main.dart                                    # Punto de entrada, tema dinámico y providers
│   │
│   ├── 📁 models/
│   │   ├── 📄 app_settings.dart                        # Modelo de configuración global (color, tamaño, etc.)
│   │   ├── 📄 video_settings.dart                       # Configuración de video (incluye saveAsDefault)
│   │   ├── 📄 audio_settings.dart
│   │   ├── 📄 image_settings.dart
│   │   └── 📄 project_config.dart
│   │
│   ├── 📁 providers/
│   │   └── 📄 settings_provider.dart                   # Provider para ajustes globales
│   │
│   ├── 📁 screens/
│   │   └── 📄 settings_screen.dart                     # Pantalla de ajustes (color, texto, opciones de exportación)
│   │
│   ├── 📁 services/
│   │   ├── 📄 ffmpeg_wrapper.dart                      # Abstracción de FFmpeg con progreso híbrido
│   │   ├── 📄 media_processor.dart                      # Procesador de video (usa VideoSettings)
│   │   ├── 📄 audio_processor.dart
│   │   ├── 📄 image_processor.dart
│   │   └── 📄 ai_manager.dart                           # Gestión de modelos IA (descarga, estado)
│   │
│   └── 📁 widgets/
│       ├── 📄 timeline_widget.dart                      # Editor de video con interruptor HW, barra de progreso, checkboxes
│       ├── 📄 audio_timeline_widget.dart                # Editor de audio con waveform y controles
│       ├── 📄 image_editor_widget.dart                  # Editor de imagen con vista previa
│       └── 📄 settings_panel.dart                        # Panel de configuración (obsoleto, mantenido por compatibilidad)
│
├── 📁 test/                                             # Pruebas (esqueleto)
│
├── 📁 build/                                            # Generado (no commitear)
├── 📁 .dart_tool/                                       # Generado (no commitear)
├── 📁 .idea/                                            # Local (no commitear)
└── 📁 .vscode/                                          # Local (no commitear)

```

---

## 🛠️ Tecnologías Utilizadas

- **Framework:** Flutter 3.35.1 (Dart 3.5+)
- **Motor Multimedia:** FFmpegKit 6.0.3 (integrado localmente vía AAR)
- **Gestión de Estado:** Provider
- **Renderizado de Audio:** OpenGL/Vulkan (vía FFmpeg)
- **Almacenamiento de Preferencias:** SharedPreferences
- **Selección de Archivos:** FilePicker
- **Reproducción de Audio:** audioplayers
- **Selector de Color:** flutter_colorpicker
- **Descarga de Modelos IA:** http + path_provider

---

## 🚀 Instalación

### Desde GitHub Actions (Recomendado)

1. Ve a la pestaña **Actions** de este repositorio.
2. Selecciona el último workflow exitoso (con check verde).
3. En **Artifacts**, descarga el archivo `premium-pro-apk.zip`.
4. Extrae y elige el APK correspondiente a tu dispositivo:

| Archivo | Arquitectura | Tamaño aprox. | Uso recomendado |
|---------|--------------|---------------|-----------------|
| `app-armeabi-v7a-release.apk` | ARMv7 (32 bits) | ~40 MB | Dispositivos muy antiguos o de gama baja |
| `app-arm64-v8a-release.apk` | ARM64 (64 bits) | ~45 MB | **La mayoría de teléfonos modernos** |
| `app-x86_64-release.apk` | x86_64 (64 bits) | ~48 MB | Emuladores o dispositivos Intel (Chromebooks) |
| `app-release.apk` | Universal (todas) | ~90 MB | Si no estás seguro de la arquitectura |

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

# (Opcional) Compila APK universal
flutter build apk --release
```

---

⚙️ Configuración

Ajustes Globales (Nuevo)

Desde la pantalla principal, toca el icono de ⚙️ Ajustes en la barra superior para acceder a las opciones globales:

· Color de acento: Elige el color que prefieras para los elementos interactivos (botones, sliders, etc.). El fondo permanece negro OLED puro.
· Color de texto: Personaliza el color del texto en toda la app.
· Tamaño de texto: Ajusta la escala del texto (de 0.8x a 1.5x).
· Mantener nombre original: Si está activado, al exportar no se añadirá un timestamp al nombre del archivo (se usará el nombre original con sufijo "_premium").
· Guardar configuraciones como predeterminadas: Cuando marcas esta opción en cualquier editor, la configuración actual se guarda como predeterminada para futuras exportaciones.

Modo Sin IA (Por Defecto)

La aplicación funciona completamente sin descargar modelos de IA para garantizar:

· ✅ Compatibilidad universal
· ✅ Sin descargas adicionales
· ✅ Máxima estabilidad

Activar IA (Opcional)

1. Ve a Ajustes > Inteligencia Artificial (dentro de la app).
2. Descarga el modelo deseado (1 GB – 8 GB).
3. Activa "Mejora IA" en exportación.

Aceleración Hardware (MediaCodec)

· En la pantalla de edición de video encontrarás un interruptor "Aceleración hardware".
· Activado por defecto: usa la GPU/MediaCodec del dispositivo para codificar más rápido y con menor consumo.
· Si encuentras problemas de compatibilidad con algún archivo, puedes desactivarlo.

Opciones en Exportación (Video, Audio, Imagen)

Cada editor incluye dos nuevas casillas:

· Mantener nombre original (hereda el valor global, pero puedes cambiarlo localmente).
· Guardar como permanente – Al marcarla, la configuración actual se guarda como predeterminada en los ajustes globales.

---

🧪 Códecs y Formatos Soportados

Tipo Códecs / Formatos Notas
Video H.264 (libx264), H.265 (libx265), VP9, AV1 Control CRF, bitrate, presets; aceleración hardware (h264_mediacodec / hevc_mediacodec) activable
Audio AAC, MP3, Opus, FLAC, WAV (PCM) Frecuencias: 44.1, 48, 96, 192 kHz; canales mono/estéreo
Imagen JPEG, PNG, WebP, AVIF Calidad ajustable (1-100), compresión PNG (0-9), metadatos opcionales

---

⚠️ Limitaciones Conocidas

Escenario Limitación
Android <2 GB RAM IA desactivada automáticamente (por estabilidad)
Android 7.0 o inferior No compatible (requiere API 26+)
Sin conexión a Internet IA requiere descarga previa; la app base funciona 100% offline
Dispositivos sin MediaCodec Codificación por software (más lenta)
Modelos IA muy pesados Requieren al menos 4 GB de RAM libre durante el procesamiento

---

📦 Archivos APK Generados

El workflow de GitHub Actions produce los siguientes archivos en el artifact premium-pro-apk.zip:

Archivo Arquitectura Tamaño aprox. Uso recomendado
app-armeabi-v7a-release.apk ARMv7 (32 bits) ~40 MB Dispositivos muy antiguos o de gama baja
app-arm64-v8a-release.apk ARM64 (64 bits) ~45 MB La mayoría de teléfonos modernos
app-x86_64-release.apk x86_64 (64 bits) ~48 MB Emuladores o dispositivos Intel (Chromebooks)
app-release.apk Universal (todas) ~90 MB Si no estás seguro de la arquitectura

Recomendación: Elige siempre el APK específico para tu arquitectura (el universal solo si es necesario). Puedes verificar la arquitectura de tu dispositivo con apps como "Droid Hardware Info".

---

📄 Licencia

GPL-3.0 - Software libre y gratuito. Sin publicidad.

---

🐛 Reportar Problemas

Abre un Issue en GitHub con:

· Dispositivo y versión de Android.
· Pasos para reproducir el error.
· Logs relevantes (puedes obtenerlos desde Ajustes > Ver Logs dentro de la app).

---

Desarrollado con ❤️ para la comunidad hispanohablante.
¡Gracias por usar Premium Pro!

```