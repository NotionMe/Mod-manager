"""
FastAPI сервер для Mod Manager
Забезпечує REST API для Flutter frontend
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import logging

from src.core.mod_manager import ModManager
from src.utils.config import ConfigManager

# Налаштування логування
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Mod Manager API", version="1.0.0")

# CORS для Flutter frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # У продакшені обмежити до конкретних origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Глобальні менеджери
config = ConfigManager()
config.load_config()
mod_manager: Optional[ModManager] = None

# Ініціалізація mod_manager
def init_mod_manager():
    global mod_manager
    mods_path = config.get_mods_path()
    save_path = config.get_save_mods_path()
    if mods_path and save_path:
        mod_manager = ModManager(mods_path, save_path)
        logger.info(f"ModManager ініціалізовано: mods={mods_path}, save={save_path}")
    else:
        logger.warning("Шляхи не налаштовані")

init_mod_manager()


# Pydantic моделі для API
class ModInfo(BaseModel):
    id: str
    name: str
    is_active: bool


class ModsResponse(BaseModel):
    success: bool
    mods: List[ModInfo]
    message: Optional[str] = None


class ToggleModRequest(BaseModel):
    mod_id: str


class ToggleModResponse(BaseModel):
    success: bool
    message: str
    is_active: bool


class PathsRequest(BaseModel):
    mods_path: str
    save_mods_path: str


class PathsResponse(BaseModel):
    success: bool
    message: str


class ConfigResponse(BaseModel):
    success: bool
    mods_path: str
    save_mods_path: str


# API endpoints
@app.get("/")
def root():
    """Головна сторінка API"""
    return {
        "name": "Mod Manager API",
        "version": "1.0.0",
        "status": "running"
    }


@app.get("/api/mods", response_model=ModsResponse)
def get_mods():
    """Отримати список всіх модів"""
    try:
        if not mod_manager:
            return ModsResponse(
                success=False,
                mods=[],
                message="ModManager не ініціалізовано. Налаштуйте шляхи."
            )
        
        mods = mod_manager.get_mods_info()
        mods_list = [
            ModInfo(id=mod.id, name=mod.name, is_active=mod.is_active)
            for mod in mods
        ]
        
        return ModsResponse(success=True, mods=mods_list)
    
    except Exception as e:
        logger.error(f"Помилка при отриманні модів: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/mods/toggle", response_model=ToggleModResponse)
def toggle_mod(request: ToggleModRequest):
    """Активувати/деактивувати мод"""
    try:
        if not mod_manager:
            raise HTTPException(
                status_code=400,
                detail="ModManager не ініціалізовано"
            )
        
        mod_id = request.mod_id
        mod = next((m for m in mod_manager.get_mods_info() if m.id == mod_id), None)
        
        if not mod:
            raise HTTPException(
                status_code=404,
                detail=f"Мод з ID '{mod_id}' не знайдено"
            )
        
        if mod.is_active:
            # Деактивувати
            success = mod_manager.deactivate_mod(mod_id)
            is_active = False
            message = f"Мод '{mod.name}' деактивовано" if success else "Помилка деактивації"
        else:
            # Активувати
            success = mod_manager.activate_mod(mod_id)
            is_active = True
            message = f"Мод '{mod.name}' активовано" if success else "Помилка активації"
        
        if not success:
            raise HTTPException(status_code=500, detail=message)
        
        return ToggleModResponse(
            success=True,
            message=message,
            is_active=is_active
        )
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Помилка при перемиканні мода: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/mods/clear-all")
def clear_all_mods():
    """Деактивувати всі моди"""
    try:
        if not mod_manager:
            raise HTTPException(
                status_code=400,
                detail="ModManager не ініціалізовано"
            )
        
        count = mod_manager.clear_all()
        return {
            "success": True,
            "message": f"Деактивовано {count} модів"
        }
    
    except Exception as e:
        logger.error(f"Помилка при очищенні: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/config", response_model=ConfigResponse)
def get_config():
    """Отримати поточну конфігурацію"""
    mods_path = config.get_mods_path() or ""
    save_path = config.get_save_mods_path() or ""
    
    return ConfigResponse(
        success=True,
        mods_path=mods_path,
        save_mods_path=save_path
    )


@app.post("/api/config", response_model=PathsResponse)
def update_config(request: PathsRequest):
    """Оновити шляхи в конфігурації"""
    try:
        config.set_mods_path(request.mods_path)
        config.set_save_mods_path(request.save_mods_path)
        config.save_config()
        
        # Реініціалізувати mod_manager з новими шляхами
        init_mod_manager()
        
        return PathsResponse(
            success=True,
            message="Конфігурацію збережено"
        )
    
    except Exception as e:
        logger.error(f"Помилка при збереженні конфігурації: {e}")
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    logger.info("Запуск API сервера на http://localhost:8000")
    uvicorn.run(app, host="0.0.0.0", port=8000)
