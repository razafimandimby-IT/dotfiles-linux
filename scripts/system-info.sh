#!/usr/bin/env bash
# =============================================================================
#  system-info.sh — System Information Dashboard
#  Part of dotfiles-linux (https://github.com/razafimandimby-IT/dotfiles-linux)
# =============================================================================
#
#  Displays a comprehensive overview of the system, including:
#    - OS, kernel version, hostname, uptime
#    - CPU model, core count, load averages
#    - Memory and swap usage
#    - Disk usage for key mount points
#    - Network interfaces and IP addresses
#    - Active system services
#    - Running Docker containers (if applicable)
#
#  Usage:
#    ./scripts/system-info.sh          — Full information
#    ./scripts/system-info.sh --short  — Compact view
#    ./scripts/system-info.sh --json   — JSON output (for automation)
#    ./scripts/system-info.sh --help   — Show help
#
#  Requires: bash 4+, standard Linux utilities (uname, lscpu, free, df, ip)
# =============================================================================

set -euo pipefail

# ── Constants ────────────────────────────────────────────────────────────────

VERSION="1.2.0"
WIDTH=72

# ── Colors ───────────────────────────────────────────────────────────────────

if [ -t 1 ]; then
    # stdout is a terminal — enable colors
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    MAGENTA='\033[0;35m'
    BOLD='\033[1m'
    DIM='\033[2m'
    NC='\033[0m'
    TICK="${GREEN}✓${NC}"
    CROSS="${RED}✗${NC}"
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; MAGENTA=''; BOLD=''; DIM=''; NC=''
    TICK="[OK]"; CROSS="[FAIL]"
fi

# ── Helper Functions ─────────────────────────────────────────────────────────

print_line() {
    local char="${1:-─}"
    printf "%*s" "$WIDTH" "" | tr ' ' "$char"
}

print_section() {
    local title="$1"
    echo ""
    echo -e "${BOLD}${BLUE}$title${NC}"
    print_line "━"
}

info_item() {
    local label="$1"
    local value="$2"
    printf "  ${BOLD}%-12s${NC} %s\n" "$label:" "$value"
}

print_separator() {
    print_line "─"
}

# ── System Information Functions ─────────────────────────────────────────────

get_os_info() {
    local os_name="" os_version="" os_codename=""

    if [ -f /etc/os-release ]; then
        os_name=$(grep -oP '(?<=^NAME=").*(?=")' /etc/os-release 2>/dev/null || grep -oP '(?<=^NAME=)[^"]+' /etc/os-release 2>/dev/null)
        os_version=$(grep -oP '(?<=^VERSION=").*(?=")' /etc/os-release 2>/dev/null || grep -oP '(?<=^VERSION_ID=").*(?=")' /etc/os-release 2>/dev/null)
        os_codename=$(grep -oP '(?<=^VERSION_CODENAME=").*(?=")' /etc/os-release 2>/dev/null || grep -oP '(?<=^VERSION_CODENAME=)[^"]+' /etc/os-release 2>/dev/null)
    elif [ -f /etc/lsb-release ]; then
        os_name=$(grep -oP '(?<=^DISTRIB_ID=).*' /etc/lsb-release 2>/dev/null)
        os_version=$(grep -oP '(?<=^DISTRIB_RELEASE=).*' /etc/lsb-release 2>/dev/null)
        os_codename=$(grep -oP '(?<=^DISTRIB_CODENAME=).*' /etc/lsb-release 2>/dev/null)
    elif [ -f /etc/debian_version ]; then
        os_name="Debian"
        os_version=$(cat /etc/debian_version 2>/dev/null)
    elif [ -f /etc/redhat-release ]; then
        os_name=$(cat /etc/redhat-release 2>/dev/null)
    else
        os_name="Unknown"
    fi

    if [ -n "$os_codename" ]; then
        echo "$os_name $os_version ($os_codename)"
    elif [ -n "$os_version" ]; then
        echo "$os_name $os_version"
    else
        echo "$os_name"
    fi
}

