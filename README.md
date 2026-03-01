# 🎬 Premium Pro v1.0 - Editor Multimedia Profesional

[![Build Status](https://github.com/usuario/premium-pro-v1/actions/workflows/build.yml/badge.svg)](https://github.com/usuario/premium-pro-v1/actions)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

Editor y compresor profesional de Imagen, Audio y Video multiplataforma (Android/Windows), optimizado para dispositivos de bajos recursos.

## ✨ Características Principales

| Módulo | Funciones |
|--------|-----------|
| 🎥 Video | Corte preciso, Speed Ramp, Color Grading, LUTs, Estabilización |
| 🎵 Audio | Waveform OpenGL, Ecualizador 10 bandas, Reducción de ruido |
| 🖼️ Imagen | HDR por capas, Escalado Lanczos4, Filtros profesionales |
| 🗜️ Compresión | H.264/H.265/VP9/AV1, Control CRF, Hardware Acceleration |

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

## 🖥️ WINDOWS

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
4. Instala en tu dispositivo (permitir fuentes desconocidas)

### Compilación Local
```bash
flutter pub get
flutter build apk --release --split-per-abi
```

## ⚙️ Configuración

### Modo Sin IA (Por Defecto)
La aplicación funciona completamente sin modelos de IA para garantizar:
- ✅ Compatibilidad universal
- ✅ Sin descargas adicionales
- ✅ Máxima estabilidad

### Activar IA (Opcional)
1. Ve a Ajustes > Inteligencia Artificial
2. Descarga el modelo deseado (1GB - 8GB)
3. Activa "Mejora IA" en exportación

## 📁 Estructura del Proyecto

premium-pro-v1/
├── 📄 .gitignore
├── 📄 analysis_options.yaml
├── 📄 pubspec.yaml
├── 📄 README.md
│
├── 📁 .github/
│   └── 📁 workflows/
│       └── 📄 build.yml
│
├── 📁 android/
│   ├── 📄 .gitignore                          ← ✅ NUEVO
│   ├── 📄 build.gradle
│   ├── 📄 settings.gradle
│   ├── 📄 gradle.properties
│   │
│   ├── 📁 gradle/
│   │   └── 📁 wrapper/
│   │       └── 📄 gradle-wrapper.properties
│   │
│   └── 📁 app/
│       ├── 📄 build.gradle                    ← ✅ ACTUALIZADO (kotlin)
│       ├── 📄 proguard-rules.pro
│       │
│       └── 📁 src/
│           └── 📁 main/
│               ├── 📄 AndroidManifest.xml     ← ✅ ACTUALIZADO
│               │
│               ├── 📁 kotlin/                 ← ✅ CORREGIDO (no java)
│               │   └── 📁 com/
│               │       └── 📁 premiumpro/
│               │           └── 📁 editor/
│               │               └── 📄 MainActivity.kt
│               │
│               ├── 📁 res/
│               │   ├── 📁 drawable/
│               │   │   └── 📄 launch_background.xml    ← ✅ NUEVO
│               │   │
│               │   ├── 📁 values/
│               │   │   └── 📄 styles.xml
│               │   │
│               │   └── 📁 mipmap-*/
│               │       └── 📄 .gitkeep               ← ✅ NUEVO (x5 densidades)
│               │
│               └── 📄 AndroidManifest.xml
│
├── 📁 assets/
│   ├── 📁 fonts/
│   │   └── 📄 .gitkeep
│   ├── 📁 icons/
│   │   └── 📄 .gitkeep               ← ✅ NUEVO
│   ├── 📁 luts/
│   │   └── 📄 .gitkeep               ← ✅ NUEVO
│   └── 📁 models/
│       └── 📄 .gitkeep               ← ✅ NUEVO
│
└── 📁 lib/
    ├── 📄 main.dart
    │
    ├── 📁 models/
    │   ├── 📄 compression_settings.dart
    │   └── 📄 project_config.dart
    │
    ├── 📁 services/
    │   ├── 📄 media_processor.dart
    │   └── 📄 ai_manager.dart
    │
    └── 📁 widgets/
        ├── 📄 timeline_widget.dart
        └── 📄 settings_panel.dart



## 🛠️ Tecnologías

- **Framework:** Flutter 3.16+
- **Motor Multimedia:** FFmpeg Kit 6.0+
- **Gestión de Estado:** Provider
- **Renderizado:** OpenGL/Vulkan (Audio Waveform)

## 📄 Licencia

GPL-3.0 - Software libre y gratuito. Sin publicidad.

## 🐛 Reportar Problemas

Abre un **Issue** en GitHub con:
- Dispositivo y versión de Android
- Logs del error (Ajustes > Ver Logs)
- Pasos para reproducir

---

**Desarrollado con ❤️ para la comunidad**
