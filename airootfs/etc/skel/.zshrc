# ~/.zshrc - madOS Zsh Configuration

# If not running interactively, don't do anything
[[ -o interactive ]] || return

# Path to Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Oh My Zsh theme
ZSH_THEME="agnoster"

# Oh My Zsh plugins
plugins=(git sudo command-not-found)

# Load Oh My Zsh if installed
if [ -d "$ZSH" ]; then
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

💻 Type 'fastfetch' to see system info
💻 Type 'opencode' to start the AI assistant

EOF
    fi
fi

# NVM (Node Version Manager) - para npm a nivel de usuario
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    # shellcheck source=/dev/null
    source "$NVM_DIR/nvm.sh"
    # Set default node version
    if command -v nvm &>/dev/null; then
        nvm alias default system 2>/dev/null || true
    fi
fi
