# Instalação Automatizada - Zabbix + Tactical RMM

Este repositório contém scripts para instalação automatizada do Zabbix Proxy, Zabbix Agent e Tactical RMM em Ubuntu Server 24.04, incluindo configuração automática de IP fixo.

## Arquivos Incluídos

- `install_zabbix_tactical_rmm.sh` - Script principal de instalação
- `check_installation.sh` - Script de verificação e troubleshooting
- `INSTALACAO_ZABBIX_TACTICAL.md` - Este arquivo de documentação

## Pré-requisitos

- Ubuntu Server 24.04 LTS (instalação limpa)
- Acesso à internet
- Usuário com privilégios sudo (não executar como root)
- Conexão de rede ativa (DHCP inicialmente)

## Funcionalidades

### Configuração Automática de Rede
- Detecta automaticamente o IP atual obtido via DHCP
- Identifica a faixa de rede (ex: 192.168.15.x)
- **Verifica se o IP .222 já está em uso** (ping test)
- Se disponível: configura IP fixo terminando em .222 (ex: 192.168.15.222)
- Se ocupado: mantém DHCP ou permite escolher outro IP
- Preserva gateway e DNS existentes
- Aplica configuração via netplan

### Instalação do Zabbix
- **Zabbix Proxy 7.0** com SQLite3
- **Zabbix Agent** para monitoramento local
- Configuração automática para servidor `monitora.nvirtual.com.br`
- Otimizações de performance (pollers, pingers, etc.)
- Habilitação de comandos remotos

### Instalação do Tactical RMM
- **Tactical RMM Agent** via script do netvolt/LinuxRMM-Script
- **MeshAgent** para conectividade remota
- Configuração automática com servidores centralmesh.nvirtual.com.br
- Requer ID do Cliente e Filial durante a instalação

### Configuração de Segurança
- Firewall UFW com regras básicas
- Portas liberadas: 22, 80, 443, 10050, 10051

## Como Usar

### 1. Preparação

#### Opção A: Instalação Rápida (Recomendada)
```bash
# Em um Ubuntu Server 24.04 limpo:
wget -O quick_install.sh https://raw.githubusercontent.com/nubium-cloud/Zabbix-Proxy-Instalation/main/quick_install.sh
chmod +x quick_install.sh
./quick_install.sh
```

#### Opção B: Instalação Rápida Segura (Token Interativo)
```bash
# Versão que solicita token durante execução:
wget -O quick_install_secure.sh https://raw.githubusercontent.com/nubium-cloud/Zabbix-Proxy-Instalation/main/quick_install_secure.sh
chmod +x quick_install_secure.sh
./quick_install_secure.sh
```

#### Opção C: Download Manual
```bash
# Fazer download dos scripts (requer token GitHub para repositório privado)
TOKEN="seu_token_github_aqui"
wget --header="Authorization: token $TOKEN" https://raw.githubusercontent.com/nubium-cloud/Zabbix-Proxy-Instalation/main/install_zabbix_tactical_rmm.sh
wget --header="Authorization: token $TOKEN" https://raw.githubusercontent.com/nubium-cloud/Zabbix-Proxy-Instalation/main/check_installation.sh

# Dar permissão de execução
chmod +x install_zabbix_tactical_rmm.sh
chmod +x check_installation.sh
```

### 2. Execução da Instalação
```bash
# Executar o script principal
./install_zabbix_tactical_rmm.sh
```

### 3. Informações Solicitadas
Durante a execução, o script solicitará:

1. **Nome do Zabbix Proxy**: Nome único para identificar este proxy no servidor Zabbix
   - Exemplo: `cliente-zbxproxy`, `empresa-proxy01`

2. **ID do Cliente (Tactical RMM)**: Identificador numérico do cliente
   - Exemplo: `123`, `456`

3. **Filial do Cliente (Tactical RMM)**: Nome ou código da filial
   - Exemplo: `MATRIZ`, `FILIAL01`, `SP`

4. **Configuração de IP**: O script detectará automaticamente a rede e verificará se o IP .222 está disponível
   - Se disponível: oferece configurar IP fixo .222
   - Se ocupado: mantém DHCP ou permite escolher outro IP
   - Opções: IP fixo personalizado, manter DHCP, ou usar .222 se disponível

### 4. Verificação da Instalação
```bash
# Executar script de verificação
./check_installation.sh
```

## Configurações Aplicadas

### Zabbix Proxy (`/etc/zabbix/zabbix_proxy.conf`)
```ini
Server=monitora.nvirtual.com.br
Hostname=[nome-informado]
StartPollers=20
StartPingers=10
StartDiscoverers=10
StartPollersUnreachable=10
EnableRemoteCommands=1
DBName=/tmp/zabbix
```

### Zabbix Agent (`/etc/zabbix/zabbix_agentd.conf`)
```ini
Server=127.0.0.1
ServerActive=127.0.0.1
Hostname=[nome-informado]
EnableRemoteCommands=1
```

### Tactical RMM Agent
```bash
# Instalação via script netvolt/LinuxRMM-Script
./rmmagent-linux.sh install \
  'https://mesh.centralmesh.nvirtual.com.br/meshagents?id=...' \
  'https://api.centralmesh.nvirtual.com.br' \
  '[ID_CLIENT]' \
  '[FILIAL_CLIENT]' \
  '7514f475df4c5f1303120fd65b18fb16b8f6baf06f73d1c2cfd4ebf83862eb82' \
  'server'
```

