#!/bin/bash

# Script para corrigir repositório Zabbix
# Uso: ./fix_zabbix_repo.sh

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
echo "🔧 CORREÇÃO DO REPOSITÓRIO ZABBIX"
echo "=========================================="

# Verificar se é Ubuntu 24.04
if ! grep -q "Ubuntu 24.04" /etc/os-release; then
    error "Este script foi desenvolvido para Ubuntu 24.04"
fi

log "Removendo configurações antigas do Zabbix..."

# Remover pacote zabbix-release
sudo apt-get remove --purge zabbix-release -y 2>/dev/null || true

# Remover todos os arquivos de repositório Zabbix antigos
sudo rm -f /etc/apt/sources.list.d/zabbix*.list*
sudo rm -f /usr/share/keyrings/zabbix*.gpg

log "Limpando cache do apt..."
sudo apt-get clean
sudo apt-get autoremove -y

log "Configurando repositório Zabbix 7.0 manualmente..."

# Criar arquivo de repositório
sudo tee /etc/apt/sources.list.d/zabbix.list > /dev/null <<EOF
# Zabbix 7.0 repository for Ubuntu 24.04 (Noble)
deb [signed-by=/usr/share/keyrings/zabbix-official-repo.gpg] https://repo.zabbix.com/zabbix/7.0/ubuntu noble main
deb-src [signed-by=/usr/share/keyrings/zabbix-official-repo.gpg] https://repo.zabbix.com/zabbix/7.0/ubuntu noble main
EOF

log "Baixando e configurando chave GPG..."
wget -qO- https://repo.zabbix.com/zabbix-official-repo.key | sudo gpg --dearmor -o /usr/share/keyrings/zabbix-official-repo.gpg

log "Atualizando lista de pacotes..."
sudo apt-get update -y

log "Verificando se repositório foi configurado corretamente..."

# Verificar se arquivo foi criado
if [[ -f "/etc/apt/sources.list.d/zabbix.list" ]]; then
    log "✅ Arquivo zabbix.list criado com sucesso"
    info "Conteúdo do arquivo:"
    cat /etc/apt/sources.list.d/zabbix.list
else
    error "❌ Falha ao criar arquivo zabbix.list"
fi

# Verificar se chave GPG foi instalada
if [[ -f "/usr/share/keyrings/zabbix-official-repo.gpg" ]]; then
    log "✅ Chave GPG instalada com sucesso"
else
    error "❌ Falha ao instalar chave GPG"
fi

# Verificar se pacotes estão disponíveis
log "Verificando disponibilidade dos pacotes Zabbix..."

if apt-cache show zabbix-proxy-sqlite3 > /dev/null 2>&1; then
    log "✅ zabbix-proxy-sqlite3 disponível"
else
    warning "❌ zabbix-proxy-sqlite3 não encontrado"
fi

if apt-cache show zabbix-agent > /dev/null 2>&1; then
    log "✅ zabbix-agent disponível"
else
    warning "❌ zabbix-agent não encontrado"
fi

# Mostrar informações de debug
echo
echo "=========================================="
echo "INFORMAÇÕES DE DEBUG"
echo "=========================================="

info "Repositórios Zabbix configurados:"
ls -la /etc/apt/sources.list.d/ | grep zabbix || echo "Nenhum encontrado"

echo
info "Testando conectividade:"
if curl -I https://repo.zabbix.com/zabbix/7.0/ubuntu/ > /dev/null 2>&1; then
    log "✅ Conectividade com repositório OK"
else
    warning "❌ Falha na conectividade com repositório"
fi

echo
info "Pacotes Zabbix disponíveis:"
apt-cache search zabbix | head -10

echo
echo "=========================================="
echo "CORREÇÃO CONCLUÍDA"
echo "=========================================="
log "Repositório Zabbix reconfigurado. Agora você pode executar o script principal novamente."
