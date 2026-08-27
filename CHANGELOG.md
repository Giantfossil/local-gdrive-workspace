# Changelog

All notable changes to this project will be documented in this file.

## [2026-08-27]

### Added
- Hilfsskript `local/bin/while_convert` zur automatisierten Batch-Konvertierung von `.docx`-Dateien in `.odt` mit Sicherheitsprüfung integriert.
- `deployment.sh` erweitert, um ausführbare Skripte aus `local/bin/` automatisch nach `~/.local/bin/` zu verlinken.
- `gdrive-mount.sh` Skript mit High-Performance VFS-Caching erstellt (`--vfs-cache-mode full`, `--vfs-read-chunk-size 32M`, `--dir-cache-time 1000h`, `--poll-interval 15s`, `--drive-pacer-min-sleep 10ms`).
- Systemd User Service Unit `gdrive-mount.service` für Mount-Pfad `/srv/gdrive` erstellt.
- Automatisches Deployment-Skript `deployment.sh` für Installation, Verlinkung und Verwaltung bereitgestellt.
- Ausführliche Anleitung in `HOWTO.md` für Google Cloud OAuth, `rclone config` und Dokumenten-Konvertierung hinzugefügt.
- Architektur- und Komponentendokumentation in `README.md`, `CHANGELOG.md` und `NOTE.md` strukturiert.
