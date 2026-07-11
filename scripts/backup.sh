#!/usr/bin/env bash
# =============================================================================
#  backup.sh — Flexible Backup Script
#  Part of dotfiles-linux (https://github.com/razafimandimby-IT/dotfiles-linux)
# =============================================================================
#
#  Supports:
#    - Full and incremental backups
#    - Compression (gzip, bzip2, xz)
#    - GPG encryption
#    - Remote sync via rsync/SSH
#    - Retention policy (auto-delete old backups)
#    - Email notifications
#    - Detailed logging
#
#  Usage:
#    ./scripts/backup.sh --source /path/to/data --dest /path/to/backups
#    ./scripts/backup.sh --source /var/www --dest /backup/web --compress gzip
#    ./scripts/backup.sh --source /etc --dest /backup/etc --encrypt --recipient user@example.com
#    ./scripts/backup.sh --source /data --dest /backup/data --remote user@server:/backups
#    ./scripts/backup.sh --config /path/to/config.conf
#
# =============================================================================

set -euo pipefail

# ── Script Info ──────────────────────────────────────────────────────────────

VERSION="1.2.0"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# ── Default Configuration ────────────────────────────────────────────────────

# These can be overridden via command-line arguments or config file
SOURCE_DIR=""                     # Directory to back up
DEST_DIR=""                       # Where to store the backup
BACKUP_NAME=""                    # Custom backup name (default: basename of source)
COMPRESS=""                       # Compression: gzip, bzip2, xz, or empty for none
ENCRYPT=false                     # Enable GPG encryption
RECIPIENT=""                      # GPG recipient key
REMOTE=""                         # Remote destination (user@host:/path)
RETENTION_DAYS=0                  # Delete backups older than N days (0 = no cleanup)
INCREMENTAL=false                 # Enable incremental backup
EXCLUDE_FILE=""                   # rsync exclude file (one pattern per line)
LOG_DIR="/var/log/backup"         # Log directory
LOG_FILE=""                       # Specific log file (auto-generated if empty)
TIMESTAMP_FORMAT="%Y%m%d-%H%M%S"  # Timestamp format for backup files
DRY_RUN=false                     # Simulate without making changes
VERBOSE=false                     # Verbose output
QUIET=false                       # Suppress non-error output
EMAIL=""                          # Email for notifications
EMAIL_ONLY_FAILURE=false          # Only email on failure
PRUNE_EXISTING=false               # Prune old backups before creating new one

# ── Colors ───────────────────────────────────────────────────────────────────

if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    DIM='\033[2m'
    NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; MAGENTA=''; BOLD=''; DIM=''; NC=''
fi

# ── Logging ──────────────────────────────────────────────────────────────────

log() {
    local level="$1"
    shift
    local msg="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Always write to log file
    if [ -n "$LOG_FILE" ]; then
        echo "${timestamp} [${level}] ${msg}" >> "$LOG_FILE" 2>/dev/null || true
    fi

    # Console output (respect quiet mode)
    if [ "$QUIET" = false ] || [ "$level" = "ERROR" ] || [ "$level" = "FATAL" ]; then
        case "$level" in
            INFO)    echo -e " ${GREEN}[INFO]${NC}  $msg" ;;
            WARN)    echo -e " ${YELLOW}[WARN]${NC}  $msg" ;;
            ERROR)   echo -e " ${RED}[ERROR]${NC} $msg" ;;
            FATAL)   echo -e " ${RED}[FATAL]${NC} $msg" ;;
            STEP)    echo -e "\n ${CYAN}━━━ $msg ━━━${NC}" ;;
            OK)      echo -e " ${GREEN}✓${NC} $msg" ;;
            FAIL)    echo -e " ${RED}✗${NC} $msg" ;;
            DEBUG)   [ "$VERBOSE" = true ] && echo -e " ${DIM}[DEBUG]${NC} $msg" ;;
            *)       echo -e "  $msg" ;;
        esac
    fi
}

info()    { log "INFO" "$*"; }
warn()    { log "WARN" "$*"; }
error()   { log "ERROR" "$*"; }
fatal()   { log "FATAL" "$*"; exit 1; }
step()    { log "STEP" "$*"; }
ok()      { log "OK" "$*"; }
fail()    { log "FAIL" "$*"; }
debug()   { log "DEBUG" "$*"; }

# ── Command-Line Argument Parsing ──────────────────────────────────────────

