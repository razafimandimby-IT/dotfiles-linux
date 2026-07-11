# =============================================================================
#  .bash_functions — Custom Shell Functions
#  Part of dotfiles-linux (https://github.com/razafimandimby-IT/dotfiles-linux)
# =============================================================================
#
#  Available functions:
#    extract <file>       — Extract any archive format automatically
#    backup <path>        — Create a timestamped .bak copy of a file or directory
#    system-info          — Display system information dashboard
#    mkcd <dir>           — Create directory and cd into it
#    calc <expression>    — Evaluate math expressions using Python
#    process-menu         — Interactive process manager (requires fzf)
#    my-ip                — Show public and local IP addresses
#    docker-clean         — Remove all unused Docker resources
#    find-pid <name>      — Find PID by process name
#    tree <dir>           — Directory tree (fallback if `tree` not installed)
#    cheat <topic>        — Quick command cheat sheets from cheat.sh
#    hex2dec / dec2hex    — Number base conversions
#    mktar / mktgz        — Create archives from a directory
#    timer                — Simple countdown timer
#    http-debug <url>     — HTTP request with full response headers
#    rand-pass <len>      — Generate a random password
#    json-validate <file> — Validate JSON file syntax
# ---------------------------------------------------------------

# ── extract: Universal Archive Extractor ─────────────────────────────────────
# Usage: extract <archive_file> [destination]
extract() {
    if [ $# -eq 0 ]; then
        echo "Usage: extract <archive_file> [destination]"
        echo "Supported formats: tar.{gz,bz2,xz,lz}, zip, rar, 7z, gz, bz2, xz, lz4, zst"
        return 1
    fi

    local file="$1"
    local dest="${2:-.}"

    if [ ! -f "$file" ]; then
        echo "Error: '$file' is not a valid file." >&2
        return 1
    fi

    # Ensure destination exists
    mkdir -p "$dest" 2>/dev/null

    case "$file" in
        *.tar.gz|*.tgz)           tar -xzf "$file" -C "$dest" ;;
        *.tar.bz2|*.tbz2|*.tbz)  tar -xjf "$file" -C "$dest" ;;
        *.tar.xz|*.txz)           tar -xJf "$file" -C "$dest" ;;
        *.tar.lz|*.tlz)           tar --lzip -xf "$file" -C "$dest" ;;
        *.tar.zst|*.tzst)         tar --zstd -xf "$file" -C "$dest" 2>/dev/null || unzstd "$file" -o "${file%.*}" ;;
        *.tar.lz4)                tar --lz4 -xf "$file" -C "$dest" 2>/dev/null || lz4 -d "$file" "${file%.*}" ;;
        *.tar)                    tar -xf "$file" -C "$dest" ;;
        *.gz)                     gunzip -c "$file" > "${file%.gz}" ;;
        *.bz2)                    bunzip2 -c "$file" > "${file%.bz2}" ;;
        *.xz)                     unxz -c "$file" > "${file%.xz}" ;;
        *.lz4)                    lz4 -d "$file" "${file%.lz4}" ;;
        *.zst)                    unzstd "$file" -o "${file%.zst}" ;;
        *.zip)                    unzip "$file" -d "$dest" ;;
        *.rar)                    unrar x "$file" "$dest" ;;
        *.7z)                     7z x "$file" -o"$dest" ;;
        *.Z)                      uncompress "$file" ;;
        *.lz)                     lzip -d "$file" ;;
        *.cab)                    cabextract "$file" -d "$dest" ;;
        *.rpm)                    rpm2cpio "$file" | cpio -idmvD "$dest" ;;
        *.deb)                    dpkg-deb -x "$file" "$dest" ;;
        *)
            echo "Error: '$file' cannot be extracted via extract()" >&2
            echo "Unsupported archive format." >&2
            return 1
            ;;
    esac

    echo "✓ Extracted '$file' → '$dest'"
}

