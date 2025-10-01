#!/usr/bin/env python3
"""
Резервний скрипт для відправки F10 на Linux
Використовується як альтернативний метод для перезавантаження модів у 3DMigoto
"""

import sys
import subprocess
import time
import os
from pathlib import Path

def check_command_exists(command):
    """Перевіряє чи існує команда в системі"""
    try:
        subprocess.run(['which', command], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        return True
    except subprocess.CalledProcessError:
        return False

def send_f10_xdotool():
    """Відправляє F10 через xdotool (X11)"""
    if not check_command_exists('xdotool'):
        print("❌ xdotool не встановлений")
        return False
    
    try:
        # Спробуємо знайти вікно гри
        window_names = ['Zenless', 'ZZZ', 'zenless']
        window_id = None
        
        for name in window_names:
            try:
                result = subprocess.run(['xdotool', 'search', '--name', '--onlyvisible', name], 
                                      capture_output=True, text=True, check=True)
                if result.stdout.strip():
                    window_id = result.stdout.strip().split('\n')[0]
                    print(f"✓ Знайдено вікно гри: {name} (ID: {window_id})")
                    break
            except subprocess.CalledProcessError:
                continue
        
        if window_id:
            # Активуємо вікно гри
            subprocess.run(['xdotool', 'windowactivate', window_id], check=True)
            time.sleep(0.2)
            
            # Відправляємо F10 до конкретного вікна
            subprocess.run(['xdotool', 'key', '--window', window_id, 'F10'], check=True)
        else:
            # Якщо вікно не знайдено, відправляємо до активного
            subprocess.run(['xdotool', 'key', 'F10'], check=True)
        
        print("✓ F10 відправлено через xdotool")
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"❌ Помилка xdotool: {e}")
        return False

def send_f10_ydotool():
    """Відправляє F10 через ydotool (Wayland)"""
    if not check_command_exists('ydotool'):
        print("❌ ydotool не встановлений")
        return False
    
    try:
        # Спробуємо активувати вікно гри
        focus_game_window()
        
        # Затримка для фокусування
        time.sleep(0.2)
        
        # F10 key code для ydotool - відправляємо кілька разів для надійності
        for i in range(2):
            subprocess.run(['ydotool', 'key', '67:1', '67:0'], check=True)
            if i < 1:
                time.sleep(0.1)
        
        print("✓ F10 відправлено через ydotool")
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"❌ Помилка ydotool: {e}")
        return False