print_usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS]

Required:
  --source DIR       Source directory to backup
  --dest DIR         Destination directory for backups

Optional:
  --name NAME        Custom backup name (default: basename of source)
  --compress TYPE    Compression type: gzip, bzip2, xz (default: none)
  --encrypt          Enable GPG encryption
  --recipient KEY    GPG recipient key (email or key ID)
  --remote DEST      Remote destination (user@host:/path)
  --retention DAYS   Delete backups older than N days
  --incremental      Enable incremental backup
  --exclude FILE     Exclude file for rsync
  --log-dir DIR      Log directory (default: /var/log/backup)
  --dry-run          Simulate without making changes
  --verbose          Verbose output
  --quiet            Suppress non-error output
  --email ADDR       Email address for notifications
  --email-on-failure Only send email on failure
  --config FILE      Load configuration from file
  --prune            Prune old backups before creating new one
  --version          Show version
  --help             Show this help message

Examples:
  ${SCRIPT_NAME} --source /var/www --dest /backup/web --compress gzip
  ${SCRIPT_NAME} --source /home/user/data --dest /backup/data --encrypt --recipient me@example.com
  ${SCRIPT_NAME} --source /etc --dest /backup/etc --remote user@backup-server:/backups
  ${SCRIPT_NAME} --source /data --dest /backup/data --incremental --retention 30
EOF
}

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --source|-s)
                SOURCE_DIR="$2"; shift 2 ;;
            --dest|-d)
                DEST_DIR="$2"; shift 2 ;;
            --name|-n)
                BACKUP_NAME="$2"; shift 2 ;;
            --compress|-c)
                COMPRESS="$2"; shift 2 ;;
            --encrypt|-e)
                ENCRYPT=true; shift ;;
            --recipient|-r)
                RECIPIENT="$2"; shift 2 ;;
            --remote|-R)
                REMOTE="$2"; shift 2 ;;
            --retention|-t)
                RETENTION_DAYS="$2"; shift 2 ;;
            --incremental|-i)
                INCREMENTAL=true; shift ;;
            --exclude|-x)
                EXCLUDE_FILE="$2"; shift 2 ;;
            --log-dir|-l)
                LOG_DIR="$2"; shift 2 ;;
            --dry-run|-n)
                DRY_RUN=true; shift ;;
            --verbose|-v)
                VERBOSE=true; shift ;;
            --quiet|-q)
                QUIET=true; shift ;;
            --email|-m)
                EMAIL="$2"; shift 2 ;;
            --email-on-failure)
                EMAIL_ONLY_FAILURE=true; shift ;;
            --config|-f)
                load_config "$2"; shift 2 ;;
            --prune)
                PRUNE_EXISTING=true; shift ;;
            --version|-V)
                echo "${SCRIPT_NAME} v${VERSION}"; exit 0 ;;
            --help|-h)
                print_usage; exit 0 ;;
            *)
                echo "Unknown option: $1" >&2
                echo "Use --help for usage information." >&2
                exit 1 ;;
        esac
    done
}

# ── Config File Loading ──────────────────────────────────────────────────────

load_config() {
    local config_file="$1"

    if [ ! -f "$config_file" ]; then
        fatal "Config file not found: $config_file"
    fi

    info "Loading configuration from: $config_file"

    # Source the config file (bash-style key=value pairs)
    while IFS='=' read -r key value; do
        # Skip comments and blank lines
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue

        # Trim whitespace
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)

        case "$key" in
            SOURCE_DIR)     SOURCE_DIR="$value" ;;
            DEST_DIR)       DEST_DIR="$value" ;;
            BACKUP_NAME)    BACKUP_NAME="$value" ;;
            COMPRESS)       COMPRESS="$value" ;;
            ENCRYPT)        ENCRYPT=$(echo "$value" | tr '[:upper:]' '[:lower:]') ; [[ "$ENCRYPT" == "true" || "$ENCRYPT" == "yes" || "$ENCRYPT" == "1" ]] && ENCRYPT=true || ENCRYPT=false ;;
            RECIPIENT)      RECIPIENT="$value" ;;
            REMOTE)         REMOTE="$value" ;;
            RETENTION_DAYS) RETENTION_DAYS="$value" ;;
            INCREMENTAL)    INCREMENTAL="$value" ;;
            EXCLUDE_FILE)   EXCLUDE_FILE="$value" ;;
            LOG_DIR)        LOG_DIR="$value" ;;
            DRY_RUN)        DRY_RUN="$value" ;;
            VERBOSE)        VERBOSE="$value" ;;
            QUIET)          QUIET="$value" ;;
            EMAIL)          EMAIL="$value" ;;
            PRUNE_EXISTING) PRUNE_EXISTING="$value" ;;
        esac
    done < "$config_file"
}

