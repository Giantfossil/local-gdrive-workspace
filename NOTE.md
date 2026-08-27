# Notes & Open Tasks

## Offene Punkte & Zukünftige Optimierungen

- [ ] **Eigene Google API Client-ID konfigurieren**: Die geteilte Rclone-Standard-Client-ID wird gedrosselt. Eine eigene Google Cloud OAuth Client-ID in `rclone config` einrichten für maximalen API-Durchsatz und Vermeidung von Quota-Limits.
- [ ] **Systemd Automount Unit**: Optional `systemd.automount` konfigurieren, sodass der FUSE-Mount erst beim ersten physischen Zugriff auf `/srv/rclone/gdrive` gestartet wird und bei Inaktivität nach X Minuten aushängt.
- [ ] **Berechtigungen `/srv/rclone/gdrive`**: Sicherstellen, dass das Zielverzeichnis `/srv/rclone/gdrive` dem Benutzer `giant:giant` gehört (`sudo mkdir -p /srv/rclone/gdrive && sudo chown giant:giant /srv/rclone/gdrive`).
- [ ] **FUSE allow_other**: Bei Bedarf `user_allow_other` in `/etc/fuse.conf` einkommentieren, wenn andere Dienste (z. B. Docker, Webserver) auf `/srv/rclone/gdrive` zugreifen sollen.
