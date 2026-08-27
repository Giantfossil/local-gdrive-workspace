# Google Drive Rclone Mount (`/srv/gdrive`)

High-Performance FUSE-Mount für Google Drive (`gdrive:`) mit optimiertem On-Demand VFS-Caching, Latenz-Tuning und automatisierter Systemd-Bereitstellung.

---

## 1. Architektur & Performance-Konzept

Der Mount ist darauf ausgelegt, Ordnerstrukturen verzögerungsfrei (schneller als das Google Drive Webinterface) im lokalen Dateisystem unter `/srv/gdrive` bereitzustellen und Dateien erst beim tatsächlichen Zugriff stückweise (chunk-basiert) aus der Cloud nachzuladen.

### Optimierungs-Parameter

- **On-Demand VFS Caching (`--vfs-cache-mode full`)**: Dateien werden nicht vorab heruntergeladen, sondern nur bei Lese-/Schreibzugriffen blockweise geladen und lokal zwischengespeichert.
- **Dynamisches Chunking (`--vfs-read-chunk-size 32M`, `--vfs-read-chunk-size-limit 2G`)**: Schneller Start beim Öffnen von Dateien, automatische Vergrößerung des Durchsatzes bei sequentiellen Zugriffen (z. B. Streaming, große Kopieroperationen).
- **Read-Ahead Puffer (`--vfs-read-ahead 128M`, `--buffer-size 64M`)**: Unterbrechungsfreies Lesen bei hoher Bandbreite.
- **Verzeichnis-Caching (`--dir-cache-time 1000h`)**: Verzeichnisbäume bleiben im Arbeitsspeicher, Verzeichniswechsel erfolgen in 0ms Latenz.
- **Echtzeit-Änderungserkennung (`--poll-interval 15s`)**: Google Drive Changes API pollt Änderungen alle 15 Sekunden automatisch und invalidiert veraltete Cache-Einträge ohne Vollscans.
- **API-Pacer Tuning (`--drive-pacer-min-sleep 10ms`, `--drive-pacer-burst 200`)**: Reduziert künstliche Wartezeiten zwischen Google API Aufrufen um das 10-fache.

---

## 2. Komponentenübersicht

| Datei | Zweck |
| :--- | :--- |
| **`deployment.sh`** | Vollautomatisches Setup- und Deployment-Skript für Mountpoint und Systemd-Service |
| **`gdrive-mount.sh`** | Ausführbares Steuerungsskript für Start (Vordergrund/Daemon), Stop, Status und Bereinigung |
| **`gdrive-mount.service`** | Systemd User Service Unit für automatischen Start beim Login / Systemstart |
| **`HOWTO.md`** | Detaillierte Schritt-für-Schritt-Anleitung inkl. `rclone config` und Google Cloud OAuth Setup |
| **`CHANGELOG.md`** | Chronologisches Änderungsprotokoll (Deltas) |
| **`NOTE.md`** | Zukünftige Aufgaben und Optimierungsideen |

---

## 3. Schnelleinstieg & Bereitstellung

### Automatische Installation

```bash
# In das Repository-Verzeichnis wechseln und Bereitstellung ausführen
cd ~/.local/src/gdrive
./deployment.sh
```

Für eine detaillierte Anleitung zur Rclone-Konfiguration (`rclone config`) und Google API Anmeldedaten siehe [`HOWTO.md`](file:///home/giant/.local/src/gdrive/HOWTO.md).

### Manuelle Skript-Steuerung

```bash
# Im Hintergrund als Daemon starten
./gdrive-mount.sh daemon

# Status prüfen
./gdrive-mount.sh status

# Aushängen
./gdrive-mount.sh stop
```

### Systemd User Service Verwaltung

```bash
# Service-Status abfragen
systemctl --user status gdrive-mount.service

# Live-Logs einsehen
journalctl --user -u gdrive-mount.service -f
```

---

## 4. Konfigurations-Variablen

Folgende Umgebungsvariablen können übergeben oder im Service angepasst werden:

| Variable | Standardwert | Beschreibung |
| :--- | :--- | :--- |
| `RCLONE_REMOTE` | `gdrive:` | Name des Rclone-Remotes |
| `RCLONE_MOUNT_POINT` | `/srv/gdrive` | Lokaler Mount-Pfad |
| `RCLONE_CACHE_DIR` | `~/.cache/rclone/gdrive` | Lokaler VFS-Cache-Ordner |
| `RCLONE_LOG_FILE` | `~/.cache/rclone/gdrive.log` | Pfad zur Logdatei |
| `RCLONE_LOG_LEVEL` | `NOTICE` | Log-Level (`DEBUG`, `INFO`, `NOTICE`, `ERROR`) |
