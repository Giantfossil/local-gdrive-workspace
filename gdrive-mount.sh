#!/usr/bin/env bash
# ==============================================================================
# gdrive-mount.sh - High Performance On-Demand Google Drive Mount via Rclone
# ==============================================================================
set -euo pipefail

# Configuration defaults (can be overridden via environment variables)
REMOTE="${RCLONE_REMOTE:-gdrive:}"
MOUNT_POINT="${RCLONE_MOUNT_POINT:-/srv/gdrive}"
CACHE_DIR="${RCLONE_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/rclone/gdrive}"
LOG_FILE="${RCLONE_LOG_FILE:-${XDG_CACHE_HOME:-$HOME/.cache}/rclone/gdrive.log}"
LOG_LEVEL="${RCLONE_LOG_LEVEL:-NOTICE}"

# Ensure cache directory exists
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$CACHE_DIR"

check_mountpoint() {
    if [[ ! -d "$MOUNT_POINT" ]]; then
        if mkdir -p "$MOUNT_POINT" 2>/dev/null; then
            echo "[INFO] Mountpoint created: $MOUNT_POINT"
        else
            echo "[ERROR] Mountpoint $MOUNT_POINT does not exist and cannot be created without appropriate permissions." >&2
            echo "[HINT] Run: sudo mkdir -p '$MOUNT_POINT' && sudo chown $(id -u):$(id -g) '$MOUNT_POINT'" >&2
            exit 1
        fi
    fi
}

is_mounted() {
    mountpoint -q "$MOUNT_POINT" 2>/dev/null
}

unmount_drive() {
    if is_mounted; then
        echo "[INFO] Unmounting $MOUNT_POINT..."
        if command -v fusermount3 &>/dev/null; then
            fusermount3 -u -z "$MOUNT_POINT" || true
        elif command -v fusermount &>/dev/null; then
            fusermount -u -z "$MOUNT_POINT" || true
        else
            umount -l "$MOUNT_POINT" || true
        fi
        sleep 1
    fi
}

cleanup() {
    echo "[INFO] Received termination signal. Cleaning up..."
    unmount_drive
    exit 0
}

# Mount flags optimized for low latency, on-demand streaming & high bandwidth
build_rclone_args() {
    local args=(
        mount "$REMOTE" "$MOUNT_POINT"
        # On-Demand VFS Caching: load only chunks accessed, cache locally
        --cache-dir="$CACHE_DIR"
        --vfs-cache-mode=full
        --vfs-cache-max-age=72h
        --vfs-cache-max-size=50G
        --vfs-cache-poll-interval=1m
        --vfs-read-chunk-size=32M
        --vfs-read-chunk-size-limit=2G
        --vfs-read-ahead=128M

        # High-Speed Directory & Metadata Caching (instant folder listing)
        --dir-cache-time=1000h
        --poll-interval=15s
        --attr-timeout=1s

        # Google Drive API & Transfer Optimization
        --drive-pacer-min-sleep=10ms
        --drive-pacer-burst=200
        --drive-chunk-size=64M
        --buffer-size=64M
        --transfers=8
        --checkers=16

        # Permissions & System Integration
        --umask=022
        --log-file="$LOG_FILE"
        --log-level="$LOG_LEVEL"
    )

    # Add --allow-other if supported in /etc/fuse.conf or running as root
    if [[ $EUID -eq 0 ]] || grep -q '^[[:space:]]*user_allow_other' /etc/fuse.conf 2>/dev/null; then
        args+=(--allow-other)
    fi

    echo "${args[@]}"
}

start_foreground() {
    check_mountpoint
    if is_mounted; then
        echo "[WARN] $MOUNT_POINT is already mounted."
        exit 0
    fi

    trap cleanup SIGINT SIGTERM SIGHUP

    echo "[INFO] Starting rclone mount: $REMOTE -> $MOUNT_POINT"
    echo "[INFO] Cache Directory: $CACHE_DIR"
    echo "[INFO] Log File: $LOG_FILE"

    local args=()
    read -r -a args <<< "$(build_rclone_args)"
    exec rclone "${args[@]}"
}

start_daemon() {
    check_mountpoint
    if is_mounted; then
        echo "[WARN] $MOUNT_POINT is already mounted."
        exit 0
    fi

    echo "[INFO] Mounting $REMOTE to $MOUNT_POINT in daemon mode..."
    local args=()
    read -r -a args <<< "$(build_rclone_args)"
    rclone "${args[@]}" --daemon

    # Wait briefly and verify mount
    sleep 2
    if is_mounted; then
        echo "[SUCCESS] Successfully mounted at $MOUNT_POINT"
    else
        echo "[ERROR] Mount failed. Check log: $LOG_FILE" >&2
        exit 1
    fi
}

status_drive() {
    if is_mounted; then
        echo "[STATUS] Active: $REMOTE is mounted on $MOUNT_POINT"
        df -h "$MOUNT_POINT" 2>/dev/null || true
    else
        echo "[STATUS] Inactive: $MOUNT_POINT is not mounted."
    fi
}

usage() {
    cat <<EOF
Usage: $(basename "$0") {start|daemon|stop|restart|status}

Commands:
  start      Start rclone mount in foreground (suitable for systemd user service)
  daemon     Start rclone mount in background (daemon mode)
  stop       Unmount $MOUNT_POINT
  restart    Unmount and start daemon
  status     Check if $MOUNT_POINT is currently mounted

Environment Variables:
  RCLONE_REMOTE       Remote name (default: gdrive:)
  RCLONE_MOUNT_POINT  Mount directory (default: /srv/gdrive)
  RCLONE_CACHE_DIR    VFS cache directory (default: ~/.cache/rclone/gdrive)
  RCLONE_LOG_FILE     Path to log file (default: ~/.cache/rclone/gdrive.log)
  RCLONE_LOG_LEVEL    Log verbosity (default: NOTICE, options: DEBUG, INFO, NOTICE, ERROR)
EOF
}

case "${1:-start}" in
    start|foreground)
        start_foreground
        ;;
    daemon|background)
        start_daemon
        ;;
    stop|umount|unmount)
        unmount_drive
        echo "[INFO] Unmounted $MOUNT_POINT"
        ;;
    restart)
        unmount_drive
        start_daemon
        ;;
    status)
        status_drive
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        usage
        exit 1
        ;;
esac