get_kernel() {
    uname -r 2>/dev/null || echo "N/A"
}

get_arch() {
    uname -m 2>/dev/null || echo "N/A"
}

get_hostname() {
    hostname -f 2>/dev/null || hostname 2>/dev/null || echo "N/A"
}

get_uptime() {
    local uptime_seconds
    if [ -f /proc/uptime ]; then
        uptime_seconds=$(awk '{print int($1)}' /proc/uptime 2>/dev/null)
    else
        uptime_seconds=$(uptime -p 2>/dev/null | grep -oP '\d+' || echo 0)
    fi

    if [ "$uptime_seconds" -gt 0 ] 2>/dev/null; then
        local days=$((uptime_seconds / 86400))
        local hours=$(( (uptime_seconds % 86400) / 3600 ))
        local minutes=$(( (uptime_seconds % 3600) / 60 ))

        local result=""
        [ "$days" -gt 0 ] && result+="${days}d "
        [ "$hours" -gt 0 ] && result+="${hours}h "
        result+="${minutes}m"
        echo "$result"
    else
        uptime -p 2>/dev/null | sed 's/up //' || echo "N/A"
    fi
}

get_cpu_info() {
    local model="" cores="" threads="" load=""

    if [ -f /proc/cpuinfo ]; then
        model=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d: -f2- | sed 's/^ //')
        cores=$(grep "cpu cores" /proc/cpuinfo 2>/dev/null | head -1 | awk '{print $4}')
        threads=$(nproc 2>/dev/null)
    fi

    if [ -z "$model" ]; then
        model=$(lscpu 2>/dev/null | grep "Model name" | cut -d: -f2- | sed 's/^ *//' || echo "N/A")
    fi
    if [ -z "$cores" ]; then
        cores=$(lscpu 2>/dev/null | grep "^CPU(s)" | awk '{print $2}' || echo "N/A")
        threads=""
    fi

    load=$(uptime 2>/dev/null | grep -oP 'load average:.*$' | cut -d: -f2 | xargs || echo "N/A")

    echo "$model|$cores|$threads|$load"
}

get_memory_info() {
    if command -v free &>/dev/null; then
        # Memory
        local mem_total mem_used mem_free mem_shared mem_cache mem_avail
        mem_total=$(free -h 2>/dev/null | awk '/^Mem:/ {print $2}')
        mem_used=$(free -h 2>/dev/null | awk '/^Mem:/ {print $3}')
        mem_free=$(free -h 2>/dev/null | awk '/^Mem:/ {print $4}')
        mem_shared=$(free -h 2>/dev/null | awk '/^Mem:/ {print $5}')
        mem_cache=$(free -h 2>/dev/null | awk '/^Mem:/ {print $6}')
        mem_avail=$(free -h 2>/dev/null | awk '/^Mem:/ {print $7}')

        # Swap
        local swap_total swap_used swap_free
        swap_total=$(free -h 2>/dev/null | awk '/^Swap:/ {print $2}')
        swap_used=$(free -h 2>/dev/null | awk '/^Swap:/ {print $3}')
        swap_free=$(free -h 2>/dev/null | awk '/^Swap:/ {print $4}')

        [ -z "$mem_total" ] && mem_total="N/A"
        [ -z "$mem_used" ] && mem_used="N/A"
        [ -z "$mem_free" ] && mem_free="N/A"
        [ -z "$swap_total" ] && swap_total="N/A"
        [ -z "$swap_used" ] && swap_used="N/A"
        [ -z "$swap_free" ] && swap_free="N/A"

        echo "RAM:${mem_total}:${mem_used}:${mem_free}:${mem_avail}|Swap:${swap_total}:${swap_used}:${swap_free}"
    else
        echo "N/A"
    fi
}

