#!/usr/bin/env bash
# =============================================================================
#  setup.sh — dotfiles-linux Bootstrap Installer
#  Part of dotfiles-linux (https://github.com/razafimandimby-IT/dotfiles-linux)
# =============================================================================
#
#  Usage:
#    ./setup.sh              — Create symlinks only
#    ./setup.sh --all        — Symlinks + install packages + configure
#    ./setup.sh --update     — Update existing symlinks
#    ./setup.sh --help       — Show help message
#
#  This script will:
#    1. Backup existing dotfiles to ~/.dotfiles-backup/
#    2. Symlink dotfiles to $HOME
#    3. Optionally install packages and tools
#    4. Configure git global settings
#    5. Generate SSH key if needed
# =============================================================================

set -euo pipefail

# ── Constants ────────────────────────────────────────────────────────────────

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$HOME/.dotfiles-setup.log"

# Files to symlink (relative to DOTFILES_DIR)
DOTFILES=(
    ".bashrc"
    ".bash_aliases"
    ".bash_functions"
    ".gitconfig"
    ".vimrc"
)

# Directories to create
SCRIPTS_DIR="$DOTFILES_DIR/scripts"

# Packages to install (by category)
PKGS_ESSENTIAL=(
    curl
    wget
    git
    vim
    htop
    tmux
    tree
    unzip
    zip
    gzip
    bzip2
    xz-utils
    rsync
    gnupg
    ca-certificates
)

PKGS_UTILITY=(
    ripgrep
    fzf
    bat
    ncdu
    jq
    httpie
    tldr
    shellcheck
    python3-pip
    python3-venv
)

PKGS_DEV=(
    build-essential
    gcc
    make
    cmake
    pkg-config
    libssl-dev
    libffi-dev
    libyaml-dev
    zlib1g-dev
)

PKGS_MONITORING=(
    net-tools
    nmap
    iperf3
    mtr
    traceroute
    dnsutils
    whois
    strace
    sysstat
    lsof
    iotop
    smartmontools
)

# ── Colors ───────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ── Helper Functions ─────────────────────────────────────────────────────────

log() {
    local level="$1"
    shift
    local msg="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${msg}" >> "$LOG_FILE"

    case "$level" in
        INFO)  echo -e "${GREEN}[INFO]${NC} $msg" ;;
        WARN)  echo -e "${YELLOW}[WARN]${NC} $msg" ;;
        ERROR) echo -e "${RED}[ERROR]${NC} $msg" ;;
        STEP)  echo -e "\n${CYAN}━━━ $msg ━━━${NC}" ;;
        *)     echo -e "$msg" ;;
    esac
}

info()    { log "INFO" "$*"; }
warn()    { log "WARN" "$*"; }
error()   { log "ERROR" "$*" >&2; }
step()    { log "STEP" "$*"; }

