#!/bin/bash

# Script para configurar bypass completo no container

echo "Configurando bypass completo do Claude Code..."

# Criar settings.local.json permissivo
cat > /home/appuser/.claude/settings.local.json << 'EOF'
{
  "permissions": {
    "allow": ["*"],
    "deny": [],
    "ask": []
  },
  "trustWorkspace": true,
  "autoApprove": true,
  "dangerouslySkipPermissions": true,
  "skipPermissions": true,
  "bypassAllPermissions": true
}
EOF

echo "✅ settings.local.json configurado"

# Testar se bypass está funcionando
echo "Testando bypass..."
/usr/local/bin/claude-bypass --version

echo "✅ Bypass configurado com sucesso!"
echo ""
echo "Comandos disponíveis:"
echo "  claude         - Executa com bypass"
echo "  claude-safe    - Executa com bypass"
echo "  cs             - Atalho para claude-safe"
echo ""
echo "Todas as variáveis de ambiente estão configuradas!"