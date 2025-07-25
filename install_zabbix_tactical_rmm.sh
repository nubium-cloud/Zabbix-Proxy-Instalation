#!/bin/bash

# Script de instalação automatizada para Ubuntu Server 24.04
# Instala Zabbix Proxy, Zabbix Agent, Tactical RMM e configura IP fixo
# Autor: Paulo Matheus
# Data: $(date +%Y-%m-%d)

set -e  # Para o script em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log
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

# Verificar se é Ubuntu 24.04
if ! grep -q "Ubuntu 24.04" /etc/os-release; then
    error "Este script foi desenvolvido para Ubuntu 24.04"
fi

log "Bem Vindo(a) a instalação automatizada do Zabbix Proxy, Zabbix Agent e Tactical RMM para Ubuntu Server 24.04."
echo "
                                                                                                           
                                                                                                                                                                                                                   
                    #####                                                                                  
    #####################                                                                                  
   ##                ####                                                                                   
   ##  ####       ###  ## ####         #### ### ############ ############        ###     ####       ###         
   ##  ######     ###  ##  ####       ####  ### ###     #####   ###   ###        ###    ######      ###         
   ##  ########   ###  ##   ####     ###    ### ###       ###   ###   ###        ###   ### ####     ###         
   ##  ###  ##### ###  ##    ####   ###     ### ###    ######   ###   ###        ###  ###   ####    ###         
   ##  ###    #######  ##      #######      ### ###    #####    ###   ###       #### ###     ####   ###         
   ##  ###      #####  ##       #####       ### ###     #####   ###    ############ ###        ###  ########### 
   ##  ###        ###  ##        ###        ### ###       ####  ###     ########## ###          ### ########### 
  ####              ####                                                                       
  #####################                                                                              INFO 1578
  ####                                                                                             
                                                                                                           
"
log "Desenvolvido por Paulo Matheus - NVirtual"
log "Iniciando instalação automatizada..."

# Solicitar informações do usuário
read -p "Digite o nome do Zabbix Proxy (ex: cliente-zbxproxy): " ZABBIX_HOSTNAME
if [[ -z "$ZABBIX_HOSTNAME" ]]; then
    error "Nome do Zabbix Proxy é obrigatório"
fi

# Solicitar informações do Tactical RMM
echo
log "Configuração do Tactical RMM..."
read -p "Digite o ID do Cliente (ID_CLIENT): " TACTICAL_CLIENT_ID
if [[ -z "$TACTICAL_CLIENT_ID" ]]; then
    error "ID do Cliente é obrigatório"
fi

read -p "Digite a Filial do Cliente (FILIAL_CLIENT): " TACTICAL_CLIENT_FILIAL
if [[ -z "$TACTICAL_CLIENT_FILIAL" ]]; then
    error "Filial do Cliente é obrigatória"
fi

# Detectar IP atual e calcular IP fixo
log "Detectando configuração de rede atual..."
CURRENT_IP=$(ip route get 8.8.8.8 | awk '{print $7; exit}')
INTERFACE=$(ip route get 8.8.8.8 | awk '{print $5; exit}')
GATEWAY=$(ip route | grep default | awk '{print $3; exit}')

if [[ -z "$CURRENT_IP" ]]; then
    error "Não foi possível detectar o IP atual"
fi

# Extrair a rede e calcular o IP .222
IFS='.' read -ra IP_PARTS <<< "$CURRENT_IP"
NETWORK="${IP_PARTS[0]}.${IP_PARTS[1]}.${IP_PARTS[2]}"
PROPOSED_IP="${NETWORK}.222"

info "IP atual detectado: $CURRENT_IP"
info "Interface de rede: $INTERFACE"
info "Gateway: $GATEWAY"
info "IP proposto: $PROPOSED_IP"

