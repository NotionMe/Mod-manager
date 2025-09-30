"""Управління конфігурацією програми"""

import json
import logging
from pathlib import Path
from typing import Dict, Any, Optional

logger = logging.getLogger(__name__)


class ConfigManager:
    """Менеджер конфігурації програми"""
    
    def __init__(self, config_path: str = "config.json"):
        """
        Ініціалізація ConfigManager
        
        Args:
            config_path: Шлях до файлу конфігурації
        """
        self.config_path = Path(config_path)
        self.config: Dict[str, Any] = {}
        
    def load_config(self) -> Dict[str, Any]:
        """
        Завантажує конфігурацію з файлу
        
        Returns:
            Словник з конфігурацією
        """
        try:
            if self.config_path.exists():
                with open(self.config_path, 'r', encoding='utf-8') as f:
                    self.config = json.load(f)
                logger.info(f"Конфігурацію завантажено з {self.config_path}")
            else:
                logger.info("Файл конфігурації не знайдено, використовуємо дефолтні значення")
                self.config = self.get_default_config()
                # Зберігаємо тільки якщо це справді новий файл
                if not self.config_path.exists():
                    self.save_config()
                
            return self.config
            
        except json.JSONDecodeError as e:
            logger.error(f"Помилка парсингу JSON: {e}")
            logger.info("Використовуємо дефолтну конфігурацію")
            self.config = self.get_default_config()
            return self.config
            
        except Exception as e:
            logger.error(f"Помилка завантаження конфігурації: {e}")
            self.config = self.get_default_config()
            return self.config
    
    def save_config(self, config: Optional[Dict[str, Any]] = None) -> bool:
        """
        Зберігає конфігурацію у файл
        
        Args:
            config: Конфігурація для збереження (якщо None - зберігається поточна)
        
        Returns:
            True якщо успішно, False якщо помилка
        """
        try:
            if config is not None:
                self.config = config
            
            with open(self.config_path, 'w', encoding='utf-8') as f:
                json.dump(self.config, f, indent=2, ensure_ascii=False)
            
            logger.info(f"Конфігурацію збережено у {self.config_path}")
            return True
            
        except Exception as e:
            logger.error(f"Помилка збереження конфігурації: {e}")
            return False
    
    def get_default_config(self) -> Dict[str, Any]:
        """
        Повертає дефолтну конфігурацію
        
        Returns:
            Словник з дефолтними значеннями
        """
        return {
            "mods_path": "",
            "save_mods_path": "",
            "active_mods": [],
            "mods_metadata": {},  # Метадані модів
            "theme": "dark-blue",
            "window_size": "900x600",
            "language": "uk",
            "first_run": True
        }
    
    def get(self, key: str, default: Any = None) -> Any:
        """
        Отримує значення з конфігурації
        
        Args:
            key: Ключ конфігурації
            default: Значення за замовчуванням
        
        Returns:
            Значення з конфігурації або default
        """
        return self.config.get(key, default)
    
    def set(self, key: str, value: Any) -> bool:
        """
        Встановлює значення в конфігурації
        
        Args:
            key: Ключ конфігурації
            value: Значення
        
        Returns:
            True якщо успішно
        """
        self.config[key] = value
        return self.save_config()
    
    def update(self, updates: Dict[str, Any]) -> bool:
        """
        Оновлює кілька значень в конфігурації
        
        Args:
            updates: Словник з оновленнями
        
        Returns:
            True якщо успішно
        """
        self.config.update(updates)
        return self.save_config()
    
    def reset_to_defaults(self) -> bool:
        """
        Скидає конфігурацію до дефолтних значень
        
        Returns:
            True якщо успішно
        """
        self.config = self.get_default_config()
        return self.save_config()
    
    def get_mods_path(self) -> str:
        """Повертає шлях до папки Mods"""
        return self.get("mods_path", "")
    
    def get_save_mods_path(self) -> str:
        """Повертає шлях до папки SaveMods"""
        return self.get("save_mods_path", "")
    
    def get_active_mods(self) -> list:
        """Повертає список активних модів"""
        return self.get("active_mods", [])
    
    def set_active_mods(self, mods: list) -> bool:
        """Встановлює список активних модів"""
        return self.set("active_mods", mods)
    
    def is_first_run(self) -> bool:
        """Перевіряє чи це перший запуск"""
        return self.get("first_run", True)
    
    def set_first_run_complete(self) -> bool:
        """Позначає що перший запуск завершено"""
        return self.set("first_run", False)
    
    def get_mods_metadata(self) -> Dict[str, dict]:
        """Повертає метадані всіх модів"""
        return self.get("mods_metadata", {})
    
    def set_mod_metadata(self, mod_id: str, metadata: dict) -> bool:
        """Встановлює метадані для конкретного мода"""
        mods_meta = self.get_mods_metadata()
        mods_meta[mod_id] = metadata
        return self.set("mods_metadata", mods_meta)
    
    def update_mods_metadata(self, mods_metadata: Dict[str, dict]) -> bool:
        """Оновлює всі метадані модів"""
        return self.set("mods_metadata", mods_metadata)
