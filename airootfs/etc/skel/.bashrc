# ~/.bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# User PATH
export PATH="$HOME/.local/bin:$PATH"

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

╔══════════════════════════════════════════════════════╗
║                                                      ║
║     ███╗   ███╗ █████╗ ██████╗  ██████╗ ███████╗     ║
║     ████╗ ████║██╔══██╗██╔══██╗██╔═══██╗██╔════╝     ║
║     ██╔████╔██║███████║██║  ██║██║   ██║███████╗     ║
║     ██║╚██╔╝██║██╔══██║██║  ██║██║   ██║╚════██║     ║
║     ██║ ╚═╝ ██║██║  ██║██████╔╝╚██████╔╝███████║     ║
║     ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚══════╝     ║
║                                                      ║
║                  ArchLinux System                    ║
║            Powered by Ollama and OpenCode            ║
║                                                      ║
╚══════════════════════════════════════════════════════╝

EOF
    fi
fi