# ── Validation ───────────────────────────────────────────────────────────────

validate_args() {
    local errors=0

    if [ -z "$SOURCE_DIR" ]; then
        error "Source directory (--source) is required."
        errors=1
    elif [ ! -d "$SOURCE_DIR" ]; then
        error "Source directory does not exist: $SOURCE_DIR"
        errors=1
    fi

    if [ -z "$DEST_DIR" ]; then
        error "Destination directory (--dest) is required."
        errors=1
    fi

    if [ "$ENCRYPT" = true ] && [ -z "$RECIPIENT" ]; then
        error "Encryption requires --recipient (GPG key email or ID)."
        errors=1
    fi

    if [ -n "$COMPRESS" ]; then
        case "$COMPRESS" in
            gzip|bzip2|xz) ;;
            *)
                error "Unsupported compression: $COMPRESS. Use gzip, bzip2, or xz."
                errors=1 ;;
        esac
    fi

    if [ -n "$EXCLUDE_FILE" ] && [ ! -f "$EXCLUDE_FILE" ]; then
        error "Exclude file not found: $EXCLUDE_FILE"
        errors=1
    fi

    if [ "$errors" -gt 0 ]; then
        fatal "Validation failed. Fix errors and re-run."
    fi
}

# ── Pre-flight Checks ────────────────────────────────────────────────────────

preflight_checks() {
    step "Pre-flight Checks"

    # Check required commands
    local required_cmds=("rsync" "tar" "date")
    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            fatal "Required command not found: $cmd"
        fi
    done
    debug "Required commands available."

    # Check optional commands
    if [ -n "$COMPRESS" ]; then
        case "$COMPRESS" in
            gzip)  command -v gzip  &>/dev/null || fatal "gzip not found (required for --compress gzip)" ;;
            bzip2) command -v bzip2 &>/dev/null || fatal "bzip2 not found (required for --compress bzip2)" ;;
            xz)    command -v xz    &>/dev/null || fatal "xz not found (required for --compress xz)" ;;
        esac
        debug "Compression tool ($COMPRESS) available."
    fi

    if [ "$ENCRYPT" = true ]; then
        command -v gpg &>/dev/null || fatal "gpg not found (required for --encrypt)"
        # Check recipient key
        if ! gpg --list-keys "$RECIPIENT" &>/dev/null; then
            warn "GPG key not found in local keyring: $RECIPIENT. Encryption may fail."
        fi
        debug "GPG available, recipient: $RECIPIENT"
    fi

    # Create destination directory
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$DEST_DIR" 2>/dev/null || fatal "Cannot create destination directory: $DEST_DIR"
        if [ ! -w "$DEST_DIR" ]; then
            fatal "Destination directory is not writable: $DEST_DIR"
        fi
    fi
    info "All pre-flight checks passed."
}

# ── Setup Logging ────────────────────────────────────────────────────────────

setup_logging() {
    if [ -n "$LOG_DIR" ]; then
        if [ "$DRY_RUN" = false ]; then
            mkdir -p "$LOG_DIR" 2>/dev/null || true
        fi
        LOG_FILE="${LOG_DIR}/backup-$(date +%Y%m%d-%H%M%S).log"
    fi
}

# ── Determine Backup Name ────────────────────────────────────────────────────

get_backup_name() {
    if [ -n "$BACKUP_NAME" ]; then
        echo "$BACKUP_NAME"
    else
        basename "$(realpath "$SOURCE_DIR")"
    fi
}

# ── Prune Old Backups ────────────────────────────────────────────────────────

