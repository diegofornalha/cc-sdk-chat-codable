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

# 2. Mover para /usr/local/bin e dar permissão (sem sudo pois appuser não tem sudo)
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