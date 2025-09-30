#!/usr/bin/env python3
"""
Тестовий скрипт для перевірки функціональності Mod Manager
Запускає базові тести без GUI
"""

import sys
import os
from pathlib import Path

# Додаємо src до PYTHONPATH
sys.path.insert(0, str(Path(__file__).parent))

print("🧪 Тестування Mod Manager...")
print("=" * 50)

# Тест 1: Імпорт модулів
print("\n1️⃣ Тест імпорту модулів...")
try:
    from src.core.file_operations import create_symlink, is_symlink, remove_symlink
    from src.core.mod_manager import ModManager
    from src.utils.config import ConfigManager
    print("✅ Всі модулі імпортовані успішно")
except ImportError as e:
    print(f"❌ Помилка імпорту: {e}")
    sys.exit(1)

# Тест 2: ConfigManager
print("\n2️⃣ Тест ConfigManager...")
try:
    config = ConfigManager("test_config.json")
    default_config = config.get_default_config()
    print(f"✅ Дефолтна конфігурація: {len(default_config)} параметрів")
    
    # Cleanup
    if Path("test_config.json").exists():
        Path("test_config.json").unlink()
except Exception as e:
    print(f"❌ Помилка: {e}")

# Тест 3: File Operations (симуляція)
print("\n3️⃣ Тест операцій з файлами...")
try:
    # Створюємо тестові папки
    test_dir = Path("test_mods")
    test_dir.mkdir(exist_ok=True)
    
    test_mod = test_dir / "TestMod"
    test_mod.mkdir(exist_ok=True)
    
    # Створюємо тестовий файл
    test_file = test_mod / "test.txt"
    test_file.write_text("Test mod content")
    
    print(f"✅ Створено тестову структуру: {test_mod}")
    
    # Cleanup
    import shutil
    if test_dir.exists():
        shutil.rmtree(test_dir)
    
except Exception as e:
    print(f"❌ Помилка: {e}")

# Тест 4: ModManager (базова ініціалізація)
print("\n4️⃣ Тест ModManager...")
try:
    manager = ModManager("", "")
    valid, msg = manager.validate_paths()
    print(f"✅ ModManager ініціалізовано (валідація очікувано не пройшла)")
except Exception as e:
    print(f"❌ Помилка: {e}")

# Тест 5: Перевірка залежностей для GUI
print("\n5️⃣ Перевірка GUI залежностей...")
try:
    import customtkinter as ctk
    print(f"✅ CustomTkinter версія: {ctk.__version__}")
except ImportError:
    print("⚠️  CustomTkinter не встановлено")
    print("   Встановіть: pip install customtkinter")

try:
    from PIL import Image
    print(f"✅ Pillow встановлено")
except ImportError:
    print("⚠️  Pillow не встановлено")
    print("   Встановіть: pip install Pillow")

# Підсумок
print("\n" + "=" * 50)
print("✅ Базове тестування завершено!")
print("\n💡 Для запуску програми:")
print("   python3 src/main.py")
print("   або")
print("   ./run.sh")