prune_old_backups() {
    if [ "$RETENTION_DAYS" -le 0 ]; then
        return
    fi

    step "Pruning Backups Older Than ${RETENTION_DAYS} Days"

    if [ ! -d "$DEST_DIR" ]; then
        debug "Destination directory does not exist yet. Nothing to prune."
        return
    fi

    local pruned=0

    # Find and delete old backup files (tar.gz, tar.bz2, tar.xz, tar, .gpg)
    while IFS= read -r -d '' old_file; do
        if [ "$DRY_RUN" = false ]; then
            rm -f "$old_file" 2>/dev/null && pruned=$((pruned + 1)) || warn "Could not delete: $old_file"
        else
            info "[DRY-RUN] Would delete: $old_file"
            pruned=$((pruned + 1))
        fi
    done < <(find "$DEST_DIR" -maxdepth 1 -type f -name "*.tar*" -o -name "*.gz" -o -name "*.bz2" -o -name "*.xz" -o -name "*.gpg" 2>/dev/null | while IFS= read -r f; do
        # Check file age based on filename timestamp (YYYYMMDD-HHMMSS pattern)
        local file_time
        file_time=$(echo "$f" | grep -oP '\d{8}-\d{6}')
        if [ -n "$file_time" ]; then
            local file_epoch
            file_epoch=$(date -d "${file_time:0:8} ${file_time:9:2}:${file_time:11:2}:${file_time:13:2}" +%s 2>/dev/null || echo 0)
            local cutoff_epoch
            cutoff_epoch=$(date -d "-${RETENTION_DAYS} days" +%s)
            if [ "$file_epoch" -lt "$cutoff_epoch" ] 2>/dev/null; then
                printf '%s\0' "$f"
            fi
        fi
    done)

    # Also check modification time as fallback
    if [ "$pruned" -eq 0 ]; then
        local old_count=0
        while IFS= read -r -d '' f; do
            if [ "$DRY_RUN" = false ]; then
                rm -f "$f" 2>/dev/null && old_count=$((old_count + 1))
            else
                info "[DRY-RUN] Would delete (by mtime): $(basename "$f")"
                old_count=$((old_count + 1))
            fi
        done < <(find "$DEST_DIR" -maxdepth 1 -type f \( -name "*.tar*" -o -name "*.gz" -o -name "*.bz2" -o -name "*.xz" -o -name "*.gpg" \) -mtime "+${RETENTION_DAYS}" -print0 2>/dev/null)

        [ "$old_count" -gt 0 ] && pruned=$((pruned + old_count))
    fi

    if [ "$pruned" -gt 0 ]; then
        ok "Pruned ${pruned} old backup(s) (retention: ${RETENTION_DAYS} days)"
    else
        info "No old backups to prune."
    fi
}

# ── Create Backup ────────────────────────────────────────────────────────────

create_backup() {
    local backup_name
    backup_name=$(get_backup_name)
    local timestamp
    timestamp=$(date +"$TIMESTAMP_FORMAT")
    local extension="tar"
    local compress_ext=""

    # Determine file extension based on compression
    if [ -n "$COMPRESS" ]; then
        case "$COMPRESS" in
            gzip)  compress_ext=".gz"   ;;
            bzip2) compress_ext=".bz2"  ;;
            xz)    compress_ext=".xz"   ;;
        esac
    fi

    local backup_file="${DEST_DIR}/${backup_name}-${timestamp}.${extension}${compress_ext}"

    step "Creating Backup: ${backup_name}"
    info "Source:      ${SOURCE_DIR}"
    info "Destination: ${backup_file}"
    info "Size:        $(du -sh "$SOURCE_DIR" 2>/dev/null | cut -f1 || echo "N/A")"
    [ -n "$COMPRESS" ] && info "Compression: ${COMPRESS}"
    [ "$ENCRYPT" = true ] && info "Encryption:  Enabled (recipient: ${RECIPIENT})"
    [ "$INCREMENTAL" = true ] && info "Mode:        Incremental"

    # If incremental, look for the previous backup as a base
    local incremental_args=""
    if [ "$INCREMENTAL" = true ]; then
        local latest_backup
        latest_backup=$(find "$DEST_DIR" -maxdepth 1 -name "${backup_name}-*.tar*" -type f 2>/dev/null | sort | tail -1)
        if [ -n "$latest_backup" ]; then
            incremental_args="--newer \"${latest_backup}\""
            info "Incremental base: $(basename "$latest_backup")"
        else
            warn "No previous backup found for incremental. Performing full backup."
        fi
    fi

    if [ "$DRY_RUN" = true ]; then
        info "[DRY-RUN] Would create: ${backup_file}"
        return
    fi

    # Build tar command
    local tar_cmd="tar -cf"
    local tar_opts=()

    # Compression flag
    if [ -n "$COMPRESS" ]; then
        case "$COMPRESS" in
            gzip)  tar_opts+=("-z") ;;
            bzip2) tar_opts+=("-j") ;;
            xz)    tar_opts+=("-J") ;;
        esac
    fi

    # Exclude file
    local exclude_args=()
    if [ -n "$EXCLUDE_FILE" ]; then
        exclude_args+=("--exclude-from=${EXCLUDE_FILE}")
    fi

    # Run tar
    local tar_exit=0
    if [ "$VERBOSE" = true ]; then
        info "Running: tar ${tar_opts[*]:-} ${exclude_args[*]:-} -cf ${backup_file} -C $(dirname "$SOURCE_DIR") $(basename "$SOURCE_DIR")"
    fi

    set +e  # Allow tar errors
    tar "${tar_opts[@]:-}" "${exclude_args[@]:-}" \
        --preserve-permissions \
        --same-owner \
        --xattrs \
        --transform "s,^${backup_name},${backup_name}-${timestamp}," \
        -cf "$backup_file" \
        -C "$(dirname "$(realpath "$SOURCE_DIR")")" \
        "$(basename "$(realpath "$SOURCE_DIR")")" 2>> "$LOG_FILE"

    tar_exit=$?
    set -e

    if [ "$tar_exit" -ne 0 ]; then
        # Some tar errors are non-fatal (e.g., file changed during read)
        warn "Tar completed with exit code ${tar_exit} (some warnings may have occurred)."
    fi

    # Verify the archive was created
    if [ ! -f "$backup_file" ]; then
        fatal "Backup file was not created: $backup_file"
    fi

    local file_size
    file_size=$(du -h "$backup_file" 2>/dev/null | cut -f1)
    ok "Archive created: ${backup_file} (${file_size})"

    # ── Encryption ──
    if [ "$ENCRYPT" = true ]; then
        encrypt_backup "$backup_file"
    fi
}

