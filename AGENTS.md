# Contexto del Proyecto: madOS

**madOS** es una distribución de Linux based on Arch Linux enfocada en ser moderna, minimalista y altamente personalizable. Utiliza Wayland como servidor de display por defecto con Hyprland/Sway como compositor principal.

## 🛠 Stack Tecnológico

- **Base:** Arch Linux (Rolling Release)
- **Kernel:** Linux estándar con soporte para kernels adicionales (LTS, Zen)
- **Init System:** systemd
- **Server de Display:** Wayland (Hyprland para hardware moderno, Sway como fallback)
- **Gestor de Paquetes:** pacman + acceso a AUR
- **Shell:** Zsh con Oh My Zsh preinstalado
- **Entorno por defecto:** Hyprland + Sway (dual compositor setup)
- **Tema:** Nordic GTK + Nordzy iconos
- **Instalador:** madOS Installer (Python + GTK3)

## 📂 Estructura del Repositorio

```
mad-os/
├── airootfs/                 # Root filesystem para la ISO (live environment)
│   ├── etc/                  # Archivos de configuración → /etc
│   │   ├── skel/             # Template para nuevos usuarios
│   │   └── systemd/system/   # Systemd units personalizados
│   ├── home/mados/           # Usuario live por defecto
│   ├── root/                 # Root user directory
│   │   └── customize_airootfs.sh  # Script de personalización en build
│   └── usr/local/
│       ├── bin/              # Scripts del sistema (mados-*)
│       └── lib/              # Módulos Python de madOS
│           ├── mados_installer/      # GUI del instalador
│           ├── mados_post_install/   # Configuración post-instalación
│           ├── mados_apps/           # Aplicaciones madOS
│           └── mados-firstboot/     # Primer arranque setup
├── Install/modules/          # Módulos del instalador
├── tests/                    # Tests automatizados (pytest + bash)
├── efiboot/                  # Configuración de arranque UEFI
├── grub/                     # Configuración GRUB BIOS
├── syslinux/                 # Configuración.Syslinux
├── packages.x86_64          # Lista de paquetes base
├── packages-*.x86_64        # Listas por perfil (minimal, dev, media)
├── pacman.conf              # Configuración de pacman
├── profiledef.sh            # Configuración de mkarchiso
└── mados-config-example.yaml # Plantilla de aprovisionamiento automático
```

### Rutas Críticas

| Ruta | Propósito |
|------|-----------|
| `/airootfs/root/customize_airootfs.sh` | Script de personalización durante build de ISO |
| `/airootfs/usr/local/bin/` | Scripts personalizados del sistema |
| `/airootfs/usr/local/lib/` | Módulos Python de aplicaciones madOS |
| `/airootfs/etc/skel/` | Template para nuevos usuarios |
| `/profiledef.sh` | Configuración de mkarchiso |

## 🛠️ Toolchain

- **mkarchiso** - Herramienta principal para construir la ISO
- **Git** - Versión 2.x+
- **Python 3.13+** - Para el instalador y aplicaciones
- **ShellCheck** - Validación de scripts bash
- **Ruff** - Linter/formatter para Python
- **Pytest** - Framework de testing

## 📝 Convenciones de Desarrollo

### Lenguajes

| Componente | Lenguaje |
|------------|----------|
| Instalador GUI | Python + GTK3 |
| Scripts del sistema | Bash |
| Aplicaciones madOS | Python |
| Configuraciones | YAML, Shell |

### Manejo de Permisos

```bash
# Scripts en /usr/local/bin/ → 755
# Archivos de configuración → 644
# Directorios de usuario → 750
# Archivos sensibles (shadow, sudoers) → 400/440
```

Ver `profiledef.sh:19-110` para la lista completa de permisos.

### Estilo de Scripts

1. **Bash:**
   - Todos los scripts deben pasar ShellCheck
   - Usar `#!/usr/bin/env bash` como shebang
   - Incluir `set -e` para errores críticos

2. **Python:**
   - Seguir configuración en `pyproject.toml`
   - Usar Ruff para linting: `ruff check .`
   - Format with: `ruff format .`
   - Target Python: 3.13

