# Troubleshooting - Entorno Gráfico

## Problema: Loop infinito después de Plymouth

Si el sistema entra en un loop intentando cargar el entorno gráfico sin éxito:

### Solución Rápida - Boot Temporal

**Opción 1: Forzar modo seguro (Sway con software rendering)**
```
En el menú de boot:
1. Presiona 'e' para editar
2. Agrega al final de la línea del kernel: mados_safe_mode
3. Presiona F10 para bootear
```

**Opción 2: Forzar gráficos básicos con nomodeset**
```
En el menú de boot:
1. Presiona 'e' para editar
2. Agrega al final: nomodeset
3. Presiona F10
```

**Opción 3: Boot en modo texto para debugging**
```
En el menú de boot:
1. Presiona 'e' para editar
2. Agrega al final: 3
3. Presiona F10
Luego ejecuta: startsway
```

### Acceder a TTY para Debugging

Si el sistema está en loop:
1. Presiona `Ctrl + Alt + F2` (o F3, F4)
2. Loguéate con usuario `mados` (sin password en live)
3. Ejecuta comandos de diagnóstico

### Comandos de Diagnóstico

```bash
# Ver logs críticos
journalctl -p 3 -b --no-pager | tail -100

# Ver logs específicos de gráficos
journalctl --grep="drm\|gpu\|wayland\|hyprland\|sway" --no-pager | tail -50

# Verificar GPU y drivers
lspci -nn | grep -iE 'VGA|3D|Display'
ls -la /dev/dri/

# Verificar si hay procesos gráficos
ps aux | grep -E "hyprland|sway|wayland"

# Ver logs del setup gráfico
cat /var/log/mados-graphical-session.log

# Intentar iniciar Sway manualmente
export WLR_RENDERER=pixman
sway

# Matar compositor y reiniciar
pkill -9 Hyprland
pkill -9 sway
```

### Causas Comunes

1. **VM sin aceleración 3D**: El sistema intenta usar Hyprland pero necesita Sway
   - Solución: Boot con `nomodeset`

2. **Drivers NVIDIA propietarios**: Pueden causar conflictos con Wayland
   - Solución: Boot con `nomodeset` o usar driver nouveau

3. **Hardware legacy sin soporte DRM**: GPUs Intel antiguas (pre-2012)
   - Solución: Boot con `mados_safe_mode`

4. **Falta de memoria RAM**: Menos de 2GB puede causar fallos
   - Solución: Asignar más RAM a la VM

5. **swww-daemon no inicia**: El wallpaper glue code puede fallar
   - Solución: Ya está parcheado para fallar silenciosamente

### Scripts de Soporte

| Script | Propósito |
|--------|-----------|
| `/usr/local/bin/mados-safe-mode` | Fuerza Sway con máxima compatibilidad |
| `/usr/local/bin/mados-graphical-session-setup` | Log de setup gráfico |
| `/usr/local/bin/select-compositor` | Detecta hardware y selecciona compositor |
| `/usr/local/bin/detect-legacy-hardware` | Detecta hardware legacy |

### Reporting Bugs

Al reportar un problema, incluye:

```bash
# Guardar información del sistema
journalctl -b > /tmp/journal.log
lspci -nn > /tmp/lspci.log
ls -la /dev/dri/ > /tmp/dri.log
cat /var/log/mados-graphical-session.log >> /tmp/journal.log

# Compactar y compartir
tar czf mados-logs.tar.gz /tmp/*.log
```

### Workarounds Específicos

**VirtualBox:**
```bash
# En la VM, instalar Guest Additions
sudo pacman -S virtualbox-guest-utils
sudo modprobe vboxvideo
```

**VMware:**
```bash
# Usar driver vmwgfx
sudo modprobe vmwgfx
```

**NVIDIA:**
```bash
# Forzar driver nouveau
sudo rmmod nvidia
sudo modprobe nouveau
```

## Próximo Build

Los siguientes fixes están incluidos en el próximo build:

1. ✅ Launcher ahora falla silenciosamente sin broken Hyprland
2. ✅ mados-wallpaper-glitch timeout reducido de 15s a 5s
3. ✅ Delays agregados a exec-once para evitar race conditions
4. ✅ Safe mode disponible con parámetro `mados_safe_mode`
5. ✅ Logging mejorado en graphical-session.service