# ── Encrypt Backup ────────────────────────────────────────────────────────────

encrypt_backup() {
    local input_file="$1"
    local output_file="${input_file}.gpg"

    step "Encrypting Backup"
    info "Recipient: ${RECIPIENT}"
    info "Output:    ${output_file}"

    if [ "$DRY_RUN" = true ]; then
        info "[DRY-RUN] Would encrypt: ${input_file}"
        return
    fi

    # Encrypt with GPG
    if gpg --batch --yes --trust-model always \
        --recipient "$RECIPIENT" \
        --output "$output_file" \
        --encrypt "$input_file" 2>> "$LOG_FILE"; then

        ok "Encrypted: ${output_file}"

        # Remove unencrypted file
        rm -f "$input_file"
        info "Removed unencrypted archive: $(basename "$input_file")"

        # Update backup_file variable for remote sync
        BACKUP_FILE="$output_file"
    else
        warn "Encryption failed. Keeping unencrypted backup."
        BACKUP_FILE="$input_file"
    fi
}

# ── Sync to Remote ───────────────────────────────────────────────────────────

sync_remote() {
    if [ -z "$REMOTE" ]; then
        return
    fi

    step "Syncing to Remote Destination"
    info "Remote: ${REMOTE}"

    local rsync_opts=("-avz" "--progress")

    if [ "$DRY_RUN" = true ]; then
        rsync_opts+=("--dry-run")
    fi

    if [ "$VERBOSE" = true ]; then
        rsync_opts+=("-v")
    fi

    # Determine what to sync (entire DEST_DIR or just the latest file)
    local source_path="${DEST_DIR}/"

    info "Running rsync to ${REMOTE}..."
    set +e
    rsync "${rsync_opts[@]}" \
        --delete \
        --partial \
        --timeout=30 \
        -e "ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10" \
        "$source_path" \
        "$REMOTE" 2>> "$LOG_FILE"

    local rsync_exit=$?
    set -e

    case "$rsync_exit" in
        0)  ok "Remote sync completed successfully." ;;
        24) warn "Remote sync completed with minor warnings (exit code 24)." ;;
        *)  fail "Remote sync failed (exit code: ${rsync_exit})." ;;
    esac
}

# ── Notification ─────────────────────────────────────────────────────────────

