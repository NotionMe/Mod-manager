#!/usr/bin/env python3
"""
CLI для Mod Manager - викликається з Flutter через subprocess
"""

import sys
import json
from pathlib import Path

# Додаємо src до path
sys.path.insert(0, str(Path(__file__).parent))

from src.core.mod_manager import ModManager
from src.utils.config import ConfigManager


def get_mods():
    """Отримати список модів"""
    config = ConfigManager()
    config.load_config()
    
    mods_path = config.config.get('mods_path')
    save_path = config.config.get('save_mods_path')
    
    if not mods_path or not save_path:
        return {'success': False, 'error': 'Шляхи не налаштовані'}
    
    manager = ModManager(mods_path, save_path)
    mods_list = manager.scan_mods_detailed()
    
    mods_json = []
    for mod in mods_list:
        mods_json.append({
            'id': mod.id,
            'name': mod.name,
            'is_active': mod.is_active
        })
    
    return {'success': True, 'mods': mods_json}


def toggle_mod(mod_id):
    """Перемкнути стан мода"""
    config = ConfigManager()
    config.load_config()
    
    mods_path = config.config.get('mods_path')
    save_path = config.config.get('save_mods_path')
    
    manager = ModManager(mods_path, save_path)
    
    # Перевірити чи активний
    is_active = manager.is_mod_active(mod_id)
    
    if is_active:
        success = manager.deactivate_mod(mod_id)
        message = 'Деактивовано' if success else 'Помилка'
    else:
        success, message = manager.activate_single_mod(mod_id)
    
    return {
        'success': success,
        'message': message,
        'is_active': not is_active if success else is_active
    }


def clear_all():
    """Деактивувати всі моди"""
    config = ConfigManager()
    config.load_config()
    
    mods_path = config.config.get('mods_path')
    save_path = config.config.get('save_mods_path')
    
    manager = ModManager(mods_path, save_path)
    success = manager.deactivate_all()
    
    return {
        'success': success,
        'message': 'Всі моди деактивовано' if success else 'Помилка'
    }


def get_config():
    """Отримати конфігурацію"""
    config = ConfigManager()
    config.load_config()
    
    return {
        'success': True,
        'mods_path': config.config.get('mods_path', ''),
        'save_mods_path': config.config.get('save_mods_path', '')
    }


def update_config(mods_path, save_mods_path):
    """Оновити конфігурацію"""
    config = ConfigManager()
    config.config['mods_path'] = mods_path
    config.config['save_mods_path'] = save_mods_path
    config.save_config()
    
    return {
        'success': True,
        'message': 'Конфігурацію збережено'
    }


def main():
    """Головна функція CLI"""
    if len(sys.argv) < 2:
        print(json.dumps({'success': False, 'error': 'No command'}))
        return
    
    command = sys.argv[1]
    
    try:
        if command == 'get_mods':
            result = get_mods()
        elif command == 'toggle_mod':
            mod_id = sys.argv[2]
            result = toggle_mod(mod_id)
        elif command == 'clear_all':
            result = clear_all()
        elif command == 'get_config':
            result = get_config()
        elif command == 'update_config':
            mods_path = sys.argv[2]
            save_mods_path = sys.argv[3]
            result = update_config(mods_path, save_mods_path)
        else:
            result = {'success': False, 'error': f'Unknown command: {command}'}
        
        print(json.dumps(result, ensure_ascii=False))
    
    except Exception as e:
        print(json.dumps({'success': False, 'error': str(e)}, ensure_ascii=False))


if __name__ == '__main__':
    main()