def focus_game_window():
    """Намагається сфокусуватися на вікні гри"""
    try:
        # Спробуємо через wmctrl
        if check_command_exists('wmctrl'):
            window_names = ['Zenless', 'ZZZ', 'zenless']
            for name in window_names:
                try:
                    subprocess.run(['wmctrl', '-a', name], check=True, 
                                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    print(f"✓ Активовано вікно через wmctrl: {name}")
                    return True
                except subprocess.CalledProcessError:
                    continue
        
        # Альтернативно через xdotool (може працювати навіть на Wayland)
        if check_command_exists('xdotool'):
            window_names = ['Zenless', 'ZZZ', 'zenless']
            for name in window_names:
                try:
                    result = subprocess.run(['xdotool', 'search', '--name', name],
                                          capture_output=True, text=True, check=True)
                    if result.stdout.strip():
                        window_id = result.stdout.strip().split('\n')[0]
                        subprocess.run(['xdotool', 'windowactivate', window_id], check=True)
                        print(f"✓ Активовано вікно через xdotool: {name}")
                        return True
                except subprocess.CalledProcessError:
                    continue
    except Exception as e:
        print(f"⚠️  Не вдалося активувати вікно гри: {e}")
    
    return False

def create_reload_signal(mods_path):
    """Створює сигнальний файл для 3DMigoto"""
    try:
        signal_file = Path(mods_path) / '.reload_signal'
        timestamp_file = Path(mods_path) / '.mod_timestamp'
        
        current_time = str(int(time.time() * 1000))
        
        signal_file.write_text(current_time)
        timestamp_file.write_text(current_time)
        
        print(f"✓ Створено сигнальні файли в {mods_path}")
        return True
        
    except Exception as e:
        print(f"❌ Помилка створення сигнальних файлів: {e}")
        return False

def create_reload_ini(mods_path):
    """Створює INI файл для 3DMigoto"""
    try:
        ini_path = Path(mods_path) / 'mod_reload_trigger.ini'
        timestamp = int(time.time() * 1000)
        
        ini_content = f"""
; Автоматично створений файл для перезавантаження модів
; Створено: {time.strftime('%Y-%m-%d %H:%M:%S')}

[Constants]
$mod_reload_timestamp = {timestamp}
$force_reload = 1

[Present]
post run = CommandListForceReload

[CommandListForceReload]
if $force_reload == 1
    $force_reload = 0
    run = BuiltInCommandListReloadConfig
endif
"""
        
        ini_path.write_text(ini_content.strip())
        print(f"✓ Створено INI файл: {ini_path}")
        
        # Видаляємо файл через 10 секунд
        import threading
        def cleanup():
            time.sleep(10)
            try:
                if ini_path.exists():
                    ini_path.unlink()
                    print("✓ Видалено тимчасовий INI файл")
            except:
                pass
        
        threading.Thread(target=cleanup, daemon=True).start()
        return True
        
    except Exception as e:
        print(f"❌ Помилка створення INI файлу: {e}")
        return False

def get_display_server():
    """Визначає тип дисплейного сервера"""
    session_type = os.environ.get('XDG_SESSION_TYPE')
    wayland_display = os.environ.get('WAYLAND_DISPLAY')
    display = os.environ.get('DISPLAY')
    
    if session_type == 'wayland' or wayland_display:
        return 'wayland'
    elif display:
        return 'x11'
    else:
        return 'unknown'

def main():
    """Головна функція"""
    if len(sys.argv) < 2:
        print("Використання: python3 f10_reload.py <шлях_до_модів>")
        sys.exit(1)
    
    mods_path = sys.argv[1]
    
    if not Path(mods_path).exists():
        print(f"❌ Шлях до модів не існує: {mods_path}")
        sys.exit(1)
    
    print("🔄 Початок перезавантаження модів...")
    print(f"📁 Шлях до модів: {mods_path}")
    
    display_server = get_display_server()
    print(f"🖥️  Дисплейний сервер: {display_server}")
    
    success = False
    
    # Метод 1: Створення сигнальних файлів
    if create_reload_signal(mods_path):
        success = True
    
    # Метод 2: Створення INI файлу
    if create_reload_ini(mods_path):
        success = True
    
    # Метод 3: Відправка F10 через відповідний інструмент
    if display_server == 'x11':
        if send_f10_xdotool():
            success = True
    elif display_server == 'wayland':
        if send_f10_ydotool():
            success = True
    
    # Метод 4: Спроба через обидва інструменти (резервний)
    if not success:
        print("⚠️  Пробуємо альтернативні методи...")
        if send_f10_xdotool() or send_f10_ydotool():
            success = True
    
    if success:
        print("✅ Команди перезавантаження модів відправлені")
        sys.exit(0)
    else:
        print("❌ Не вдалося відправити команди перезавантаження")
        print("\n📝 Інструкції:")
        print("1. Встановіть xdotool: sudo apt install xdotool")
        print("2. Або встановіть ydotool + wmctrl:")
        print("   sudo apt install ydotool wmctrl")
        print("   sudo usermod -a -G input $USER")
        print("   sudo systemctl enable --now ydotool.service")
        print("3. Переконайтеся що гра запущена і вікно НЕ згорнуте")
        print("4. Перевірте що XXMI правильно налаштований")
        print("\n⚠️  ВАЖЛИВО для Wayland:")
        print("   - Вікно гри має бути видимим (не згорнутим)")
        print("   - ydotool потребує прав доступу (група input)")
        print("   - Може знадобитися перезавантаження після налаштування")
        sys.exit(1)

if __name__ == '__main__':
    main()