#!/bin/bash

# Script de deploy para produção
set -e

echo "==================================="
echo "Deploy para chat.agentesintegrados.com"
echo "==================================="

# Verificar se está no diretório correto
if [ ! -f "docker-compose.production.yml" ]; then
    echo "Erro: Execute este script no diretório raiz do projeto"
    exit 1
fi

# Carregar variáveis de ambiente
if [ -f ".env.production" ]; then
    echo "Carregando configurações de produção..."
    export $(cat .env.production | grep -v '^#' | xargs)
else
    echo "Erro: Arquivo .env.production não encontrado!"
    exit 1
fi

# Parar containers existentes
echo "Parando containers existentes..."
docker compose -f docker-compose.production.yml down

# Construir imagens
echo "Construindo imagens Docker..."
docker compose -f docker-compose.production.yml build --no-cache

# Iniciar serviços
echo "Iniciando serviços..."
docker compose -f docker-compose.production.yml up -d

# Aguardar serviços iniciarem
echo "Aguardando serviços iniciarem..."
sleep 10

# Verificar status dos serviços
echo "Verificando status dos serviços..."
docker compose -f docker-compose.production.yml ps

# Verificar logs
echo ""
echo "Para ver os logs, execute:"
echo "docker compose -f docker-compose.production.yml logs -f"

echo ""
echo "==================================="
echo "Deploy concluído!"
echo "Acesse: https://chat.agentesintegrados.com"
echo "==================================="