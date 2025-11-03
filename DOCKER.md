# DayDream BBS Docker Image

## Installation

### Option 1: Docker Hub (wenn verfügbar)

```bash
docker pull daydream-bbs:latest
docker run -d -p 23:23 --name daydream-bbs daydream-bbs:latest
```

### Option 2: Lokaler Build

1. Binary-Package herunterladen vom GitHub Release
2. In das Verzeichnis mit dem Binary-Package wechseln
3. Docker Image bauen:

```bash
docker build --build-arg BINARY_PACKAGE=daydream-binaries-x86_64-2.20.0.tar.gz -t daydream-bbs:latest .
```

4. Container starten:

```bash
docker run -d -p 23:23 --name daydream-bbs daydream-bbs:latest
```

### Option 3: Docker Compose

```bash
docker-compose up -d
```

## Verwendung

### Zugriff auf den BBS

```bash
telnet localhost
```

### Daten persistieren

```bash
docker run -d -p 23:23 \
  -v daydream-data:/home/bbs \
  -v daydream-logs:/home/bbs/logfiles \
  --name daydream-bbs \
  daydream-bbs:latest
```

### Daten-Verzeichnisse

- `/home/bbs` - Hauptverzeichnis des BBS
- `/home/bbs/logfiles` - Log-Dateien
- `/home/bbs/users` - Benutzer-Daten
- `/home/bbs/confs` - Konferenzen

### Logs ansehen

```bash
docker logs daydream-bbs
docker logs -f daydream-bbs  # Follow mode
```

### Container stoppen/starten

```bash
docker stop daydream-bbs
docker start daydream-bbs
docker restart daydream-bbs
```

### Shell-Zugriff

```bash
docker exec -it daydream-bbs /bin/bash
```

### Container entfernen

```bash
docker stop daydream-bbs
docker rm daydream-bbs
```

## Ports

- **23** - Telnet (BBS-Zugriff)
- **21** - FTP (optional, falls aktiviert)

## Umgebungsvariablen

- `DAYDREAM` - Installationspfad (Standard: `/home/bbs`)
- `INSTALL_PATH` - Installationspfad (Standard: `/home/bbs`)

## Beispiel: Vollständige Installation mit Volumes

```bash
docker run -d \
  --name daydream-bbs \
  -p 23:23 \
  -p 21:21 \
  -v daydream-data:/home/bbs \
  -v daydream-logs:/home/bbs/logfiles \
  --restart unless-stopped \
  daydream-bbs:latest
```

## Troubleshooting

### Container startet nicht

```bash
docker logs daydream-bbs
```

### Berechtigungsprobleme

Der Container sollte automatisch die Berechtigungen setzen. Falls Probleme auftreten:

```bash
docker exec daydream-bbs chown -R bbsadmin:bbs /home/bbs
```

### Port bereits belegt

Ändere den Port-Mapping:

```bash
docker run -d -p 2323:23 --name daydream-bbs daydream-bbs:latest
```

Dann mit `telnet localhost 2323` verbinden.

