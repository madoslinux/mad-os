# Changelog

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Sin versión] - YYYY-MM-DD

### Agregado
- Documentación inicial del proyecto (README.md)
- Este archivo CHANGELOG.md
- Configuración de pre-commit hooks para automatización de calidad de código

### Cambiado
- Reducidas las exclusiones de reglas en ruff para mejorar la calidad del código
  - Eliminada la exclusión global de `E501` (line-too-long)
  - Mantenidas solo exclusiones específicas por archivo cuando es necesario

### Mejorado
- Documentación de la estructura del proyecto
- Guía de contribución más clara
- Convenciones de commits según Conventional Commits

## [0.1.0] - 2024-01-01

### Agregado
- Distribución base basada en Arch Linux
- Entorno de escritorio GNOME con Wayland
- Tema Nord personalizado
- Instalador gráfico y por terminal
- Perfiles de paquetes: minimal, standard, developer, media
- Scripts de construcción de ISO con archiso
- Sistema de configuración mediante YAML
- Integración continua con GitHub Actions
- Pruebas unitarias básicas

### Cambiado
- Migración inicial de configuración a pyproject.toml

### Seguridad
- Configuraciones hardened por defecto
- Permisos de archivos revisados

---

## Formato de las versiones

- **Agregado**: para nuevas funcionalidades.
- **Cambiado**: para cambios en funcionalidades existentes.
- **Obsoleto**: para funcionalidades que pronto serán removidas.
- **Removido**: para funcionalidades eliminadas.
- **Corregido**: para correcciones de bugs.
- **Seguridad**: para vulnerabilidades corregidas.

## Notas

- Las fechas deben seguir el formato AAAA-MM-DD (ISO 8601).
- Los números de versión siguen Semantic Versioning (MAJOR.MINOR.PATCH).
- Los cambios deben estar agrupados por tipo y ordenados cronológicamente.