# Verificar se o IP .222 já está em uso
log "Verificando se o IP $PROPOSED_IP já está em uso..."
if ping -c 3 -W 2 "$PROPOSED_IP" > /dev/null 2>&1; then
    warning "O IP $PROPOSED_IP já está em uso por outro equipamento!"
    warning "Mantendo configuração DHCP para evitar conflitos de IP."

    read -p "Deseja usar um IP fixo diferente? (s/N): " USE_DIFFERENT_IP
    if [[ "$USE_DIFFERENT_IP" =~ ^[Ss]$ ]]; then
        read -p "Digite o IP fixo desejado: " FIXED_IP
        if [[ -z "$FIXED_IP" ]]; then
            error "IP fixo é obrigatório"
        fi

        # Verificar se o IP customizado também está em uso
        log "Verificando se o IP $FIXED_IP está disponível..."
        if ping -c 3 -W 2 "$FIXED_IP" > /dev/null 2>&1; then
            error "O IP $FIXED_IP também já está em uso! Escolha outro IP."
        fi
    else
        info "Mantendo configuração DHCP atual."
        KEEP_DHCP=true
    fi
else
    log "IP $PROPOSED_IP está disponível!"
    FIXED_IP="$PROPOSED_IP"

    read -p "Confirma a configuração do IP fixo $FIXED_IP? (s/N): " CONFIRM_IP
    if [[ ! "$CONFIRM_IP" =~ ^[Ss]$ ]]; then
        read -p "Digite o IP fixo desejado (ou 'dhcp' para manter DHCP): " USER_INPUT
        if [[ "$USER_INPUT" == "dhcp" ]]; then
            info "Mantendo configuração DHCP atual."
            KEEP_DHCP=true
        elif [[ -n "$USER_INPUT" ]]; then
            FIXED_IP="$USER_INPUT"
            # Verificar se o IP customizado está em uso
            log "Verificando se o IP $FIXED_IP está disponível..."
            if ping -c 3 -W 2 "$FIXED_IP" > /dev/null 2>&1; then
                error "O IP $FIXED_IP já está em uso! Escolha outro IP."
            fi
        else
            error "IP fixo é obrigatório"
        fi
    fi
fi

# Detectar DNS servers
DNS_SERVERS=$(systemd-resolve --status 2>/dev/null | grep "DNS Servers" | head -1 | awk '{print $3,$4}' | tr ' ' ',' || echo "8.8.8.8,8.8.4.4")
if [[ -z "$DNS_SERVERS" ]] || [[ "$DNS_SERVERS" == "," ]]; then
    DNS_SERVERS="8.8.8.8,8.8.4.4"
    warning "Usando DNS padrão: $DNS_SERVERS"
fi

log "Atualizando sistema..."
sudo apt-get update -y
sudo apt-get upgrade -y

log "Instalando pacotes básicos..."
sudo apt-get install vim traceroute snmp build-essential snmp-mibs-downloader iputils-ping net-tools curl wget -y

# Verificar se Zabbix já está instalado e se arquivos .conf existem
ZABBIX_PROXY_INSTALLED=false
ZABBIX_AGENT_INSTALLED=false
ZABBIX_PROXY_CONF_EXISTS=false
ZABBIX_AGENT_CONF_EXISTS=false

if dpkg -l | grep -q "zabbix-proxy"; then
    ZABBIX_PROXY_INSTALLED=true
    if [[ -f "/etc/zabbix/zabbix_proxy.conf" ]]; then
        ZABBIX_PROXY_CONF_EXISTS=true
        warning "Zabbix Proxy já está instalado com arquivo de configuração. Será reconfigurado."
    else
        warning "Zabbix Proxy instalado mas arquivo .conf não existe. Será reinstalado completamente."
    fi
fi

if dpkg -l | grep -q "zabbix-agent"; then
    ZABBIX_AGENT_INSTALLED=true
    if [[ -f "/etc/zabbix/zabbix_agentd.conf" ]]; then
        ZABBIX_AGENT_CONF_EXISTS=true
        warning "Zabbix Agent já está instalado com arquivo de configuração. Será reconfigurado."
    else
        warning "Zabbix Agent instalado mas arquivo .conf não existe. Será reinstalado completamente."
    fi
fi

# Instalar/Reinstalar Zabbix conforme necessário
NEED_PROXY_INSTALL=false
NEED_AGENT_INSTALL=false

if [[ "$ZABBIX_PROXY_INSTALLED" == "false" ]] || [[ "$ZABBIX_PROXY_CONF_EXISTS" == "false" ]]; then
    NEED_PROXY_INSTALL=true
fi

if [[ "$ZABBIX_AGENT_INSTALLED" == "false" ]] || [[ "$ZABBIX_AGENT_CONF_EXISTS" == "false" ]]; then
    NEED_AGENT_INSTALL=true
