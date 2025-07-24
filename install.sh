#!/bin/bash

# Script de instalação ultra-rápida
# Uso: curl -sSL https://raw.githubusercontent.com/nubium-cloud/Zabbix-Proxy-Instalation/main/install.sh | bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERRO] $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

echo "=========================================="
echo "🚀 INSTALAÇÃO ZABBIX + TACTICAL RMM"
echo "=========================================="
echo "Repositório: nubium-cloud/Zabbix-Proxy-Instalation"
echo "Versão: Ultra-rápida"
echo "=========================================="

# Verificações básicas (removido verificação de root - permitindo execução como root)

if ! grep -q "Ubuntu 24.04" /etc/os-release; then
    error "Este script foi desenvolvido para Ubuntu 24.04"
fi

if ! ping -c 3 8.8.8.8 > /dev/null 2>&1; then
    error "Sem conectividade com a internet. Verifique sua conexão de rede."
fi

# Token de acesso (hardcoded para facilidade)
GITHUB_TOKEN="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"
REPO_BASE="https://raw.githubusercontent.com/nubium-cloud/Zabbix-Proxy-Instalation/main"

log "Criando ambiente de instalação..."
WORK_DIR="/tmp/zabbix_tactical_install_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

log "Baixando script principal de instalação..."
if ! wget --header="Authorization: token $GITHUB_TOKEN" -O install_zabbix_tactical_rmm.sh "$REPO_BASE/install_zabbix_tactical_rmm.sh"; then
    error "Falha ao baixar script principal. Verifique conectividade."
fi

chmod +x install_zabbix_tactical_rmm.sh

echo
info "Script principal baixado com sucesso!"
info "Localização: $WORK_DIR"
echo
log "Iniciando instalação completa..."
echo

# Executar instalação principal
./install_zabbix_tactical_rmm.sh

# Verificar se a instalação foi bem-sucedida
if [[ $? -eq 0 ]]; then
    echo
    echo "=========================================="
    echo "✅ INSTALAÇÃO CONCLUÍDA COM SUCESSO!"
    echo "=========================================="
    
    # Baixar script de verificação para uso futuro
    log "Baixando script de verificação para uso futuro..."
    if wget --header="Authorization: token $GITHUB_TOKEN" -O check_installation.sh "$REPO_BASE/check_installation.sh" 2>/dev/null; then
        chmod +x check_installation.sh
        echo "Script de verificação disponível em: $WORK_DIR/check_installation.sh"
    fi
    
    echo
    echo "Para verificar a instalação no futuro:"
    echo "cd $WORK_DIR && ./check_installation.sh"
    echo
    echo "Repositório: https://github.com/nubium-cloud/Zabbix-Proxy-Instalation"
    echo "=========================================="
else
    error "Falha na instalação. Verifique os logs acima."
fi

# Limpar token da memória
unset GITHUB_TOKEN
