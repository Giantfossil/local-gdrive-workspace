# Changelog

All notable changes to this project will be documented in this file.

## [2026-08-27]

### Added
- Created `gdrive-mount.sh` script with high-performance VFS caching (`--vfs-cache-mode full`, `--vfs-read-chunk-size 32M`, `--dir-cache-time 1000h`, `--poll-interval 15s`, `--drive-pacer-min-sleep 10ms`).
- Added systemd user service template `gdrive-mount.service` targeting mount point `/srv/gdrive`.
- Created project documentation in `README.md`, `CHANGELOG.md`, and `NOTE.md`.
