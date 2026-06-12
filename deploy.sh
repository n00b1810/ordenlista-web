#!/bin/bash
# Deploy script para OrdenLista Web
# Uso: ./deploy.sh [produccion|local]

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}→${NC} $1"; }
ok()  { echo -e "${GREEN}✓${NC} $1"; }
err() { echo -e "${RED}✗${NC} $1"; }

MODE=${1:-local}
REPO="https://github.com/n00b1810/ordenlista-web.git"
BRANCH="master"

if [ "$MODE" = "produccion" ]; then
    VPS="root@74.208.227.159"
    WEB_ROOT="/var/www/ordenlista-web"
    
    log "Desplegando a producción ($VPS:$WEB_ROOT)..."
    ssh "$VPS" "
        set -e
        REPO_DIR=\"/opt/repos/ordenlista-web\"
        if [ -d \"\$REPO_DIR\" ]; then
            cd \"\$REPO_DIR\" && git fetch origin && git reset --hard origin/$BRANCH
        else
            git clone $REPO \"\$REPO_DIR\" && cd \"\$REPO_DIR\"
        fi
        rsync -av --delete --exclude='.git/' --exclude='.github/' \"\$REPO_DIR/\" \"$WEB_ROOT/\"
        chown -R www-data:www-data \"$WEB_ROOT\" 2>/dev/null || true
    "
    # Ping IndexNow
    log "Notificando a IndexNow..."
    IDX_KEY="ordenlista-indexnow-key"
    curl -s -X POST "https://api.indexnow.org/indexnow" \
        -H "Content-Type: application/json; charset=utf-8" \
        -d "{
            \"host\": \"ordenlista.com\",
            \"key\": \"$IDX_KEY\",
            \"keyLocation\": \"https://ordenlista.com/idx-key.txt\",
            \"urlList\": [
                \"https://ordenlista.com/\",
                \"https://ordenlista.com/blog/\",
                \"https://ordenlista.com/blog/sistema-pos-para-restaurantes-guia-completa.html\"
            ]
        }" > /dev/null 2>&1
    ok "IndexNow notificado"
    ok "Despliegue completado"
elif [ "$MODE" = "local" ]; then
    log "Preparando para deploy local (abcti-server-1)..."
    sudo mkdir -p /var/www/ordenlista-web 2>/dev/null || mkdir -p /tmp/ordenlista-web-preview
    sudo rsync -av --delete --exclude='.git/' --exclude='.github/' ./ /var/www/ordenlista-web/ 2>/dev/null || rsync -av --delete --exclude='.git/' --exclude='.github/' ./ /tmp/ordenlista-web-preview/
    ok "Deploy local completado en /var/www/ordenlista-web"
fi