fi

if [[ "$NEED_PROXY_INSTALL" == "true" ]] || [[ "$NEED_AGENT_INSTALL" == "true" ]]; then
    log "Configurando repositório e instalando/reinstalando Zabbix..."
    cd /tmp

    # Verificar e configurar repositório Zabbix
    log "Verificando repositório Zabbix..."

    # Verificar se repositórios Zabbix estão configurados
    if ! ls /etc/apt/sources.list.d/ | grep -q zabbix 2>/dev/null; then
        log "Repositório Zabbix não encontrado. Configurando..."

        # Remover possíveis instalações antigas do zabbix-release
        sudo apt-get remove --purge zabbix-release -y 2>/dev/null || true

        # Baixar e instalar zabbix-release
        cd /tmp
        rm -f zabbix-release_latest_7.0+ubuntu24.04_all.deb
        wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.0%2Bubuntu24.04_all.deb
        sudo dpkg -i zabbix-release_latest_7.0+ubuntu24.04_all.deb

        # Atualizar lista de pacotes
        sudo apt-get update -y
    else
        log "Repositório Zabbix já configurado. Atualizando lista de pacotes..."
        sudo apt-get update -y
    fi

    # Verificar se o pacote está disponível
    log "Verificando disponibilidade do pacote zabbix-proxy-sqlite3..."
    if ! apt-cache show zabbix-proxy-sqlite3 > /dev/null 2>&1; then
        warning "Pacote zabbix-proxy-sqlite3 não encontrado. Tentando reconfigurar repositório..."

        # Forçar reconfiguração do repositório
        sudo rm -f /etc/apt/sources.list.d/zabbix.list
        cd /tmp
        rm -f zabbix-release_latest_7.0+ubuntu24.04_all.deb
        wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.0%2Bubuntu24.04_all.deb
        sudo dpkg -i zabbix-release_latest_7.0+ubuntu24.04_all.deb
        sudo apt-get update -y

        # Verificar novamente
        if ! apt-cache show zabbix-proxy-sqlite3 > /dev/null 2>&1; then
            warning "Ainda não foi possível encontrar o pacote. Informações de debug:"
            info "Repositórios Zabbix configurados:"
            ls -la /etc/apt/sources.list.d/ | grep zabbix || echo "Nenhum repositório Zabbix encontrado"
            info "Conteúdo do arquivo zabbix.list:"
            cat /etc/apt/sources.list.d/zabbix.list 2>/dev/null || echo "Arquivo zabbix.list não encontrado"

            # Forçar criação manual do arquivo zabbix.list
            warning "Criando arquivo zabbix.list manualmente..."
            sudo tee /etc/apt/sources.list.d/zabbix.list > /dev/null <<EOF
# Zabbix 7.0 repository for Ubuntu 24.04 (Noble)
deb [signed-by=/usr/share/keyrings/zabbix-official-repo.gpg] https://repo.zabbix.com/zabbix/7.0/ubuntu noble main
deb-src [signed-by=/usr/share/keyrings/zabbix-official-repo.gpg] https://repo.zabbix.com/zabbix/7.0/ubuntu noble main
EOF

            # Baixar e adicionar chave GPG
            log "Configurando chave GPG do repositório Zabbix..."
            wget -qO- https://repo.zabbix.com/zabbix-official-repo.key | sudo gpg --dearmor -o /usr/share/keyrings/zabbix-official-repo.gpg

            # Atualizar novamente
            sudo apt-get update -y

            # Verificar uma última vez
            if ! apt-cache show zabbix-proxy-sqlite3 > /dev/null 2>&1; then
                info "Testando conectividade com repositório Zabbix:"
                curl -I https://repo.zabbix.com/zabbix/7.0/ubuntu/ 2>/dev/null || echo "Falha na conectividade"
                error "Não foi possível encontrar o pacote zabbix-proxy-sqlite3 mesmo após configuração manual. Verifique conectividade."
            else
                log "✅ Pacote zabbix-proxy-sqlite3 encontrado após configuração manual"
            fi
        else
            log "✅ Pacote zabbix-proxy-sqlite3 encontrado após reconfiguração"
        fi
    else
        log "✅ Pacote zabbix-proxy-sqlite3 disponível"
    fi

    if [[ "$NEED_PROXY_INSTALL" == "true" ]]; then
        if [[ "$ZABBIX_PROXY_INSTALLED" == "true" ]]; then
            log "Reinstalando Zabbix Proxy SQLite3 (arquivo .conf ausente)..."
            sudo apt-get remove --purge zabbix-proxy-sqlite3 -y
            sudo apt-get autoremove -y
            sudo apt-get update -y
            sudo apt-get install zabbix-proxy-sqlite3 -y
        else
            log "Instalando Zabbix Proxy SQLite3..."
            sudo apt-get install zabbix-proxy-sqlite3 -y
        fi
    fi
