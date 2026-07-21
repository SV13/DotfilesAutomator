# Cross-Platform Dotfiles Automator

An idempotent, production-ready Bash automation tool designed to set up development environments, install core packages, and safely manage user configuration dotfiles across Linux and macOS systems.

---

## Features

- **Cross-Platform Support:** Automatically detects the host operating system (`Debian`, `Ubuntu`, `Kali Linux`, or `macOS`) and installs packages using the appropriate package manager.
- **Idempotent Execution:** Skips packages and symbolic links that already exist, preventing redundant operations.
- **Safe Configuration Backups:** Creates timestamped backups (`~/.dotfiles_backup_YYYYMMDD_HHMMSS`) before replacing existing configuration files.
- **Dry-Run Mode:** Preview every action using `--dry-run` without making any system changes.
- **Enhanced Terminal Output:** Color-coded logging for `INFO`, `SUCCESS`, `WARNING`, and `ERROR` messages.
- **Strict Shell Safety:** Uses `set -euo pipefail` to improve reliability and fail safely on unexpected errors.

---

## Supported Platforms

| Operating System | Package Manager |
|------------------|-----------------|
| Debian | `apt` |
| Ubuntu | `apt` |
| Kali Linux | `apt` |
| macOS | `brew` |

---

## Prerequisites

Before running the script, ensure you have:

- Bash 4.0 or later
- Git

---

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/SV13/DotfilesAutomator.git
cd DotfilesAutomator
```

---

### 2. Make the Script Executable

```bash
chmod +x setup.sh
```

---

### 3. Preview Changes (Dry-Run)

Run the script in dry-run mode to see what changes will be made without modifying your system.

```bash
./setup.sh --dry-run
```

---

### 4. Run the Installation

Once you're satisfied with the preview, execute the full installation.

```bash
./setup.sh
```

---

## Project Structure

```text
DotfilesAutomator/
├── setup.sh          # Main automation script
├── configs/          # Configuration files (.bashrc, .vimrc, .tmux.conf, etc.)
├── README.md         # Project documentation
└── .gitignore        # Git ignore rules
```

---

## How It Works

The automation script performs the following steps:

1. Detects the host operating system.
2. Selects the appropriate package manager.
3. Installs required development packages.
4. Creates timestamped backups of existing configuration files.
5. Creates symbolic links to the managed dotfiles.
6. Skips any resources that are already correctly configured.

Because the script is **idempotent**, it can be executed multiple times without duplicating installations or overwriting unchanged configurations.

---

## License

This project is licensed under the MIT License.