#!/usr/bin/env bash
# ==============================================================================
# deployment.sh - Setup & Installation Script for Google Drive Mount (/srv/rclone/gdrive)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOUNT_POINT="${RCLONE_MOUNT_POINT:-/srv/rclone/gdrive}"
REMOTE_NAME="${RCLONE_REMOTE:-gdrive:}"
SERVICE_NAME="gdrive-mount.service"
USER_SYSTEMD_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
USER_BIN_DIR="${HOME}/.local/bin"

print_header() {
    echo "============================================================"
    echo " Google Drive Rclone Mount Deployment (/srv/rclone/gdrive)"
    echo "============================================================"
}

check_dependencies() {
    echo "[1/6] Checking dependencies..."
    local missing=()
    for cmd in rclone fusermount3 systemctl; do
        if ! command -v "$cmd" &>/dev/null; then
            if [[ "$cmd" == "fusermount3" ]] && command -v fusermount &>/dev/null; then
                continue
            fi
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "[ERROR] Missing required commands: ${missing[*]}" >&2
        echo "[HINT] Install them via package manager (e.g. pacman -S rclone fuse3)" >&2
        exit 1
    fi
    echo "      Dependencies OK."
}

check_rclone_remote() {
    echo "[2/6] Checking rclone remote configuration..."
    local remote_clean="${REMOTE_NAME%:}"
    if rclone listremotes | grep -q "^${remote_clean}:"; then
        echo "      Remote '${REMOTE_NAME}' is configured."
    else
        echo "[WARN] Remote '${REMOTE_NAME}' not found in rclone configuration!" >&2
        echo "      Please run 'rclone config' to set up your Google Drive remote." >&2
        echo "      See HOWTO.md for step-by-step instructions." >&2
        read -rp "Do you want to continue anyway? [y/N] " answer
        if [[ ! "$answer" =~ ^[yY]$ ]]; then
            exit 1
        fi
    fi
}

setup_mountpoint() {
    echo "[3/6] Setting up mount directory: $MOUNT_POINT"
    if [[ ! -d "$MOUNT_POINT" ]]; then
        if mkdir -p "$MOUNT_POINT" 2>/dev/null; then
            echo "      Directory created: $MOUNT_POINT"
        else
            echo "      Requesting sudo permissions to create $MOUNT_POINT and assign ownership to $USER..."
            sudo mkdir -p "$MOUNT_POINT"
            sudo chown -R "$(id -u):$(id -g)" "$MOUNT_POINT"
            echo "      Directory created and ownership assigned to $USER."
        fi
    else
        # Ensure user can write to the directory if not already mounted
        if ! mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
            if [[ ! -w "$MOUNT_POINT" ]]; then
                echo "      Adjusting ownership of existing $MOUNT_POINT to $USER..."
                sudo chown -R "$(id -u):$(id -g)" "$MOUNT_POINT"
            fi
        fi
        echo "      Mountpoint $MOUNT_POINT exists and is ready."
    fi
}

install_user_binaries() {
    echo "[4/6] Installing user helper utilities to $USER_BIN_DIR..."
    mkdir -p "$USER_BIN_DIR"
    if [[ -d "$SCRIPT_DIR/local/bin" ]]; then
        for bin_file in "$SCRIPT_DIR/local/bin"/*; do
            if [[ -f "$bin_file" ]]; then
                local bin_name
                bin_name="$(basename "$bin_file")"
                chmod +x "$bin_file"
                ln -sf "$bin_file" "$USER_BIN_DIR/$bin_name"
                echo "      Symlinked utility: $USER_BIN_DIR/$bin_name -> $bin_file"
            fi
        done
    fi
}

install_systemd_service() {
    echo "[5/6] Installing systemd user service..."
    mkdir -p "$USER_SYSTEMD_DIR"
    local service_src="$SCRIPT_DIR/$SERVICE_NAME"
    local service_dst="$USER_SYSTEMD_DIR/$SERVICE_NAME"

    if [[ ! -f "$service_src" ]]; then
        echo "[ERROR] Service file $service_src not found." >&2
        exit 1
    fi

    ln -sf "$service_src" "$service_dst"
    echo "      Symlinked: $service_dst -> $service_src"

    systemctl --user daemon-reload
    echo "      Systemd user daemon reloaded."
}

enable_and_start_service() {
    echo "[6/6] Enabling and starting $SERVICE_NAME..."
    systemctl --user enable --now "$SERVICE_NAME"
    sleep 2

    if systemctl --user is-active --quiet "$SERVICE_NAME"; then
        echo "============================================================"
        echo "[SUCCESS] Google Drive mount service is active and running!"
        echo "Mount target: $MOUNT_POINT"
        echo "Status command: systemctl --user status $SERVICE_NAME"
        echo "============================================================"
    else
        echo "[WARN] Service failed to start or is not yet active." >&2
        echo "Check status with: systemctl --user status $SERVICE_NAME" >&2
        echo "Check logs with:   journalctl --user -u $SERVICE_NAME -n 50 --no-pager" >&2
    fi
}

uninstall_service() {
    echo "Uninstalling $SERVICE_NAME..."
    systemctl --user stop "$SERVICE_NAME" 2>/dev/null || true
    systemctl --user disable "$SERVICE_NAME" 2>/dev/null || true

    local service_dst="$USER_SYSTEMD_DIR/$SERVICE_NAME"
    if [[ -L "$service_dst" || -f "$service_dst" ]]; then
        rm -f "$service_dst"
        echo "Removed symlink: $service_dst"
    fi

    if [[ -d "$SCRIPT_DIR/local/bin" ]]; then
        for bin_file in "$SCRIPT_DIR/local/bin"/*; do
            local bin_name
            bin_name="$(basename "$bin_file")"
            if [[ -L "$USER_BIN_DIR/$bin_name" ]]; then
                rm -f "$USER_BIN_DIR/$bin_name"
                echo "Removed symlink: $USER_BIN_DIR/$bin_name"
            fi
        done
    fi

    systemctl --user daemon-reload
    echo "[SUCCESS] Uninstallation completed."
}

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --install, -i     Run full deployment (dependencies, mountpoint, helper scripts, systemd service setup, enable & start)
  --setup-only      Setup mountpoint, helper scripts and systemd symlink without starting service
  --uninstall, -u   Stop, disable and remove systemd user service and binary symlinks
  --status, -s      Show status of systemd service and mountpoint
  --help, -h        Show this help message

Default (no args) runs full deployment (--install).
EOF
}

action="${1:---install}"

case "$action" in
    --install|-i|install)
        print_header
        check_dependencies
        check_rclone_remote
        setup_mountpoint
        install_user_binaries
        install_systemd_service
        enable_and_start_service
        ;;
    --setup-only|setup)
        print_header
        check_dependencies
        check_rclone_remote
        setup_mountpoint
        install_user_binaries
        install_systemd_service
        echo "[SUCCESS] Setup complete. Start service manually with: systemctl --user start $SERVICE_NAME"
        ;;
    --uninstall|-u|uninstall)
        uninstall_service
        ;;
    --status|-s|status)
        echo "=== Systemd User Service Status ==="
        systemctl --user status "$SERVICE_NAME" --no-pager || true
        echo ""
        echo "=== Mountpoint Status ==="
        "$SCRIPT_DIR/gdrive-mount.sh" status
        ;;
    --help|-h|help)
        usage
        ;;
    *)
        usage
        exit 1
        ;;
esac