3. **Commits:**
   - Convención: [Conventional Commits](https://www.conventionalcommits.org/)
   - Formatos: `feat:`, `fix:`, `docs:`, `style:`, `refactor:`, `test:`, `chore:`

## 🚀 Flujo de Trabajo de la ISO

### Build de la ISO

```bash
# 1. Clonar repositorio
git clone https://github.com/madkoding/mad-os.git
cd mad-os

# 2. Instalar dependencias (Arch Linux)
sudo pacman -S archiso

# 3. Construir ISO
mkarchiso -v -w /tmp/archiso-workspace -o out/ .

# La ISO se genera en: out/madOS_YYYYMM.iso
```

### Testing

```bash
# Probar en QEMU (live session)
qemu-system-x86_64 -m 4G -cdrom out/madOS_YYYYMM.iso \
  -boot d -enable-kvm -smp 4

# Ejecutar test suite
python3 -m pytest tests/ -v

# Tests específicos
python3 -m pytest tests/test_boot_scripts.py -v
python3 -m pytest tests/test_installer_installation.py -v
```

### Testing con VirtualBox

```bash
# Convertir ISO a VDI (opcional para pruebas persistentes)
VBoxManage createhd --filename mados.vdi --size 25000
VBoxManage storageattach "VM_NAME" --storagectl "SATA" \
  --port 0 --device 0 --type dvddrive --medium out/madOS.iso
```

## ⚠️ Reglas de Oro para la IA

1. **Seguridad:** Nunca sugieras cambios que rompan dependencias base del sistema o debiliten configuraciones de seguridad (sudo, permisos, firewall)

2. **Rendimiento:** El sistema debe consumir menos de 800 MB de RAM en reposo. Priorizar herramientas ligeras sobre alternativas pesadas

3. **Compatibilidad:** Los scripts deben funcionar en entornos Live (filesystem de solo lectura) y sistemas instalados

4. **Hardware:**
   - Soporte nativo para NVIDIA (drivers propietarios) y AMD (Mesa)
   - Optimizaciones para laptops (gestión de energía)
   - Detección automática de hardware legado

5. **Rolling Release:** Verificar compatibilidad con actualizaciones continuas de Arch. Evitar soluciones que requieran rebuild manual tras actualizaciones

6. **Wayland-first:** Todas las configuraciones de display deben priorizar Wayland. X11 solo como fallback compatibility

## 🔒 Reglas de Testing y Validación (OBLIGATORIO)

**ANTES DE SUBIR CUALQUIER CAMBIO A MAIN O DEVELOP, DEBES:**

1. **Ejecutar todos los tests relevantes:**
   ```bash
   # Si modificas scripts de sistema (bash)
   shellcheck airootfs/usr/local/bin/*.sh
   
   # Si modificas Python
   ruff check airootfs/ tests/
   ruff format airootfs/ tests/ --check
   
   # Ejecutar tests específicos según lo que modificaste
   python3 -m pytest tests/test_liveusb_scripts.py -v
   python3 -m pytest tests/test_gpu_detection.py -v
   python3 -m pytest tests/test_hyprland_config.py tests/test_sway_config.py -v
   ```

2. **Si NO existen tests para lo que modificaste → CREARLOS:**
   - Agregar tests unitarios en `tests/test_<modulo>.py`
   - Agregar tests de integración en `tests/test-*.sh`
   - No subir código sin tests si el test suite ya existe

3. **Verificar que NO se rompa lógica existente:**
   - Si cambias `detect-legacy-hardware`, correr `tests/test_gpu_detection.py`
   - Si cambias `.zlogin` o `start-hyprland`, correr tests de compositor
   - Si cambias lógica de login, verificar que `tests/test_liveusb_scripts.py` pase

4. **Run full test suite antes de merge:**
   ```bash
   python3 -m pytest tests/ -v
   ```
   - **TODOS los tests deben pasar** antes de push/merge
   - Si fallan tests existentes → REVERTIR o CORREGIR

5. **Commit message debe incluir:**
   - Qué se modificó
   - Qué tests se ejecutaron
   - Si se agregaron nuevos tests

**Ejemplo de commit correcto:**
```
fix: detect-legacy-hardware uses eglinfo for real 3D check

- Restored main branch's eglinfo-based detection
- Now correctly identifies hardware without OpenGL
- Avoids Hyprland crash on legacy hardware

Tests executed:
- tests/test_gpu_detection.py: 103 passing
- tests/test_liveusb_scripts.py: 12 passing (280 subtests)

No new tests added (existing tests validated the fix).
```

**Ejemplo de commit INCORRECTO (no hacer):**
```
fix: graphics startup
```
❌ Falta detalle, no menciona tests, no prueba nada.

## 🎯 Enfoque del Proyecto

**madOS está diseñado para:**
- Desarrollo de software con herramientas AI/ML integradas
- Usuarios que buscan un sistema minimalista pero completo
- Entornos de producción que requieren estabilidad con software actualizado

## 📦 Perfiles de Paquetes

| Perfil | Uso | Tamaño aprox |
|--------|-----|--------------|
| Minimal | Base system only | ~1.5 GB |
| Standard | Desktop + apps esenciales | ~3 GB |
| Developer | Herramientas de desarrollo, IDEs, compilers | ~5 GB |
| Media | Multimedia production | ~6 GB |

## 🔧 Scripts Personalizados Disponibles

Los siguientes scripts están disponibles en `/usr/local/bin/`:

| Script | Propósito |
|--------|-----------|
| `mados-update` | Actualización del sistema con optimizaciones madOS |
| `mados-health-check` | Diagnóstico del sistema |
| `mados-logs` | Visor de logs unificado |
| `mados-audio-quality` | Configuración de audio de alta calidad |
| `mados-hardware-config` | Configuración automática de hardware |
| `mados-persistence` | Gestión de modo persistente en USB |
| `setup-opencode` | Instalación de OpenCode AI assistant |
| `setup-ollama` | Instalación de Ollama para IA local |

## 🧪 Testing y Validación

```bash
# Validar scripts bash
shellcheck airootfs/usr/local/bin/*.sh

# Validar Python
ruff check airootfs/ tests/

# Ejecutar todos los tests
python3 -m pytest tests/ -v --tb=short

# Con cobertura
python3 -m pytest tests/ --cov=airootfs/usr/local/lib --cov-report=html
```

## 📚 Recursos Adicionales

- **Documentación Arch Linux:** https://wiki.archlinux.org/
- **Hyprland Wiki:** https://wiki.hyprland.org/
- **Sway Wiki:** https://swaywm.org/
- **Repositorio:** https://github.com/madkoding/mad-os
- **Issues:** https://github.com/madkoding/mad-os/issues

---

**Última actualización:** Marzo 2026  
**Versión del documento:** 1.0
