# Sequence Diagrams

This document contains sequence diagrams for key madOS workflows.

## ISO Build Process

```mermaid
sequenceDiagram
    participant U as User
    participant M as mkarchiso
    participant P as Pacman
    participant A as airootfs
    participant S as SquashFS

    U->>M: sudo mkarchiso -v -w work/ -o out/ .
    
    par Bootstrap
        M->>P: Download base packages
        P-->>M: Packages installed
    and Prepare Rootfs
        M->>A: Copy airootfs/ to work/
        M->>A: Run customize_airootfs.sh
    and Configure Boot
        M->>M: Setup GRUB (UEFI)
        M->>M: Setup Syslinux (BIOS)
    end
    
    M->>S: Compress airootfs to squashfs
    M->>M: Generate ISO image
    M-->>U: Output: out/madOS-*.iso
```

## Live USB Boot Process

```mermaid
sequenceDiagram
    participant B as Bootloader
    participant K as Linux Kernel
    participant S as Systemd
    participant A as archiso
    participant W as Sway/Hyprland
    participant I as mados-installer-autostart

    B->>K: Load Linux + initramfs
    K->>S: Boot systemd
    S->>A: Mount squashfs (read-only)
    S->>A: Setup overlayfs (persistence)
    S->>S: Start display manager (greetd → cage)
    
    S->>W: Launch compositor
    W->>W: Load sway/hyprland config
    W->>W: Start waybar, wallpaper, etc.
    
    W->>I: Execute autostart scripts
    alt In archiso live environment
        I->>I: Check /run/archiso exists
        I->>I: Check NOT Ventoy boot
        I->>I: Fix pacman-db
        I->>I: Launch installer at /usr/local/bin/mados-installer
    else Ventoy or installed system
        I->>I: Exit silently
    end
```

## Installer Launch Flow

```mermaid
sequenceDiagram
    participant U as User
    participant D as Desktop Entry
    participant A as mados-installer-autostart
    participant I as /usr/local/bin/mados-installer
    participant G as GTK UI

    U->>D: Click "madOS Installer" or run command
    D->>A: sudo /usr/local/bin/mados-installer-autostart
    
    rect rgb(240, 248, 255)
        note right of A: Pre-flight checks
        A->>A: Check /run/archiso (live env?)
        A->>A: Check /proc/cmdline (Ventoy?)
        A->>A: Fix pacman-db (pacman-key)
    end
    
    A->>A: Set GDK_BACKEND=wayland
    A->>I: Execute installer
    I->>G: Launch GTK window
    G-->>U: Show installer UI
```

## First Boot Setup (OpenCode/Ollama)

```mermaid
sequenceDiagram
    participant S as Systemd
    participant B as bash
    participant O as OpenCode
    participant L as Ollama
    
    S->>B: Execute setup-opencode.sh (Type=oneshot)
    
    B->>B: Check network connectivity
    alt No network
        B->>B: Check /run/archiso (live USB)
        B->>B: Copy from live USB if available
    else Has network
        B->>O: Download/install OpenCode
        O->>B: Return success/failure
    end
    
    S->>B: Execute setup-ollama.sh (Type=oneshot)
    
    B->>B: Check network connectivity
    alt No network
        B->>B: Check /run/archiso
        B->>B: Copy from live USB if available
    else Has network
        B->>L: Download Ollama binary
        L->>B: Return success/failure
    end
    
    B->>B: Configure zshrc with aliases
    B-->>S: Exit 0 (always succeed)
```

## USB Persistence Detection

```mermaid
sequenceDiagram
    participant K as Kernel
    participant D as mados-persist-detect.sh
    participant P as blkid
    participant M as mount
    participant C as mados-persist-sync.sh

    K->>D: Run via systemd (persist-detect.service)
    
    D->>P: blkid -o device -s LABEL
    P-->>D: List block devices
    
    loop Each block device
        D->>P: blkid -s PERSISTENT
        alt Has PERSISTENT flag
            D->>M: Mount persistence partition
            M-->>D: /run/mnt/persist
            
            D->>D: Check /run/mnt/persist/mados/
            alt madOS data exists
                D->>C: Sync to /home/mados
                C-->>D: Sync complete
            end
            
            D->>M: Umount
        else No persistence
            D->>D: Continue (no persistence)
        end
    end
    
    D-->>K: Exit
```

## Desktop App Launch (Gamepad Mode)

```mermaid
sequenceDiagram
    participant G as Gamepad Input
    participant W as Sway/Hyprland
    participant GM as mados-gamepad-wm
    participant M as mados-launcher
    participant A as mados-video-player
    
    G->>GM: Gamepad button press
    GM->>GM: Detect gamepad event
    GM->>GM: Check game session active
    
    alt Gamepad mode enabled
        GM->>W: Enable gamepad bindings
        GM->>W: Map gamepad to keyboard
        
        G->>GM: Navigate with d-pad
        GM->>W: Inject key events
        W->>M: Open launcher
        
        M->>A: Launch selected app
        A-->>U: Show fullscreen app
    else Normal desktop
        G->>W: Pass through to normal input
    end
```