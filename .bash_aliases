# =============================================================================
#  .bash_aliases — Sysadmin Aliases
#  Part of dotfiles-linux (https://github.com/razafimandimby-IT/dotfiles-linux)
# =============================================================================
#
#  ┌─ Category index ───────────────────────────────────────────────────┐
#  │  1. System & Services    (systemctl, journalctl, sys admin)        │
#  │  2. Docker               (container & image management)            │
#  │  3. Networking           (IP, ports, connectivity)                  │
#  │  4. APT / Package Mgmt   (apt, dpkg, snap)                         │
#  │  5. File Management      (ls, find, disk usage)                    │
#  │  6. Git                  (quick shortcuts)                         │
#  │  7. Process Management   (ps, top, kill)                           │
#  │  8. Security & Perms     (chmod, chown, firewall)                  │
#  │  9. Tmux / Screen        (session management)                      │
#  │ 10. Miscellaneous        (shortcuts, weather, fun)                 │
#  └────────────────────────────────────────────────────────────────────┘

# ── 1. System & Services ────────────────────────────────────────────────────

# systemctl shortcuts
alias sys-start='sudo systemctl start'
alias sys-stop='sudo systemctl stop'
alias sys-restart='sudo systemctl restart'
alias sys-reload='sudo systemctl reload'
alias sys-status='systemctl status'
alias sys-enable='sudo systemctl enable'
alias sys-disable='sudo systemctl disable'
alias sys-enabled='systemctl list-unit-files | grep enabled'
alias sys-list='systemctl list-units --type=service --all'
alias sys-failed='systemctl --failed'
alias sysd='sudo systemctl daemon-reload'
alias sys-edit='sudo systemctl edit'

# journalctl shortcuts
alias jlog='journalctl -xe --no-pager -n 50'
alias jlog-f='journalctl -f'
alias jlog-u='journalctl -xe -u'
alias jlog-b='journalctl -xb -n 100'
alias jlog-p='journalctl -p err -b'
alias jlog-now='journalctl --since "1 hour ago"'

# System info
alias cpu-info='lscpu'
alias mem-info='free -h'
alias disk-info='df -h'
alias disk-usage='du -sh * | sort -h'
alias mount-info='mount | column -t'
alias kernel-info='uname -a'
alias os-info='cat /etc/os-release 2>/dev/null || cat /etc/*release 2>/dev/null'
alias uptime-info='uptime -p'

# System updates
alias update='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt autoclean'
alias update-fresh='sudo apt update'
alias upgrade-all='sudo apt update && sudo apt full-upgrade -y'
alias dist-upgrade='sudo apt update && sudo apt dist-upgrade -y'

# ── 2. Docker ───────────────────────────────────────────────────────────────

alias d='docker'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dlog='docker logs -f'
alias dlogs='docker logs -f --tail 100'
alias dexec='docker exec -it'
alias dstop='docker stop'
alias dstop-all='docker stop $(docker ps -q) 2>/dev/null'
alias drm='docker rm'
alias drm-all='docker rm $(docker ps -aq) 2>/dev/null'
alias dimg='docker images'
alias drmi='docker rmi'
alias drmi-dangling='docker image prune'
alias dprune='docker system prune -a -f'
alias dprune-all='docker system prune -a --volumes -f'
alias dvol='docker volume ls'
alias dnet='docker network ls'
alias dcompose='docker compose'
alias dcup='docker compose up -d'
alias dcdown='docker compose down'
alias dcstart='docker compose start'
alias dcstop='docker compose stop'
alias dcrestart='docker compose restart'
alias dcbuild='docker compose build'
alias dclogs='docker compose logs -f'
alias di='docker info'
alias dstats='docker stats --no-stream'
alias dtop='docker top'

# Docker cleanup
alias dclean='docker rm -v $(docker ps -aq -f status=exited) 2>/dev/null; docker rmi $(docker images -f dangling=true -q) 2>/dev/null; docker volume rm $(docker volume ls -qf dangling=true) 2>/dev/null'