send_notification() {
    local status="$1"
    local subject=""
    local body=""

    if [ -z "$EMAIL" ]; then
        return
    fi

    if [ "$EMAIL_ONLY_FAILURE" = true ] && [ "$status" = "success" ]; then
        debug "Skipping email notification (success + email-on-failure mode)."
        return
    fi

    case "$status" in
        success)
            subject="[Backup] SUCCESS — $(get_backup_name) — $(date +%Y-%m-%d)"
            if [ -n "$REMOTE" ]; then
                body="Backup completed successfully.\n\nSource: ${SOURCE_DIR}\nDestination: ${DEST_DIR}\nRemote: ${REMOTE}\nCompression: ${COMPRESS:-none}\nEncryption: ${ENCRYPT}"
            else
                body="Backup completed successfully.\n\nSource: ${SOURCE_DIR}\nDestination: ${DEST_DIR}\nCompression: ${COMPRESS:-none}\nEncryption: ${ENCRYPT}"
            fi
            ;;
        failure)
            subject="[Backup] FAILURE — $(get_backup_name) — $(date +%Y-%m-%d)"
            body="Backup FAILED.\n\nSource: ${SOURCE_DIR}\nDestination: ${DEST_DIR}\n\nCheck the log for details: ${LOG_FILE}"
            ;;
    esac

    # Try sending email via mail command
    if command -v mail &>/dev/null; then
        echo -e "$body" | mail -s "$subject" "$EMAIL" 2>/dev/null && \
            info "Email notification sent to ${EMAIL}" || \
            warn "Failed to send email notification."
    elif command -v sendmail &>/dev/null; then
        {
            echo "Subject: $subject"
            echo "To: $EMAIL"
            echo ""
            echo -e "$body"
        } | sendmail "$EMAIL" 2>/dev/null && \
            info "Email notification sent to ${EMAIL}" || \
            warn "Failed to send email notification."
    else
        warn "No mail command found. Cannot send email notification."
    fi
}

# ── Summary ───────────────────────────────────────────────────────────────────

print_summary() {
    step "Backup Summary"
    echo ""
    echo -e "  ${BOLD}Backup Name:${NC}    $(get_backup_name)"
    echo -e "  ${BOLD}Source:${NC}         ${SOURCE_DIR}"
    echo -e "  ${BOLD}Destination:${NC}    ${DEST_DIR}"
    echo -e "  ${BOLD}Compression:${NC}    ${COMPRESS:-none}"
    echo -e "  ${BOLD}Encryption:${NC}     ${ENCRYPT:-no}"
    [ -n "$REMOTE" ] && echo -e "  ${BOLD}Remote:${NC}        ${REMOTE}"
    [ "$RETENTION_DAYS" -gt 0 ] && echo -e "  ${BOLD}Retention:${NC}     ${RETENTION_DAYS} days"
    echo -e "  ${BOLD}Completed:${NC}     $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "  ${BOLD}Log File:${NC}      ${LOG_FILE}"
    echo ""
}

# ── Main ─────────────────────────────────────────────────────────────────────

main() {
    local start_time
    start_time=$(date +%s)
    local exit_status="success"

    echo ""
    echo -e "${BOLD}${BLUE}  ╔══════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}  ║        Backup Script v${VERSION}          ║${NC}"
    echo -e "${BOLD}${BLUE}  ╚══════════════════════════════════════════╝${NC}"
    echo ""

    # Parse and validate
    parse_args "$@"
    setup_logging
    validate_args

    # Run backup process
    preflight_checks

    if [ "$PRUNE_EXISTING" = true ]; then
        prune_old_backups
    fi

    create_backup
    sync_remote

    if [ "$RETENTION_DAYS" -gt 0 ] && [ "$PRUNE_EXISTING" = false ]; then
        prune_old_backups
    fi

    # Calculate duration
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local duration_str
    if [ "$duration" -ge 60 ]; then
        duration_str="$((duration / 60))m $((duration % 60))s"
    else
        duration_str="${duration}s"
    fi

    print_summary
    info "Total time: ${duration_str}"
    info "Log file:   ${LOG_FILE}"
    echo ""

    # Notification
    send_notification "$exit_status"

    # Final message
    if [ "$DRY_RUN" = true ]; then
        echo -e " ${YELLOW}⚠ DRY RUN — No changes were made.${NC}"
        echo ""
    else
        echo -e " ${GREEN}${BOLD}✓ Backup completed successfully.${NC}"
        echo ""
    fi
}

# Trap for unexpected errors
trap 'echo -e " ${RED}Backup interrupted or failed. Check log: ${LOG_FILE}${NC}"' EXIT

main "$@"

# Remove trap on clean exit
trap - EXIT
