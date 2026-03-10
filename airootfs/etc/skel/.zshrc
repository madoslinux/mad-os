# ~/.zshrc - madOS Zsh Configuration

# If not running interactively, don't do anything
[[ -o interactive ]] || return

# Path to Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Oh My Zsh theme
ZSH_THEME="agnoster"

# Oh My Zsh plugins
plugins=(git sudo command-not-found)

# Load Oh My Zsh if installed and readable
if [ -d "$ZSH" ] && [ -f "$ZSH/oh-my-zsh.sh" ]; then
    source "$ZSH/oh-my-zsh.sh"
else
    # Fallback prompt if Oh My Zsh is not yet installed
    PROMPT='%F{green}%n@%m%f:%F{blue}%~%f%# '
fi

# Aliases
alias ls='ls --color=auto'
alias ll='ls -lah'
alias grep='grep --color=auto'

# Welcome message on live USB
if [ -f /etc/hostname ] && grep -q "mados" /etc/hostname 2>/dev/null; then
    # Only show on first terminal open per session
    if [ ! -f /tmp/.madOS-welcome-shown-zsh ]; then
        touch /tmp/.madOS-welcome-shown-zsh
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
║         AI-Orchestrated Arch Linux System            ║
║           Powered by Ollama and OpenCode             ║
║                                                      ║
╚══════════════════════════════════════════════════════╝

EOF
    fi
fi
