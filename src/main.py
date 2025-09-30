"""
Головна програма Mod Manager на PyQt6
"""

import sys
import logging
from pathlib import Path
from PyQt6.QtWidgets import QApplication
from PyQt6.QtCore import QTimer

# Налаштування логування
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('mod_manager.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

# Імпорти модулів програми
from src.core.mod_manager import ModManager
from src.utils.config import ConfigManager
from src.gui.main_window import MainWindow


class ModManagerApp:
    """Головний клас програми"""
    
    def __init__(self):
        """Ініціалізація програми"""
        logger.info("=== Запуск Mod Manager на PyQt6 ===")
        
        # Ініціалізація менеджерів
        self.config = ConfigManager()
        self.config.load_config()
        
        # Створюємо ModManager з шляхами з конфігу
        mods_path = self.config.get_mods_path()
        save_path = self.config.get_save_mods_path()
        self.mod_manager = ModManager(mods_path, save_path)
        
        # Створюємо PyQt6 додаток
        self.app = QApplication(sys.argv)
        
        # Створюємо головне вікно з менеджерами
        self.window = MainWindow(self.mod_manager, self.config)
        
        # Завантажуємо початкові дані
        self.window.load_initial_data()
        
        # Встановлюємо шляхи в Settings
        if mods_path:
            self.window.settings_tab.mods_path_input.setText(str(mods_path))
        
        # Перевіряємо чи це перший запуск
        if self.config.is_first_run() or not mods_path or not save_path:
            logger.info("Перший запуск - відкриваємо вкладку налаштувань")
            # Переключаємо на Settings
            self.window.tab_bar.set_current_tab(2)
    
    def refresh_mods(self):
        """Оновлює список модів"""
        logger.info("Оновлення списку модів...")
        
        # TODO: Інтеграція з mod_manager для завантаження реальних даних
        # mods_detailed = self.mod_manager.scan_mods_detailed()
        # active_mods = self.mod_manager.get_active_mods()
        
        logger.info("Список модів оновлено")
    
    def run(self):
        """Запускає головний цикл програми"""
        logger.info("Запуск головного циклу PyQt6...")
        try:
            # Показуємо вікно
            self.window.show()
            
            # Запускаємо event loop
            sys.exit(self.app.exec())
        except KeyboardInterrupt:
            logger.info("Отримано сигнал зупинки...")
        except Exception as e:
            logger.error(f"Помилка під час роботи програми: {e}")
        finally:
            logger.info("=== Завершення роботи Mod Manager ===")


def main():
    """Точка входу в програму"""
    try:
        app = ModManagerApp()
        app.run()
    except Exception as e:
        logger.error(f"Критична помилка: {e}", exc_info=True)
        sys.exit(1)


if __name__ == "__main__":
    main()