# ── backup: Create Timestamped Backup ────────────────────────────────────────
# Usage: backup <file_or_directory>
backup() {
    if [ $# -eq 0 ]; then
        echo "Usage: backup <file_or_directory>"
        return 1
    fi

    local target="$1"
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)

    if [ ! -e "$target" ]; then
        echo "Error: '$target' does not exist." >&2
        return 1
    fi

    local base
    base=$(basename "$target")
    local dir
    dir=$(dirname "$(realpath "$target")")
    local backup_path="${dir}/${base}.bak.${timestamp}"

    if [ -d "$target" ]; then
        cp -r "$target" "$backup_path"
    else
        cp "$target" "$backup_path"
    fi

    echo "✓ Backup created: $backup_path"
}

# ── system-info: System Information Dashboard ────────────────────────────────
# Usage: system-info [--short]
system-info() {
    local width=68
    local short_mode=false

    [[ "$1" == "--short" ]] && short_mode=true

    # Print separator line
    sep() {
        printf '═%.0s' $(seq 1 $width)
        echo
    }

    # Print section header
    section() {
        printf " %-15s %s\n" "$1" "$2"
    }

    # Get value for a key (fallback to an alternative command)
    get_val() {
        local cmd="$1"
        local fallback="$2"
        local val
        val=$(eval "$cmd" 2>/dev/null) || val="$fallback"
        echo "$val"
    }

    # ── Header ──
    echo
    printf "╔%s╗\n" "$(printf '═%.0s' $(seq 1 $width))"
    printf "║%s║\n" "$(printf " %-${width}s" "SYSTEM INFORMATION")"
    printf "╠%s╣\n" "$(printf '═%.0s' $(seq 1 $width))"

    # ── OS & Kernel ──
    local os_name="" os_version="" kernel="" hostname="" uptime_str=""
    if [ -f /etc/os-release ]; then
        os_name=$(grep -oP '(?<=^NAME=").*(?=")' /etc/os-release 2>/dev/null || grep -oP '(?<=^NAME=)[^"]+' /etc/os-release 2>/dev/null)
        os_version=$(grep -oP '(?<=^VERSION=").*(?=")' /etc/os-release 2>/dev/null || grep -oP '(?<=^VERSION_ID=").*(?=")' /etc/os-release 2>/dev/null)
    elif [ -f /etc/lsb-release ]; then
        os_name=$(grep -oP '(?<=^DISTRIB_ID=).*' /etc/lsb-release 2>/dev/null)
        os_version=$(grep -oP '(?<=^DISTRIB_RELEASE=).*' /etc/lsb-release 2>/dev/null)
    else
        os_name="Unknown"
        os_version=""
    fi
    kernel=$(uname -r 2>/dev/null || echo "N/A")
    hostname=$(hostname -f 2>/dev/null || hostname 2>/dev/null || echo "N/A")
    uptime_str=$(uptime -p 2>/dev/null | sed 's/up //' || echo "N/A")

    printf "║ %-${width}s ║\n" " OS:      $os_name $os_version ($(uname -m))"
    printf "║ %-${width}s ║\n" " Kernel:  $kernel"
    printf "║ %-${width}s ║\n" " Host:    $hostname"
    printf "║ %-${width}s ║\n" " Uptime:  $uptime_str"
    printf "╠%s╣\n" "$(printf '─%.0s' $(seq 1 $width))"

    # ── CPU ──
    local cpu_model="" cpu_cores="" cpu_threads="" load=""
    cpu_model=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d: -f2- | sed 's/^ //' || echo "N/A")
    cpu_cores=$(grep -c "cpu cores" /proc/cpuinfo 2>/dev/null | head -1 || echo "N/A")
    cpu_threads=$(nproc 2>/dev/null || echo "N/A")
    load=$(uptime 2>/dev/null | grep -oP 'load average:.*$' | cut -d: -f2 | xargs || echo "N/A")

    printf "║ %-${width}s ║\n" " CPU:     $cpu_model"
    printf "║ %-${width}s ║\n" " Cores:   ${cpu_cores} physical / ${cpu_threads} logical"
    printf "║ %-${width}s ║\n" " Load:    $load"
    printf "╠%s╣\n" "$(printf '─%.0s' $(seq 1 $width))"

    # ── Memory ──
    if command -v free &>/dev/null; then
        local mem_total mem_used mem_free swap_total swap_used swap_free
        mem_total=$(free -h 2>/dev/null | awk '/^Mem:/ {print $2}')
        mem_used=$(free -h 2>/dev/null | awk '/^Mem:/ {print $3}')
        mem_free=$(free -h 2>/dev/null | awk '/^Mem:/ {print $4}')
        swap_total=$(free -h 2>/dev/null | awk '/^Swap:/ {print $2}')
        swap_used=$(free -h 2>/dev/null | awk '/^Swap:/ {print $3}')
        swap_free=$(free -h 2>/dev/null | awk '/^Swap:/ {print $4}')
        swap_total="${swap_total:-0B}"
        swap_used="${swap_used:-0B}"
        swap_free="${swap_free:-0B}"

        printf "║ %-${width}s ║\n" " RAM:     ${mem_total} total | ${mem_used} used | ${mem_free} free"
        printf "║ %-${width}s ║\n" " Swap:    ${swap_total} total | ${swap_used} used | ${swap_free} free"
    fi
    printf "╠%s╣\n" "$(printf '─%.0s' $(seq 1 $width))"

    # ── Disk ──
    if command -v df &>/dev/null; then
        printf "║ %-${width}s ║\n" " Disk:"
        while IFS= read -r line; do
            local filesystem size used avail use_pcent mount
            filesystem=$(echo "$line" | awk '{print $1}')
            size=$(echo "$line" | awk '{print $2}')
            used=$(echo "$line" | awk '{print $3}')
            avail=$(echo "$line" | awk '{print $4}')
            use_pcent=$(echo "$line" | awk '{print $5}')
            mount=$(echo "$line" | awk '{print $6}')
            printf "║   %-5s %-8s used / %-8s (%s)  %-${width}s ║\n" "$mount" "$used" "$size" "$use_pcent" ""
        done < <(df -h / /home /var 2>/dev/null | tail -n +2 | head -5)
    fi
    printf "╠%s╣\n" "$(printf '─%.0s' $(seq 1 $width))"

    # ── Network ──
    if command -v ip &>/dev/null; then
        printf "║ %-${width}s ║\n" " Network:"
        while IFS= read -r line; do
            local iface addr
            iface=$(echo "$line" | awk '{print $2}')
            addr=$(echo "$line" | awk '{print $3}')
            if [ -n "$addr" ] && [ "$addr" != "lo" ]; then
                printf "║   %-8s %-${width}s ║\n" "$iface" "$addr"
            fi
        done < <(ip -br addr 2>/dev/null | tail -n +2 | head -5)
    fi

    # ── Services (only in full mode) ──
    if [ "$short_mode" = false ] && command -v systemctl &>/dev/null; then
        printf "╠%s╣\n" "$(printf '─%.0s' $(seq 1 $width))"
        printf "║ %-${width}s ║\n" " Active Services:"
        while IFS= read -r line; do
            local srv_name srv_status
            srv_name=$(echo "$line" | awk '{print $1}')
            srv_status=$(echo "$line" | awk '{print $2}')
            local srv_display="${srv_name} (${srv_status})"
            printf "║   ● %-${width}s ║\n" "$srv_display"
        done < <(systemctl list-units --type=service --state=running --no-legend 2>/dev/null | head -8)
    fi

    # ── Footer ──
    printf "╚%s╝\n" "$(printf '═%.0s' $(seq 1 $width))"
    echo

    # ── Docker info (if available, short mode only) ──
    if command -v docker &>/dev/null && [ "$short_mode" = true ]; then
        echo " Docker: $(docker ps -q 2>/dev/null | wc -l) running / $(docker ps -aq 2>/dev/null | wc -l) total containers"
        echo
    fi
}

