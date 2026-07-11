# dotfiles-linux

[![Linux](https://img.shields.io/badge/OS-Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://www.linux.org/)
[![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Git](https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white)](https://git-scm.com/)
[![Vim](https://img.shields.io/badge/Editor-Vim-019733?style=for-the-badge&logo=vim&logoColor=white)](https://www.vim.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg?style=for-the-badge)](https://github.com/razafimandimby-IT/dotfiles-linux/graphs/commit-activity)

> Personal Linux configuration files (dotfiles) for system administrators — aliases, functions, scripts, and development environment setup.

---

## ✨ Features

- **Enhanced Shell Experience** — Colorful prompt with Git branch detection, directory status indicators, and command-not-found suggestions
- **Sysadmin Aliases** — Quick shortcuts for `systemctl`, `journalctl`, `docker`, `apt`, `network` diagnostics, and more
- **Productive Functions** — Archive extraction, system info display, process management, backup helpers, and math eval
- **Vim Configuration** — Minimal but powerful `.vimrc` with syntax highlighting, line numbers, and sensible defaults
- **Git Shortcuts** — Clean `.gitconfig` with useful aliases (`gco`, `gst`, `glg`, `gba`, etc.)
- **Bootstrap Script** — One-command setup with symlinks, package installation, and optional tooling
- **Utility Scripts** — System information dashboard and automated backup script

---

## Quick Install

```bash
bash <(curl -sSL https://raw.githubusercontent.com/razafimandimby-IT/dotfiles-linux/main/setup.sh)
```

Or, for a full install with symlinks and recommended packages:

```bash
curl -sSL https://raw.githubusercontent.com/razafimandimby-IT/dotfiles-linux/main/setup.sh | bash -s -- --all
```

---

## Contents

| File | Description |
|------|-------------|
| `.bashrc` | Main Bash configuration — color support, custom prompt (`user@host:dir$` with colors), history tuning, and interactive shell settings |
| `.bash_aliases` | 40+ aliases grouped by category (system, Docker, Git, networking, apt, file management) |
| `.bash_functions` | Reusable shell functions — `extract()` (auto-detect archive format), `backup()`, `system-info()`, `process-menu()`, `calc()`, `mkcd()` |
| `.gitconfig` | Git user config with color UI, aliases (`gco`, `gst`, `glg`, `gba`, `grm`), and diff settings |
| `.vimrc` | Minimal Vim setup — line numbers, syntax highlighting, 4-space tabs, search improvements, mouse support |
| `setup.sh` | Bootstrap installer — creates symlinks, installs packages (bat, ripgrep, fzf, htop, tmux, neovim), sets up Git, and applies configs |
| `scripts/system-info.sh` | System information dashboard — displays OS, kernel, uptime, CPU, RAM, disk usage, network interfaces, and running services |
| `scripts/backup.sh` | Configurable backup script — supports full/incremental backups with compression, encryption, remote sync, and retention policies |

---

## File Details

### `.bashrc` — Shell Configuration

- Enables 256-color support and sets the `TERM` variable appropriately
- Custom PS1 prompt: `[user@host dir]$\n` with current Git branch display when inside a repository
- History configuration: large history file (10000 lines), ignores duplicates and commands starting with spaces
- Sources `.bash_aliases` and `.bash_functions` if they exist
- Smart tab completion configuration

### `.bash_aliases` — Sysadmin Aliases

**System & Services**
```bash
alias sys-start='sudo systemctl start'
alias sys-stop='sudo systemctl stop'
alias sys-restart='sudo systemctl restart'
alias sys-status='systemctl status'
alias sys-enable='sudo systemctl enable'
alias sys-disable='sudo systemctl disable'
alias sys-reload='sudo systemctl daemon-reload'
alias jlog='journalctl -xe --no-pager -n 50'
alias jlog-f='journalctl -f'
alias jlog-u='journalctl -xe -u'
```

**Docker**
```bash
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dlog='docker logs -f'
alias dexec='docker exec -it'
alias dstop='docker stop'
alias drm='docker rm'
alias dimg='docker images'
alias dprune='docker system prune -a -f'
```

**Networking**
```bash
alias myip='curl -s ifconfig.me'
alias localip='ip -4 addr show | grep -oP "(?<=inet\s)\d+(\.\d+){3}" | grep -v 127.0.0.1'
alias ports='ss -tulanp'
alias netstat='ss -tuln'
alias ping='ping -c 4'
```

### `.bash_functions` — Shell Functions

| Function | Description |
|----------|-------------|
| `extract <file>` | Extract any archive (.tar.gz, .tar.bz2, .zip, .rar, .7z) by auto-detecting the format |
| `backup <path>` | Copy a file/directory with a `.bak` suffix and timestamp |
| `system-info` | Display a clean summary of OS, kernel, CPU, RAM (total/used/free), disk usage, and uptime |
| `mkcd <dir>` | Create a directory and change into it in one command |
| `calc <expression>` | Evaluate a mathematical expression using Python |
| `process-menu` | Interactive process viewer with kill option using `fzf` |
| `my-ip` | Display both public and local IP addresses |

### `.gitconfig` — Git Aliases

```ini
[alias]
    co = checkout
    br = branch
    ci = commit
    st = status
    lg = log --oneline --graph --decorate --all
    lga = log --oneline --graph --decorate --all --show-notes
    aa = add --all
    unstage = reset HEAD --
    last = log -1 HEAD
    amend = commit --amend --no-edit
    undo = reset --soft HEAD~1
    dc = diff --cached
    ba = branch -a
    rm = branch -d
    rmm = branch -D
    pullr = pull --rebase
    pf = push --force-with-lease
    cleanup = !git branch --merged | grep -v \"\\*\\|main\\|master\" | xargs -r git branch -d
```

### `.vimrc` — Vim Configuration

Simple, no-plugin Vim setup:
- Line numbers (relative + absolute hybrid on modern Vim)
- 4-space tabs with `expandtab`
- Syntax highlighting enabled
- Search highlighting with `/` and `?` case-insensitive
- Mouse support for resizing panes
- 80-character color column indicator
- Persistent undo

### `setup.sh` — Bootstrap Script

The setup script does the following:
1. Creates backup of existing dotfiles in `~/.dotfiles-backup/`
2. Symlinks all configuration files to `$HOME`
3. Installs system packages (bat, ripgrep, fzf, htop, tmux, neovim, htop, curl, wget, git, vim)
4. Installs CLI tools via snap or cargo if available
5. Generates SSH key if none exists
6. Configures global Git settings (user name, email, default branch)
7. Detects the OS package manager (apt, dnf, pacman, zypper) and installs accordingly

### `scripts/system-info.sh`

A system dashboard that displays:

```
======================== SYSTEM INFORMATION ========================
 OS:          Ubuntu 22.04.3 LTS (x86_64)
 Kernel:      6.2.0-26-generic
 Hostname:    server-01
 Uptime:      12 days, 7 hours, 43 minutes
─────────────────────────────────────────────────────────────────────
 CPU:         Intel(R) Xeon(R) E-2288G CPU @ 3.70GHz
 Cores:       8 physical / 16 logical
 Load Avg:    0.52, 0.41, 0.35
─────────────────────────────────────────────────────────────────────
 Memory:      31.2 GiB total | 12.6 GiB used | 16.4 GiB free
 Swap:        4.0 GiB total | 0.0 GiB used | 4.0 GiB free
─────────────────────────────────────────────────────────────────────
 Disk /:      220G used / 456G total (51%) | /dev/sda2
 Disk /home:  340G used / 890G total (39%) | /dev/sdb1
─────────────────────────────────────────────────────────────────────
 Network:
   eth0:      192.168.1.100/24 (1000 Mbps) | rx: 1.2 TB  tx: 85.3 GB
   wlan0:     10.0.0.5/16 (300 Mbps)       | rx: 45.2 GB tx: 12.1 GB
─────────────────────────────────────────────────────────────────────
 Services:
   ● nginx          active  (running)  since 2024-06-28
   ● postgresql     active  (running)  since 2024-06-28
   ● sshd           active  (running)  since 2024-06-28
   ● docker         active  (running)  since 2024-07-01
====================================================================
```

### `scripts/backup.sh`

Flexible backup script with:
- **Full backup**: Archives the specified source directory
- **Incremental mode**: Uses `rsync` and timestamps for incremental backups
- **Compression**: gzip, bzip2, or xz
- **Encryption**: Optional GPG encryption with a recipient key
- **Remote sync**: Sends backups to a remote server via SSH/rsync
- **Retention**: Automatically removes backups older than N days
- **Logging**: Writes detailed logs to `/var/log/backup/` or custom path

Usage:
```bash
./scripts/backup.sh \
  --source /var/www \
  --dest /backup/web \
  --compress gzip \
  --retention 30 \
  --remote user@backup-server:/backups
```

---

## Screenshots

> *Terminal preview of the configured shell environment.*

```
┌──────────────────────────────────────────────────────────┐
│  [louis@server-01 ~]$ system-info                         │
│                                                          │
│  ======================== SYSTEM INFO =================  │
│   OS: Ubuntu 22.04.3 LTS                                 │
│   Kernel: 6.2.0-26-generic                               │
│   ...                                                    │
│                                                          │
│  [louis@server-01 ~/projects (main)]$ gst                │
│  On branch main                                           │
│  Your branch is up to date with 'origin/main'.            │
│                                                          │
│  nothing to commit, working tree clean                    │
└──────────────────────────────────────────────────────────┘
```

---

## Manual Installation

### 1. Clone the Repository

```bash
git clone https://github.com/razafimandimby-IT/dotfiles-linux.git ~/.dotfiles
cd ~/.dotfiles
```

### 2. Run the Setup Script

```bash
chmod +x setup.sh
./setup.sh
```

### 3. (Optional) Apply Manually

Symlink individual files:

```bash
ln -sf ~/.dotfiles/.bashrc      ~/.bashrc
ln -sf ~/.dotfiles/.bash_aliases ~/.bash_aliases
ln -sf ~/.dotfiles/.bash_functions ~/.bash_functions
ln -sf ~/.dotfiles/.gitconfig   ~/.gitconfig
ln -sf ~/.dotfiles/.vimrc       ~/.vimrc
```

---

## Updating

Pull the latest changes and re-run the setup:

```bash
cd ~/.dotfiles && git pull && ./setup.sh --update
```

---

## Customization

- Edit `.bash_aliases` to add or modify aliases for your workflow
- Change the PS1 prompt in `.bashrc` under the `# Custom Prompt` section
- Update `scripts/backup.sh` variables at the top of the script for default paths
- Modify `setup.sh` `PKGS` array to add or remove auto-installed packages

---

## Requirements

- **OS**: Linux (Debian/Ubuntu, RHEL/CentOS/Fedora, Arch, openSUSE)
- **Shell**: Bash 4.0+
- **Core**: `curl`, `git`, `vim`
- **Optional**: `fzf`, `bat`, `ripgrep`, `htop`, `tmux`, `neovim` (auto-installed by setup.sh)

---

## License

MIT License

Copyright (c) 2024 [Louis Denis RAZAFIMANDIMBY](https://github.com/razafimandimby-IT)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

<div align="center">
  <sub>Built with  by <a href="https://github.com/razafimandimby-IT">Louis Denis RAZAFIMANDIMBY</a></sub>
</div>
