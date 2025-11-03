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
    netcat \
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
        cp -r "$BINARY_DIR"/INSTALL/* $INSTALL_PATH/ 2>/dev/null || true; \
    fi && \
    if [ -d "$BINARY_DIR/DOCS" ]; then \
        cp -r "$BINARY_DIR"/DOCS $INSTALL_PATH/docs 2>/dev/null || true; \
    fi && \
    rm -rf "$BINARY_DIR"

# Setze Berechtigungen
RUN chown -R bbsadmin:bbs $INSTALL_PATH && \
    chmod -R 755 $INSTALL_PATH && \
    chown zipcheck $INSTALL_PATH/utils/runas 2>/dev/null || true && \
    chmod u+s $INSTALL_PATH/utils/runas 2>/dev/null || true

# Erstelle Entrypoint-Script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Initialisiere BBS falls noch nicht geschehen\n\
if [ ! -f "$INSTALL_PATH/configs/daydream.cfg" ]; then\n\
    echo "Initialisiere DayDream BBS..."\n\
    cd $INSTALL_PATH\n\
    . scripts/ddenv.sh 2>/dev/null || true\n\
    if [ -f utils/ddcfg ]; then\n\
        utils/ddcfg configs/daydream.cfg 2>/dev/null || true\n\
    fi\n\
fi\n\
\n\
# Setze Berechtigungen\n\
chown -R bbsadmin:bbs $INSTALL_PATH 2>/dev/null || true\n\
chmod 775 $INSTALL_PATH 2>/dev/null || true\n\
chown zipcheck $INSTALL_PATH/utils/runas 2>/dev/null || true\n\
chmod u+s $INSTALL_PATH/utils/runas 2>/dev/null || true\n\
\n\
# Starte Telnet-Server (einfacher TCP-Server statt systemd)\n\
echo "DayDream BBS startet auf Port 23..."\n\
cd $INSTALL_PATH\n\
exec $INSTALL_PATH/bin/ddtelnetd -u bbs\n\
' > /usr/local/bin/start-daydream.sh && \
    chmod +x /usr/local/bin/start-daydream.sh

# Exponiere Ports
EXPOSE 23 21

# Setze Working Directory
WORKDIR $INSTALL_PATH

# Entrypoint
ENTRYPOINT ["/usr/local/bin/start-daydream.sh"]

