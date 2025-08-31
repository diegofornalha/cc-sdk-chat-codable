# Guia de Deploy - Claude Code SDK Chat

## Pré-requisitos
- Docker e Docker Compose instalados
- Caddy instalado no servidor (para HTTPS automático)
- Domínio configurado apontando para o servidor

## Configuração Passo a Passo

### 1. Clone o repositório
```bash
git clone <seu-repositorio>
cd cc-sdk-chat
```

### 2. Configure as variáveis de ambiente
```bash
cp .env.example .env.production
# Edite .env.production com suas configurações
```

### 3. Build e inicie os containers
```bash
docker compose -f docker-compose.production.yml up -d --build
```

### 4. **IMPORTANTE: Autenticação do Claude Code CLI**

Após iniciar os containers, você **DEVE** autenticar o Claude Code CLI dentro do container da API:

```bash
# Acesse o container da API
docker exec -it cc-sdk-api /bin/bash

# Dentro do container, faça login no Claude Code
claude-code login

# Siga as instruções na tela:
# 1. Copie o código de autenticação mostrado
# 2. Acesse o link fornecido no navegador
# 3. Cole o código de autenticação
# 4. Confirme o login

# Após o login bem-sucedido, saia do container
exit
```

⚠️ **Nota**: Sem essa autenticação, a API retornará "Invalid API key" em todas as requisições.

### 5. Configure o Caddy para HTTPS

Adicione ao arquivo `/etc/caddy/Caddyfile`:

```caddy
chat.agentesintegrados.com {
    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "SAMEORIGIN"
        X-XSS-Protection "1; mode=block"
    }

    # Frontend
    handle {
        reverse_proxy localhost:3020 {
            header_up Host {host}
            header_up X-Real-IP {remote}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto {scheme}
        }
    }

    # API
    handle /api/* {
        reverse_proxy localhost:8002 {
            header_up Host {host}
            header_up X-Real-IP {remote}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto {scheme}
            flush_interval -1
        }
    }
}
```

Recarregue o Caddy:
```bash
sudo systemctl reload caddy
```

## Verificação

### 1. Verifique se os containers estão rodando
```bash
docker compose -f docker-compose.production.yml ps
```

Você deve ver:
- `cc-sdk-api` - Status: healthy
- `cc-sdk-frontend` - Status: running
- `claude-redis` - Status: healthy

### 2. Teste a API localmente
```bash
# Criar nova sessão
curl -X POST http://localhost:8002/api/new-session \
  -H "Content-Type: application/json" \
  -d '{}'

# Deve retornar algo como:
# {"session_id":"uuid-aqui"}
```

### 3. Teste o frontend
```bash
curl -I http://localhost:3020
# Deve retornar HTTP/1.1 200 OK
```

### 4. Acesse a aplicação
Abra no navegador: https://chat.agentesintegrados.com

## Solução de Problemas

### API retorna "Invalid API key"
- Execute o passo 4 (autenticação do Claude Code CLI)
- Verifique se o login foi bem-sucedido dentro do container

### Container da API reiniciando
```bash
# Verifique os logs
docker compose -f docker-compose.production.yml logs api --tail 50

# Se houver erro de módulo não encontrado, reconstrua:
docker compose -f docker-compose.production.yml build api
docker compose -f docker-compose.production.yml up -d api
```

### Erro de CORS
- Verifique se o domínio está configurado em `/api/server.py`
- Certifique-se que está acessando via HTTPS

## Manutenção

### Atualizar a aplicação
```bash
git pull
docker compose -f docker-compose.production.yml down
docker compose -f docker-compose.production.yml up -d --build
# Refaça a autenticação do Claude Code (passo 4)
```

### Ver logs em tempo real
```bash
docker compose -f docker-compose.production.yml logs -f
```

### Fazer backup do estado de autenticação
```bash
# O estado de autenticação fica em ~/.claude dentro do container
# Para fazer backup:
docker exec cc-sdk-api tar -czf /tmp/claude-auth.tar.gz /root/.claude
docker cp cc-sdk-api:/tmp/claude-auth.tar.gz ./claude-auth-backup.tar.gz
```

### Restaurar autenticação após rebuild
```bash
# Copie o backup para o container
docker cp ./claude-auth-backup.tar.gz cc-sdk-api:/tmp/
docker exec cc-sdk-api tar -xzf /tmp/claude-auth.tar.gz -C /
```

## Segurança

1. **Não exponha as portas diretamente**: Use sempre o Caddy como proxy reverso
2. **Mantenha o Claude Code autenticado**: Verifique periodicamente se a autenticação está válida
3. **Use HTTPS sempre**: O Caddy gerencia certificados SSL automaticamente
4. **Monitore os logs**: Configure alertas para erros de autenticação

## Comandos Úteis

```bash
# Status dos serviços
docker compose -f docker-compose.production.yml ps

# Reiniciar todos os serviços
docker compose -f docker-compose.production.yml restart

# Parar tudo
docker compose -f docker-compose.production.yml down

# Rebuild completo
docker compose -f docker-compose.production.yml down
docker compose -f docker-compose.production.yml up -d --build

# Logs de um serviço específico
docker compose -f docker-compose.production.yml logs api -f
docker compose -f docker-compose.production.yml logs frontend -f

# Executar comando dentro do container
docker exec cc-sdk-api claude-code --version
```