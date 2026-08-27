# Google Drive Rclone Mount - HowTo & Einrichtungsanleitung

Schritt-für-Schritt-Anleitung zur Erstellung der Rclone-Konfiguration für Google Drive (`gdrive:`), Einrichtung des High-Performance On-Demand Mounts und Deployment auf dem System.

---

## 1. Voraussetzungen

Folgende Pakete müssen auf dem System installiert sein:

```bash
# EndeavourOS / Arch Linux
sudo pacman -S rclone fuse3 libreoffice-fresh
```

---

## 2. Google Drive Rclone-Konfiguration (`rclone config`)

> [!TIP]
> **Warum eine eigene Google Cloud Client-ID empfohlen wird:**
> Standardmäßig verwendet Rclone eine globale, geteilte Google Client-ID. Bei hoher Last führt dies zu Google API Rate-Limits (HTTP 429) und künstlicher Drosselung. Eine eigene (kostenlose) Google Client-ID sorgt für volle Bandbreite und maximale API-Abfrageraten.

### Option A: Eigene Google Client-ID erstellen (Empfohlen)

1. Öffne die [Google Cloud Console](https://console.cloud.google.com/).
2. Erstelle ein neues Projekt (z. B. `Rclone-Drive`).
3. Gehe zu **APIs & Dienste** > **Bibliothek** und aktiviere die **Google Drive API**.
4. Gehe zu **APIs & Dienste** > **OAuth-Zustimmungsbildschirm**:
   - Wähle **Extern** und klicke auf *Erstellen*.
   - Gib einen App-Namen ein (z. B. `Rclone`) und deine E-Mail-Adresse.
   - Speichere die Schritte durch und füge unter **Testnutzer** deine eigene Google-Mail-Adresse hinzu.
5. Gehe zu **APIs & Dienste** > **Anmeldedaten**:
   - Klicke auf **+ Anmeldedaten erstellen** > **OAuth-Client-ID**.
   - Anwendungstyp: **Desktop-App**.
   - Name: `Rclone Desktop`.
   - Nach dem Erstellen erhältst du die **Client-ID** und das **Client-Geheimnis (Client Secret)**.

---

### Option B: Interaktiver `rclone config` Assistent

Führe im Terminal folgenden Befehl aus:

```bash
rclone config
```

Folge den Eingabeaufforderungen wie folgt:

| Abfrage / Prompt | Eingabe | Erklärung |
| :--- | :--- | :--- |
| `e/n/d/r/c/s/q>` | `n` | Neues Remote erstellen |
| `name>` | `gdrive` | Name des Remotes (wichtig: `gdrive` kleingeschrieben) |
| `Storage>` | `drive` | Typ: Google Drive (oder Nummer für `Google Drive` wählen) |
| `client_id>` | `<Deine_Client_ID>` | Deine Google Client-ID (oder leer lassen für Standard) |
| `client_secret>` | `<Dein_Client_Secret>` | Dein Client Secret (oder leer lassen für Standard) |
| `scope>` | `1` | `drive` (Vollzugriff auf alle Dateien) |
| `service_account_file>` | *Enter* | Leer lassen |
| `Edit advanced config?>` | `n` | Keine erweiterten Einstellungen erforderlich |
| `Use web browser to authenticate?>` | `y` | Browser öffnet sich automatisch zur Bestätigung |
| *Im Browser:* | Login & Zustimmen | Zugriff für Rclone auf Google Drive erlauben |
| `Configure this as a Shared Drive (Team Drive)?>` | `n` | `n` für persönliches Drive (oder `y` für Shared Drive) |
| `Keep this "gdrive" remote?>` | `y` | Bestätigen und speichern |
| `e/n/d/r/c/s/q>` | `q` | Rclone-Konfiguration beenden |

---

## 3. Verbindung testen

Überprüfe, ob Rclone die Ordner deines Google Drive auflisten kann:

```bash
# Verzeichnisse im Root-Verzeichnis auflisten
rclone lsd gdrive:

# Dateien auflisten (optional)
rclone ls gdrive: --max-depth 1
```

---

## 4. Automatisches Deployment mit `deployment.sh`

Das Deployment-Skript richtet den Mountpoint `/srv/rclone/gdrive` ein, verknüpft den Systemd-User-Service und startet den Mount:

```bash
cd ~/.local/src/system/gdrive
./deployment.sh
```

### Deployment-Aktionen

- **Vollständige Installation & Start**: `./deployment.sh --install`
- **Status prüfen**: `./deployment.sh --status`
- **Dienst deinstallieren & stoppen**: `./deployment.sh --uninstall`

---

## 5. Manuelle Steuerung & Systemd-Befehle

### Steuerung über das Shell-Skript

```bash
# Mount im Hintergrund starten
~/.local/src/system/gdrive/gdrive-mount.sh daemon

# Mount-Status anzeigen
~/.local/src/system/gdrive/gdrive-mount.sh status

# Sauber aushängen
~/.local/src/system/gdrive/gdrive-mount.sh stop
```

### Steuerung über Systemd (Autostart beim Login)

```bash
# Status des Dienstes anzeigen
systemctl --user status gdrive-mount.service

# Dienst neu starten
systemctl --user restart gdrive-mount.service

# Live-Logs ansehen
journalctl --user -u gdrive-mount.service -f
```

---

## 6. Batch-Dokumentenkonvertierung (`while_convert`)

Mit dem Werkzeug [`local/bin/while_convert`](file:///home/giant/.local/src/system/gdrive/local/bin/while_convert) können exportierte `.docx`-Dateien (z. B. aus Google Drive) automatisiert in LibreOffice `.odt`-Dateien umgewandelt werden.

### Funktionsweise der Schleife
- **Intervall-Auslösung (alle 10 Minuten)**: Das Skript scannt das Zielverzeichnis nicht bei jedem einzelnen Datei-Event, sondern in festen Abständen (Standard: `600s` / 10 Minuten). Dadurch wird verhindert, dass unvollständig synchronisierte oder gerade bearbeitete Dateien vorzeitig konvertiert werden.
- **Sicherheitsprüfung**: Die Originaldatei `.docx` wird erst und ausschließlich dann gelöscht, wenn die erzeugte `.odt`-Datei existiert und eine Dateigröße von mehr als 0 Byte aufweist.
- **Lock-Schutz**: Temporäre Office-Sperrdateien (z. B. `~$Dokument.docx`) werden automatisch ignoriert.
- **Zeitstempel-Logging**: Jeder Konvertierungsvorgang wird mit präzisem Datum und Uhrzeit protokolliert.

### Manuelle Terminal-Ausführung

```bash
# Periodische 10-Minuten-Schleife für /srv/rclone/gdrive starten (Beenden mit Ctrl+C)
while_convert

# Spezifisches Verzeichnis überwachen
while_convert /srv/rclone/gdrive/Buero

# Abweichendes Intervall festlegen (z. B. alle 5 Minuten oder alle 300 Sekunden)
while_convert -i 5m /srv/rclone/gdrive

# Einmaliger Durchlauf (One-Shot) ohne Endlosschleife
while_convert --once /srv/rclone/gdrive

# Hilfe & Optionen anzeigen
while_convert --help
```

### Automatischer Hintergrundbetrieb via Systemd User Service

Um die 10-Minuten-Schleife permanent im Hintergrund laufen zu lassen, kann der hinterlegte Systemd-Dienst genutzt werden:

```bash
# Dienst aktivieren und sofort starten
systemctl --user enable --now gdrive-convert.service

# Status überprüfen
systemctl --user status gdrive-convert.service

# Live-Logs der Konvertierung einsehen
journalctl --user -u gdrive-convert.service -f

# Dienst bei Bedarf stoppen
systemctl --user stop gdrive-convert.service
```

---

## 7. Fehlerbehebung (Troubleshooting)

### Problem: Mountpoint `/srv/rclone/gdrive` hat keine Schreibrechte
Falls `/srv/rclone/gdrive` als `root` erstellt wurde:
```bash
sudo mkdir -p /srv/rclone/gdrive
sudo chown -R $USER:$USER /srv/rclone/gdrive
```

### Problem: Dateisystem blockiert beim Aushängen (Device busy)
Falls Prozesse noch auf den Ordner zugreifen:
```bash
fusermount3 -u -z /srv/rclone/gdrive
```

### Problem: Anderen Benutzern / Containern Zugriff gewähren (`--allow-other`)
Damit Prozesse anderer Benutzer (z. B. Docker oder Webserver) auf `/srv/rclone/gdrive` zugreifen können:
1. In `/etc/fuse.conf` die Zeile `#user_allow_other` einkommentieren (`user_allow_other`).
2. Das Skript erkennt diesen Eintrag automatisch und hängt `--allow-other` an.
