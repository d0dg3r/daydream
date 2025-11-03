# DayDream BBS Docker Image
# Verwendet vorkompilierte Binaries für schnelle Installation

FROM debian:bookworm-slim

# Metadaten
LABEL maintainer="DayDream BBS Team"
LABEL description="DayDream BBS - A dialup BBS for Linux"
LABEL version="2.20.0"

# Installiere Abhängigkeiten
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    telnet \
    netcat-openbsd \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Erstelle BBS-Benutzer und Gruppen
RUN groupadd -r zipcheck && \
    groupadd -r bbs && \
    useradd -r -g zipcheck -s /bin/false zipcheck && \
    useradd -r -d /home/bbs -G zipcheck -g bbs -s /bin/false bbs && \
    useradd -r -d /home/bbs -m -G zipcheck -g bbs bbsadmin

# Setze Installationspfad
ENV INSTALL_PATH=/home/bbs
ENV DAYDREAM=/home/bbs

# Kopiere Binary-Package (ARG für Build-Kontext)
ARG BINARY_PACKAGE
COPY ${BINARY_PACKAGE} /tmp/

# Installiere Binaries
WORKDIR /tmp
RUN BINARY_TAR=$(ls daydream-binaries-*.tar.gz | head -1) && \
    tar -xzf "$BINARY_TAR" && \
    rm "$BINARY_TAR" && \
    BINARY_DIR=$(ls -d daydream-binaries-* | head -1) && \
    mkdir -p $INSTALL_PATH && \
    cp -r "$BINARY_DIR"/bin $INSTALL_PATH/ 2>/dev/null || true && \
    cp -r "$BINARY_DIR"/lib $INSTALL_PATH/ 2>/dev/null || true && \
    cp -r "$BINARY_DIR"/utils $INSTALL_PATH/ 2>/dev/null || true && \
    cp -r "$BINARY_DIR"/doors $INSTALL_PATH/ 2>/dev/null || true && \
    cp -r "$BINARY_DIR"/python $INSTALL_PATH/ 2>/dev/null || true && \
    cp -r "$BINARY_DIR"/include $INSTALL_PATH/ 2>/dev/null || true && \
    if [ -d "$BINARY_DIR/INSTALL" ]; then \
        cp -r "$BINARY_DIR"/INSTALL $INSTALL_PATH/ 2>/dev/null || true; \
    fi && \
    if [ -d "$BINARY_DIR/DOCS" ]; then \
        cp -r "$BINARY_DIR"/DOCS $INSTALL_PATH/docs 2>/dev/null || true; \
    fi && \
    # Erstelle configs-Verzeichnis falls nicht vorhanden \
    mkdir -p $INSTALL_PATH/configs 2>/dev/null || true && \
    # Kopiere Config-Datei falls vorhanden \
    if [ -f "$BINARY_DIR/INSTALL/configs/daydream.cfg" ] && [ ! -f "$INSTALL_PATH/configs/daydream.cfg" ]; then \
        cp "$BINARY_DIR/INSTALL/configs/daydream.cfg" "$INSTALL_PATH/configs/daydream.cfg" 2>/dev/null || true; \
    fi && \
    rm -rf "$BINARY_DIR"

# Setze Berechtigungen
RUN chown -R bbsadmin:bbs $INSTALL_PATH && \
    chmod -R 755 $INSTALL_PATH && \
    chown zipcheck $INSTALL_PATH/utils/runas 2>/dev/null || true && \
    chmod u+s $INSTALL_PATH/utils/runas 2>/dev/null || true

# Installiere socat für TCP-Listener
RUN apt-get update && \
    apt-get install -y --no-install-recommends socat && \
    rm -rf /var/lib/apt/lists/*

# Erstelle Entrypoint-Script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Initialisiere BBS falls noch nicht geschehen\n\
cd $INSTALL_PATH\n\
if [ -f scripts/ddenv.sh ]; then\n\
    . scripts/ddenv.sh 2>/dev/null || true\n\
fi\n\
\n\
if [ ! -f configs/daydream.cfg ]; then\n\
    echo "Initialisiere DayDream BBS..."\n\
    mkdir -p configs data 2>/dev/null || true\n\
    if [ -f INSTALL/configs/daydream.cfg ]; then\n\
        cp INSTALL/configs/daydream.cfg configs/daydream.cfg 2>/dev/null || true\n\
    elif [ -f configs/daydream.cfg.example ]; then\n\
        cp configs/daydream.cfg.example configs/daydream.cfg 2>/dev/null || true\n\
    fi\n\
fi\n\
\n\
if [ -f utils/ddcfg ] && [ -f configs/daydream.cfg ] && [ ! -f data/daydream.dat ]; then\n\
    echo "Kompiliere Config-Datei..."\n\
    mkdir -p data 2>/dev/null || true\n\
    utils/ddcfg configs/daydream.cfg 2>&1 || echo "Warnung: Config-Kompilierung fehlgeschlagen"\n\
fi\n\
\n\
# Setze Berechtigungen\n\
chown -R bbsadmin:bbs $INSTALL_PATH 2>/dev/null || true\n\
chmod 775 $INSTALL_PATH 2>/dev/null || true\n\
chown zipcheck $INSTALL_PATH/utils/runas 2>/dev/null || true\n\
chmod u+s $INSTALL_PATH/utils/runas 2>/dev/null || true\n\
\n\
# Starte TCP-Server mit socat (ddtelnetd erwartet stdin/stdout als Socket)\n\
echo "DayDream BBS startet auf Port 23..."\n\
cd $INSTALL_PATH\n\
if [ -f bin/ddtelnetd ]; then\n\
    # Verwende socat als TCP-Listener, der ddtelnetd für jede Verbindung startet\n\
    exec socat TCP-LISTEN:23,fork,reuseaddr EXEC:"bin/ddtelnetd -u bbs",pty,stderr\n\
else\n\
    echo "Error: ddtelnetd nicht gefunden!"\n\
    exit 1\n\
fi\n\
' > /usr/local/bin/start-daydream.sh && \
    chmod +x /usr/local/bin/start-daydream.sh

# Exponiere Ports
EXPOSE 23 21

# Setze Working Directory
WORKDIR $INSTALL_PATH

# Entrypoint
ENTRYPOINT ["/usr/local/bin/start-daydream.sh"]

