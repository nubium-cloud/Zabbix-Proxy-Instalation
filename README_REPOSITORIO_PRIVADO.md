# 🔐 Instalação Zabbix + Tactical RMM - Repositório Privado

Este repositório contém scripts para instalação automatizada do Zabbix Proxy, Zabbix Agent e Tactical RMM em Ubuntu Server 24.04.

## 📍 Informações do Repositório

- **Repositório**: https://github.com/nubium-cloud/Zabbix-Proxy-Instalation.git
- **Tipo**: Repositório Privado
- **Token de Acesso**: `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`

## 🚀 Métodos de Instalação

### 🎯 **Método 1: Quick Install (Mais Fácil)**
```bash
# Download e execução em uma linha:
wget -O quick_install.sh https://raw.githubusercontent.com/nubium-cloud/Zabbix-Proxy-Instalation/main/quick_install.sh && chmod +x quick_install.sh && ./quick_install.sh
```

### 🔒 **Método 2: Quick Install Seguro (Token Interativo)**
```bash
# Versão que solicita token durante execução:
wget -O quick_install_secure.sh https://raw.githubusercontent.com/nubium-cloud/Zabbix-Proxy-Instalation/main/quick_install_secure.sh && chmod +x quick_install_secure.sh && ./quick_install_secure.sh
```

### 🛠️ **Método 3: Download Manual**
```bash
# Definir token
TOKEN="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"

# Baixar scripts principais
wget --header="Authorization: token $TOKEN" -O install_zabbix_tactical_rmm.sh https://raw.githubusercontent.com/nubium-cloud/Zabbix-Proxy-Instalation/main/install_zabbix_tactical_rmm.sh
wget --header="Authorization: token $TOKEN" -O check_installation.sh https://raw.githubusercontent.com/nubium-cloud/Zabbix-Proxy-Instalation/main/check_installation.sh
wget --header="Authorization: token $TOKEN" -O reinstall_tactical_rmm.sh https://raw.githubusercontent.com/nubium-cloud/Zabbix-Proxy-Instalation/main/reinstall_tactical_rmm.sh

# Dar permissões
chmod +x *.sh

# Executar instalação
./install_zabbix_tactical_rmm.sh
```

## 📋 **Informações Solicitadas Durante a Instalação**

1. **Nome do Zabbix Proxy** (ex: `cliente-zbxproxy`)
2. **ID do Cliente Tactical RMM** (valor numérico)
3. **Filial do Cliente** (nome/código da filial)
4. **Configuração de IP** (automática com verificação de conflito)

## 🔧 **Scripts Disponíveis**

| Script | Função | Uso |
|--------|--------|-----|
| `quick_install.sh` | 📥 Baixa e executa instalação completa | Primeira instalação |
| `quick_install_secure.sh` | 🔒 Versão segura com token interativo | Primeira instalação (segura) |
| `install_zabbix_tactical_rmm.sh` | 🔧 Instalação completa Zabbix + Tactical | Instalação principal |
| `check_installation.sh` | ✅ Verificação pós-instalação | Diagnóstico e troubleshooting |
| `reinstall_tactical_rmm.sh` | 🔄 Reinstala apenas Tactical RMM | Correção de problemas específicos |

## 🌐 **Configuração de Rede Inteligente**

- ✅ **Detecta IP atual** via DHCP
- ✅ **Verifica conflito** no IP .222 (ping test)
- ✅ **Opções flexíveis**:
  - IP fixo .222 (se disponível)
  - IP fixo personalizado
  - Manter DHCP (se .222 ocupado)

## 📊 **Serviços Configurados**

### Zabbix
- **Proxy**: SQLite3 com otimizações
- **Agent**: Monitoramento local
- **Servidor**: `monitora.nvirtual.com.br`

### Tactical RMM
- **Mesh Server**: `mesh.centralmesh.nvirtual.com.br`
- **API Server**: `api.centralmesh.nvirtual.com.br`
- **Instalação**: Via script netvolt/LinuxRMM-Script

## 🔍 **Verificação Pós-Instalação**

```bash
# Verificar tudo
./check_installation.sh

# Verificar serviços específicos
sudo systemctl status zabbix-proxy
sudo systemctl status zabbix-agent
sudo systemctl status tacticalagent

# Verificar logs
sudo journalctl -u zabbix-proxy -f
sudo journalctl -u tacticalagent -f
```

## 🆘 **Troubleshooting Rápido**

### Problema: Token Inválido
```bash
# Verificar se o token está correto
curl -H "Authorization: token SEU_TOKEN" https://api.github.com/user
```

### Problema: IP .222 Ocupado
```bash
# Verificar quem está usando
ping 192.168.X.222
nmap -sn 192.168.X.222

# Reinstalar mantendo DHCP
./install_zabbix_tactical_rmm.sh
# Escolher "manter DHCP" quando perguntado
```

### Problema: Tactical RMM Não Conecta
```bash
# Reinstalar apenas Tactical RMM
./reinstall_tactical_rmm.sh
```

## 🔐 **Segurança do Token**

- **Token Atual**: Fine-grained token com acesso ao repositório
- **Escopo**: Apenas leitura do repositório Zabbix-Proxy-Instalation
- **Validade**: Verificar periodicamente se ainda está ativo
- **Renovação**: Gerar novo token se necessário em https://github.com/settings/tokens

## 📞 **Suporte**

1. Execute `./check_installation.sh` para diagnóstico
2. Verifique logs dos serviços
3. Consulte a documentação completa no `readme.md`

---

**Repositório**: https://github.com/nubium-cloud/Zabbix-Proxy-Instalation  
**Organização**: NVirtual Cloud  
**Última Atualização**: $(date +%Y-%m-%d)
