# 🎬 Premium Pro v1.0 - Editor Multimedia Profesional

Editor y compresor profesional de Video, Audio e Imagen.

[![Build Status](https://github.com/tu-usuario/Premium_Pro_v1.0/actions/workflows/build.yml/badge.svg)](https://github.com/tu-usuario/Premium_Pro_v1.0/actions)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

Editor y compresor profesional de Imagen, Audio y Video multiplataforma (Android/Windows), optimizado para dispositivos de bajos recursos.

## ✨ Características Principales

| Módulo | Funciones |
|--------|-----------|
| 🎥 Video | Corte preciso, Speed Ramp (0.1x-16x), Color Grading, LUTs, Estabilización, Texto animado, Transiciones, Interpolación de frames (IA opcional), **Aceleración hardware activable (MediaCodec)** |
| 🎵 Audio | Waveform OpenGL, Ecualizador 10 bandas, Compresor, Normalización (LUFS), Reducción de ruido (IA opcional), Edición multipista, Fades |
| 🖼️ Imagen | HDR por capas, Escalado Lanczos4, Filtros profesionales, Ajustes precisos, Pincel básico, Upscaling IA (opcional) |
| 🗜️ Compresión | H.264/H.265/VP9/AV1, Control CRF, Bitrate, Presets, **Aceleración hardware (MediaCodec) con interruptor** |

- ✅ Modo Oscuro OLED (#000000 puro)
- ✅ Sin Publicidad
- ✅ Sin IA por defecto (funciona 100% offline)
- ✅ FFmpeg integrado (vía AAR local)

# 📋 REQUISITOS COMPLETOS - PREMIUM PRO v1.0

---

## 🤖 ANDROID

### Requisitos Mínimos
| Componente | Requisito |
|------------|-----------|
| **Sistema Operativo** | Android 8.0 (API 26) o superior |
| **RAM** | 2 GB mínimo |
| **Almacenamiento** | 250 MB libres (instalación) + espacio para proyectos |
| **Procesador** | ARMv7 (armeabi-v7a) o ARM64 (arm64-v8a) |
| **Pantalla** | Resolución mínima 720p |

### Requisitos Recomendados
| Componente | Requisito |
|------------|-----------|
| **Sistema Operativo** | Android 11 (API 30) o superior |
| **RAM** | 4 GB o superior |
| **Almacenamiento** | 500 MB libres + espacio para proyectos |
| **Procesador** | Octa-core 2.0 GHz o superior |
| **Pantalla** | Resolución 1080p o superior |

### Permisos Requeridos
- `READ_EXTERNAL_STORAGE` (Android 12 o inferior)
- `READ_MEDIA_VIDEO`, `READ_MEDIA_AUDIO`, `READ_MEDIA_IMAGES` (Android 13+)
- `WRITE_EXTERNAL_STORAGE` (Android 12 o inferior)
- `INTERNET` (solo para descarga opcional de modelos IA)
- `ACCESS_NETWORK_STATE`
- `WAKE_LOCK`
- `FOREGROUND_SERVICE`
- `FOREGROUND_SERVICE_DATA_PROCESSING`

---

## 🖥️ WINDOWS (Cuando esté disponible)

### Requisitos Mínimos
| Componente | Requisito |
|------------|-----------|
| **Sistema Operativo** | Windows 10 (64-bit) versión 1903 o superior |
| **RAM** | 4 GB mínimo |
| **Almacenamiento** | 500 MB libres (instalación) + espacio para proyectos |
| **Procesador** | Intel Core i3 o equivalente AMD (4ª generación o superior) |
| **Gráficos** | DirectX 11 compatible |
| **Pantalla** | Resolución mínima 1280x720 |

### Requisitos Recomendados
| Componente | Requisito |
|------------|-----------|
| **Sistema Operativo** | Windows 11 (64-bit) |
| **RAM** | 8 GB o superior |
| **Almacenamiento** | 1 GB libres + espacio para proyectos |
| **Procesador** | Intel Core i5/i7 o equivalente AMD (8ª generación o superior) |
| **Gráficos** | GPU dedicada con 2 GB VRAM (NVIDIA/AMD) |
| **Pantalla** | Resolución 1920x1080 o superior |

### Permisos Requeridos
- Acceso al sistema de archivos (lectura/escritura)
- Acceso a Internet (solo para descarga opcional de modelos IA)

---

## 🎬 REQUISITOS ADICIONALES POR FUNCIÓN

### Para Procesamiento de Video
| Función | Requisito Adicional |
|---------|---------------------|
| Exportación H.264 | Soporte hardware MediaCodec (Android) / DXVA2 (Windows) |
| Exportación H.265 | Android 10+ o Windows 11 con GPU compatible |
| Video 4K | 4 GB RAM mínimo, 6 GB recomendado |
| Interpolación de Frames (IA) | 6 GB RAM mínimo, modelo IA descargado (2-4 GB) |

### Para Procesamiento de Audio
| Función | Requisito Adicional |
|---------|---------------------|
| Audio 32-bit float | 2 GB RAM mínimo |
| Reducción de Ruido IA | 4 GB RAM mínimo, modelo IA descargado |

### Para Procesamiento de Imagen
| Función | Requisito Adicional |
|---------|---------------------|
| Imágenes hasta 4K | 2 GB RAM mínimo |
| Imágenes 8K (8192x8192) | 6 GB RAM mínimo |
| Upscaling IA (2x-16x) | 4 GB RAM mínimo, modelo IA descargado (1-8 GB) |
| HDR por capas | 4 GB RAM mínimo |

---

## 📦 ESPACIO EN DISCO REQUERIDO

| Componente | Espacio Requerido |
|------------|-------------------|
| **Instalación Base** | 250 MB (Android) / 500 MB (Windows) |
| **Modelos IA (Opcional)** | 1 GB (Móvil) / 4 GB (Equilibrado) / 8 GB+ (Desktop) |
| **Caché de Procesamiento** | 500 MB - 2 GB (dependiendo del proyecto) |
| **Total Recomendado** | 2 GB libres (sin IA) / 10 GB libres (con IA) |

---

## 🔋 RENDIMIENTO ESPERADO

| Dispositivo | Tiempo Exportación 1080p (1 min) |
|-------------|----------------------------------|
| Gama Baja (2 GB RAM) | 3-5 minutos |
| Gama Media (4 GB RAM) | 1-2 minutos |
| Gama Alta (6+ GB RAM) | 30-60 segundos |

---

## ⚠️ LIMITACIONES CONOCIDAS

| Escenario | Limitación |
|-----------|------------|
| Android con <2 GB RAM | IA desactivada automáticamente |
| Android 7.0 o inferior | No compatible |
| Windows 7/8 | No compatible (requiere Windows 10+) |
| Sin conexión a Internet | Funciona 100% offline (IA requiere descarga inicial) |
| Dispositivos sin MediaCodec | Codificación por software (más lento) |

## 🚀 Instalación

### Desde GitHub Actions (Recomendado)
1. Ve a la pestaña **Actions** en este repositorio
2. Selecciona el último workflow exitoso
3. Descarga el APK de **Artifacts**
4. Extrae y elige el APK correspondiente a tu dispositivo:

| Archivo | Arquitectura | Tamaño aprox. | Uso recomendado |
|---------|--------------|---------------|-----------------|
| `app-armeabi-v7a-release.apk` | ARMv7 (32 bits) | ~40 MB | Dispositivos muy antiguos o de gama baja |
| `app-arm64-v8a-release.apk` | ARM64 (64 bits) | ~45 MB | **La mayoría de teléfonos modernos** |
| `app-x86_64-release.apk` | x86_64 (64 bits) | ~48 MB | Emuladores o dispositivos Intel (Chromebooks) |
| `app-release.apk` | Universal (todas) | ~90 MB | Si no estás seguro de la arquitectura |

5. Instala en tu dispositivo (permitir fuentes desconocidas)

### Compilación Local
```bash
flutter pub get
flutter build apk --release --split-per-abi

Premium_Pro_v1.0/
│
├── 📄 pubspec.yaml                                    ✅ MODIFICADO (ffmpeg_kit_flutter: 6.0.3, provider, etc.)
├── 📄 README.md                                       ⚪ SIN CAMBIOS
├── 📄 .gitignore                                      ⚪ SIN CAMBIOS
├── 📄 analysis_options.yaml                           ⚪ SIN CAMBIOS
├── 📄 .metadata                                       ⚪ SIN CAMBIOS
│
├── 📁 .github/
│   └── 📁 workflows/
│       └── 📄 build.yml                               ✅ MODIFICADO (descarga AAR, genera APKs separados + universal)
│
├── 📁 android/
│   ├── 📄 build.gradle                                ✅ MODIFICADO (repositorios: google, mavenCentral, jitpack)
│   ├── 📄 settings.gradle                             ✅ MODIFICADO (AGP 8.6.0, Kotlin 2.1.20)
│   ├── 📄 gradle.properties                           ✅ MODIFICADO (memoria 4GB)
│   ├── 📄 local.properties                            ⚠️ AUTO-GENERADO (no commitear)
│   │
│   ├── 📁 gradle/
│   │   └── 📁 wrapper/
│   │       ├── 📄 gradle-wrapper.properties           ✅ MODIFICADO (Gradle 8.11.1)
│   │       └── 📄 gradle-wrapper.jar                  ⚪ SIN CAMBIOS
│   │
│   └── 📁 app/
│       ├── 📄 build.gradle                            ✅ MODIFICADO (dependencias locales, resolución de FFmpeg)
│       ├── 📄 proguard-rules.pro                      ⚪ SIN CAMBIOS
│       ├── 📄 androidTest.gradle                      ⚪ SIN CAMBIOS (si existe)
│       │
│       ├── 📁 libs/                                    📦 NUEVO (carpeta para AAR local)
│       │   └── 📄 ffmpeg-kit-fix.aar                  (se descarga automáticamente en CI)
│       │
│       └── 📁 src/
│           └── 📁 main/
│               ├── 📄 AndroidManifest.xml             ✅ MODIFICADO (permisos + services)
│               ├── 📄 MainActivity.kt                 ⚪ SIN CAMBIOS
│               │
│               ├── 📁 kotlin/
│               │   └── 📁 com/
│               │       └── 📁 premiumpro/
│               │           └── 📁 editor/
│               │               └── 📄 MainActivity.kt ⚪ SIN CAMBIOS
│               │
│               ├── 📁 res/
│               │   ├── 📁 drawable/
│               │   │   ├── 📄 launch_background.xml   ✅ NUEVO
│               │   │   └── 📄 .gitkeep                ✅ NUEVO
│               │   │
│               │   ├── 📁 mipmap-anydpi-v26/
│               │   │   ├── 📄 ic_launcher.xml         ✅ NUEVO
│               │   │   └── 📄 .gitkeep                ✅ NUEVO
│               │   │
│               │   ├── 📁 mipmap-hdpi/
│               │   │   ├── 📄 ic_launcher.png         ⚪ OPCIONAL
│               │   │   └── 📄 .gitkeep                ✅ NUEVO
│               │   │
│               │   ├── 📁 mipmap-mdpi/
│               │   │   ├── 📄 ic_launcher.png         ⚪ OPCIONAL
│               │   │   └── 📄 .gitkeep                ✅ NUEVO
│               │   │
│               │   ├── 📁 mipmap-xhdpi/
│               │   │   ├── 📄 ic_launcher.png         ⚪ OPCIONAL
│               │   │   └── 📄 .gitkeep                ✅ NUEVO
│               │   │
│               │   ├── 📁 mipmap-xxhdpi/
│               │   │   ├── 📄 ic_launcher.png         ⚪ OPCIONAL
│               │   │   └── 📄 .gitkeep                ✅ NUEVO
│               │   │
│               │   ├── 📁 mipmap-xxxhdpi/
│               │   │   ├── 📄 ic_launcher.png         ⚪ OPCIONAL
│               │   │   └── 📄 .gitkeep                ✅ NUEVO
│               │   │
│               │   ├── 📁 values/
│               │   │   ├── 📄 styles.xml              ✅ NUEVO
│               │   │   ├── 📄 strings.xml             ⚪ OPCIONAL
│               │   │   ├── 📄 colors.xml              ⚪ OPCIONAL
│               │   │   └── 📄 .gitkeep                ✅ NUEVO
│               │   │
│               │   └── 📁 xml/
│               │       ├── 📄 file_paths.xml          ✅ NUEVO
│               │       └── 📄 .gitkeep                ✅ NUEVO
│               │
│               └── 📁 assets/ (si existen assets nativos)
│
├── 📁 lib/
│   ├── 📄 main.dart                                   ✅ MODIFICADO (PremiumProApp + providers)
│   │
│   ├── 📁 services/
│   │   ├── 📄 ffmpeg_wrapper.dart                     ✅ NUEVO (capa de abstracción con progreso híbrido)
│   │   ├── 📄 media_processor.dart                    ✅ MODIFICADO (usa VideoSettings)
│   │   ├── 📄 audio_processor.dart                    ✅ NUEVO
│   │   ├── 📄 image_processor.dart                    ✅ NUEVO
│   │   ├── 📄 ai_manager.dart                         ⚪ SIN CAMBIOS
│   │   └── 📄 .gitkeep                                ✅ NUEVO
│   │
│   ├── 📁 widgets/
│   │   ├── 📄 timeline_widget.dart                    ✅ MODIFICADO (interruptor HW, barra de progreso)
│   │   ├── 📄 audio_timeline_widget.dart              ✅ NUEVO
│   │   ├── 📄 image_editor_widget.dart                ✅ NUEVO
│   │   ├── 📄 settings_panel.dart                     ✅ NUEVO (tooltips, gestión IA)
│   │   └── 📄 .gitkeep                                ✅ NUEVO
│   │
│   ├── 📁 models/
│   │   ├── 📄 video_settings.dart                     ✅ NUEVO (incluye hardwareAcceleration)
│   │   ├── 📄 audio_settings.dart                     ✅ NUEVO
│   │   ├── 📄 image_settings.dart                     ✅ NUEVO
│   │   ├── 📄 project_config.dart                     ⚪ OPCIONAL
│   │   └── 📄 .gitkeep                                ✅ NUEVO
│   │
│   ├── 📁 screens/
│   │   ├── 📄 home_screen.dart                        ⚪ OPCIONAL
│   │   ├── 📄 editor_screen.dart                      ⚪ OPCIONAL
│   │   └── 📄 .gitkeep                                ✅ NUEVO
│   │
│   ├── 📁 utils/
│   │   ├── 📄 constants.dart                          ⚪ OPCIONAL
│   │   ├── 📄 helpers.dart                            ⚪ OPCIONAL
│   │   └── 📄 .gitkeep                                ✅ NUEVO
│   │
│   └── 📁 theme/
│       ├── 📄 app_theme.dart                          ⚪ OPCIONAL
│       └── 📄 .gitkeep                                ✅ NUEVO
│
├── 📁 assets/
│   │
│   ├── 📁 fonts/
│   │   ├── 📄 .gitkeep                                ✅ NUEVO (requerido)
│   │   ├── 📄 MaterialIcons-Regular.otf               ⚪ OPCIONAL (incluido en Flutter)
│   │   ├── 📄 Roboto-Regular.ttf                      ⚪ OPCIONAL (incluido en Flutter)
│   │   └── 📄 (fuentes personalizadas .ttf/.otf)      ⚪ OPCIONAL
│   │
│   ├── 📁 icons/
│   │   ├── 📄 .gitkeep                                ✅ NUEVO (requerido)
│   │   ├── 📄 app_icon.png                            ⚪ OPCIONAL
│   │   ├── 📄 video_icon.png                          ⚪ OPCIONAL
│   │   ├── 📄 audio_icon.png                          ⚪ OPCIONAL
│   │   ├── 📄 image_icon.png                          ⚪ OPCIONAL
│   │   ├── 📄 export_icon.png                         ⚪ OPCIONAL
│   │   ├── 📄 settings_icon.png                       ⚪ OPCIONAL
│   │   └── 📄 (iconos .png/.svg)                      ⚪ OPCIONAL
│   │
│   ├── 📁 luts/
│   │   ├── 📄 .gitkeep                                ✅ NUEVO (requerido)
│   │   ├── 📄 cinematic.cube                          ⚪ OPCIONAL
│   │   ├── 📄 vintage.cube                            ⚪ OPCIONAL
│   │   ├── 📄 bw.cube                                 ⚪ OPCIONAL
│   │   ├── 📄 vivid.cube                              ⚪ OPCIONAL
│   │   ├── 📄 warm.cube                               ⚪ OPCIONAL
│   │   ├── 📄 cool.cube                               ⚪ OPCIONAL
│   │   └── 📄 (LUTs .cube)                            ⚪ OPCIONAL
│   │
│   └── 📁 models/
│       ├── 📄 .gitkeep                                ✅ NUEVO (requerido)
│       ├── 📄 object_detection.tflite                 ⚪ OPCIONAL
│       ├── 📄 face_detection.tflite                   ⚪ OPCIONAL
│       ├── 📄 style_transfer.tflite                   ⚪ OPCIONAL
│       ├── 📄 super_resolution.tflite                 ⚪ OPCIONAL
│       └── 📄 (modelos .tflite/.onnx)                 ⚪ OPCIONAL
│
├── 📁 test/
│   ├── 📄 widget_test.dart                            ⚪ SIN CAMBIOS
│   ├── 📄 media_processor_test.dart                   ⚪ OPCIONAL
│   ├── 📄 ffmpeg_wrapper_test.dart                    ⚪ OPCIONAL
│   └── 📄 .gitkeep                                    ✅ NUEVO
│
├── 📁 build/                                          ⚠️ AUTO-GENERADO (no commitear)
│   ├── 📁 app/
│   ├── 📁 flutter_assets/
│   └── 📁 ios/
│
├── 📁 .dart_tool/                                     ⚠️ AUTO-GENERADO (no commitear)
│   ├── 📄 package_config.json
│   └── 📁 flutter_build/
│
├── 📁 .idea/                                          ⚠️ LOCAL (no commitear)
│   └── 📄 (configuración de Android Studio)
│
└── 📁 .vscode/                                        ⚠️ LOCAL (no commitear)
    ├── 📄 settings.json
    └── 📄 launch.json