### Configuração de Rede (`/etc/netplan/01-netcfg.yaml`)
```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    [interface]:
      dhcp4: false
      addresses:
        - [ip-fixo]/24
      gateway4: [gateway-detectado]
      nameservers:
        addresses: [dns-detectados]
```

## Troubleshooting

### Verificar Status dos Serviços
```bash
sudo systemctl status zabbix-proxy
sudo systemctl status zabbix-agent
sudo systemctl status tacticalagent
```

### Verificar Logs
```bash
# Logs em tempo real
sudo journalctl -u zabbix-proxy -f
sudo journalctl -u zabbix-agent -f
sudo journalctl -u tacticalagent -f

# Arquivos de log
sudo tail -f /var/log/zabbix/zabbix_proxy.log
sudo tail -f /var/log/zabbix/zabbix_agentd.log
```

### Testar Conectividade
```bash
# Testar conexão com servidor Zabbix
telnet monitora.nvirtual.com.br 10051

# Testar agent local
zabbix_get -s localhost -k system.hostname

# Testar conectividade Tactical RMM
ping api.centralmesh.nvirtual.com.br
ping mesh.centralmesh.nvirtual.com.br
```

### Reiniciar Serviços
```bash
sudo systemctl restart zabbix-proxy
sudo systemctl restart zabbix-agent
sudo systemctl restart tacticalagent
```

### Problemas Comuns

#### 1. Conflito de IP (.222 já em uso)
```bash
# Verificar se o IP .222 está realmente em uso
ping -c 5 192.168.X.222  # Substitua X pela sua rede

# Se responder, há conflito. Opções:
# 1. Manter DHCP (recomendado)
# 2. Usar outro IP fixo (ex: .223, .224)
# 3. Identificar e reconfigurar o equipamento que usa .222

# Para voltar ao DHCP se configurou IP fixo:
sudo cp /etc/netplan/01-netcfg.yaml.backup.* /etc/netplan/01-netcfg.yaml
sudo netplan apply
```

#### 2. Falha na Conectividade Após Configurar IP Fixo
```bash
# Verificar configuração
cat /etc/netplan/01-netcfg.yaml

# Reaplicar configuração
sudo netplan apply

# Restaurar backup se necessário
sudo cp /etc/netplan/01-netcfg.yaml.backup.* /etc/netplan/01-netcfg.yaml
sudo netplan apply
```

#### 3. Zabbix Proxy Não Conecta ao Servidor
```bash
# Verificar conectividade
ping monitora.nvirtual.com.br
telnet monitora.nvirtual.com.br 10051

# Verificar configuração
grep -E "^(Server|Hostname)" /etc/zabbix/zabbix_proxy.conf
```

#### 4. Problemas de Firewall
```bash
# Verificar status
sudo ufw status

# Reconfigurar se necessário
sudo ufw allow 10050/tcp
sudo ufw allow 10051/tcp
sudo ufw reload
```

#### 5. Tactical RMM Agent Não Conecta
```bash
# Verificar se o agente está instalado
ls -la /opt/tacticalagent/

# Verificar se o MeshAgent está rodando
ps aux | grep meshagent

# Verificar logs do agente
sudo journalctl -u tacticalagent -n 50

# Reinstalar se necessário
cd /tmp
wget https://raw.githubusercontent.com/netvolt/LinuxRMM-Script/main/rmmagent-linux.sh
chmod +x rmmagent-linux.sh
./rmmagent-linux.sh install [parâmetros]
```

#### 6. Problemas de Conectividade com Servidores Tactical RMM
```bash
# Testar DNS
nslookup api.centralmesh.nvirtual.com.br
nslookup mesh.centralmesh.nvirtual.com.br

# Testar conectividade HTTPS
curl -I https://api.centralmesh.nvirtual.com.br
curl -I https://mesh.centralmesh.nvirtual.com.br

# Verificar se não há proxy/firewall bloqueando
telnet api.centralmesh.nvirtual.com.br 443
telnet mesh.centralmesh.nvirtual.com.br 443
```

## Portas Utilizadas

| Serviço | Porta | Protocolo | Descrição |
|---------|-------|-----------|-----------|
| SSH | 22 | TCP | Acesso remoto |
| HTTP | 80 | TCP | Tactical RMM |
| HTTPS | 443 | TCP | Tactical RMM |
| Zabbix Agent | 10050 | TCP | Monitoramento |
| Zabbix Proxy | 10051 | TCP | Comunicação com servidor |

## Arquivos de Backup

O script cria backups automáticos dos arquivos de configuração:
- `/etc/netplan/01-netcfg.yaml.backup.[timestamp]`
- `/etc/zabbix/zabbix_proxy.conf.backup`
- `/etc/zabbix/zabbix_agentd.conf.backup`

## Suporte

Para problemas ou dúvidas:
1. Execute o script `check_installation.sh` para diagnóstico
2. Verifique os logs dos serviços
3. Consulte a documentação oficial do Zabbix e Tactical RMM

## Changelog

### v1.0
- Instalação automatizada do Zabbix 7.0
- Configuração automática de IP fixo
- Instalação do Tactical RMM
- Scripts de verificação e troubleshooting