else
    log "Zabbix já instalado com arquivos de configuração. Prosseguindo com reconfiguração..."
fi

log "Configurando Zabbix Proxy..."

# Verificar se arquivo de configuração existe
if [[ ! -f "/etc/zabbix/zabbix_proxy.conf" ]]; then
    error "Arquivo /etc/zabbix/zabbix_proxy.conf não encontrado após instalação. Verifique a instalação do Zabbix Proxy."
fi

# Backup da configuração original
sudo cp /etc/zabbix/zabbix_proxy.conf /etc/zabbix/zabbix_proxy.conf.backup.$(date +%Y%m%d_%H%M%S)

# Alterar apenas as linhas específicas no arquivo de configuração
sudo sed -i "s/^# Server=.*/Server=monitora.nvirtual.com.br/" /etc/zabbix/zabbix_proxy.conf
sudo sed -i "s/^Server=.*/Server=monitora.nvirtual.com.br/" /etc/zabbix/zabbix_proxy.conf
sudo sed -i "s/^# Hostname=.*/Hostname=$ZABBIX_HOSTNAME/" /etc/zabbix/zabbix_proxy.conf
sudo sed -i "s/^Hostname=.*/Hostname=$ZABBIX_HOSTNAME/" /etc/zabbix/zabbix_proxy.conf
sudo sed -i "s/^# DBName=.*/DBName=\/tmp\/zabbix/" /etc/zabbix/zabbix_proxy.conf
sudo sed -i "s/^DBName=.*/DBName=\/tmp\/zabbix/" /etc/zabbix/zabbix_proxy.conf
sudo sed -i "s/^# EnableRemoteCommands=.*/EnableRemoteCommands=1/" /etc/zabbix/zabbix_proxy.conf
sudo sed -i "s/^EnableRemoteCommands=.*/EnableRemoteCommands=1/" /etc/zabbix/zabbix_proxy.conf
sudo sed -i "s/^# StartPollers=.*/StartPollers=20/" /etc/zabbix/zabbix_proxy.conf
sudo sed -i "s/^StartPollers=.*/StartPollers=20/" /etc/zabbix/zabbix_proxy.conf
sudo sed -i "s/^# StartPingers=.*/StartPingers=10/" /etc/zabbix/zabbix_proxy.conf
sudo sed -i "s/^StartPingers=.*/StartPingers=10/" /etc/zabbix/zabbix_proxy.conf
sudo sed -i "s/^# StartDiscoverers=.*/StartDiscoverers=10/" /etc/zabbix/zabbix_proxy.conf
sudo sed -i "s/^StartDiscoverers=.*/StartDiscoverers=10/" /etc/zabbix/zabbix_proxy.conf
sudo sed -i "s/^# StartPollersUnreachable=.*/StartPollersUnreachable=10/" /etc/zabbix/zabbix_proxy.conf
sudo sed -i "s/^StartPollersUnreachable=.*/StartPollersUnreachable=10/" /etc/zabbix/zabbix_proxy.conf

if [[ "$NEED_AGENT_INSTALL" == "true" ]]; then
    if [[ "$ZABBIX_AGENT_INSTALLED" == "true" ]]; then
        log "Reinstalando Zabbix Agent (arquivo .conf ausente)..."
        sudo apt-get remove --purge zabbix-agent -y
        sudo apt-get autoremove -y
        sudo apt-get update -y
        sudo apt-get install zabbix-agent -y
    else
        log "Instalando Zabbix Agent..."
        sudo apt-get install zabbix-agent -y
    fi
fi

log "Configurando Zabbix Agent..."

