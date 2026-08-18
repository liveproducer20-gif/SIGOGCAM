"""Ollama / Qwen integration for code generation."""

import json
import httpx

OLLAMA_BASE_URL = "http://localhost:11434"
DEFAULT_MODEL = "qwen3:8b"


def _build_payload(messages: list[dict], model: str, stream: bool) -> dict:
    return {
        "model": model,
        "messages": messages,
        "stream": stream,
        "options": {"num_predict": 2048},
        "think": False,
    }


async def generate_code(prompt: str, model: str = DEFAULT_MODEL, system: str | None = None) -> str:
    messages = []
    if system:
        messages.append({"role": "system", "content": system})
    messages.append({"role": "user", "content": prompt})

    async with httpx.AsyncClient(timeout=300.0) as client:
        resp = await client.post(
            f"{OLLAMA_BASE_URL}/api/chat",
            json=_build_payload(messages, model, stream=False),
        )
        resp.raise_for_status()
        data = resp.json()
        return data.get("message", {}).get("content", "")


async def generate_stream(prompt: str, model: str = DEFAULT_MODEL, system: str | None = None):
    messages = []
    if system:
        messages.append({"role": "system", "content": system})
    messages.append({"role": "user", "content": prompt})

    async with httpx.AsyncClient(timeout=300.0) as client:
        async with client.stream(
            "POST",
            f"{OLLAMA_BASE_URL}/api/chat",
            json=_build_payload(messages, model, stream=True),
        ) as resp:
            resp.raise_for_status()
            async for line in resp.aiter_lines():
                if line:
                    chunk = json.loads(line)
                    token = chunk.get("message", {}).get("content", "")
                    if token:
                        yield token