# ── mkcd: mkdir + cd ────────────────────────────────────────────────────────
# Usage: mkcd <directory>
mkcd() {
    if [ $# -eq 0 ]; then
        echo "Usage: mkcd <directory>"
        return 1
    fi
    mkdir -p "$1" && cd "$1" || return 1
}

# ── calc: Math Expression Evaluator ─────────────────────────────────────────
# Usage: calc "2 + 2"  or  calc "sqrt(16) * 3"
calc() {
    if [ $# -eq 0 ]; then
        echo "Usage: calc <expression>"
        echo "Examples:"
        echo "  calc '2 + 2'"
        echo "  calc 'sqrt(16) * 3'"
        echo "  calc '2**10'"
        return 1
    fi
    python3 -c "
import math
from math import sqrt, sin, cos, tan, log, log10, pi, e, floor, ceil, pow

try:
    result = eval('$*')
    if isinstance(result, float):
        print(f'{result:.10g}')
    else:
        print(result)
except Exception as ex:
    print(f'Error: {ex}')
" 2>/dev/null || python -c "
import math
from math import sqrt, sin, cos, tan, log, log10, pi, e, floor, ceil

try:
    result = eval('$*')
    if isinstance(result, float):
        print(f'{result:.10g}')
    else:
        print(result)
except Exception as ex:
    print(f'Error: {ex}')
" 2>/dev/null || echo "Error: Python not found. Please install python3."
}

# ── process-menu: Interactive Process Manager ───────────────────────────────
# Usage: process-menu
# Requires: fzf
process-menu() {
    if ! command -v fzf &>/dev/null; then
        echo "Error: 'fzf' is required for this function." >&2
        echo "Install it with: sudo apt install fzf" >&2
        return 1
    fi

    local pid
    pid=$(ps aux --sort=-%cpu | fzf --header-lines=1 \
        --preview 'echo {}' \
        --preview-window=up:3:wrap \
        --prompt='Select process to kill: ' \
        | awk '{print $2}')

    if [ -n "$pid" ]; then
        local pname
        pname=$(ps -p "$pid" -o comm= 2>/dev/null)
        echo "Selected: $pname (PID: $pid)"
        read -r -p "Kill this process? (y/N) " response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            kill -15 "$pid" 2>/dev/null && echo "✓ Process $pid terminated." \
                || { kill -9 "$pid" 2>/dev/null && echo "✓ Process $pid forcefully killed." \
                || echo "✗ Failed to kill process $pid."; }
        else
            echo "Canceled."
        fi
    fi
}

# ── my-ip: Show IP Addresses ─────────────────────────────────────────────────
# Usage: my-ip
my-ip() {
    echo "┌─ Public IP ──────────────────────────────┐"
    local public_ip
    public_ip=$(curl -s --max-time 3 ifconfig.me 2>/dev/null)
    if [ -n "$public_ip" ]; then
        echo "│  Public IPv4 : $public_ip"
    else
        public_ip=$(curl -s --max-time 3 icanhazip.com 2>/dev/null)
        [ -n "$public_ip" ] && echo "│  Public IPv4 : $public_ip" || echo "│  Public IP  : (timeout)"
    fi
    # Also try IPv6
    local public_ip6
    public_ip6=$(curl -s --max-time 3 ifconfig.me 2>/dev/null)
    echo "│                                       │"
    echo "├─ Local IPs ────────────────────────────┤"
    if command -v ip &>/dev/null; then
        ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | while IFS= read -r ipaddr; do
            local iface
            iface=$(ip -4 addr show | grep -B2 "$ipaddr" | head -1 | awk '{print $2}' | tr -d ':')
            [ "$ipaddr" != "127.0.0.1" ] && echo "│  $iface : $ipaddr"
        done
    fi
    echo "└───────────────────────────────────────┘"
}

# ── docker-clean: Remove Unused Docker Resources ─────────────────────────────
# Usage: docker-clean
docker-clean() {
    echo " Removing stopped containers..."
    docker rm -v "$(docker ps -aq -f status=exited)" 2>/dev/null && echo "  ✓ Done" || echo "  No stopped containers."

    echo " Removing dangling images..."
    docker rmi "$(docker images -f dangling=true -q)" 2>/dev/null && echo "  ✓ Done" || echo "  No dangling images."

    echo " Removing unused volumes..."
    docker volume rm "$(docker volume ls -qf dangling=true)" 2>/dev/null && echo "  ✓ Done" || echo "  No unused volumes."

    echo " Removing unused networks..."
    docker network prune -f 2>/dev/null && echo "  ✓ Done" || echo "  No unused networks."

    echo " Build cache pruning..."
    docker builder prune -f 2>/dev/null && echo "  ✓ Done" || echo "  No build cache."

    echo ""
    echo " Current Docker status:"
    echo "  Containers: $(docker ps -q 2>/dev/null | wc -l) running / $(docker ps -aq 2>/dev/null | wc -l) total"
    echo "  Images:     $(docker images -q 2>/dev/null | sort -u | wc -l) total"
    echo "  Volumes:    $(docker volume ls -q 2>/dev/null | wc -l) total"
}

# ── find-pid: Find PID by Process Name ──────────────────────────────────────
# Usage: find-pid <process_name>
find-pid() {
    if [ $# -eq 0 ]; then
        echo "Usage: find-pid <process_name>"
        return 1
    fi
    pgrep -fl "$1" | grep -v "find-pid" || echo "No process found matching '$1'"
}

# ── tree: Directory Tree ────────────────────────────────────────────────────
# Usage: tree [directory] [max_depth]
tree() {
    local dir="${1:-.}"
    local depth="${2:-2}"
    find "$dir" -maxdepth "$depth" -print 2>/dev/null | sed \
        -e 's;[^/]*/;|   ;g' \
        -e 's;|   \([^|]\);+-- \1;' \
        -e 's;|   +;|   +;' \
        -e 's;|   |;|   |;'
}

# ── cheat: Quick Command Reference ──────────────────────────────────────────
# Usage: cheat <command>
cheat() {
    if [ $# -eq 0 ]; then
        echo "Usage: cheat <command>"
        echo "Example: cheat tar, cheat find, cheat docker"
        return 1
    fi
    curl -s "https://cheat.sh/$1" | less -R
}

# ── hex2dec / dec2hex: Number Base Conversion ───────────────────────────────
# Usage: hex2dec ff  or  dec2hex 255
hex2dec() {
    if [ $# -eq 0 ]; then
        echo "Usage: hex2dec <hexadecimal>"
        return 1
    fi
    printf "%d\n" "$1" 2>/dev/null || echo "Error: Invalid hexadecimal number."
}

dec2hex() {
    if [ $# -eq 0 ]; then
        echo "Usage: dec2hex <decimal>"
        return 1
    fi
    printf "%x\n" "$1" 2>/dev/null || echo "Error: Invalid decimal number."
}

# ── mktar / mktgz: Create Archives ──────────────────────────────────────────
# Usage: mktar <directory>  or  mktgz <directory>
mktar() {
    if [ $# -eq 0 ]; then
        echo "Usage: mktar <directory>"
        return 1
    fi
    local dir="${1%/}"
    if [ ! -d "$dir" ]; then
        echo "Error: '$dir' is not a directory." >&2
        return 1
    fi
    tar -cvf "${dir}.tar" "$dir" && echo "✓ Created ${dir}.tar"
}

mktgz() {
    if [ $# -eq 0 ]; then
        echo "Usage: mktgz <directory>"
        return 1
    fi
    local dir="${1%/}"
    if [ ! -d "$dir" ]; then
        echo "Error: '$dir' is not a directory." >&2
        return 1
    fi
    tar -czvf "${dir}.tar.gz" "$dir" && echo "✓ Created ${dir}.tar.gz"
}

# ── timer: Simple Countdown Timer ───────────────────────────────────────────
# Usage: timer <seconds>  or  timer <minutes>m
timer() {
    if [ $# -eq 0 ]; then
        echo "Usage: timer <seconds>  (or <minutes>m, e.g., 5m)"
        return 1
    fi

    local total_seconds=0

    case "$1" in
        *m) total_seconds=$((${1%m} * 60)) ;;
        *h) total_seconds=$((${1%h} * 3600)) ;;
        *s) total_seconds=${1%s} ;;
        *) total_seconds=$1 ;;
    esac

    if [ "$total_seconds" -le 0 ]; then
        echo "Error: Invalid time duration."
        return 1
    fi

    local end_time=$(( $(date +%s) + total_seconds ))

    while [ "$(date +%s)" -lt "$end_time" ]; do
        local remaining=$(( end_time - $(date +%s) ))
        printf "\r  Timer: %02d:%02d " $(( remaining / 60 )) $(( remaining % 60 ))
        sleep 1
    done

    printf "\r  Timer: 00:00 \a\n"
    echo "  Time's up!"
}

# ── http-debug: HTTP Request Debugger ───────────────────────────────────────
# Usage: http-debug <url> [curl_options]
http-debug() {
    if [ $# -eq 0 ]; then
        echo "Usage: http-debug <url> [curl_options]"
        return 1
    fi
    local url="$1"
    shift
    curl -v -s "$@" "$url" 2>&1 | less -R
}

# ── rand-pass: Random Password Generator ────────────────────────────────────
# Usage: rand-pass [length]
rand-pass() {
    local len="${1:-24}"
    if ! [[ "$len" =~ ^[0-9]+$ ]] || [ "$len" -lt 8 ] || [ "$len" -gt 128 ]; then
        echo "Usage: rand-pass [length]  (length must be between 8 and 128)"
        return 1
    fi
    # Uses /dev/urandom for cryptographic-quality randomness
    local pass
    pass=$(tr -dc 'A-Za-z0-9!@#$%^&*()_+-=' < /dev/urandom 2>/dev/null | head -c "$len")
    echo "$pass"
    # Copy to clipboard if available
    if command -v xclip &>/dev/null; then
        echo -n "$pass" | xclip -selection clipboard
        echo "(copied to clipboard)"
    elif command -v wl-copy &>/dev/null; then
        echo -n "$pass" | wl-copy
        echo "(copied to clipboard)"
    fi
}

# ── json-validate: Validate JSON File ───────────────────────────────────────
# Usage: json-validate <file>
json-validate() {
    if [ $# -eq 0 ]; then
        echo "Usage: json-validate <file>"
        return 1
    fi
    if [ ! -f "$1" ]; then
        echo "Error: '$1' is not a file." >&2
        return 1
    fi
    if command -v python3 &>/dev/null; then
        python3 -m json.tool "$1" >/dev/null 2>&1
    elif command -v python &>/dev/null; then
        python -m json.tool "$1" >/dev/null 2>&1
    elif command -v jq &>/dev/null; then
        jq . "$1" >/dev/null 2>&1
    else
        echo "Error: Need python3, python, or jq to validate JSON."
        return 1
    fi

    if [ $? -eq 0 ]; then
        echo "✓ Valid JSON: $1"
    else
        echo "✗ Invalid JSON: $1"
        return 1
    fi
}

# ── swap-files: Swap Two Files ──────────────────────────────────────────────
# Usage: swap-files <file1> <file2>
swap-files() {
    if [ $# -ne 2 ]; then
        echo "Usage: swap-files <file1> <file2>"
        return 1
    fi
    if [ ! -f "$1" ] || [ ! -f "$2" ]; then
        echo "Error: Both files must exist." >&2
        return 1
    fi
    local tmp
    tmp=$(mktemp)
    cp "$1" "$tmp"
    cp "$2" "$1"
    cp "$tmp" "$2"
    rm -f "$tmp"
    echo "✓ Swapped '$1' and '$2'"
}

# ── man-pdf: Save Man Page as PDF ───────────────────────────────────────────
# Usage: man-pdf <command>
man-pdf() {
    if [ $# -eq 0 ]; then
        echo "Usage: man-pdf <command>"
        return 1
    fi
    man -Tpdf "$1" > "${1}.pdf" 2>/dev/null && echo "✓ Created ${1}.pdf" \
        || echo "Error: Could not generate PDF for '$1'. Is groff installed?"
}
