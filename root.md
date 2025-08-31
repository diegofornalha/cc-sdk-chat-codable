Instruções para configurar o Caddy (executar como root)

  1. Editar o arquivo Caddyfile:

  sudo nano /etc/caddy/Caddyfile

  2. Adicionar esta configuração no final do arquivo:

  chat.agentesintegrados.com {
      # Headers de segurança
      header {
          Strict-Transport-Security "max-age=31536000;
  includeSubDomains"
          X-Content-Type-Options "nosniff"
          X-Frame-Options "SAMEORIGIN"
          X-XSS-Protection "1; mode=block"
      }

      # API - Proxy reverso para backend
      handle /api/* {
          reverse_proxy localhost:8002 {
              header_up Host {host}
              header_up X-Real-IP {remote}
              header_up X-Forwarded-For {remote}
              header_up X-Forwarded-Proto {scheme}

              # Para SSE (Server-Sent Events)
              flush_interval -1

              # Timeout maior para streaming
              transport http {
                  read_timeout 0
                  write_timeout 0
              }
          }
      }

      # Frontend - Proxy reverso para Next.js
      handle {
          reverse_proxy localhost:3020 {
              header_up Host {host}
              header_up X-Real-IP {remote}
              header_up X-Forwarded-For {remote}
              header_up X-Forwarded-Proto {scheme}
          }
      }

      # Logs
      log {
          output file /var/log/caddy/chat.agentesintegrados.com.log
          format console
      }
  }

  3. Criar diretório de logs (se não existir):

  sudo mkdir -p /var/log/caddy

  4. Testar a configuração:

  sudo caddy validate --config /etc/caddy/Caddyfile

  5. Recarregar o Caddy:

  sudo systemctl reload caddy

  6. Verificar status do Caddy:

  sudo systemctl status caddy

  7. Verificar logs (se houver erro):

  sudo journalctl -u caddy -n 50

  8. Testar o acesso:

  curl -I https://chat.agentesintegrados.com

  ---
  Nota: Certifique-se de que o domínio chat.agentesintegrados.com está
  apontando para o IP do servidor.