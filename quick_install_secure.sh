#!/bin/bash

# Script de instalação rápida (versão segura)
# Baixa e executa o script principal de instalação de repositório privado

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

warning() {
    echo -e "${YELLOW}[AVISO] $1${NC}"
}

echo "=========================================="
echo "INSTALAÇÃO RÁPIDA - ZABBIX + TACTICAL RMM"
echo "=========================================="

# Verificar se está rodando como root (removido - permitindo execução como root)

# Verificar se é Ubuntu 24.04
if ! grep -q "Ubuntu 24.04" /etc/os-release; then
    error "Este script foi desenvolvido para Ubuntu 24.04"
fi

# Verificar conectividade
if ! ping -c 3 8.8.8.8 > /dev/null 2>&1; then
    error "Sem conectividade com a internet. Verifique sua conexão de rede."
fi

# Solicitar token de acesso
echo
info "Este repositório é privado e requer autenticação."
echo "Você pode usar o token padrão ou fornecer seu próprio token GitHub."
echo
read -p "Usar token padrão da NVirtual? (s/N): " USE_DEFAULT_TOKEN

if [[ "$USE_DEFAULT_TOKEN" =~ ^[Ss]$ ]]; then
    GITHUB_TOKEN="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"
    info "Usando token padrão da NVirtual."
else
    echo
    info "Para obter um token GitHub:"
    info "1. Acesse: https://github.com/settings/tokens"
    info "2. Clique em 'Generate new token (classic)'"
    info "3. Selecione escopo 'repo' para repositórios privados"
    info "4. Copie o token gerado"
    echo
    read -p "Digite seu token GitHub: " GITHUB_TOKEN
    if [[ -z "$GITHUB_TOKEN" ]]; then
        error "Token GitHub é obrigatório para acessar repositório privado"
    fi
fi

log "Criando diretório de trabalho..."
WORK_DIR="/tmp/zabbix_tactical_install"
mkdir -p $WORK_DIR
cd $WORK_DIR

# Configuração do repositório
REPO_BASE="https://raw.githubusercontent.com/nubium-cloud/Zabbix-Proxy-Instalation/main"

log "Baixando scripts de instalação do repositório privado..."

# Função para download com autenticação
download_file() {
    local filename="$1"
    local url="$2"
    local required="$3"
    
    if wget --header="Authorization: token $GITHUB_TOKEN" -O "$filename" "$url" 2>/dev/null; then
        log "✅ $filename baixado com sucesso"
        return 0
    else
        if [[ "$required" == "true" ]]; then
            error "❌ Falha ao baixar $filename. Verifique o token de acesso e conectividade."
        else
            warning "⚠️ $filename não baixado (opcional)"
            return 1
        fi
    fi
}

# Baixar scripts
download_file "install_zabbix_tactical_rmm.sh" "$REPO_BASE/install_zabbix_tactical_rmm.sh" "true"
download_file "check_installation.sh" "$REPO_BASE/check_installation.sh" "true"
download_file "reinstall_tactical_rmm.sh" "$REPO_BASE/reinstall_tactical_rmm.sh" "false"
download_file "INSTALACAO_ZABBIX_TACTICAL.md" "$REPO_BASE/INSTALACAO_ZABBIX_TACTICAL.md" "false"

log "Dando permissões de execução..."
chmod +x install_zabbix_tactical_rmm.sh
chmod +x check_installation.sh
chmod +x reinstall_tactical_rmm.sh 2>/dev/null || true

echo
echo "=========================================="
echo "ARQUIVOS BAIXADOS COM SUCESSO!"
echo "=========================================="
echo "Localização: $WORK_DIR"
echo "Repositório: https://github.com/nubium-cloud/Zabbix-Proxy-Instalation"
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

# Limpar token da memória por segurança
unset GITHUB_TOKEN