# Verificar se arquivo de configuração existe
if [[ ! -f "/etc/zabbix/zabbix_agentd.conf" ]]; then
    error "Arquivo /etc/zabbix/zabbix_agentd.conf não encontrado após instalação. Verifique a instalação do Zabbix Agent."
fi

# Backup da configuração original
sudo cp /etc/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf.backup.$(date +%Y%m%d_%H%M%S)

# Alterar apenas as linhas específicas no arquivo de configuração
sudo sed -i "s/^# Server=.*/Server=127.0.0.1/" /etc/zabbix/zabbix_agentd.conf
sudo sed -i "s/^Server=.*/Server=127.0.0.1/" /etc/zabbix/zabbix_agentd.conf
sudo sed -i "s/^# ServerActive=.*/ServerActive=127.0.0.1/" /etc/zabbix/zabbix_agentd.conf
sudo sed -i "s/^ServerActive=.*/ServerActive=127.0.0.1/" /etc/zabbix/zabbix_agentd.conf
sudo sed -i "s/^# Hostname=.*/Hostname=$ZABBIX_HOSTNAME/" /etc/zabbix/zabbix_agentd.conf
sudo sed -i "s/^Hostname=.*/Hostname=$ZABBIX_HOSTNAME/" /etc/zabbix/zabbix_agentd.conf
sudo sed -i "s/^# EnableRemoteCommands=.*/EnableRemoteCommands=1/" /etc/zabbix/zabbix_agentd.conf
sudo sed -i "s/^EnableRemoteCommands=.*/EnableRemoteCommands=1/" /etc/zabbix/zabbix_agentd.conf

log "Habilitando e iniciando serviços Zabbix..."

# Desmascarar serviços se estiverem mascarados
sudo systemctl unmask zabbix-agent 2>/dev/null || true
sudo systemctl unmask zabbix-proxy 2>/dev/null || true

# Parar serviços se estiverem rodando
sudo systemctl stop zabbix-agent 2>/dev/null || true
sudo systemctl stop zabbix-proxy 2>/dev/null || true

# Habilitar e iniciar serviços
sudo systemctl enable zabbix-agent
sudo systemctl enable zabbix-proxy
sudo systemctl start zabbix-agent
sudo systemctl start zabbix-proxy

# Verificar status dos serviços
sleep 5

log "Verificando status dos serviços..."

# Verificar zabbix-agent
if sudo systemctl is-active --quiet zabbix-agent; then
    log "✅ Zabbix Agent iniciado com sucesso"
else
    warning "❌ Falha ao iniciar zabbix-agent"
    info "Status do zabbix-agent:"
    sudo systemctl status zabbix-agent --no-pager -l
    info "Tentando reiniciar zabbix-agent..."
    sudo systemctl restart zabbix-agent
    sleep 3
    if sudo systemctl is-active --quiet zabbix-agent; then
        log "✅ Zabbix Agent reiniciado com sucesso"
    else
        error "❌ Falha crítica ao iniciar zabbix-agent. Verifique os logs: sudo journalctl -u zabbix-agent -f"
    fi
fi

# Verificar zabbix-proxy
if sudo systemctl is-active --quiet zabbix-proxy; then
    log "✅ Zabbix Proxy iniciado com sucesso"
else
    warning "❌ Falha ao iniciar zabbix-proxy"
    info "Status do zabbix-proxy:"
    sudo systemctl status zabbix-proxy --no-pager -l
    info "Tentando reiniciar zabbix-proxy..."
    sudo systemctl restart zabbix-proxy
    sleep 3
    if sudo systemctl is-active --quiet zabbix-proxy; then
        log "✅ Zabbix Proxy reiniciado com sucesso"
    else
        error "❌ Falha crítica ao iniciar zabbix-proxy. Verifique os logs: sudo journalctl -u zabbix-proxy -f"
    fi
fi

log "Serviços Zabbix configurados!"

# Instalar Tactical RMM
log "Instalando Tactical RMM Agent..."

# Baixar e executar o script de instalação do Tactical RMM
cd /tmp
wget https://raw.githubusercontent.com/netvolt/LinuxRMM-Script/main/rmmagent-linux.sh
sudo chmod +x rmmagent-linux.sh

