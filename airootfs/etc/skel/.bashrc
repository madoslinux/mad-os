# ~/.bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Aliases
alias ls='ls --color=auto'
alias ll='ls -lah'
alias grep='grep --color=auto'

# Prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Welcome message on live USB
if [ -f /etc/hostname ] && grep -q "mados" /etc/hostname 2>/dev/null; then
    # Only show on first terminal open
    if [ ! -f /tmp/.madOS-welcome-shown ]; then
        touch /tmp/.madOS-welcome-shown
        cat << 'EOF'

╔═══════════════════════════════════════════════════╗
║                                                   ║
║     ███╗   ███╗ █████╗ ██████╗  ██████╗ ███████╗ ║
║     ████╗ ████║██╔══██╗██╔══██╗██╔═══██╗██╔════╝ ║
║     ██╔████╔██║███████║██║  ██║██║   ██║███████╗ ║
║     ██║╚██╔╝██║██╔══██║██║  ██║██║   ██║╚════██║ ║
║     ██║ ╚═╝ ██║██║  ██║██████╔╝╚██████╔╝███████║ ║
║     ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚══════╝ ║
║                                                   ║
║         AI-Orchestrated Arch Linux System        ║
║               Powered by OpenCode                ║
║                                                   ║
╚═══════════════════════════════════════════════════╝

Welcome to madOS Live Environment!

📦 To install madOS to disk:
   sudo /usr/local/bin/mados-installer

🌐 Network setup:
   nmtui                    (Network Manager TUI)
   sudo systemctl start iwd (WiFi daemon)

💻 System specs:
   • Sway Wayland compositor
   • OpenCode AI assistant
   • Optimized for 1.9GB RAM
   • Intel Atom support

📚 Keyboard shortcuts:
   Super+Enter      - Open terminal
   Super+D          - Application launcher
   Super+Q          - Close window

🐛 Debugging:
   mados-debug              (quick system diagnostics)
   mados-debug chromium     (Chromium logs)
   mados-debug apps         (Python app diagnostics)
   less /usr/share/doc/madOS/DEBUGGING.md

Type 'opencode' to start the AI assistant (after installation)

EOF
    fi
fi
