#!/bin/bash

# Script de instalação rápida
# Baixa e executa o script principal de instalação

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
echo "INSTALAÇÃO RÁPIDA - ZABBIX + TACTICAL RMM"
echo "=========================================="

# Verificar se está rodando como root
if [[ $EUID -eq 0 ]]; then
   error "Este script não deve ser executado como root. Execute como usuário normal."
fi

# Verificar se é Ubuntu 24.04
if ! grep -q "Ubuntu 24.04" /etc/os-release; then
    error "Este script foi desenvolvido para Ubuntu 24.04"
fi

# Verificar conectividade
if ! ping -c 3 8.8.8.8 > /dev/null 2>&1; then
    error "Sem conectividade com a internet. Verifique sua conexão de rede."
fi

log "Criando diretório de trabalho..."
WORK_DIR="/tmp/zabbix_tactical_install"
mkdir -p $WORK_DIR
cd $WORK_DIR

# URLs dos scripts (ajustar conforme necessário)
REPO_BASE="https://raw.githubusercontent.com/paulomatheusgrr/alert-email-automation/main"

log "Baixando scripts de instalação..."

# Script principal
if ! wget -O install_zabbix_tactical_rmm.sh "$REPO_BASE/install_zabbix_tactical_rmm.sh"; then
    error "Falha ao baixar script principal"
fi

# Script de verificação
if ! wget -O check_installation.sh "$REPO_BASE/check_installation.sh"; then
    error "Falha ao baixar script de verificação"
fi

# Script de reinstalação do Tactical RMM
if ! wget -O reinstall_tactical_rmm.sh "$REPO_BASE/reinstall_tactical_rmm.sh"; then
    info "Script de reinstalação do Tactical RMM não baixado (opcional)"
fi

# Documentação
if ! wget -O INSTALACAO_ZABBIX_TACTICAL.md "$REPO_BASE/INSTALACAO_ZABBIX_TACTICAL.md"; then
    info "Documentação não baixada (opcional)"
fi

log "Dando permissões de execução..."
chmod +x install_zabbix_tactical_rmm.sh
chmod +x check_installation.sh
chmod +x reinstall_tactical_rmm.sh 2>/dev/null || true

echo
echo "=========================================="
echo "ARQUIVOS BAIXADOS COM SUCESSO!"
echo "=========================================="
echo "Localização: $WORK_DIR"
echo
echo "Arquivos disponíveis:"
echo "- install_zabbix_tactical_rmm.sh (script principal)"
echo "- check_installation.sh (verificação)"
echo "- reinstall_tactical_rmm.sh (reinstalar Tactical RMM)"
echo "- INSTALACAO_ZABBIX_TACTICAL.md (documentação)"
echo
echo "Para iniciar a instalação:"
echo "cd $WORK_DIR"
echo "./install_zabbix_tactical_rmm.sh"
echo
echo "Para verificar a instalação após concluída:"
echo "./check_installation.sh"
echo
echo "Para reinstalar apenas o Tactical RMM (se necessário):"
echo "./reinstall_tactical_rmm.sh"
echo "=========================================="

read -p "Deseja executar a instalação agora? (s/N): " RUN_NOW
if [[ "$RUN_NOW" =~ ^[Ss]$ ]]; then
    log "Iniciando instalação..."
    ./install_zabbix_tactical_rmm.sh
else
    info "Instalação não executada. Use os comandos acima quando estiver pronto."
fi
