from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse

from app.core.ai import generate_code, generate_stream
from app.core.responses import ok
from app.modules.ai.models import CodeGenerateInput, ChatInput

router = APIRouter()

CODE_SYSTEM = (
    "Eres un asistente de programación experto en Python, PHP, SQL y JavaScript. "
    "Genera código limpio, bien comentado y siguiendo buenas prácticas. "
    "Responde solo con el código solicitado y una breve explicación si es necesaria. "
    "No incluyas saludos ni texto innecesario."
)

CHAT_SYSTEM = (
    "Eres un asistente técnico para el sistema SIGO (Sistema de Gestión Operativa). "
    "Responde de forma concisa y técnica. Si te preguntan sobre código, responde con código. "
    "Si te preguntan sobre la arquitectura del sistema, responde basándote en: "
    "PHP frontend + Python FastAPI backend + SQL Server."
)


@router.post("/ai/generate")
async def code_generate(payload: CodeGenerateInput):
    try:
        prompt = payload.prompt
        if payload.context:
            prompt = f"Contexto:\n{payload.context}\n\nTarea:\n{payload.prompt}"
        if payload.language:
            prompt += f"\n\nLenguaje: {payload.language}"

        result = await generate_code(prompt, system=CODE_SYSTEM)
        return ok({"code": result})
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Error al conectar con Ollama: {str(e)}")


@router.post("/ai/generate-stream")
async def code_generate_stream(payload: CodeGenerateInput):
    try:
        prompt = payload.prompt
        if payload.context:
            prompt = f"Contexto:\n{payload.context}\n\nTarea:\n{payload.prompt}"
        if payload.language:
            prompt += f"\n\nLenguaje: {payload.language}"

        return StreamingResponse(
            generate_stream(prompt, system=CODE_SYSTEM),
            media_type="text/plain",
        )
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Error al conectar con Ollama: {str(e)}")


@router.post("/ai/chat")
async def ai_chat(payload: ChatInput):
    try:
        prompt = payload.message
        if payload.context:
            prompt = f"Contexto:\n{payload.context}\n\nPregunta:\n{payload.message}"

        result = await generate_code(prompt, system=CHAT_SYSTEM)
        return ok({"response": result})
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Error al conectar con Ollama: {str(e)}")
