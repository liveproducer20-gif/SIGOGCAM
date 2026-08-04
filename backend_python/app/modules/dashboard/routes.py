from fastapi import APIRouter, Depends

from app.core.responses import ok
from app.middleware.auth import current_user
from app.modules.dashboard.repository import summary


router = APIRouter(tags=["dashboard"])


@router.get("/resumen")
def dashboard_summary(user: dict = Depends(current_user)):
    return ok(summary())