confirm() {
    read -r -p "$1 [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

# ── Detect OS & Package Manager ─────────────────────────────────────────────

detect_pm() {
    if command -v apt &>/dev/null; then
        PM="apt"
        PM_INSTALL="sudo apt install -y"
        PM_UPDATE="sudo apt update"
        PM_UPGRADE="sudo apt upgrade -y"
    elif command -v dnf &>/dev/null; then
        PM="dnf"
        PM_INSTALL="sudo dnf install -y"
        PM_UPDATE="sudo dnf check-update || true"
        PM_UPGRADE="sudo dnf upgrade -y"
    elif command -v yum &>/dev/null; then
        PM="yum"
        PM_INSTALL="sudo yum install -y"
        PM_UPDATE="sudo yum check-update || true"
        PM_UPGRADE="sudo yum update -y"
    elif command -v pacman &>/dev/null; then
        PM="pacman"
        PM_INSTALL="sudo pacman -S --noconfirm"
        PM_UPDATE="sudo pacman -Sy"
        PM_UPGRADE="sudo pacman -Syu --noconfirm"
    elif command -v zypper &>/dev/null; then
        PM="zypper"
        PM_INSTALL="sudo zypper install -y"
        PM_UPDATE="sudo zypper refresh"
        PM_UPGRADE="sudo zypper update -y"
    else
        PM="unknown"
        warn "No supported package manager found."
        warn "You will need to install packages manually."
    fi
    info "Detected package manager: ${PM:-unknown}"
}

# ── Install Packages ─────────────────────────────────────────────────────────

install_packages() {
    step "Installing Packages"

    if [ "$PM" = "unknown" ]; then
        warn "Skipping package installation (no known package manager)."
        return
    fi

    info "Updating package repositories..."
    eval "$PM_UPDATE" || true

    # Combine all packages
    local all_pkgs=("${PKGS_ESSENTIAL[@]}" "${PKGS_UTILITY[@]}" "${PKGS_DEV[@]}" "${PKGS_MONITORING[@]}")

    info "Installing ${#all_pkgs[@]} packages..."
    if [ "$PM" = "apt" ]; then
        eval "$PM_INSTALL" "${all_pkgs[@]}" || warn "Some packages could not be installed."
    elif [ "$PM" = "dnf" ] || [ "$PM" = "yum" ]; then
        # Map Debian package names to RPM equivalents
        local rpm_pkgs=()
        for pkg in "${all_pkgs[@]}"; do
            case "$pkg" in
                build-essential)   rpm_pkgs+=("gcc" "gcc-c++" "make") ;;
                python3-pip)       rpm_pkgs+=("python3-pip") ;;
                python3-venv)      rpm_pkgs+=("python3-venv" 2>/dev/null || python3 -m venv --help &>/dev/null && true) ;;
                libssl-dev)        rpm_pkgs+=("openssl-devel") ;;
                libffi-dev)        rpm_pkgs+=("libffi-devel") ;;
                libyaml-dev)       rpm_pkgs+=("libyaml-devel") ;;
                zlib1g-dev)        rpm_pkgs+=("zlib-devel") ;;
                xz-utils)          rpm_pkgs+=("xz") ;;
                net-tools)         rpm_pkgs+=("net-tools") ;;
                dnsutils)          rpm_pkgs+=("bind-utils") ;;
                shellcheck)        rpm_pkgs+=("ShellCheck") ;;
                *)                 rpm_pkgs+=("$pkg") ;;
            esac
        done
        eval "$PM_INSTALL" "${rpm_pkgs[@]}" || warn "Some packages could not be installed."
    elif [ "$PM" = "pacman" ]; then
        local arch_pkgs=()
        for pkg in "${all_pkgs[@]}"; do
            case "$pkg" in
                build-essential)   arch_pkgs+=("base-devel") ;;
                libssl-dev)        arch_pkgs+=("openssl") ;;
                libffi-dev)        arch_pkgs+=("libffi") ;;
                libyaml-dev)       arch_pkgs+=("libyaml") ;;
                zlib1g-dev)        arch_pkgs+=("zlib") ;;
                xz-utils)          arch_pkgs+=("xz") ;;
                python3-pip)       arch_pkgs+=("python-pip") ;;
                python3-venv)      arch_pkgs+=("python-virtualenv") ;;
                net-tools)         arch_pkgs+=("net-tools") ;;
                dnsutils)          arch_pkgs+=("bind") ;;
                shellcheck)        arch_pkgs+=("shellcheck") ;;
                *)                 arch_pkgs+=("$pkg") ;;
            esac
        done
        eval "$PM_INSTALL" "${arch_pkgs[@]}" || warn "Some packages could not be installed."
    else
        eval "$PM_INSTALL" "${all_pkgs[@]}" || warn "Some packages could not be installed."
    fi

    # ── Install additional tools if available ──
    info "Installing additional CLI tools..."

    # Install bat (if not already installed via packages)
    if ! command -v bat &>/dev/null && command -v batcat &>/dev/null; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
        info "Symlinked batcat -> bat"
    fi

    info "Package installation complete."
}

# ── Backup Existing Dotfiles ────────────────────────────────────────────────

backup_dotfiles() {
    step "Backing Up Existing Dotfiles"

    mkdir -p "$BACKUP_DIR"

    for file in "${DOTFILES[@]}"; do
        local src="$HOME/$file"
        if [ -f "$src" ] || [ -L "$src" ]; then
            cp -L "$src" "$BACKUP_DIR/" 2>/dev/null || cp "$src" "$BACKUP_DIR/" 2>/dev/null || true
            info "Backed up: $file"
        fi
    done

    info "Backup created at: $BACKUP_DIR"
}

# ── Create Symlinks ──────────────────────────────────────────────────────────

