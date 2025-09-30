"""
Модель даних для мода
"""

from dataclasses import dataclass
from typing import Dict, Optional, List
from pathlib import Path
import json
import configparser
import logging

logger = logging.getLogger(__name__)


@dataclass
class ModInfo:
    """Інформація про мод"""
    id: str  # Унікальний ідентифікатор (назва папки)
    name: str  # Відображувана назва
    description: str  # Опис мода
    image_path: Optional[str] = None  # Шлях до front.png
    keybinds: Dict[str, str] = None  # Keybinds з .ini файлу
    is_active: bool = False  # Чи активний мод
    folder_path: str = ""  # Повний шлях до папки мода
    
    def __post_init__(self):
        if self.keybinds is None:
            self.keybinds = {}
    
    def to_dict(self) -> dict:
        """Конвертує в словник для збереження в JSON"""
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "image_path": self.image_path,
            "keybinds": self.keybinds,
            "is_active": self.is_active,
            "folder_path": self.folder_path
        }
    
    @classmethod
    def from_dict(cls, data: dict) -> 'ModInfo':
        """Створює ModInfo з словника"""
        return cls(
            id=data.get("id", ""),
            name=data.get("name", ""),
            description=data.get("description", ""),
            image_path=data.get("image_path"),
            keybinds=data.get("keybinds", {}),
            is_active=data.get("is_active", False),
            folder_path=data.get("folder_path", "")
        )


class ModScanner:
    """Сканер для аналізу папок модів та витягування метаданих"""
    
    @staticmethod
    def scan_mod_folder(mod_path: Path) -> ModInfo:
        """
        Сканує папку мода та витягує всю інформацію
        
        Args:
            mod_path: Шлях до папки мода
            
        Returns:
            ModInfo з заповненими даними
        """
        mod_id = mod_path.name
        logger.info(f"Сканування мода: {mod_id}")
        
        # Початкові дані
        mod_info = ModInfo(
            id=mod_id,
            name=mod_id,  # За замовчуванням назва = id
            description="",
            folder_path=str(mod_path)
        )
        
        try:
            # Шукаємо зображення для аватарки (пріоритет: Preview.png, front.png, preview.jpg, front.jpg)
            image_candidates = [
                mod_path / "Preview.png",
                mod_path / "front.png", 
                mod_path / "preview.png",
                mod_path / "Preview.jpg",
                mod_path / "front.jpg",
                mod_path / "preview.jpg",
                mod_path / "thumbnail.png",
                mod_path / "icon.png"
            ]
            
            for image_path in image_candidates:
                if image_path.exists():
                    mod_info.image_path = str(image_path)
                    logger.info(f"Знайдено зображення: {image_path.name}")
                    break
            else:
                logger.debug(f"Зображення не знайдено для мода {mod_id}")
            
            # Шукаємо .ini файли
            ini_files = list(mod_path.glob("*.ini"))
            
            for ini_file in ini_files:
                logger.info(f"Аналіз .ini файлу: {ini_file.name}")
                
                # Парсимо .ini файл
                config = configparser.ConfigParser()
                config.read(ini_file, encoding='utf-8')
                
                # Витягуємо keybinds
                keybinds = ModScanner._extract_keybinds(config)
                mod_info.keybinds.update(keybinds)
                
                # Якщо назва мода не встановлена, беремо з коментарів .ini
                if mod_info.name == mod_id:
                    name_from_ini = ModScanner._extract_mod_name(ini_file)
                    if name_from_ini:
                        mod_info.name = name_from_ini
            
            # Якщо опис порожній, генеруємо базовий
            if not mod_info.description:
                mod_info.description = f"Мод {mod_info.name}"
                if mod_info.keybinds:
                    keys = ", ".join(mod_info.keybinds.keys())
                    mod_info.description += f" (клавіші: {keys})"
                    
        except Exception as e:
            logger.error(f"Помилка сканування мода {mod_id}: {e}")
        
        return mod_info
    
    @staticmethod
    def _extract_keybinds(config: configparser.ConfigParser) -> Dict[str, str]:
        """Витягує keybinds з .ini конфігурації"""
        keybinds = {}
        
        for section_name in config.sections():
            section = config[section_name]
            
            # Шукаємо поля з key = 
            if 'key' in section:
                key_value = section['key']
                
                # Визначаємо опис на основі назви секції
                if 'harness' in section_name.lower():
                    description = "Харнес"
                elif 'bottom' in section_name.lower():
                    description = "Низ"
                elif 'tail' in section_name.lower():
                    description = "Хвіст"
                elif 'face' in section_name.lower():
                    description = "Обличчя"
                elif 'color' in section_name.lower():
                    description = "Колір"
                else:
                    description = section_name
                
                keybinds[description] = key_value
                
        return keybinds
    
    @staticmethod
    def _extract_mod_name(ini_file: Path) -> Optional[str]:
        """Витягує назву мода з коментарів .ini файлу"""
        try:
            with open(ini_file, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            # Шукаємо коментарі на початку файлу
            for line in lines[:10]:  # Перші 10 рядків
                line = line.strip()
                if line.startswith(';') or line.startswith('#'):
                    # Можливо це назва мода
                    comment = line[1:].strip()
                    if len(comment) > 2 and not comment.lower().startswith('created'):
                        return comment
                        
        except Exception as e:
            logger.error(f"Помилка читання .ini файлу {ini_file}: {e}")
        
        return None