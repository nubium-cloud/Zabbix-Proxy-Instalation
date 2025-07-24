#!/bin/bash

# Script para reinstalar apenas o Tactical RMM Agent
# Útil quando há problemas na instalação inicial ou necessidade de reconfiguração

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

warning() {
    echo -e "${YELLOW}[AVISO] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

echo "=========================================="
echo "REINSTALAÇÃO DO TACTICAL RMM AGENT"
echo "=========================================="

# Verificar se está rodando como root
if [[ $EUID -eq 0 ]]; then
   error "Este script não deve ser executado como root. Execute como usuário normal."
fi

# Verificar conectividade
if ! ping -c 3 8.8.8.8 > /dev/null 2>&1; then
    error "Sem conectividade com a internet. Verifique sua conexão de rede."
fi

# Solicitar informações do usuário
read -p "Digite o ID do Cliente (ID_CLIENT): " TACTICAL_CLIENT_ID
if [[ -z "$TACTICAL_CLIENT_ID" ]]; then
    error "ID do Cliente é obrigatório"
fi

read -p "Digite a Filial do Cliente (FILIAL_CLIENT): " TACTICAL_CLIENT_FILIAL
if [[ -z "$TACTICAL_CLIENT_FILIAL" ]]; then
    error "Filial do Cliente é obrigatória"
fi

echo
info "Configurações que serão aplicadas:"
info "Cliente ID: $TACTICAL_CLIENT_ID"
info "Filial: $TACTICAL_CLIENT_FILIAL"
info "Mesh Server: mesh.centralmesh.nvirtual.com.br"
info "API Server: api.centralmesh.nvirtual.com.br"
echo

read -p "Confirma a reinstalação com essas configurações? (s/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Ss]$ ]]; then
    info "Reinstalação cancelada pelo usuário."
    exit 0
fi

# Parar serviços existentes
log "Parando serviços existentes..."
sudo systemctl stop tacticalagent 2>/dev/null || true
sudo pkill -f meshagent 2>/dev/null || true

# Remover instalação anterior
log "Removendo instalação anterior..."
sudo rm -rf /opt/tacticalagent/ 2>/dev/null || true
sudo rm -rf /opt/meshagent/ 2>/dev/null || true
sudo rm -f /etc/systemd/system/tacticalagent.service 2>/dev/null || true
sudo systemctl daemon-reload

# Baixar script de instalação
log "Baixando script de instalação..."
cd /tmp
rm -f rmmagent-linux.sh
wget https://raw.githubusercontent.com/netvolt/LinuxRMM-Script/main/rmmagent-linux.sh

if [[ ! -f "rmmagent-linux.sh" ]]; then
    error "Falha ao baixar o script de instalação"
fi

sudo chmod +x rmmagent-linux.sh

# Executar instalação
log "Instalando Tactical RMM Agent..."
./rmmagent-linux.sh install 'https://mesh.centralmesh.nvirtual.com.br/meshagents?id=7Nss2LHe67mTwByGHQ3H3lOI4x8Awfk6kwbQgxSMMq%40qIJKjK6OOSBMWfXBYgPlb&installflags=2&meshinstall=6' 'https://api.centralmesh.nvirtual.com.br' "$TACTICAL_CLIENT_ID" "$TACTICAL_CLIENT_FILIAL" '7514f475df4c5f1303120fd65b18fb16b8f6baf06f73d1c2cfd4ebf83862eb82' 'server'

# Verificar instalação
sleep 5

log "Verificando instalação..."

# Verificar se o agente foi instalado
if [[ -f "/opt/tacticalagent/tacticalagent" ]]; then
    log "✅ Tactical RMM Agent instalado com sucesso"
else
    error "❌ Falha na instalação do Tactical RMM Agent"
fi

# Verificar se o MeshAgent foi instalado
if [[ -d "/opt/meshagent" ]]; then
    log "✅ MeshAgent instalado com sucesso"
else
    warning "⚠️ MeshAgent não encontrado"
fi

# Verificar serviços
if systemctl is-active --quiet tacticalagent; then
    log "✅ Tactical RMM Agent Service está ativo"
else
    warning "⚠️ Tactical RMM Agent Service não está ativo"
    info "Tentando iniciar o serviço..."
    sudo systemctl start tacticalagent
    sleep 3
    if systemctl is-active --quiet tacticalagent; then
        log "✅ Tactical RMM Agent Service iniciado com sucesso"
    else
        error "❌ Falha ao iniciar Tactical RMM Agent Service"
    fi
fi

# Verificar MeshAgent process
if pgrep -f meshagent > /dev/null; then
    log "✅ MeshAgent está rodando"
else
    warning "⚠️ MeshAgent não está rodando"
fi

# Testar conectividade
log "Testando conectividade..."

if ping -c 3 api.centralmesh.nvirtual.com.br > /dev/null 2>&1; then
    log "✅ Conectividade com API Server: OK"
else
    warning "⚠️ Falha na conectividade com api.centralmesh.nvirtual.com.br"
fi

if ping -c 3 mesh.centralmesh.nvirtual.com.br > /dev/null 2>&1; then
    log "✅ Conectividade com Mesh Server: OK"
else
    warning "⚠️ Falha na conectividade com mesh.centralmesh.nvirtual.com.br"
fi

echo
echo "=========================================="
echo "RESUMO DA REINSTALAÇÃO"
echo "=========================================="
echo "Cliente ID: $TACTICAL_CLIENT_ID"
echo "Filial: $TACTICAL_CLIENT_FILIAL"
echo "Mesh Server: mesh.centralmesh.nvirtual.com.br"
echo "API Server: api.centralmesh.nvirtual.com.br"
echo
echo "Arquivos instalados:"
echo "- /opt/tacticalagent/tacticalagent"
echo "- /opt/meshagent/"
echo "- /etc/systemd/system/tacticalagent.service"
echo
echo "Comandos úteis:"
echo "- Verificar status: sudo systemctl status tacticalagent"
echo "- Verificar logs: sudo journalctl -u tacticalagent -f"
echo "- Verificar processos: ps aux | grep -E '(tactical|mesh)'"
echo "- Verificar versão: /opt/tacticalagent/tacticalagent -version"
echo "=========================================="

log "Reinstalação do Tactical RMM Agent concluída!"

# Limpeza
rm -f /tmp/rmmagent-linux.sh