# ── 3. Networking ───────────────────────────────────────────────────────────

# IP addresses
alias myip='curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || curl -s ipinfo.io/ip'
alias myip-all='curl -s ipinfo.io 2>/dev/null'
alias myiplocal='ip -4 addr show | grep -oP "(?<=inet\s)\d+(\.\d+){3}" | grep -v 127.0.0.1'
alias myip6='ip -6 addr show | grep -oP "(?<=inet6\s)[\da-f:]+" | grep -v "^::1"'
alias myip-public='curl -s ifconfig.me 2>/dev/null'

# Connection & ports
alias ports='ss -tulanp'
alias listening='ss -tuln'
alias connections='ss -tuna | tail -n +2'
alias netstat='ss -tuln'
alias socket-stats='ss -s'

# Connectivity
alias ping='ping -c 4'
alias ping-fast='ping -c 1'
alias ping-google='ping -c 4 8.8.8.8'
alias fastping='ping -c 100 -s 1 -f 8.8.8.8'
alias traceroute='traceroute -n 2>/dev/null || traceroute'
alias tracepath='tracepath -n 8.8.8.8 2>/dev/null || echo "tracepath not installed"'
alias dns-lookup='nslookup'
alias dns-check='dig +short'
alias dns-check-all='dig +nocmd any'
alias dns-flush='sudo resolvectl flush-caches 2>/dev/null || sudo systemd-resolve --flush-caches 2>/dev/null || echo "No resolver cache flush available"'

# Network interfaces
alias netif='ip -br addr'
alias netif-detail='ip addr'
alias netlink='ip link show'
alias netroute='ip route'
alias netneigh='ip neigh'
alias netstat-r='ip route show table all'
alias netmon='sudo tcpdump -i any -n -c 100 2>/dev/null'

# Firewall (ufw)
alias ufw-list='sudo ufw status verbose'
alias ufw-enable='sudo ufw enable'
alias ufw-disable='sudo ufw disable'
alias ufw-allow='sudo ufw allow'
alias ufw-deny='sudo ufw deny'
alias ufw-reload='sudo ufw reload'
alias ufw-reset='sudo ufw reset'

# Wi-Fi
alias wifi-list='nmcli dev wifi list 2>/dev/null || iwlist scan 2>/dev/null | grep ESSID'
alias wifi-status='nmcli dev status 2>/dev/null || iwconfig 2>/dev/null'
alias wifi-connect='nmcli dev wifi connect'

# ── 4. APT / Package Management ─────────────────────────────────────────────

# apt shortcuts
alias apt-get='sudo apt'
alias apt-install='sudo apt install -y'
alias apt-remove='sudo apt remove -y'
alias apt-purge='sudo apt purge -y'
alias apt-autoremove='sudo apt autoremove -y'
alias apt-search='apt search'
alias apt-show='apt show'
alias apt-update='sudo apt update'
alias apt-upgrade='sudo apt upgrade -y'
alias apt-full-upgrade='sudo apt full-upgrade -y'
alias apt-clean='sudo apt autoclean && sudo apt clean'
alias apt-list-upgradable='apt list --upgradable 2>/dev/null'
alias apt-history='cat /var/log/apt/history.log | grep -E "^Start-Date:|^Commandline:"'

# dpkg shortcuts
alias dpkg-list='dpkg -l'
alias dpkg-files='dpkg -L'
alias dpkg-owned='dpkg -S'
alias dpkg-reconfigure='sudo dpkg-reconfigure'
alias pkgs-by-size='dpkg-query -W -f="\${Installed-Size}\t\${Package}\n" | sort -n'

# snap
alias snap-list='snap list'
alias snap-install='sudo snap install'
alias snap-remove='sudo snap remove'
alias snap-update='sudo snap refresh'
alias snap-changes='snap changes'

# ── 5. File Management ──────────────────────────────────────────────────────

