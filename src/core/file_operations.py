"""Операції з файлами та symbolic links"""

import os
import shutil
import logging
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)


def create_symlink(src: str, dst: str) -> bool:
    """
    Створює symbolic link
    
    Args:
        src: Шлях до оригінальної папки (Mods/mod_name)
        dst: Шлях де створити symlink (SaveMods/mod_name)
    
    Returns:
        True якщо успішно, False якщо помилка
    """
    try:
        # Перетворюємо в абсолютні шляхи
        src_path = Path(src).resolve()
        dst_path = Path(dst)  # НЕ робимо resolve для dst!
        
        # Дебаг
        logger.info(f"Створення symlink: src={src_path}, dst={dst_path}")
        
        # Перевіряємо чи джерело існує
        if not src_path.exists():
            logger.error(f"Джерело не існує: {src_path}")
            return False
        
        # Перевіряємо чи джерело є папкою
        if not src_path.is_dir():
            logger.error(f"Джерело не є папкою: {src_path}")
            return False
        
        # Видаляємо якщо вже існує щось за цим шляхом
        if dst_path.exists() or dst_path.is_symlink():
            logger.warning(f"Видаляємо існуючий файл/symlink: {dst_path}")
            safe_remove(str(dst_path))
        
        # Створюємо symlink
        os.symlink(src_path, dst_path, target_is_directory=True)
        logger.info(f"Створено symlink: {dst_path} -> {src_path}")
        return True
        
    except PermissionError:
        logger.error(f"Немає прав для створення symlink: {dst}")
        return False
    except OSError as e:
        logger.error(f"Помилка створення symlink: {e}")
        return False
    except Exception as e:
        logger.error(f"Неочікувана помилка: {e}")
        return False


def remove_symlink(path: str) -> bool:
    """
    Видаляє symbolic link (не видаляє оригінальні файли!)
    
    Args:
        path: Шлях до symlink
    
    Returns:
        True якщо успішно, False якщо помилка
    """
    try:
        path_obj = Path(path)
        
        # Перевіряємо чи це symlink
        if not path_obj.is_symlink():
            logger.warning(f"Це не symlink: {path}")
            return False
        
        # Видаляємо symlink
        path_obj.unlink()
        logger.info(f"Видалено symlink: {path}")
        return True
        
    except PermissionError:
        logger.error(f"Немає прав для видалення: {path}")
        return False
    except OSError as e:
        logger.error(f"Помилка видалення symlink: {e}")
        return False
    except Exception as e:
        logger.error(f"Неочікувана помилка: {e}")
        return False


def is_symlink(path: str) -> bool:
    """
    Перевіряє чи є шлях symbolic link
    
    Args:
        path: Шлях для перевірки
    
    Returns:
        True якщо symlink, False якщо ні
    """
    try:
        return Path(path).is_symlink()
    except Exception as e:
        logger.error(f"Помилка перевірки symlink: {e}")
        return False


def get_symlink_target(path: str) -> Optional[str]:
    """
    Повертає шлях куди веде symlink
    
    Args:
        path: Шлях до symlink
    
    Returns:
        Шлях до цільової папки або None
    """
    try:
        path_obj = Path(path)
        
        if not path_obj.is_symlink():
            return None
        
        target = os.readlink(path)
        return str(Path(target).resolve())
        
    except Exception as e:
        logger.error(f"Помилка читання symlink: {e}")
        return None


def safe_remove(path: str) -> bool:
    """
    Безпечне видалення файлу, папки або symlink
    
    Args:
        path: Шлях для видалення
    
    Returns:
        True якщо успішно, False якщо помилка
    """
    try:
        path_obj = Path(path)
        
        if not path_obj.exists() and not path_obj.is_symlink():
            logger.warning(f"Шлях не існує: {path}")
            return True
        
        # Якщо це symlink - видаляємо його
        if path_obj.is_symlink():
            path_obj.unlink()
            logger.info(f"Видалено symlink: {path}")
            return True
        
        # Якщо це папка - видаляємо з вмістом
        if path_obj.is_dir():
            shutil.rmtree(path)
            logger.info(f"Видалено папку: {path}")
            return True
        
        # Якщо це файл - видаляємо
        if path_obj.is_file():
            path_obj.unlink()
            logger.info(f"Видалено файл: {path}")
            return True
        
        return False
        
    except PermissionError:
        logger.error(f"Немає прав для видалення: {path}")
        return False
    except OSError as e:
        logger.error(f"Помилка видалення: {e}")
        return False
    except Exception as e:
        logger.error(f"Неочікувана помилка: {e}")
        return False


def get_directory_size(path: str) -> int:
    """
    Повертає розмір папки в байтах
    
    Args:
        path: Шлях до папки
    
    Returns:
        Розмір в байтах
    """
    try:
        total_size = 0
        path_obj = Path(path)
        
        if not path_obj.exists():
            return 0
        
        for item in path_obj.rglob('*'):
            if item.is_file():
                total_size += item.stat().st_size
        
        return total_size
        
    except Exception as e:
        logger.error(f"Помилка обчислення розміру: {e}")
        return 0


def count_files(path: str) -> int:
    """
    Підраховує кількість файлів в папці
    
    Args:
        path: Шлях до папки
    
    Returns:
        Кількість файлів
    """
    try:
        path_obj = Path(path)
        
        if not path_obj.exists():
            return 0
        
        return sum(1 for item in path_obj.rglob('*') if item.is_file())
        
    except Exception as e:
        logger.error(f"Помилка підрахунку файлів: {e}")
        return 0


def format_size(size_bytes: int) -> str:
    """
    Форматує розмір в зручний для читання формат
    
    Args:
        size_bytes: Розмір в байтах
    
    Returns:
        Відформатований рядок (наприклад "1.5 GB")
    """
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if size_bytes < 1024.0:
            return f"{size_bytes:.1f} {unit}"
        size_bytes /= 1024.0
    return f"{size_bytes:.1f} PB"
