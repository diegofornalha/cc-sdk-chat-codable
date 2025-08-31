# 🚀 Claude Code Bypass para Docker - Configuração Completa

## 📋 Índice
- [Visão Geral](#visão-geral)
- [Configurações Implementadas](#configurações-implementadas)
- [Como Funciona](#como-funciona)
- [Instalação](#instalação)
- [Uso](#uso)
- [Troubleshooting](#troubleshooting)
- [Scripts Auxiliares](#scripts-auxiliares)

## 🎯 Visão Geral

Esta documentação descreve a configuração completa do **Claude Code CLI com bypass de permissões** em containers Docker, permitindo execução automatizada sem prompts de confirmação.

### Características Principais:
- ✅ **Execução com usuário não-root** (appuser - UID 1002)
- ✅ **Bypass completo de permissões** 
- ✅ **Sem prompts de confirmação**
- ✅ **Configuração persistente**
- ✅ **Compatível com automação e CI/CD**

## ⚙️ Configurações Implementadas

### 1. Variáveis de Ambiente

Todas as variáveis necessárias para bypass completo:

```bash
CLAUDE_DANGEROUSLY_SKIP_PERMISSIONS=true  # Principal flag de bypass
CLAUDE_AUTO_APPROVE=true                  # Auto-aprova todas ações
CLAUDE_TRUST_ALL_DIRECTORIES=true         # Confia em todos diretórios
CLAUDE_AUTO_APPROVE_MCP=true              # Auto-aprova MCP servers
CLAUDE_BYPASS_PERMISSIONS=true            # Bypass adicional
CLAUDE_NO_PROMPT=true                     # Sem prompts interativos
CLAUDE_DISABLE_TELEMETRY=1                # Desativa telemetria
```

### 2. Dockerfile Configurado

```dockerfile
# Dockerfile para API Python com Claude SDK
FROM python:3.11-slim

# Define diretório de trabalho
WORKDIR /app

# Instala dependências do sistema e Node.js para Claude Code CLI
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g @anthropic-ai/claude-code \
    && rm -rf /var/lib/apt/lists/*

# Copia arquivos de requisitos primeiro (para cache do Docker)
COPY requirements.txt .

# Instala dependências Python
RUN pip install --no-cache-dir -r requirements.txt

# Copia código da aplicação
COPY . .

# Criar script de bypass
RUN echo '#!/bin/bash' > /usr/local/bin/claude-bypass && \
    echo 'export CLAUDE_DANGEROUSLY_SKIP_PERMISSIONS=true' >> /usr/local/bin/claude-bypass && \
    echo 'export CLAUDE_AUTO_APPROVE_MCP=true' >> /usr/local/bin/claude-bypass && \
    echo 'export CLAUDE_TRUST_ALL_DIRECTORIES=true' >> /usr/local/bin/claude-bypass && \
    echo 'export CLAUDE_DISABLE_TELEMETRY=1' >> /usr/local/bin/claude-bypass && \
    echo 'export CLAUDE_BYPASS_PERMISSIONS=true' >> /usr/local/bin/claude-bypass && \
    echo 'export CLAUDE_NO_PROMPT=true' >> /usr/local/bin/claude-bypass && \
    echo 'export CLAUDE_AUTO_APPROVE=true' >> /usr/local/bin/claude-bypass && \
    echo 'exec claude --dangerously-skip-permissions "$@"' >> /usr/local/bin/claude-bypass && \
    chmod +x /usr/local/bin/claude-bypass

# Criar claude-safe como link
RUN ln -sf /usr/local/bin/claude-bypass /usr/local/bin/claude-safe

# Cria usuário não-root com mesmo UID do host (1002)
RUN useradd -m -u 1002 -s /bin/bash appuser && \
    chown -R appuser:appuser /app

# Configurar para o usuário appuser
USER appuser

# Criar diretório .claude para o appuser
RUN mkdir -p /home/appuser/.claude

# Criar settings.local.json permissivo
RUN echo '{"permissions":{"allow":["*"],"deny":[],"ask":[]},"trustWorkspace":true,"autoApprove":true,"dangerouslySkipPermissions":true}' > /home/appuser/.claude/settings.local.json

# Adicionar aliases ao bashrc do appuser
RUN echo 'export CLAUDE_DANGEROUSLY_SKIP_PERMISSIONS=true' >> /home/appuser/.bashrc && \
    echo 'export CLAUDE_AUTO_APPROVE=true' >> /home/appuser/.bashrc && \
    echo 'export CLAUDE_TRUST_ALL_DIRECTORIES=true' >> /home/appuser/.bashrc && \
    echo 'export CLAUDE_AUTO_APPROVE_MCP=true' >> /home/appuser/.bashrc && \
    echo 'export CLAUDE_BYPASS_PERMISSIONS=true' >> /home/appuser/.bashrc && \
    echo 'export CLAUDE_NO_PROMPT=true' >> /home/appuser/.bashrc && \
    echo 'export CLAUDE_DISABLE_TELEMETRY=1' >> /home/appuser/.bashrc && \
    echo 'alias claude="/usr/local/bin/claude-bypass"' >> /home/appuser/.bashrc && \
    echo 'alias claude-safe="/usr/local/bin/claude-bypass"' >> /home/appuser/.bashrc && \
    echo 'alias cs="claude-safe"' >> /home/appuser/.bashrc

# Configurar variáveis de ambiente permanentes
ENV CLAUDE_DANGEROUSLY_SKIP_PERMISSIONS=true
ENV CLAUDE_AUTO_APPROVE=true
ENV CLAUDE_TRUST_ALL_DIRECTORIES=true
ENV CLAUDE_AUTO_APPROVE_MCP=true
ENV CLAUDE_BYPASS_PERMISSIONS=true
ENV CLAUDE_NO_PROMPT=true
ENV CLAUDE_DISABLE_TELEMETRY=1

# Expõe porta
EXPOSE 8002

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8002/ || exit 1

# Comando para iniciar a aplicação
CMD ["python3", "-u", "server.py"]
```

### 3. Docker Compose

```yaml
version: '3.8'

services:
  # API Backend com Claude Code SDK
  api:
    build:
      context: ./api
      dockerfile: Dockerfile
    container_name: cc-sdk-api
    ports:
      - "${API_PORT:-8002}:8002"
    environment:
      # Python
      - PYTHONUNBUFFERED=1
      - LOG_LEVEL=${LOG_LEVEL:-INFO}
      
      # Claude Code Bypass Permissions
      - CLAUDE_DANGEROUSLY_SKIP_PERMISSIONS=true
      - CLAUDE_AUTO_APPROVE=true
      - CLAUDE_TRUST_ALL_DIRECTORIES=true
      - CLAUDE_AUTO_APPROVE_MCP=true
      - CLAUDE_BYPASS_PERMISSIONS=true
      - CLAUDE_NO_PROMPT=true
      - CLAUDE_DISABLE_TELEMETRY=1
      
      # API Config
      - MAX_SESSION_TIME=${MAX_SESSION_TIME:-3600}
      - MAX_SESSIONS_PER_IP=${MAX_SESSIONS_PER_IP:-10}
    volumes:
      # Claude config - permite escrita para salvar autenticação
      - ~/.claude:/home/appuser/.claude
      # Logs persistentes
      - ./logs/api:/app/logs
    networks:
      - claude-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8002/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

## 🔧 Como Funciona

### Arquitetura do Bypass

```
┌─────────────────────────────────────┐
│         Container Docker            │
│                                     │
│  ┌─────────────────────────────┐   │
│  │     Usuário: appuser        │   │
│  │      (UID: 1002)            │   │
│  └──────────┬──────────────────┘   │
│             │                       │
│  ┌──────────▼──────────────────┐   │
│  │   /usr/local/bin/           │   │
│  │   ├── claude-bypass         │   │
│  │   └── claude-safe (link)    │   │
│  └──────────┬──────────────────┘   │
│             │                       │
│  ┌──────────▼──────────────────┐   │
│  │   Variáveis de Ambiente     │   │
│  │   + Flag --dangerously-     │   │
│  │     skip-permissions        │   │
│  └──────────┬──────────────────┘   │
│             │                       │
│  ┌──────────▼──────────────────┐   │
│  │    Claude Code CLI          │   │
│  │    (Executa sem prompts)    │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

### Fluxo de Execução

1. **Comando enviado** → `claude` ou `claude-safe`
2. **Script claude-bypass**:
   - Exporta todas variáveis de bypass
   - Adiciona flag `--dangerously-skip-permissions`
3. **Claude Code CLI** executa sem pedir confirmações
4. **Resultado** retornado ao usuário

## 📦 Instalação

### Opção 1: Build Completo

```bash
# Clone o repositório
cd /home/codable/Claudable/cc-sdk-chat

# Build e inicie os containers
docker compose up -d --build

# Verifique se está rodando
docker ps | grep cc-sdk-api
```

### Opção 2: Instalar Bypass em Container Existente

Use o script `install-bypass-runtime.sh`:

```bash
# Torne executável
chmod +x scripts/install-bypass-runtime.sh

# Execute
./scripts/install-bypass-runtime.sh
```

## 🚀 Uso

### Dentro do Container

```bash
# Acessar o container
docker exec -it cc-sdk-api bash

# Usar Claude com bypass (todas as formas funcionam)
claude "crie um arquivo hello.py"
claude-safe "liste os arquivos"
cs "execute python hello.py"

# Verificar versão
claude --version
```

### Do Host (Sem Entrar no Container)

```bash
# Executar comando direto
docker exec cc-sdk-api claude-bypass "crie um script test.sh"

# Com pipe
echo "explique este código" | docker exec -i cc-sdk-api claude-bypass

# Executar script Python com Claude
docker exec cc-sdk-api claude-bypass "execute: python script.py"
```

### Exemplos Práticos

```bash
# Criar arquivo
docker exec cc-sdk-api claude-bypass "crie um arquivo config.json com configurações básicas"

# Analisar código
docker exec cc-sdk-api claude-bypass "analise o arquivo server.py e sugira melhorias"

# Executar comandos
docker exec cc-sdk-api claude-bypass "liste todos os processos Python rodando"

# Gerar documentação
docker exec cc-sdk-api claude-bypass "gere documentação para a API em api_handler.py"
```

## 🔍 Verificação e Testes

### Verificar Instalação

```bash
# Verificar se scripts existem
docker exec cc-sdk-api ls -la /usr/local/bin/claude*

# Verificar variáveis de ambiente
docker exec cc-sdk-api env | grep CLAUDE

# Verificar settings.local.json
docker exec cc-sdk-api cat /home/appuser/.claude/settings.local.json

# Testar bypass
docker exec cc-sdk-api claude-bypass --version
```

### Teste Completo

```bash
# Script de teste
cat > test-bypass.sh << 'EOF'
#!/bin/bash
echo "=== Testando Claude Bypass ==="

# Teste 1: Versão
echo "1. Versão:"
docker exec cc-sdk-api claude-bypass --version

# Teste 2: Criar arquivo
echo "2. Criando arquivo:"
docker exec cc-sdk-api claude-bypass "crie um arquivo /tmp/test.txt com o conteúdo 'Hello Claude'"

# Teste 3: Verificar arquivo
echo "3. Verificando arquivo:"
docker exec cc-sdk-api cat /tmp/test.txt

echo "=== Testes concluídos ==="
EOF

chmod +x test-bypass.sh
./test-bypass.sh
```

## 🛠️ Troubleshooting

### Problema: "EROFS: read-only file system"

**Solução**: Remover `:ro` do volume no docker-compose.yml:
```yaml
volumes:
  - ~/.claude:/home/appuser/.claude  # Sem :ro
```

### Problema: "Permission denied"

**Solução**: Verificar UID do usuário:
```bash
# No host
id -u

# Ajustar no Dockerfile se necessário
RUN useradd -m -u SEU_UID -s /bin/bash appuser
```

### Problema: "Claude ainda pede confirmação"

**Solução**: Reinstalar bypass:
```bash
./scripts/install-bypass-runtime.sh
```

### Problema: "Command not found: claude"

**Solução**: Source do bashrc:
```bash
docker exec -it cc-sdk-api bash -c "source ~/.bashrc && claude --version"
```

## 📁 Scripts Auxiliares

### install-bypass-runtime.sh

Script para instalar bypass em container já rodando:

```bash
#!/bin/bash

# Script para instalar bypass em container já rodando
# Execute este script para adicionar bypass sem rebuild

CONTAINER_NAME="cc-sdk-api"

echo "=== Instalando Claude Bypass no Container $CONTAINER_NAME ==="

# 1. Criar script claude-bypass dentro do container
echo "1. Criando script claude-bypass..."
docker exec $CONTAINER_NAME bash -c 'cat > /tmp/claude-bypass << "EOF"
#!/bin/bash
export CLAUDE_DANGEROUSLY_SKIP_PERMISSIONS=true
export CLAUDE_AUTO_APPROVE_MCP=true
export CLAUDE_TRUST_ALL_DIRECTORIES=true
export CLAUDE_DISABLE_TELEMETRY=1
export CLAUDE_BYPASS_PERMISSIONS=true
export CLAUDE_NO_PROMPT=true
export CLAUDE_AUTO_APPROVE=true
exec claude --dangerously-skip-permissions "$@"
EOF'

# 2. Mover para /usr/local/bin e dar permissão
echo "2. Instalando claude-bypass..."
docker exec --user root $CONTAINER_NAME bash -c 'mv /tmp/claude-bypass /usr/local/bin/claude-bypass'
docker exec --user root $CONTAINER_NAME bash -c 'chmod +x /usr/local/bin/claude-bypass'

# 3. Criar link para claude-safe
echo "3. Criando link claude-safe..."
docker exec --user root $CONTAINER_NAME bash -c 'ln -sf /usr/local/bin/claude-bypass /usr/local/bin/claude-safe'

# 4. Criar settings.local.json para appuser
echo "4. Configurando settings.local.json..."
docker exec --user appuser $CONTAINER_NAME bash -c 'mkdir -p /home/appuser/.claude'
docker exec --user appuser $CONTAINER_NAME bash -c 'echo "{\"permissions\":{\"allow\":[\"*\"],\"deny\":[],\"ask\":[]},\"trustWorkspace\":true,\"autoApprove\":true,\"dangerouslySkipPermissions\":true}" > /home/appuser/.claude/settings.local.json'

# 5. Adicionar aliases ao bashrc
echo "5. Configurando aliases..."
docker exec --user appuser $CONTAINER_NAME bash -c 'cat >> /home/appuser/.bashrc << "EOF"

# Claude Bypass Configuration
export CLAUDE_DANGEROUSLY_SKIP_PERMISSIONS=true
export CLAUDE_AUTO_APPROVE=true
export CLAUDE_TRUST_ALL_DIRECTORIES=true
export CLAUDE_AUTO_APPROVE_MCP=true
export CLAUDE_BYPASS_PERMISSIONS=true
export CLAUDE_NO_PROMPT=true
export CLAUDE_DISABLE_TELEMETRY=1

# Aliases
alias claude="/usr/local/bin/claude-bypass"
alias claude-safe="/usr/local/bin/claude-bypass"
alias cs="claude-safe"
EOF'

# 6. Testar
echo "6. Testando instalação..."
docker exec --user appuser $CONTAINER_NAME bash -c 'source /home/appuser/.bashrc && /usr/local/bin/claude-bypass --version'

if [ $? -eq 0 ]; then
    echo "✅ Claude Bypass instalado com sucesso!"
    echo ""
    echo "Para usar:"
    echo "  docker exec -it $CONTAINER_NAME bash"
    echo "  claude-safe \"seu comando aqui\""
    echo ""
    echo "Ou diretamente:"
    echo "  docker exec $CONTAINER_NAME claude-bypass \"seu comando\""
else
    echo "❌ Erro na instalação. Verifique os logs acima."
fi
```

## 🎯 Resumo dos Comandos

| Comando | Descrição |
|---------|-----------|
| `claude` | Executa Claude com bypass (alias) |
| `claude-safe` | Executa Claude com bypass (link) |
| `cs` | Atalho para claude-safe |
| `claude-bypass` | Script principal com bypass |

## ✅ Checklist de Verificação

- [ ] Container rodando com usuário não-root (appuser)
- [ ] Scripts claude-bypass e claude-safe instalados
- [ ] Variáveis de ambiente configuradas
- [ ] settings.local.json com permissões totais
- [ ] Aliases configurados no .bashrc
- [ ] Teste de execução sem prompts funcionando

## 🚨 Importante

⚠️ **Segurança**: O bypass remove TODAS as confirmações de segurança. Use apenas em ambientes controlados e confiáveis.

⚠️ **Produção**: Para ambientes de produção, considere limitar as permissões em vez de permitir tudo (`"allow": ["*"]`).

## 📚 Referências

- [Claude Code CLI Documentation](https://docs.anthropic.com/claude-code)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Non-root Container Security](https://docs.docker.com/engine/security/userns-remap/)

---

**Última atualização**: 31 de Agosto de 2025
**Versão**: 1.0.0
**Autor**: Sistema configurado via Claude Code