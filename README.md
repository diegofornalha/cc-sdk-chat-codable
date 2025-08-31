# Claude Code SDK Chat

Interface web moderna para interagir com o Claude através do Claude Code SDK, com suporte a streaming em tempo real.

## 🚀 Características

- **Chat em Tempo Real**: Respostas em streaming via Server-Sent Events (SSE)
- **Interface Moderna**: UI construída com Next.js e Tailwind CSS
- **Gerenciamento de Sessões**: Múltiplas conversas simultâneas
- **Histórico Persistente**: Mantém contexto das conversas
- **Deploy com Docker**: Configuração simples e escalável
- **HTTPS Automático**: Integração com Caddy para certificados SSL

## 📋 Pré-requisitos

- Docker e Docker Compose
- Node.js 20+ (para desenvolvimento local)
- Python 3.11+ (para desenvolvimento local)
- Conta Anthropic com acesso ao Claude Code

## 🏗️ Arquitetura

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Frontend  │────▶│     API     │────▶│Claude Code  │
│  (Next.js)  │◀────│  (FastAPI)  │◀────│    SDK      │
└─────────────┘     └─────────────┘     └─────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │    Redis    │
                    │   (Cache)   │
                    └─────────────┘
```

## 🚀 Quick Start

### Desenvolvimento Local

1. **Clone o repositório**
```bash
git clone <repositorio>
cd cc-sdk-chat
```

2. **Configure o ambiente**
```bash
cp .env.example .env
# Edite .env com suas configurações
```

3. **Inicie com Docker Compose**
```bash
docker compose up -d --build
```

4. **Autentique o Claude Code** (IMPORTANTE!)
```bash
docker exec -it cc-sdk-api /bin/bash
claude-code login
# Siga as instruções na tela
exit
```

5. **Acesse a aplicação**
```
http://localhost:3020
```

## 🌐 Deploy em Produção

Para instruções detalhadas de deploy em produção com HTTPS, consulte [DEPLOY.md](./DEPLOY.md).

### Resumo Rápido:

1. Configure o arquivo `.env.production`
2. Execute: `docker compose -f docker-compose.production.yml up -d --build`
3. Autentique o Claude Code dentro do container
4. Configure o Caddy para seu domínio
5. Acesse via HTTPS

## 🛠️ Desenvolvimento

### Estrutura do Projeto

```
cc-sdk-chat/
├── api/                    # Backend FastAPI
│   ├── server.py          # Servidor principal
│   ├── claude_handler.py  # Integração com Claude SDK
│   └── Dockerfile
├── chat/                   # Frontend Next.js
│   ├── src/
│   │   ├── components/    # Componentes React
│   │   ├── hooks/        # Custom hooks
│   │   └── stores/       # Zustand stores
│   └── Dockerfile
├── docker-compose.yml      # Config desenvolvimento
└── docker-compose.production.yml  # Config produção
```

### API Endpoints

- `GET /` - Health check
- `POST /api/new-session` - Criar nova sessão
- `POST /api/chat` - Enviar mensagem (SSE response)
- `POST /api/interrupt/{session_id}` - Interromper resposta
- `DELETE /api/clear/{session_id}` - Limpar sessão
- `GET /api/sessions/{session_id}` - Obter informações da sessão
- `GET /docs` - Documentação Swagger

### Tecnologias Utilizadas

**Backend:**
- FastAPI
- Claude Code SDK Python
- Redis (cache)
- Uvicorn (ASGI server)

**Frontend:**
- Next.js 14
- React 18
- Tailwind CSS
- Zustand (state management)
- Radix UI (componentes)

## 📝 Configuração

### Variáveis de Ambiente

```env
# API
API_PORT=8002
LOG_LEVEL=INFO
MAX_SESSION_TIME=3600
MAX_SESSIONS_PER_IP=10

# Frontend
FRONTEND_PORT=3020
NEXT_PUBLIC_API_URL=http://localhost:8002

# Produção
DOMAIN=seu-dominio.com
NODE_ENV=production
```

## 🐛 Solução de Problemas

### "Invalid API key"
- Execute o login do Claude Code dentro do container
- Verifique se o token não expirou

### Container reiniciando
- Verifique logs: `docker compose logs api -f`
- Reconstrua se necessário: `docker compose build api`

### Erro de CORS
- Verifique domínios permitidos em `api/server.py`
- Use HTTPS em produção

## 📊 Monitoramento

### Logs
```bash
# Todos os serviços
docker compose logs -f

# Serviço específico
docker compose logs api -f
docker compose logs frontend -f
```

### Status dos containers
```bash
docker compose ps
```

## 🤝 Contribuindo

1. Fork o projeto
2. Crie sua feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 🆘 Suporte

Para problemas ou dúvidas:
- Abra uma [issue](https://github.com/seu-usuario/cc-sdk-chat/issues)
- Consulte a [documentação de deploy](./DEPLOY.md)
- Verifique a [documentação da API](./api/API_DOCS.md)

## 🙏 Agradecimentos

- [Anthropic](https://www.anthropic.com/) pelo Claude
- [Claude Code SDK](https://github.com/anthropics/claude-code) pela integração
- Comunidade open source pelos componentes utilizados