#!/bin/bash

# Script de verificação da instalação
# Verifica se todos os serviços estão funcionando corretamente

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
}

warning() {
    echo -e "${YELLOW}[AVISO] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

success() {
    echo -e "${GREEN}[OK] $1${NC}"
}

echo "=========================================="
echo "VERIFICAÇÃO DA INSTALAÇÃO"
echo "=========================================="

# Verificar conectividade de rede
log "Verificando conectividade de rede..."
if ping -c 3 8.8.8.8 > /dev/null 2>&1; then
    success "Conectividade com internet: OK"
else
    error "Falha na conectividade com internet"
fi

if ping -c 3 monitora.nvirtual.com.br > /dev/null 2>&1; then
    success "Conectividade com servidor Zabbix: OK"
else
    warning "Falha na conectividade com monitora.nvirtual.com.br"
fi

# Verificar IP configurado
log "Verificando configuração de IP..."
CURRENT_IP=$(ip route get 8.8.8.8 | awk '{print $7; exit}')
INTERFACE=$(ip route get 8.8.8.8 | awk '{print $5; exit}')
echo "IP atual: $CURRENT_IP"
echo "Interface: $INTERFACE"

# Verificar se está usando DHCP ou IP fixo
NETPLAN_FILE="/etc/netplan/01-netcfg.yaml"
if [[ -f "$NETPLAN_FILE" ]] && grep -q "dhcp4: false" "$NETPLAN_FILE"; then
    success "Configuração: IP FIXO"
    if [[ "$CURRENT_IP" == *.222 ]]; then
        success "IP fixo configurado corretamente (.222)"
    else
        info "IP fixo configurado: $CURRENT_IP"
    fi
else
    info "Configuração: DHCP"
    if [[ "$CURRENT_IP" == *.222 ]]; then
        warning "IP atual termina em .222 via DHCP - pode haver conflito se outro equipamento usar IP fixo .222"
    else
        success "IP via DHCP: $CURRENT_IP"
    fi
fi

# Verificar serviços Zabbix
log "Verificando serviços Zabbix..."

if systemctl is-active --quiet zabbix-agent; then
    success "Zabbix Agent: ATIVO"
else
    error "Zabbix Agent: INATIVO"
    echo "Para verificar logs: sudo journalctl -u zabbix-agent -f"
fi

if systemctl is-active --quiet zabbix-proxy; then
    success "Zabbix Proxy: ATIVO"
else
    error "Zabbix Proxy: INATIVO"
    echo "Para verificar logs: sudo journalctl -u zabbix-proxy -f"
fi

# Verificar portas
log "Verificando portas..."
if netstat -tuln | grep -q ":10050"; then
    success "Porta 10050 (Zabbix Agent): ABERTA"
else
    warning "Porta 10050 não está em uso"
fi

if netstat -tuln | grep -q ":10051"; then
    success "Porta 10051 (Zabbix Proxy): ABERTA"
else
    warning "Porta 10051 não está em uso"
fi

# Verificar arquivos de configuração
log "Verificando arquivos de configuração..."

if [[ -f "/etc/zabbix/zabbix_agentd.conf" ]]; then
    success "Arquivo de configuração do Agent: EXISTE"
    AGENT_HOSTNAME=$(grep "^Hostname=" /etc/zabbix/zabbix_agentd.conf | cut -d'=' -f2)
    echo "Hostname do Agent: $AGENT_HOSTNAME"
else
    error "Arquivo de configuração do Agent: NÃO ENCONTRADO"
fi

if [[ -f "/etc/zabbix/zabbix_proxy.conf" ]]; then
    success "Arquivo de configuração do Proxy: EXISTE"
    PROXY_HOSTNAME=$(grep "^Hostname=" /etc/zabbix/zabbix_proxy.conf | cut -d'=' -f2)
    PROXY_SERVER=$(grep "^Server=" /etc/zabbix/zabbix_proxy.conf | cut -d'=' -f2)
    echo "Hostname do Proxy: $PROXY_HOSTNAME"
    echo "Servidor Zabbix: $PROXY_SERVER"
else
    error "Arquivo de configuração do Proxy: NÃO ENCONTRADO"
fi

# Verificar logs recentes
log "Verificando logs recentes..."
if [[ -f "/var/log/zabbix/zabbix_agentd.log" ]]; then
    echo "Últimas linhas do log do Agent:"
    sudo tail -5 /var/log/zabbix/zabbix_agentd.log
else
    warning "Log do Agent não encontrado"
fi

if [[ -f "/var/log/zabbix/zabbix_proxy.log" ]]; then
    echo "Últimas linhas do log do Proxy:"
    sudo tail -5 /var/log/zabbix/zabbix_proxy.log
else
    warning "Log do Proxy não encontrado"
fi

# Verificar firewall
log "Verificando firewall..."
if command -v ufw &> /dev/null; then
    UFW_STATUS=$(sudo ufw status | head -1)
    echo "Status do UFW: $UFW_STATUS"
    if [[ "$UFW_STATUS" == *"active"* ]]; then
        echo "Regras do firewall:"
        sudo ufw status numbered | grep -E "(10050|10051|22|80|443)"
    fi
fi

# Verificar espaço em disco
log "Verificando espaço em disco..."
df -h / | tail -1 | awk '{print "Espaço livre: " $4 " (" $5 " usado)"}'

# Verificar memória
log "Verificando memória..."
free -h | grep "Mem:" | awk '{print "Memória: " $3 " usado de " $2}'

# Verificar Tactical RMM
log "Verificando Tactical RMM Agent..."

# Verificar se o agente está instalado
if [[ -f "/opt/tacticalagent/tacticalagent" ]]; then
    success "Tactical RMM Agent: INSTALADO"

    # Verificar se o serviço está rodando
    if systemctl is-active --quiet tacticalagent; then
        success "Tactical RMM Agent Service: ATIVO"
    else
        warning "Tactical RMM Agent Service: INATIVO"
        echo "Para verificar status: sudo systemctl status tacticalagent"
    fi

    # Verificar versão do agente
    AGENT_VERSION=$(/opt/tacticalagent/tacticalagent -version 2>/dev/null || echo "Não disponível")
    echo "Versão do Agent: $AGENT_VERSION"

else
    warning "Tactical RMM Agent não encontrado em /opt/tacticalagent/"
fi

# Verificar se o MeshAgent está instalado
if [[ -d "/opt/meshagent" ]]; then
    success "MeshAgent: INSTALADO"
    if pgrep -f meshagent > /dev/null; then
        success "MeshAgent Process: RODANDO"
    else
        warning "MeshAgent Process: NÃO RODANDO"
    fi
else
    warning "MeshAgent não encontrado em /opt/meshagent/"
fi

# Verificar conectividade com servidores Tactical RMM
if ping -c 3 api.centralmesh.nvirtual.com.br > /dev/null 2>&1; then
    success "Conectividade com API Tactical RMM: OK"
else
    warning "Falha na conectividade com api.centralmesh.nvirtual.com.br"
fi

if ping -c 3 mesh.centralmesh.nvirtual.com.br > /dev/null 2>&1; then
    success "Conectividade com Mesh Server: OK"
else
    warning "Falha na conectividade com mesh.centralmesh.nvirtual.com.br"
fi

echo
echo "=========================================="
echo "COMANDOS ÚTEIS PARA TROUBLESHOOTING"
echo "=========================================="
echo "Verificar status dos serviços:"
echo "  sudo systemctl status zabbix-agent"
echo "  sudo systemctl status zabbix-proxy"
echo "  sudo systemctl status tacticalagent"
echo
echo "Verificar logs em tempo real:"
echo "  sudo journalctl -u zabbix-agent -f"
echo "  sudo journalctl -u zabbix-proxy -f"
echo "  sudo journalctl -u tacticalagent -f"
echo
echo "Reiniciar serviços:"
echo "  sudo systemctl restart zabbix-agent"
echo "  sudo systemctl restart zabbix-proxy"
echo "  sudo systemctl restart tacticalagent"
echo
echo "Testar conectividade:"
echo "  telnet monitora.nvirtual.com.br 10051"
echo "  zabbix_get -s localhost -k system.hostname"
echo "  ping api.centralmesh.nvirtual.com.br"
echo "  ping mesh.centralmesh.nvirtual.com.br"
echo
echo "Verificar Tactical RMM:"
echo "  /opt/tacticalagent/tacticalagent -version"
echo "  ps aux | grep -E '(tactical|mesh)'"
echo "  ls -la /opt/tacticalagent/"
echo "  ls -la /opt/meshagent/"
echo
echo "Verificar configuração de rede:"
echo "  ip addr show"
echo "  ip route show"
echo "  cat /etc/netplan/01-netcfg.yaml"
echo "=========================================="