info "Instalando Tactical RMM Agent com as configurações fornecidas..."
info "Cliente ID: $TACTICAL_CLIENT_ID"
info "Filial: $TACTICAL_CLIENT_FILIAL"

# Executar instalação do Tactical RMM com os parâmetros corretos
./rmmagent-linux.sh install 'https://mesh.centralmesh.nvirtual.com.br/meshagents?id=7Nss2LHe67mTwByGHQ3H3lOI4x8Awfk6kwbQgxSMMq%40qIJKjK6OOSBMWfXBYgPlb&installflags=2&meshinstall=6' 'https://api.centralmesh.nvirtual.com.br' "$TACTICAL_CLIENT_ID" "$TACTICAL_CLIENT_FILIAL" 'ecd275ac5baa7e615674a38f2de333f00dd2635e179f9a08e4026db2e5856ae3' 'server'

if [[ $? -eq 0 ]]; then
    log "Tactical RMM Agent instalado com sucesso!"
else
    warning "Houve um problema na instalação do Tactical RMM Agent. Verifique os logs."
fi

log "Configuração de firewall básico..."
sudo ufw allow 22/tcp
sudo ufw allow 10050/tcp
sudo ufw allow 10051/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# Configurar IP (fixo ou manter DHCP) - APÓS todas as instalações
log "Configurando rede..."
if [[ "$KEEP_DHCP" == "true" ]]; then
    log "Mantendo configuração DHCP atual..."
    info "IP atual será mantido via DHCP: $CURRENT_IP"
    FINAL_IP="$CURRENT_IP (DHCP)"
else
    log "Configurando IP fixo..."
    NETPLAN_FILE="/etc/netplan/01-netcfg.yaml"

    # Backup da configuração atual
    sudo cp $NETPLAN_FILE ${NETPLAN_FILE}.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

    # Formatar DNS servers corretamente para netplan
    DNS_ARRAY=$(echo $DNS_SERVERS | sed 's/,/, /g')

    # Criar nova configuração netplan
    sudo tee $NETPLAN_FILE > /dev/null <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $INTERFACE:
      dhcp4: false
      addresses:
        - $FIXED_IP/24
      routes:
        - to: default
          via: $GATEWAY
      nameservers:
        addresses: [$DNS_ARRAY]
EOF

    log "Aplicando configuração de rede..."
    sudo netplan apply

    # Aguardar estabilização da rede
    sleep 5

    # Verificar conectividade
    if ! ping -c 3 8.8.8.8 > /dev/null 2>&1; then
        warning "Possível problema de conectividade após configurar IP fixo."
        info "Você pode restaurar o backup: sudo cp ${NETPLAN_FILE}.backup.* $NETPLAN_FILE && sudo netplan apply"
    else
        log "IP fixo configurado com sucesso: $FIXED_IP"
    fi

    FINAL_IP="$FIXED_IP (Fixo)"
fi

log "Instalação concluída com sucesso!"
echo
echo "=========================================="
echo "RESUMO DA INSTALAÇÃO"
echo "=========================================="
echo "Configuração de IP: $FINAL_IP"
echo "Interface de rede: $INTERFACE"
echo "Gateway: $GATEWAY"
echo "DNS: $DNS_SERVERS"
echo "Hostname Zabbix: $ZABBIX_HOSTNAME"
echo "Zabbix Server: monitora.nvirtual.com.br"
echo
echo "Tactical RMM:"
echo "- Cliente ID: $TACTICAL_CLIENT_ID"
echo "- Filial: $TACTICAL_CLIENT_FILIAL"
echo "- Mesh Server: mesh.centralmesh.nvirtual.com.br"
echo "- API Server: api.centralmesh.nvirtual.com.br"
echo
echo "Serviços instalados e ativos:"
echo "- Zabbix Proxy (porta 10051)"
echo "- Zabbix Agent (porta 10050)"
echo "- Tactical RMM Agent"
echo
echo "Logs importantes:"
echo "- Zabbix Proxy: /var/log/zabbix/zabbix_proxy.log"
echo "- Zabbix Agent: /var/log/zabbix/zabbix_agentd.log"
echo
echo "Para verificar status dos serviços:"
echo "sudo systemctl status zabbix-proxy"
echo "sudo systemctl status zabbix-agent"
echo "=========================================="

log "Script finalizado!"
