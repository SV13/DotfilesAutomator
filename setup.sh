#!/usr/bin/env bash

# Global flags
DRY_RUN=false

# Fail fast settings for safe execution
set -euo pipefail

# ------------------------------------------------------------------------------
# COLOR LOGGING HELPERS
# ------------------------------------------------------------------------------
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color / Reset

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# ------------------------------------------------------------------------------
# PARSE FLAGS
# ------------------------------------------------------------------------------
parse_flags() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                log_warning "DRY RUN MODE ENABLED — No changes will be made to your system."
                shift
                ;;
            -h|--help)
                echo "Usage: ./setup.sh [--dry-run] [--help]"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

# ------------------------------------------------------------------------------
# OS DETECTION
# ------------------------------------------------------------------------------
OS=""

detect_os() {
    log_info "Detecting operating system..."
    
    case "$(uname -s)" in
        Darwin*)
            OS="macos"
            log_success "Environment: macOS detected"
            ;;
        Linux*)
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                case "$ID" in
                    ubuntu|debian)
                        OS="debian"
                        log_success "Environment: Debian/Ubuntu detected"
                        ;;
                    fedora|rhel|centos)
                        OS="redhat"
                        log_success "Environment: RedHat/Fedora family detected"
                        ;;
                    *)
                        log_warning "Generic Linux detected ($ID). Defaulting to Debian mode."
                        OS="debian"
                        ;;
                esac
            else
                log_error "Unsupported Linux distribution."
                exit 1
            fi
            ;;
        *)
            log_error "Unsupported Operating System: $(uname -s)"
            exit 1
            ;;
    esac
}

# ------------------------------------------------------------------------------
# PACKAGE DEFINITIONS & INSTALLATION
# ------------------------------------------------------------------------------
DEBIAN_PACKAGES=(
    "git"
    "curl"
    "wget"
    "jq"
    "build-essential"
    "tmux"
    "htop"
)

MACOS_PACKAGES=(
    "git"
    "curl"
    "jq"
    "tmux"
    "htop"
)

install_debian_packages() {
    log_info "Updating package indices..."
    if [ "$DRY_RUN" = false ]; then
        sudo apt-get update -y > /dev/null 2>&1
    fi

    for pkg in "${DEBIAN_PACKAGES[@]}"; do
        if dpkg -l "$pkg" > /dev/null 2>&1; then
            log_warning "Package '$pkg' is already installed. Skipping..."
        else
            if [ "$DRY_RUN" = true ]; then
                log_info "[DRY-RUN] Would execute: sudo apt-get install -y '$pkg'"
            else
                log_info "Installing '$pkg'..."
                sudo apt-get install -y "$pkg" > /dev/null 2>&1
                log_success "Package '$pkg' installed successfully."
            fi
        fi
    done
}

install_macos_packages() {
    if ! command -v brew > /dev/null 2>&1; then
        log_info "Homebrew not found. Installing Homebrew..."
        if [ "$DRY_RUN" = false ]; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
    fi

    for pkg in "${MACOS_PACKAGES[@]}"; do
        if brew list "$pkg" > /dev/null 2>&1; then
            log_warning "Formula '$pkg' is already installed. Skipping..."
        else
            if [ "$DRY_RUN" = true ]; then
                log_info "[DRY-RUN] Would execute: brew install '$pkg'"
            else
                log_info "Installing '$pkg' via Homebrew..."
                brew install "$pkg" > /dev/null 2>&1
                log_success "Formula '$pkg' installed successfully."
            fi
        fi
    done
}

setup_packages() {
    log_info "Starting package installation phase..."
    case "$OS" in
        debian)
            install_debian_packages
            ;;
        macos)
            install_macos_packages
            ;;
        *)
            log_error "No package installer configured for OS type: $OS"
            exit 1
            ;;
    esac
}

# ------------------------------------------------------------------------------
# DOTFILES SYMLINKING
# ------------------------------------------------------------------------------
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/configs"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

link_dotfile() {
    local src="$1"
    local filename="$(basename "$src")"
    local target="$HOME/$filename"

    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ "$(readlink -f "$target")" == "$src" ]; then
            log_warning "Link for '$filename' already exists and points to repo. Skipping..."
            return
        fi

        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY-RUN] Would backup '$target' to '$BACKUP_DIR/$filename'"
        else
            if [ ! -d "$BACKUP_DIR" ]; then
                log_info "Creating backup directory at: $BACKUP_DIR"
                mkdir -p "$BACKUP_DIR"
            fi
            log_warning "Existing '$filename' found. Backing up to $BACKUP_DIR/$filename"
            mv "$target" "$BACKUP_DIR/$filename"
        fi
    fi

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would symlink '$src' -> '$target'"
    else
        log_info "Linking '$src' -> '$target'..."
        ln -sfn "$src" "$target"
        log_success "Symlinked '$filename' successfully."
    fi
}

setup_symlinks() {
    log_info "Starting dotfiles symlinking phase..."

    if [ ! -d "$DOTFILES_DIR" ]; then
        log_error "Config directory '$DOTFILES_DIR' does not exist."
        exit 1
    fi

    shopt -s dotglob
    for config_file in "$DOTFILES_DIR"/.*; do
        local base_name="$(basename "$config_file")"
        if [ "$base_name" == "." ] || [ "$base_name" == ".." ]; then
            continue
        fi

        if [ -f "$config_file" ]; then
            link_dotfile "$config_file"
        fi
    done
    shopt -u dotglob
}

# ------------------------------------------------------------------------------
# MAIN EXECUTION FLOW
# ------------------------------------------------------------------------------
main() {
    # 1. Parse CLI arguments
    parse_flags "$@"

    log_info "Starting environment automator..."
    detect_os
    
    # 2. Package management
    setup_packages
    
    # 3. Symlink dotfiles
    setup_symlinks
    
    log_success "Setup phase complete!"
}

main "$@"