"""Менеджер модів - головна логіка роботи з модами"""

import logging
from pathlib import Path
from typing import List, Optional, Dict
from .file_operations import (
    create_symlink,
    remove_symlink,
    is_symlink,
    get_symlink_target,
    get_directory_size,
    count_files,
    format_size,
    safe_remove
)
from .mod_info import ModInfo, ModScanner

logger = logging.getLogger(__name__)


class ModManager:
    """Менеджер для роботи з модами через symbolic links"""
    
    def __init__(self, mods_path: str, save_mods_path: str):
        """
        Ініціалізація ModManager
        
        Args:
            mods_path: Шлях до папки з оригінальними модами (SaveMods)
            save_mods_path: Шлях до папки куди створювати links (Mods)
        """
        self.mods_path = Path(mods_path) if mods_path else None
        self.save_mods_path = Path(save_mods_path) if save_mods_path else None
        
    def set_paths(self, mods_path: str, save_mods_path: str):
        """
        Встановлює шляхи до папок
        
        Args:
            mods_path: Шлях до папки з оригінальними модами (SaveMods)
            save_mods_path: Шлях до папки куди створювати links (Mods)
        """
        self.mods_path = Path(mods_path)
        self.save_mods_path = Path(save_mods_path)
        logger.info(f"Встановлено шляхи: Mods={mods_path}, SaveMods={save_mods_path}")
    
    def validate_paths(self) -> tuple[bool, str]:
        """
        Перевіряє чи шляхи валідні
        
        Returns:
            (True, "") якщо OK, (False, "помилка") якщо проблема
        """
        if not self.mods_path or not self.save_mods_path:
            return False, "Шляхи не встановлені. Будь ласка, налаштуйте їх у Налаштуваннях."
        
        if not self.mods_path.exists():
            return False, f"Папка з модами не існує: {self.mods_path}"
        
        if not self.mods_path.is_dir():
            return False, f"Шлях до модів не є папкою: {self.mods_path}"
        
        # Папка для links може не існувати - створимо при потребі
        if self.save_mods_path.exists() and not self.save_mods_path.is_dir():
            return False, f"Шлях для links існує але не є папкою: {self.save_mods_path}"
        
        return True, ""
    
    def scan_mods(self) -> List[str]:
        """
        Сканує папку з оригінальними модами і повертає список доступних модів
        
        Returns:
            Список назв модів (підпапок)
        """
        try:
            valid, error = self.validate_paths()
            if not valid:
                logger.error(f"Невалідні шляхи: {error}")
                return []
            
            logger.info(f"Сканування папки з модами: {self.mods_path}")
            
            # Перевіряємо чи папка існує та доступна
            if not self.mods_path.exists():
                logger.error(f"Папка з модами не існує: {self.mods_path}")
                return []
            
            # Перелічуємо всі елементи в папці
            all_items = list(self.mods_path.iterdir())
            logger.info(f"Всього елементів в папці: {len(all_items)}")
            
            for item in all_items:
                item_type = "DIR" if item.is_dir() else "FILE"
                logger.info(f"  {item_type}: {item.name}")
            
            mods = []
            for item in self.mods_path.iterdir():
                # Пропускаємо файли, беремо тільки папки
                if item.is_dir():
                    # Пропускаємо системні папки та сховані
                    if not item.name.startswith('.'):
                        mods.append(item.name)
                        logger.info(f"Додано мод: {item.name}")
            
            mods.sort()  # Сортуємо за алфавітом
            logger.info(f"Знайдено {len(mods)} модів: {mods}")
            return mods
            
        except PermissionError:
            logger.error(f"Немає доступу до папки з модами: {self.mods_path}")
            return []
        except Exception as e:
            logger.error(f"Помилка видалення symlinks: {e}")
            return False
    
    def deactivate_mod(self, mod_id: str) -> bool:
        """
        Деактивує конкретний мод
        
        Args:
            mod_id: Ідентифікатор мода
            
        Returns:
            True якщо успішно, False якщо помилка
        """
        try:
            if not self.save_mods_path.exists():
                return True  # Немає чого деактивувати
            
            link_path = self.save_mods_path / mod_id
            
            if link_path.exists() and link_path.is_symlink():
                if remove_symlink(str(link_path)):
                    logger.info(f"Деактивовано мод: {mod_id}")
                    return True
                else:
                    logger.error(f"Не вдалося видалити symlink для {mod_id}")
                    return False
            else:
                logger.warning(f"Symlink для {mod_id} не знайдено")
                return True  # Вже деактивований
                
        except Exception as e:
            logger.error(f"Помилка деактивації мода {mod_id}: {e}")
            return False
    
    def activate_single_mod(self, mod_id: str) -> tuple[bool, str]:
        """
        Активує один конкретний мод БЕЗ видалення інших активних модів
        
        Args:
            mod_id: Ідентифікатор мода
            
        Returns:
            (True, "повідомлення") якщо успішно, (False, "помилка") якщо проблема
        """
        try:
            valid, error = self.validate_paths()
            if not valid:
                return False, error
            
            # Перевіряємо чи мод існує
            src = self.mods_path / mod_id
            if not src.exists():
                return False, f"Мод '{mod_id}' не знайдено"
            
            # Створюємо папку для links якщо не існує
            if not self.save_mods_path.exists():
                self.save_mods_path.mkdir(parents=True, exist_ok=True)
                logger.info(f"Створено папку для links: {self.save_mods_path}")
            
            # Шлях до symlink
            dst = self.save_mods_path / mod_id
            
            # Перевіряємо чи мод вже активний
            if dst.exists() and dst.is_symlink():
                return True, f"Мод '{mod_id}' вже активний"
            
            # Видаляємо якщо існує щось по цьому шляху (але не symlink)
            if dst.exists():
                safe_remove(str(dst))
            
            # Створюємо symlink
            if create_symlink(str(src), str(dst)):
                logger.info(f"Активовано мод: {mod_id}")
                return True, f"Мод '{mod_id}' активовано"
            else:
                return False, f"Не вдалося створити symlink для '{mod_id}'"
                
        except Exception as e:
            logger.error(f"Помилка активації мода {mod_id}: {e}")
            return False, f"Помилка: {e}"
    
    def scan_mods_detailed(self) -> List[ModInfo]:
        """
        Сканує папку з модами і повертає детальну інформацію
        
        Returns:
            Список ModInfo з повною інформацією про моди
        """
        try:
            valid, error = self.validate_paths()
            if not valid:
                logger.error(f"Невалідні шляхи: {error}")
                return []
            
            logger.info(f"Детальне сканування папки з модами: {self.mods_path}")
            
            if not self.mods_path.exists():
                logger.error(f"Папка з модами не існує: {self.mods_path}")
                return []
            
            mod_infos = []
            
            for item in self.mods_path.iterdir():
                if item.is_dir() and not item.name.startswith('.'):
                    # Скануємо папку мода
                    mod_info = ModScanner.scan_mod_folder(item)
                    
                    # Перевіряємо чи мод активний
                    mod_info.is_active = self.is_mod_active(mod_info.id)
                    
                    mod_infos.append(mod_info)
                    logger.info(f"Додано мод: {mod_info.name} ({mod_info.id})")
            
            mod_infos.sort(key=lambda x: x.name.lower())
            logger.info(f"Знайдено {len(mod_infos)} модів з деталями")
            return mod_infos
            
        except PermissionError:
            logger.error(f"Немає доступу до папки з модами: {self.mods_path}")
            return []
        except Exception as e:
            logger.error(f"Помилка детального сканування модів: {e}")
            return []
    
    def get_active_mods(self) -> List[str]:
        """
        Повертає список активних модів (symlinks в папці для links)
        
        Returns:
            Список назв активних модів
        """
        try:
            if not self.save_mods_path or not self.save_mods_path.exists():
                return []
            
            active_mods = []
            for item in self.save_mods_path.iterdir():
                # Перевіряємо чи це symlink
                if item.is_symlink():
                    active_mods.append(item.name)
            
            active_mods.sort()
            logger.info(f"Активних модів: {len(active_mods)}")
            return active_mods
            
        except Exception as e:
            logger.error(f"Помилка читання активних модів: {e}")
            return []
    
    def is_mod_active(self, mod_name: str) -> bool:
        """
        Перевіряє чи мод активний
        
        Args:
            mod_name: Назва моду
        
        Returns:
            True якщо мод активний (symlink існує)
        """
        try:
            if not self.save_mods_path:
                return False
            
            mod_link = self.save_mods_path / mod_name
            return mod_link.is_symlink()
            
        except Exception as e:
            logger.error(f"Помилка перевірки моду: {e}")
            return False
    
    def activate_mods(self, mod_names: List[str]) -> tuple[bool, str]:
        """
        Активує вибрані моди (створює symlinks)
        
        Args:
            mod_names: Список назв модів для активації
        
        Returns:
            (True, "повідомлення") якщо успішно, (False, "помилка") якщо ні
        """
        try:
            valid, error = self.validate_paths()
            if not valid:
                return False, error
            
            if not mod_names:
                return False, "Не вибрано жодного моду"
            
            # Створюємо папку для links якщо не існує
            if not self.save_mods_path.exists():
                self.save_mods_path.mkdir(parents=True, exist_ok=True)
                logger.info(f"Створено папку для links: {self.save_mods_path}")
            
            # Видаляємо всі існуючі symlinks
            logger.info("Видалення старих symlinks...")
            self.deactivate_all()
            
            # Створюємо symlinks для вибраних модів
            success_count = 0
            failed_mods = []
            
            for mod_name in mod_names:
                src = self.mods_path / mod_name
                dst = self.save_mods_path / mod_name
                
                # Перевіряємо чи мод існує
                if not src.exists():
                    logger.warning(f"Мод не існує: {mod_name}")
                    failed_mods.append(mod_name)
                    continue
                
                # Створюємо symlink
                if create_symlink(str(src), str(dst)):
                    success_count += 1
                    logger.info(f"Активовано мод: {mod_name}")
                else:
                    failed_mods.append(mod_name)
                    logger.error(f"Не вдалося активувати мод: {mod_name}")
            
            # Формуємо повідомлення про результат
            if success_count == len(mod_names):
                msg = f"✅ Успішно активовано {success_count} модів!"
                return True, msg
            elif success_count > 0:
                msg = f"⚠️ Активовано {success_count} з {len(mod_names)} модів.\n"
                msg += f"Помилки: {', '.join(failed_mods)}"
                return True, msg
            else:
                msg = f"❌ Не вдалося активувати моди.\n"
                msg += f"Перевірте шляхи та права доступу."
                return False, msg
                
        except Exception as e:
            logger.error(f"Помилка активації модів: {e}")
            return False, f"Помилка: {str(e)}"
    
    def deactivate_all(self) -> bool:
        """
        Деактивує всі моди (видаляє всі symlinks з SaveMods)
        
        Returns:
            True якщо успішно
        """
        try:
            if not self.save_mods_path or not self.save_mods_path.exists():
                logger.info("SaveMods не існує, нічого видаляти")
                return True
            
            removed_count = 0
            for item in self.save_mods_path.iterdir():
                # Видаляємо тільки symlinks
                if item.is_symlink():
                    if remove_symlink(str(item)):
                        removed_count += 1
            
            logger.info(f"Видалено {removed_count} symlinks")
            return True
            
        except Exception as e:
            logger.error(f"Помилка деактивації модів: {e}")
            return False
    
    def get_mod_info(self, mod_name: str) -> Dict[str, any]:
        """
        Повертає інформацію про мод
        
        Args:
            mod_name: Назва моду
        
        Returns:
            Словник з інформацією про мод
        """
        try:
            mod_path = self.mods_path / mod_name
            
            if not mod_path.exists():
                return {
                    "name": mod_name,
                    "exists": False,
                    "size": 0,
                    "size_formatted": "0 B",
                    "files_count": 0,
                    "is_active": False
                }
            
            size = get_directory_size(str(mod_path))
            files_count = count_files(str(mod_path))
            is_active = self.is_mod_active(mod_name)
            
            return {
                "name": mod_name,
                "exists": True,
                "size": size,
                "size_formatted": format_size(size),
                "files_count": files_count,
                "is_active": is_active,
                "path": str(mod_path)
            }
            
        except Exception as e:
            logger.error(f"Помилка отримання інфо про мод: {e}")
            return {
                "name": mod_name,
                "exists": False,
                "error": str(e)
            }
