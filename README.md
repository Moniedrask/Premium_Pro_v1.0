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

## 📋 Requisitos Mínimos

- **Android:** 8.0 (API 26) o superior
- **RAM:** 2GB mínimo (4GB recomendado)
- **Almacenamiento:** 250MB para instalación + espacio para proyectos
- **Sin Internet:** Funciona completamente offline (IA es opcional)

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
