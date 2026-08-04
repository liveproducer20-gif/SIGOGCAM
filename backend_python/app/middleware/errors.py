from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse

from app.core.responses import fail


def register_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(HTTPException)
    async def handle_http_error(request: Request, exc: HTTPException):
        return JSONResponse(
            status_code=exc.status_code,
            content=fail(str(exc.detail)),
        )

    @app.exception_handler(Exception)
    async def handle_unexpected_error(request: Request, exc: Exception):
        return JSONResponse(
            status_code=500,
            content=fail("Error interno del servidor", {"detalle": str(exc)}),
        )
