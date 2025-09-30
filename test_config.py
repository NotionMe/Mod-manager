#!/usr/bin/env python3
"""
Тестування конфігурації та збереження
"""

import sys
import os
sys.path.append('/home/notion/Repos/fork')

from src.utils.config import ConfigManager

def test_config():
    """Тестує збереження конфігурації"""
    print("=== Тест конфігурації ===")
    
    config = ConfigManager()
    
    # Показуємо поточну конфігурацію
    print("Поточна конфігурація:")
    print(f"Mods path: '{config.get_mods_path()}'")
    print(f"SaveMods path: '{config.get_save_mods_path()}'")
    print(f"First run: {config.is_first_run()}")
    
    # Тестуємо оновлення
    test_mods = "/test/mods"
    test_save = "/test/savemods"
    
    print(f"\nОновлюємо шляхи:")
    print(f"Mods: {test_mods}")
    print(f"SaveMods: {test_save}")
    
    result = config.update({
        "mods_path": test_mods,
        "save_mods_path": test_save
    })
    
    print(f"Результат збереження: {result}")
    
    # Перевіряємо чи збереглося
    print(f"\nПісля оновлення:")
    print(f"Mods path: '{config.get_mods_path()}'")
    print(f"SaveMods path: '{config.get_save_mods_path()}'")
    
    # Тестуємо перезавантаження
    print(f"\nПерезавантажуємо конфіг...")
    config2 = ConfigManager()
    print(f"Mods path: '{config2.get_mods_path()}'")
    print(f"SaveMods path: '{config2.get_save_mods_path()}'")

if __name__ == "__main__":
    test_config()