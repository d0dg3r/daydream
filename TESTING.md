# DayDream BBS - Test-Anleitung

## Live-Tests auf Server

### 1. Installation mit systemd auf Debian/Ubuntu Server

```bash
# 1. Binary-Package vom GitHub Release herunterladen
# 2. Auf Server hochladen und entpacken
tar -xzf daydream-binaries-x86_64-2.20.0.tar.gz
cd daydream-binaries-x86_64-2.20.0

# 3. Installation starten
sudo ./install-debian-systemd.sh
# Installationspfad: /home/bbs

# 4. Service starten
sudo systemctl start daydream-telnet.socket

# 5. Testen
telnet localhost
# oder von extern: telnet your-server-ip

# 6. Logs ansehen
sudo journalctl -u daydream-telnet@* -f

# 7. Service stoppen
sudo systemctl stop daydream-telnet.socket
```

### 2. Docker-Test

```bash
# Docker Image bauen (benötigt Binary-Package)
docker build --build-arg BINARY_PACKAGE=daydream-binaries-x86_64-2.20.0.tar.gz -t daydream-bbs:test .

# Container starten
docker run -d -p 2323:23 --name daydream-test daydream-bbs:test

# Teste Verbindung
telnet localhost 2323

# Logs ansehen
docker logs daydream-test

# Container stoppen
docker stop daydream-test
docker rm daydream-test
```

### 3. Manueller Test der Binaries

```bash
# Nach Installation auf Server
cd /home/bbs

# Teste ddtelnetd
bin/ddtelnetd --help 2>&1 || true

# Teste daydream Binary
bin/daydream --help 2>&1 || true

# Teste Utils
utils/ddcfg --help 2>&1 || true
utils/ddwho --help 2>&1 || true

# Teste Verbindung
telnet localhost 23
```

## Debugging-Tipps

### Logs aktivieren

```bash
# BBS-Logs
tail -f /home/bbs/logfiles/*.log

# Systemd-Logs
sudo journalctl -u daydream-telnet@* -f

# Docker-Logs
docker logs -f daydream-bbs
```

### Verbindungsprobleme debuggen

```bash
# Prüfe ob Port offen ist
netstat -tlnp | grep 23
# oder
ss -tlnp | grep 23

# Teste mit netcat
nc localhost 23

# Prüfe Firewall
sudo iptables -L -n | grep 23
```

### Berechtigungsprobleme

```bash
# Prüfe Benutzer
id bbs
id bbsadmin
id zipcheck

# Prüfe Verzeichnis-Berechtigungen
ls -la /home/bbs/
```

## Test-Szenarien

### 1. Erste Verbindung

```bash
# Starte Server
sudo systemctl start daydream-telnet.socket

# Verbinde mit telnet
telnet localhost

# Erwartetes Ergebnis:
# DayDream BBS Willkommensbildschirm
# Display Mode-Auswahl
```

### 2. Benutzer-Registrierung

```bash
# Nach Telnet-Verbindung:
# 1. Display Mode wählen (1)
# 2. "N" für neuen Benutzer
# 3. Registrierungsformular ausfüllen
```

### 3. Admin-Zugriff

```bash
# Als bbsadmin einloggen
ssh bbsadmin@localhost
# oder
su - bbsadmin
```

## Häufige Probleme

### Port bereits belegt

```bash
# Finde Prozess auf Port 23
sudo lsof -i :23
# oder
sudo fuser 23/tcp

# Stoppe alten Service
sudo systemctl stop daydream-telnet.socket
```

### Libraries nicht gefunden

```bash
# Prüfe LD_LIBRARY_PATH
echo $LD_LIBRARY_PATH

# Setze manuell
export LD_LIBRARY_PATH=/home/bbs/lib:$LD_LIBRARY_PATH
```

### Binaries nicht ausführbar

```bash
# Mache ausführbar
chmod +x /home/bbs/bin/*
chmod +x /home/bbs/utils/*
chmod +x /home/bbs/doors/*
```