# ls enhancements
alias l='ls -F'
alias la='ls -A'
alias ll='ls -AlFh'
alias lla='ls -AlFha'
alias ls-size='ls -lShr'
alias ls-time='ls -ltrh'
alias ls-ext='ls -lX'
alias ldot='ls -ld .*'

# find shortcuts
alias find-big='find / -xdev -type f -size +100M -exec ls -lh {} \; 2>/dev/null | sort -k5 -h -r | head -20'
alias find-empty='find . -type f -empty -o -type d -empty'
alias find-text='grep -rI'
alias find-suid='find / -xdev -perm -4000 -type f 2>/dev/null'
alias find-sgid='find / -xdev -perm -2000 -type f 2>/dev/null'
alias find-sticky='find / -xdev -perm -1000 -type d 2>/dev/null'
alias find-recent='find . -mmin -60 -type f'

# Disk usage
alias biggest='du -h --max-depth=1 2>/dev/null | sort -h'
alias biggest-all='du -sh * .[^.]* 2>/dev/null | sort -h'
alias dir-size='du -sh'
alias tree-size='du -h --max-depth=1 2>/dev/null | sort -rh'

# File operations
alias mkdir='mkdir -p -v'
alias chown='sudo chown'
alias chmod='chmod -v'
alias ln='ln -v'
alias cp-progress='rsync -ah --progress'
alias rm-empty-dirs='find . -type d -empty -delete'

# ── 6. Git ──────────────────────────────────────────────────────────────────

alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gap='git add -p'
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gbD='git branch -D'
alias gc='git commit -v'
alias gc!='git commit -v --amend'
alias gca='git commit -v -a'
alias gca!='git commit -v -a --amend'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gclean='git clean -fd'
alias gclone='git clone --recursive'
alias gcl='git clone'
alias gcount='git shortlog -sn'
alias gcp='git cherry-pick'
alias gd='git diff'
alias gdc='git diff --cached'
alias gdw='git diff --word-diff'
alias gf='git fetch --all --prune'
alias gl='git log --oneline --graph --decorate -20'
alias glg='git log --oneline --graph --decorate --all'
alias glga='git log --oneline --graph --decorate --all --show-notes'
alias glo='git log --oneline -20'
alias gm='git merge'
alias gmf='git merge --ff-only'
alias gmnf='git merge --no-ff'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpoat='git push origin --all && git push origin --tags'
alias gpull='git pull --rebase'
alias gr='git remote'
alias gra='git remote add'
alias grr='git remote rm'
alias grv='git remote -v'
alias gres='git reset'
alias greset='git reset --hard HEAD'
alias grev='git revert'
alias grm='git rm'
alias grs='git reset --soft HEAD~1'
alias gsh='git show'
alias gst='git status -sb'
alias gsta='git stash'
alias gstaa='git stash apply'
alias gstd='git stash drop'
alias gstl='git stash list'
alias gstp='git stash pop'
alias gsts='git stash show -p'
alias gtag='git tag'
alias gtl='git tag -l | sort -V'
alias gunstage='git reset HEAD --'
alias gup='git pull --rebase'

# ── 7. Process Management ───────────────────────────────────────────────────

alias ps-all='ps auxf'
alias ps-tree='ps auxf'
alias ps-user='ps -U $USER -u $USER u'
alias ps-mem='ps aux --sort=-%mem | head -20'
alias ps-cpu='ps aux --sort=-%cpu | head -20'
alias top-mem='top -b -o +%MEM -n 1 | head -25'
alias top-cpu='top -b -o +%CPU -n 1 | head -25'
alias kill-all='sudo killall'
alias kill-name='pkill'
alias kill-zombies='ps aux | awk "{if (\$8 == \"Z\") print \$2}" | xargs -r sudo kill -9 2>/dev/null'
alias memtop='ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head'
alias cputop='ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head'
alias threads='ps -eLF | wc -l'