create_symlinks() {
    step "Creating Symlinks"

    for file in "${DOTFILES[@]}"; do
        local src="$DOTFILES_DIR/$file"
        local dest="$HOME/$file"

        if [ ! -f "$src" ]; then
            warn "Source file not found: $src — skipping"
            continue
        fi

        # Remove existing file/symlink
        if [ -L "$dest" ] || [ -f "$dest" ]; then
            rm -f "$dest"
            info "Removed existing: $dest"
        fi

        ln -sf "$src" "$dest"
        info "Linked: $src → $dest"
    done

    # Copy scripts directory (not symlinked to avoid breaking paths)
    if [ -d "$SCRIPTS_DIR" ]; then
        mkdir -p "$HOME/scripts"
        for script in "$SCRIPTS_DIR"/*.sh; do
            if [ -f "$script" ]; then
                cp "$script" "$HOME/scripts/"
                chmod +x "$HOME/scripts/$(basename "$script")"
                info "Copied script: $(basename "$script") → ~/scripts/"
            fi
        done
    fi

    info "Symlinks created successfully."
}

# ── Setup Git Configuration ─────────────────────────────────────────────────

setup_git() {
    step "Configuring Git"

    # Set default branch name
    git config --global init.defaultBranch main

    # Ask for user info if not already configured
    local current_name current_email
    current_name=$(git config --global user.name 2>/dev/null || echo "")
    current_email=$(git config --global user.email 2>/dev/null || echo "")

    if [ -z "$current_name" ]; then
        info "Git user.name is not set."
        echo ""
        echo " Enter your Git user information:"
        echo " (Leave blank and press Enter to skip)"
        read -r -p "  Name: " git_name
        read -r -p "  Email: " git_email
        echo ""

        if [ -n "$git_name" ]; then
            git config --global user.name "$git_name"
            info "Git user.name set to: $git_name"
        fi
        if [ -n "$git_email" ]; then
            git config --global user.email "$git_email"
            info "Git user.email set to: $git_email"
        fi
    else
        info "Git user already configured: $current_name <$current_email>"
    fi

    # Set up credential helper
    git config --global credential.helper 'cache --timeout=3600'
    info "Git credential helper set (1-hour cache)."
}

# ── Generate SSH Key ────────────────────────────────────────────────────────

setup_ssh() {
    step "SSH Key Setup"

    local ssh_key="$HOME/.ssh/id_ed25519"

    if [ -f "$ssh_key" ]; then
        info "SSH key already exists: $ssh_key"
        info "Public key: ${ssh_key}.pub"
        cat "${ssh_key}.pub"
    else
        if confirm "No SSH key found. Generate a new Ed25519 key?"; then
            mkdir -p "$HOME/.ssh"
            chmod 700 "$HOME/.ssh"
            ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)-$(date +%Y-%m-%d)" -f "$ssh_key" -N ""
            chmod 600 "$ssh_key"
            chmod 644 "${ssh_key}.pub"
            info "SSH key generated: $ssh_key"
            echo ""
            echo "Your public SSH key:"
            cat "${ssh_key}.pub"
            echo ""
            info "Add this key to your GitHub/GitLab account."
        fi
    fi
}

# ── Setup FZF (Fuzzy Finder) ────────────────────────────────────────────────

setup_fzf() {
    if command -v fzf &>/dev/null; then
        info "FZF is already installed."
        return
    fi

    if confirm "Install FZF (fuzzy finder) from source?"; then
        if command -v git &>/dev/null; then
            git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf" 2>/dev/null
            if [ -f "$HOME/.fzf/install" ]; then
                "$HOME/.fzf/install" --all 2>/dev/null || true
                info "FZF installed."
            fi
        fi
    fi
}

# ── Ensure Scripts Are Executable ───────────────────────────────────────────

make_executable() {
    if [ -d "$SCRIPTS_DIR" ]; then
        chmod +x "$SCRIPTS_DIR"/*.sh 2>/dev/null || true
        info "Made scripts executable."
    fi
}

# ── Post-Install Message ────────────────────────────────────────────────────

show_summary() {
    step "Setup Complete"

    echo ""
    echo -e "${GREEN}${BOLD}  ✓ dotfiles-linux has been installed!${NC}"
    echo ""
    echo "  Files installed:"
    for file in "${DOTFILES[@]}"; do
        echo "    • ~/$file"
    done
    echo "    • ~/scripts/*.sh"
    echo ""
    echo "  Backup location: $BACKUP_DIR"
    echo "  Log file: $LOG_FILE"
    echo ""
    echo "  ${YELLOW}To apply changes, run:${NC}"
    echo "    source ~/.bashrc"
    echo ""
    echo "  ${YELLOW}Available commands after setup:${NC}"
    echo "    system-info    — Show system information dashboard"
    echo "    my-ip          — Show public and local IPs"
    echo "    extract <file> — Extract any archive automatically"
    echo "    backup <path>  — Create timestamped backup"
    echo "    mkcd <dir>     — Create and cd into a directory"
    echo "    process-menu   — Interactive process manager"
    echo "    timer <sec>    — Countdown timer"
    echo ""
    echo "  ${YELLOW}Check the log for details:${NC} $LOG_FILE"
    echo ""
}

# ── Main ────────────────────────────────────────────────────────────────────

main() {
    # Parse arguments
    local action="${1:-}"
    echo ""
    echo -e "${BLUE}${BOLD}  ╔══════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}${BOLD}  ║       dotfiles-linux Bootstrap Setup     ║${NC}"
    echo -e "${BLUE}${BOLD}  ║  linux dotfiles for sysadmins            ║${NC}"
    echo -e "${BLUE}${BOLD}  ╚══════════════════════════════════════════╝${NC}"
    echo ""

    case "$action" in
        --help|-h)
            echo "Usage: ./setup.sh [OPTION]"
            echo ""
            echo "Options:"
            echo "  (none)    Create symlinks only"
            echo "  --all     Full install: symlinks + packages + config"
            echo "  --update  Update existing symlinks"
            echo "  --help    Show this help message"
            exit 0
            ;;
        --update)
            info "Updating dotfiles..."
            create_symlinks
            info "Update complete."
            exit 0
            ;;
        --all)
            info "Starting full installation..."
            detect_pm
            backup_dotfiles
            create_symlinks
            install_packages
            setup_git
            setup_ssh
            setup_fzf
            make_executable
            show_summary
            ;;
        "")
            warn "Running in symlink-only mode. Use '--all' for full setup."
            backup_dotfiles
            create_symlinks
            make_executable
            echo ""
            info "Symlinks created. Run 'source ~/.bashrc' to apply."
            echo ""
            ;;
        *)
            error "Unknown option: $action"
            echo "Usage: ./setup.sh [--all|--update|--help]"
            exit 1
            ;;
    esac
}

main "$@"
