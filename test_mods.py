#!/usr/bin/env python3
"""
Тестування сканування модів
"""

import sys
import os
sys.path.append('/home/notion/Repos/fork')

from src.core.mod_manager import ModManager
from src.utils.config import ConfigManager
from pathlib import Path

def test_mod_scanning():
    """Тестує сканування модів"""
    print("=== Тест сканування модів ===")
    
    # Завантажуємо конфіг
    config = ConfigManager()
    mods_path = config.get_mods_path()
    save_path = config.get_save_mods_path()
    
    print(f"Mods path: {mods_path}")
    print(f"SaveMods path: {save_path}")
    
    # Перевіряємо що є в папці Mods
    mods_dir = Path(mods_path)
    if mods_dir.exists():
        print(f"\nВміст папки {mods_path}:")
        items = list(mods_dir.iterdir())
        print(f"Загальна кількість елементів: {len(items)}")
        
        for item in items:
            type_str = "DIR" if item.is_dir() else "FILE"
            size = item.stat().st_size if item.is_file() else "N/A"
            print(f"  {type_str:4} | {item.name:30} | {size}")
    else:
        print(f"❌ Папка {mods_path} не існує!")
        return
    
    # Тестуємо ModManager
    print(f"\n=== Тест ModManager ===")
    mod_manager = ModManager()
    mod_manager.set_paths(mods_path, save_path)
    
    # Валідація шляхів
    valid, error = mod_manager.validate_paths()
    print(f"Валідація шляхів: {valid}")
    if not valid:
        print(f"Помилка: {error}")
        return
    
    # Сканування модів
    mods = mod_manager.scan_mods()
    print(f"Знайдено модів: {len(mods)}")
    for mod in mods:
        print(f"  📦 {mod}")
    
    # Активні моди
    active = mod_manager.get_active_mods()
    print(f"Активних модів: {len(active)}")
    for mod in active:
        print(f"  ✅ {mod}")

if __name__ == "__main__":
    test_mod_scanning()