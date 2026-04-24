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
        M->>M: Setup systemd-boot (UEFI)
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
    participant W as Hyprland
    participant I as mados-installer-autostart

    B->>K: Load Linux + initramfs
    K->>S: Boot systemd
    S->>A: Mount squashfs (read-only)
    S->>S: Start display manager (SDDM)
    
    S->>W: Launch compositor
    W->>W: Load hyprland config
    W->>W: Start waybar, wallpaper, etc.
    
    W->>I: Execute autostart scripts
    alt In archiso live environment
        I->>I: Check /run/archiso exists
        I->>I: Launch installer at /usr/local/bin/mados-installer
    else Installed system
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
    end

    A->>I: Execute installer
    I->>G: Launch GTK window
    G-->>U: Show installer UI
```

## Desktop App Launch (Gamepad Mode)

```mermaid
sequenceDiagram
    participant G as Gamepad Input
    participant W as Hyprland
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