# ── 8. Security & Permissions ───────────────────────────────────────────────

alias perm-file='stat -c "%a %A %U:%G %n"'
alias perm-dir='find . -type d -exec stat -c "%a %A %U:%G %n" {} \;'
alias perm-755='find . -type f -exec chmod 755 {} \;'
alias perm-644='find . -type f -exec chmod 644 {} \;'
alias own='sudo chown -R $USER:$USER'
alias own-root='sudo chown -R root:root'
alias ssh-list='grep -E "^Host " ~/.ssh/config 2>/dev/null | cut -d" " -f2'
alias ssh-keygen='ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)-$(date +%Y-%m-%d)"'
alias ssh-copy='ssh-copy-id -i ~/.ssh/id_ed25519.pub'
alias port-check='lsof -i :'
alias port-listen='lsof -i -P -n | grep LISTEN'
alias last-logins='last -20'
alias auth-fails='sudo journalctl -u sshd -n 100 --no-pager | grep "Failed password\|Invalid user" | tail -20'

# ── 9. Tmux / Screen ────────────────────────────────────────────────────────

if command -v tmux &>/dev/null; then
    alias tmux='tmux -2'                                    # Force 256 colors
    alias tnew='tmux new -s'
    alias tlist='tmux list-sessions'
    alias tattach='tmux attach -t'
    alias tkill='tmux kill-session -t'
    alias tkill-all='tmux kill-server'
    alias trename='tmux rename-session -t'
    alias tsplit='tmux split-window -v'
    alias tsplit-h='tmux split-window -h'
fi

# ── 10. Miscellaneous ──────────────────────────────────────────────────────

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ~='cd ~'
alias -- -='cd -'
alias home='cd ~'
alias root='cd /'
alias cls='clear'
alias c='clear'
alias h='history'
alias hg='history | grep -i'
alias q='exit'
alias path='echo -e "${PATH//:/\\n}"'

# File viewing
alias cat='bat --style=plain --paging=never 2>/dev/null || cat'
alias less='less -R'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias head='head -n'
alias tail='tail -n'
alias tail-f='tail -f -n 50'
alias jq='jq . 2>/dev/null || cat'
alias pretty-json='python3 -m json.tool 2>/dev/null || python -m json.tool 2>/dev/null || jq .'

# Clock / date
alias now='date +"%Y-%m-%d %H:%M:%S"'
alias now-date='date +"%Y-%m-%d"'
alias now-epoch='date +%s'
alias timestamp='date +%Y%m%d-%H%M%S'

# Networking shortcuts
alias weather='curl -s wttr.in 2>/dev/null | head -20'
alias weather-city='curl -s wttr.in/'
alias cheat='curl -s cheat.sh/'

# Quick edit
alias ez='vim ~/.zshrc 2>/dev/null || vim ~/.bashrc'
alias ev='vim ~/.vimrc'
alias eg='vim ~/.gitconfig'
alias ea='vim ~/.bash_aliases'
alias ef='vim ~/.bash_functions'
alias es='vim ~/scripts/'

# Reload
alias reload='source ~/.bashrc'
alias refresh='source ~/.bashrc && exec bash'

# Screenshot
alias screenshot='gnome-screenshot -c 2>/dev/null || spectacle -b -n 2>/dev/null || echo "No screenshot tool found"'
alias screenshot-area='gnome-screenshot -a -c 2>/dev/null || spectacle -r -b -n 2>/dev/null || echo "No screenshot tool found"'

# Fun
alias please='sudo $(fc -ln -1)'
alias fucking='sudo $(fc -ln -1)'
alias again='sudo $(fc -ln -1)'
alias matrix='echo -e "\e[32m"; while true; do echo -n "$(cat /dev/urandom | tr -dc "0-9a-f" | head -c 80)"; sleep 0.05; done 2>/dev/null'
alias zen='xrandr -o inverted 2>/dev/null; sleep 2; xrandr -o normal 2>/dev/null'
