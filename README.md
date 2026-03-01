# 馃幀 Premium Pro v1.0 - Editor Multimedia Profesional

[![Build Status](https://github.com/usuario/premium-pro-v1/actions/workflows/build.yml/badge.svg)](https://github.com/usuario/premium-pro-v1/actions)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

Editor y compresor profesional de Imagen, Audio y Video multiplataforma (Android/Windows), optimizado para dispositivos de bajos recursos.

## 鉁� Caracter铆sticas Principales

| M贸dulo | Funciones |
|--------|-----------|
| 馃帴 Video | Corte preciso, Speed Ramp, Color Grading, LUTs, Estabilizaci贸n |
| 馃幍 Audio | Waveform OpenGL, Ecualizador 10 bandas, Reducci贸n de ruido |
| 馃柤锔� Imagen | HDR por capas, Escalado Lanczos4, Filtros profesionales |
| 馃棞锔� Compresi贸n | H.264/H.265/VP9/AV1, Control CRF, Hardware Acceleration |

## 馃搵 Requisitos M铆nimos

- **Android:** 8.0 (API 26) o superior
- **RAM:** 2GB m铆nimo (4GB recomendado)
- **Almacenamiento:** 250MB para instalaci贸n + espacio para proyectos
- **Sin Internet:** Funciona completamente offline (IA es opcional)

## 馃殌 Instalaci贸n

### Desde GitHub Actions (Recomendado)
1. Ve a la pesta帽a **Actions** en este repositorio
2. Selecciona el 煤ltimo workflow exitoso
3. Descarga el APK de **Artifacts**
4. Instala en tu dispositivo (permitir fuentes desconocidas)

### Compilaci贸n Local
```bash
flutter pub get
flutter build apk --release --split-per-abi
```

## 鈿欙笍 Configuraci贸n

### Modo Sin IA (Por Defecto)
La aplicaci贸n funciona completamente sin modelos de IA para garantizar:
- 鉁� Compatibilidad universal
- 鉁� Sin descargas adicionales
- 鉁� M谩xima estabilidad

### Activar IA (Opcional)
1. Ve a Ajustes > Inteligencia Artificial
2. Descarga el modelo deseado (1GB - 8GB)
3. Activa "Mejora IA" en exportaci贸n

## 馃搧 Estructura del Proyecto

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