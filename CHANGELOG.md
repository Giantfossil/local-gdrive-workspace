# Changelog

All notable changes to this project will be documented in this file.

## [2026-08-28]

### Changed
- Standard-Zielverzeichnis und Mountpoint von `/srv/gdrive` auf `/srv/rclone/gdrive` umgestellt (`gdrive-mount.sh`, `gdrive-mount.service`, `deployment.sh` sowie Dokumentation).
- Pfad zum Steuerungsskript in `gdrive-mount.service` auf `%h/.local/src/system/gdrive/gdrive-mount.sh` korrigiert.
- Pfadangaben im Repository in `README.md` und `HOWTO.md` auf `~/.local/src/system/gdrive/` aktualisiert.
- `local/bin/while_convert` um periodische 10-Minuten-Schleife (`DEFAULT_INTERVAL=600`, `--interval`, `--once`), Lockfile-Schutz (`~$*`) und Zeitstempel-Logging erweitert.
- Systemd User Service `gdrive-convert.service` hinzugefügt und in `deployment.sh` integriert.

## [2026-08-27]

### Added
- `requirements.txt` mit Systemanforderungen (`rclone`, `fuse3`, `libreoffice`, `systemd`) und Installationsbefehlen für verschiedene Paketmanager (`pacman`, `apt`, `dnf`, `zypper`, `apk`, `brew`) hinzugefügt.
- Hilfsskript `local/bin/while_convert` zur automatisierten Batch-Konvertierung von `.docx`-Dateien in `.odt` mit Sicherheitsprüfung integriert.
- `deployment.sh` erweitert, um ausführbare Skripte aus `local/bin/` automatisch nach `~/.local/bin/` zu verlinken.
- `gdrive-mount.sh` Skript mit High-Performance VFS-Caching erstellt (`--vfs-cache-mode full`, `--vfs-read-chunk-size 32M`, `--dir-cache-time 1000h`, `--poll-interval 15s`, `--drive-pacer-min-sleep 10ms`).
- Systemd User Service Unit `gdrive-mount.service` für Mount-Pfad `/srv/gdrive` erstellt.
- Automatisches Deployment-Skript `deployment.sh` für Installation, Verlinkung und Verwaltung bereitgestellt.
- Ausführliche Anleitung in `HOWTO.md` für Google Cloud OAuth, `rclone config` und Dokumenten-Konvertierung hinzugefügt.
- MIT-Lizenzdatei `LICENSE` hinzugefügt.
- Architektur- und Komponentendokumentation in `README.md`, `CHANGELOG.md` und `NOTE.md` strukturiert.
