from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.middleware.errors import register_error_handlers
from app.modules.admin.routes import router as admin_router
from app.modules.anuncios.routes import router as anuncios_router
from app.modules.auth.routes import router as auth_router
from app.modules.cartillas.routes import router as cartillas_router
from app.modules.catalogos.routes import router as catalogos_router
from app.modules.configuracion.routes import router as configuracion_router
from app.modules.eventos.routes import router as eventos_router
from app.modules.distribucion_geografica.routes import router as distribucion_geografica_router
from app.modules.dashboard.routes import router as dashboard_router
from app.modules.health.routes import router as health_router
from app.modules.insignias.routes import router as insignias_router
from app.modules.personal.routes import router as personal_router
from app.modules.soporte.routes import router as soporte_router
from app.modules.usuarios.routes import router as usuarios_router


app = FastAPI(
    title="SIGO-GCAM API",
    version="2.0.0",
    docs_url=f"{settings.api_prefix}/docs",
    redoc_url=None,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

register_error_handlers(app)

app.include_router(health_router, prefix=settings.api_prefix)
app.include_router(auth_router, prefix=f"{settings.api_prefix}/auth")
app.include_router(admin_router, prefix=f"{settings.api_prefix}/admin")
app.include_router(catalogos_router, prefix=f"{settings.api_prefix}/catalogos")
app.include_router(configuracion_router, prefix=f"{settings.api_prefix}/configuracion")
app.include_router(cartillas_router, prefix=f"{settings.api_prefix}/cartillas")
app.include_router(personal_router, prefix=f"{settings.api_prefix}/personal")
app.include_router(eventos_router, prefix=f"{settings.api_prefix}/eventos")
app.include_router(distribucion_geografica_router, prefix=settings.api_prefix)
app.include_router(dashboard_router, prefix=f"{settings.api_prefix}/dashboard")
app.include_router(anuncios_router, prefix=f"{settings.api_prefix}/anuncios")
app.include_router(insignias_router, prefix=f"{settings.api_prefix}/insignias")
app.include_router(soporte_router, prefix=f"{settings.api_prefix}/soporte")
app.include_router(usuarios_router, prefix=f"{settings.api_prefix}/usuarios")
