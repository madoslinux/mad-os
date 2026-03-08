# madOS

**madOS** es una distribución de Linux basada en Arch Linux, diseñada para ser moderna, minimalista y altamente personalizable. Utiliza el entorno de escritorio GNOME con Wayland por defecto y sigue las mejores prácticas de seguridad y rendimiento.

## 📋 Tabla de Contenidos

- [Características](#características)
- [Requisitos del Sistema](#requisitos-del-sistema)
- [Instalación](#instalación)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Desarrollo](#desarrollo)
- [Contribuir](#contribuir)
- [Licencia](#licencia)

## ✨ Características

- **Base Arch Linux**: Acceso al repositorio AUR y actualizaciones rolling release
- **GNOME + Wayland**: Entorno de escritorio moderno con soporte completo para Wayland
- **Tema Nord**: Esquema de colores agradable y consistente
- **Installer Personalizado**: Herramienta de instalación gráfica y por terminal
- **Perfiles de Paquetes**: Múltiples configuraciones (minimal, standard, developer, media)
- **Seguridad**: Configuraciones hardened por defecto

## 💻 Requisitos del Sistema

### Mínimos
- **Procesador**: x86_64 compatible (Intel/AMD)
- **RAM**: 4 GB
- **Almacenamiento**: 20 GB
- **Resolución**: 1024x768

### Recomendados
- **Procesador**: Dual-core 2.0 GHz o superior
- **RAM**: 8 GB o más
- **Almacenamiento**: 50 GB SSD
- **Resolución**: 1920x1080 o superior

## 📥 Instalación

### Desde ISO

1. Descarga la última ISO desde [Releases](https://github.com/madox-os/mados/releases)
2. Graba la ISO en un USB booteable:
   ```bash
   sudo dd if=mados.iso of=/dev/sdX bs=4M status=progress
   ```
3. Arranca desde el USB
4. Sigue el asistente de instalación

### Construir tu propia ISO

```bash
# Clonar el repositorio
git clone https://github.com/madox-os/mados.git
cd mados

# Instalar dependencias
pip install -r requirements.txt

# Construir la ISO
./build-iso.sh
```

Para más detalles, consulta la [documentación de construcción](docs/BUILDING.md).

## 📁 Estructura del Proyecto

```
mados/
├── .github/                 # Configuración de GitHub Actions y templates
├── airootfs/                # Sistema de archivos raíz para la ISO
│   └── usr/local/
│       ├── bin/             # Scripts y ejecutables del sistema
│       ├── lib/             # Librerías y módulos Python
│       └── share/           # Recursos compartidos (temas, iconos)
├── efiboot/                 # Archivos de boot EFI
├── grub/                    # Configuración de GRUB
├── syslinux/                # Configuración de SYSLINUX
├── tests/                   # Pruebas unitarias y de integración
├── CONTRIBUTING.md          # Guía para contribuidores
├── LICENSE                  # Licencia del proyecto (MIT)
├── packages*.x86_64         # Listas de paquetes por perfil
├── profiledef.sh            # Definición del perfil de Archiso
├── pyproject.toml           # Configuración de herramientas Python
└── README.md                # Este archivo
```

## 🛠️ Desarrollo

### Configurar el entorno

```bash
# Crear entorno virtual
python -m venv venv
source venv/bin/activate

# Instalar dependencias de desarrollo
pip install -r requirements.txt

# Instalar pre-commit hooks
pre-commit install
```

### Ejecutar pruebas

```bash
# Todas las pruebas
pytest

# Con cobertura
pytest --cov=airootfs/usr/local/lib --cov-report=html

# Linting
ruff check .
ruff format .
```

### Convenciones de Commits

Este proyecto sigue [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: añadir nueva característica
fix: corregir bug
docs: actualizar documentación
style: formato, sin cambios en lógica
refactor: reestructurar código
test: añadir/modificar pruebas
chore: mantenimiento, dependencias
```

## 🤝 Contribuir

¡Las contribuciones son bienvenidas! Por favor, lee nuestra [Guía de Contribución](CONTRIBUTING.md) antes de empezar.

Pasos básicos:
1. Fork el repositorio
2. Crea una rama (`git checkout -b feature/nueva-caracteristica`)
3. Realiza tus cambios
4. Ejecuta las pruebas (`pytest`)
5. Commit siguiendo convenciones (`git commit -m 'feat: descripción'`)
6. Push a tu rama (`git push origin feature/nueva-caracteristica`)
7. Abre un Pull Request

## 📄 Licencia

Este proyecto está licenciado bajo la licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

## 🔗 Enlaces

- [Sitio Web](https://mados.dev)
- [Documentación](https://docs.mados.dev)
- [Reportar Bugs](https://github.com/madox-os/mados/issues)
- [Discord](https://discord.gg/mados)

---

**madOS** - Modern, Agile, Dynamic Operating System
