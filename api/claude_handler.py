"""Handler simplificado para Claude sem SDK."""

import asyncio
from typing import AsyncGenerator, Optional, Dict, Any
from dataclasses import dataclass
import json
import time

@dataclass
class SessionConfig:
    """Configuração de sessão."""
    session_id: str
    max_tokens: int = 4096
    temperature: float = 0.7
    
class ClaudeHandler:
    """Handler básico para simular respostas do Claude."""
    
    def __init__(self):
        self.sessions = {}
        
    async def create_session(self, config: SessionConfig) -> Dict[str, Any]:
        """Cria uma nova sessão."""
        self.sessions[config.session_id] = {
            "config": config,
            "history": [],
            "created_at": time.time()
        }
        return {"session_id": config.session_id, "status": "created"}
    
    async def send_message(
        self, 
        session_id: str,
        message: str
    ) -> AsyncGenerator[str, None]:
        """Envia mensagem e retorna resposta simulada."""
        
        # Simula resposta do Claude
        response = f"Esta é uma resposta simulada para: {message}"
        
        # Simula streaming
        words = response.split()
        for word in words:
            yield json.dumps({
                "type": "text",
                "content": word + " "
            })
            await asyncio.sleep(0.05)
            
        # Marca fim da resposta
        yield json.dumps({
            "type": "end",
            "content": ""
        })
    
    async def close_session(self, session_id: str):
        """Fecha a sessão."""
        if session_id in self.sessions:
            del self.sessions[session_id]