get_disk_info() {
    local mounts=("/" "/home" "/var" "/tmp" "/data" "/opt")
    local results=()

    if command -v df &>/dev/null; then
        for mount in "${mounts[@]}"; do
            if mountpoint -q "$mount" 2>/dev/null; then
                local line
                line=$(df -h "$mount" 2>/dev/null | tail -1)
                if [ -n "$line" ]; then
                    local size used avail use_pct filesystem
                    size=$(echo "$line" | awk '{print $2}')
                    used=$(echo "$line" | awk '{print $3}')
                    avail=$(echo "$line" | awk '{print $4}')
                    use_pct=$(echo "$line" | awk '{print $5}')
                    filesystem=$(echo "$line" | awk '{print $1}')
                    results+=("$mount:$size:$used:$avail:$use_pct:$filesystem")
                fi
            fi
        done
    fi

    if [ ${#results[@]} -eq 0 ]; then
        echo "N/A"
    else
        printf '%s\n' "${results[@]}"
    fi
}

get_network_info() {
    local results=()

    if command -v ip &>/dev/null; then
        while IFS= read -r line; do
            local iface addr
            iface=$(echo "$line" | awk '{print $2}')
            addr=$(echo "$line" | awk '{print $3}')
            # Skip loopback and interfaces without IP
            if [ -n "$addr" ] && [ "$iface" != "lo" ]; then
                # Check if interface is up
                local state
                state=$(ip link show "$iface" 2>/dev/null | grep -oP '(?<=state )\w+' || echo "unknown")
                results+=("$iface:$addr:$state")
            fi
        done < <(ip -br addr 2>/dev/null | tail -n +2)
    elif command -v ifconfig &>/dev/null; then
        ifconfig 2>/dev/null | grep -E "^[a-z]|inet " | while IFS= read -r line; do
            echo "$line"
        done
    fi

    if [ ${#results[@]} -eq 0 ]; then
        echo "N/A"
    else
        printf '%s\n' "${results[@]}"
    fi
}

get_services_info() {
    local results=()

    if command -v systemctl &>/dev/null; then
        local services=(
            "nginx"
            "apache2"
            "httpd"
            "postgresql"
            "mysql"
            "mariadb"
            "redis"
            "docker"
            "sshd"
            "ssh"
            "ufw"
            "fail2ban"
            "cron"
            "rsyslog"
            "prometheus"
            "grafana-server"
        )

        for svc in "${services[@]}"; do
            local status
            status=$(systemctl is-active "$svc" 2>/dev/null || true)
            if [ -n "$status" ] && [ "$status" != "unknown" ]; then
                local enabled
                enabled=$(systemctl is-enabled "$svc" 2>/dev/null || echo "N/A")
                results+=("$svc:$status:$enabled")
            fi
        done
    fi

    # If no systemd services found, try a broader scan
    if [ ${#results[@]} -eq 0 ] && [ -d /etc/init.d ]; then
        for svc in /etc/init.d/*; do
            local name
            name=$(basename "$svc")
            results+=("$name:unknown:unknown")
        done
    fi

    if [ ${#results[@]} -eq 0 ]; then
        echo "N/A"
    else
        printf '%s\n' "${results[@]}"
    fi
}

get_docker_info() {
    if ! command -v docker &>/dev/null; then
        echo "N/A"
        return
    fi

    local running_containers="" total_containers="" images="" volumes=""

    running_containers=$(docker ps -q 2>/dev/null | wc -l) || running_containers=0
    total_containers=$(docker ps -aq 2>/dev/null | wc -l) || total_containers=0
    images=$(docker images -q 2>/dev/null | sort -u | wc -l) || images=0
    volumes=$(docker volume ls -q 2>/dev/null | wc -l) || volumes=0

    echo "${running_containers}:${total_containers}:${images}:${volumes}"
}

get_users_info() {
    local logged_in user_count
    logged_in=$(who 2>/dev/null | wc -l) || logged_in=0
    user_count=$(cat /etc/passwd 2>/dev/null | grep -cE "/bin/(ba|z)?sh" || echo "N/A")
    echo "$logged_in|$user_count"
}

get_temperature_info() {
    if command -v sensors &>/dev/null; then
        sensors -u 2>/dev/null | grep -m1 "temp1_input" | awk '{print $2}' | cut -d. -f1 || echo "N/A"
    elif [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        local temp
        temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
        echo "$((temp / 1000))°C"
    else
        echo "N/A"
    fi
}

# ── Display: Normal Mode ─────────────────────────────────────────────────────

display_normal() {
    local os_arch
    os_arch=$(get_arch)

    # ── Header ──
    echo ""
    echo -e "${BOLD}${CYAN}  ╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}  ║                    SYSTEM INFORMATION DASHBOARD               ║${NC}"
    echo -e "${BOLD}${CYAN}  ╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # ── OS & System ──
    print_section "OS & System"
    info_item "OS" "$(get_os_info) (${os_arch})"
    info_item "Kernel" "$(get_kernel)"
    info_item "Hostname" "$(get_hostname)"
    info_item "Uptime" "$(get_uptime)"
    info_item "Date" "$(date '+%Y-%m-%d %H:%M:%S %Z')"

    # ── CPU ──
    print_section "CPU"
    IFS='|' read -r cpu_model cpu_cores cpu_threads cpu_load <<< "$(get_cpu_info)"
    info_item "Model" "${cpu_model:-N/A}"
    if [ -n "${cpu_threads:-}" ]; then
        info_item "Cores" "${cpu_cores:-N/A} physical / ${cpu_threads} logical"
    else
        info_item "Cores" "${cpu_cores:-N/A}"
    fi
    info_item "Load Avg" "${cpu_load:-N/A}"

    # ── Memory ──
    print_section "Memory"
    local mem_info
    mem_info=$(get_memory_info)
    if [ "$mem_info" != "N/A" ]; then
        local ram_part swap_part
        ram_part=$(echo "$mem_info" | cut -d'|' -f1)
        swap_part=$(echo "$mem_info" | cut -d'|' -f2)

        IFS=':' read -r _ ram_total ram_used ram_free ram_avail <<< "$ram_part"
        IFS=':' read -r _ swap_total swap_used swap_free <<< "$swap_part"

        info_item "RAM" "${ram_total} total"
        info_item "Used" "${ram_used}"
        info_item "Free" "${ram_free}"
        info_item "Avail" "${ram_avail}"

        print_separator
        info_item "Swap" "${swap_total} total"
        info_item "Used" "${swap_used}"
        info_item "Free" "${swap_free}"
    else
        info_item "RAM" "N/A (free not available)"
    fi

    # ── Disk ──
    print_section "Disk Usage"
    local disk_info
    disk_info=$(get_disk_info)
    if [ "$disk_info" != "N/A" ]; then
        printf "  %-15s %-10s %-10s %-10s %-8s %s\n" "Mount" "Size" "Used" "Avail" "Use%" "Filesystem"
        print_line "─"
        while IFS= read -r line; do
            IFS=':' read -r mount size used avail use_pct filesystem <<< "$line"
            # Color code based on usage
            local pct_num
            pct_num=${use_pct%\%}
            local color="$GREEN"
            if [ "$pct_num" -gt 90 ] 2>/dev/null; then
                color="$RED"
            elif [ "$pct_num" -gt 75 ] 2>/dev/null; then
                color="$YELLOW"
            fi
            printf "  ${BOLD}%-15s${NC} %-10s %-10s %-10s ${color}%-8s${NC} %s\n" "$mount" "$size" "$used" "$avail" "$use_pct" "$filesystem"
        done <<< "$disk_info"
    else
        info_item "Disk" "N/A (df not available)"
    fi

    # ── Network ──
    print_section "Network Interfaces"
    local net_info
    net_info=$(get_network_info)
    if [ "$net_info" != "N/A" ]; then
        printf "  %-15s %-25s %s\n" "Interface" "IP Address" "State"
        print_line "─"
        while IFS= read -r line; do
            IFS=':' read -r iface addr state <<< "$line"
            local state_color="$GREEN"
            [ "$state" != "UP" ] && [ "$state" != "up" ] && state_color="$RED"
            printf "  ${BOLD}%-15s${NC} %-25s ${state_color}%s${NC}\n" "$iface" "$addr" "$state"
        done <<< "$net_info"
    else
        info_item "Network" "N/A (ip not available)"
    fi

    # ── Active Services ──
    print_section "Active Services"
    local svc_info
    svc_info=$(get_services_info)
    if [ "$svc_info" != "N/A" ]; then
        printf "  %-25s %-15s %s\n" "Service" "Status" "Enabled"
        print_line "─"
        while IFS= read -r line; do
            IFS=':' read -r svc_name svc_status svc_enabled <<< "$line"
            local status_color="$GREEN"
            [ "$svc_status" != "active" ] && [ "$svc_status" != "running" ] && status_color="$RED"
            local enabled_symbol="${GREEN}●${NC}"
            [ "$svc_enabled" != "enabled" ] && enabled_symbol="${DIM}○${NC}"
            printf "  ${enabled_symbol} %-23s ${status_color}%-15s${NC} %s\n" "$svc_name" "$svc_status" "$svc_enabled"
        done <<< "$svc_info"
    else
        info_item "Services" "N/A (systemctl not available)"
    fi

    # ── Docker ──
    print_section "Docker"
    local docker_info
    docker_info=$(get_docker_info)
    if [ "$docker_info" != "N/A" ]; then
        IFS=':' read -r dock_running dock_total dock_images dock_volumes <<< "$docker_info"
        info_item "Running" "${dock_running} containers"
        info_item "Total" "${dock_total} containers"
        info_item "Images" "${dock_images} total"
        info_item "Volumes" "${dock_volumes} total"
    else
        info_item "Docker" "Not installed or not available"
    fi

    # ── Users & Sessions ──
    print_section "Users & Sessions"
    IFS='|' read -r logged_in total_users <<< "$(get_users_info)"
    info_item "Logged In" "${logged_in} user(s)"
    info_item "Shell Users" "${total_users} total"

    # ── Temperature ──
    print_section "Hardware"
    local temp
    temp=$(get_temperature_info)
    info_item "CPU Temp" "${temp}"

    # ── Footer ──
    echo ""
    print_line "═"
    echo -e " ${DIM}System Information v${VERSION} • Generated $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo ""
}

# ── Display: Short Mode ──────────────────────────────────────────────────────

display_short() {
    echo ""
    echo -e "${BOLD}${CYAN}═══ System Summary ═══${NC}"
    echo ""

    local cpu_model
    cpu_model=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d: -f2- | sed 's/^ //' | sed 's/(R)//g; s/(TM)//g; s/CPU //g; s/\s\+/ /g' | cut -d' ' -f2-5)

    info_item "OS" "$(get_os_info) ($(get_arch))"
    info_item "Kernel" "$(get_kernel)"
    info_item "Host" "$(get_hostname)"
    info_item "Uptime" "$(get_uptime)"
    info_item "CPU" "${cpu_model:-N/A} ($(nproc 2>/dev/null || echo "?") cores)"
    info_item "RAM" "$(free -h 2>/dev/null | awk '/^Mem:/ {print $3 "/" $2 " used"}' || echo "N/A")"
    info_item "Load" "$(uptime 2>/dev/null | grep -oP 'load average:.*$' | cut -d: -f2 | xargs || echo "N/A")"
    info_item "IP" "$(curl -s --max-time 2 ifconfig.me 2>/dev/null || echo "N/A")"

    echo ""
    if command -v docker &>/dev/null; then
        info_item "Docker" "$(docker ps -q 2>/dev/null | wc -l) running / $(docker ps -aq 2>/dev/null | wc -l) total"
    fi
    echo ""
}

# ── Display: JSON Mode ──────────────────────────────────────────────────────

display_json() {
    local os_arch
    os_arch=$(get_arch)
    IFS='|' read -r cpu_model cpu_cores cpu_threads cpu_load <<< "$(get_cpu_info)"

    # Build JSON manually (avoid jq dependency for this)
    printf '{\n'
    printf '  "version": "%s",\n' "$VERSION"
    printf '  "generated": "%s",\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    printf '  "system": {\n'
    printf '    "os": "%s",\n' "$(get_os_info | sed 's/"/\\"/g')"
    printf '    "kernel": "%s",\n' "$(get_kernel)"
    printf '    "architecture": "%s",\n' "$os_arch"
    printf '    "hostname": "%s",\n' "$(get_hostname)"
    printf '    "uptime": "%s"\n' "$(get_uptime)"
    printf '  },\n'
    printf '  "cpu": {\n'
    printf '    "model": "%s",\n' "$(echo "${cpu_model:-N/A}" | sed 's/"/\\"/g')"
    printf '    "cores": "%s",\n' "${cpu_cores:-N/A}"
    printf '    "threads": "%s",\n' "${cpu_threads:-N/A}"
    printf '    "load_average": "%s"\n' "${cpu_load:-N/A}"
    printf '  },\n'

    local mem_info
    mem_info=$(get_memory_info)
    if [ "$mem_info" != "N/A" ]; then
        local ram_part swap_part
        ram_part=$(echo "$mem_info" | cut -d'|' -f1)
        swap_part=$(echo "$mem_info" | cut -d'|' -f2)
        IFS=':' read -r _ ram_total ram_used ram_free ram_avail <<< "$ram_part"
        IFS=':' read -r _ swap_total swap_used swap_free <<< "$swap_part"
        printf '  "memory": {\n'
        printf '    "ram_total": "%s",\n' "${ram_total:-N/A}"
        printf '    "ram_used": "%s",\n' "${ram_used:-N/A}"
        printf '    "ram_free": "%s",\n' "${ram_free:-N/A}"
        printf '    "ram_available": "%s",\n' "${ram_avail:-N/A}"
        printf '    "swap_total": "%s",\n' "${swap_total:-N/A}"
        printf '    "swap_used": "%s",\n' "${swap_used:-N/A}"
        printf '    "swap_free": "%s"\n' "${swap_free:-N/A}"
        printf '  },\n'
    fi

    local docker_info
    docker_info=$(get_docker_info)
    if [ "$docker_info" != "N/A" ]; then
        IFS=':' read -r dock_running dock_total dock_images dock_volumes <<< "$docker_info"
        printf '  "docker": {\n'
        printf '    "containers_running": %s,\n' "${dock_running:-0}"
        printf '    "containers_total": %s,\n' "${dock_total:-0}"
        printf '    "images": %s,\n' "${dock_images:-0}"
        printf '    "volumes": %s\n' "${dock_volumes:-0}"
        printf '  }\n'
    fi

    printf '}\n'
}

# ── Main ─────────────────────────────────────────────────────────────────────

main() {
    local mode="${1:-normal}"

    case "$mode" in
        --short|-s)
            display_short
            ;;
        --json|-j)
            display_json
            ;;
        --help|-h)
            echo "System Information Dashboard v${VERSION}"
            echo ""
            echo "Usage: $0 [OPTION]"
            echo ""
            echo "Options:"
            echo "  (none)    Display full system information (default)"
            echo "  --short   Display compact summary"
            echo "  --json    Output in JSON format (for automation)"
            echo "  --help    Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                # Full dashboard"
            echo "  $0 --short        # Quick summary"
            echo "  $0 --json         # JSON output (pipe to jq for formatting)"
            exit 0
            ;;
        "")
            display_normal
            ;;
        *)
            echo "Unknown option: $mode" >&2
            echo "Usage: $0 [--short|--json|--help]" >&2
            exit 1
            ;;
    esac
}

main "$@"
