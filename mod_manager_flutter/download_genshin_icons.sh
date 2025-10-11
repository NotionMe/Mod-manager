#!/bin/bash

# Скрипт для скачування іконок персонажів Genshin Impact
BASE_URL="https://sunderarmor.com/GENSHIN/Characters/1"
OUTPUT_DIR="assets/genshin"

mkdir -p "$OUTPUT_DIR"

# Список персонажів (назви з великої літери як на сайті)
characters=(
    "Albedo" "Alhaitham" "Aloy" "Arlecchino" "Ayaka" "Ayato" "Baizhu"
    "Chasca" "Chiori" "Citlali" "Clorinde" "Cyno" "Dehya" "Diluc"
    "Emilie" "Escoffier" "Eula" "Flins" "Furina" "Ganyu" "Hutao"
    "Itto" "Jean" "Kazuha" "Keqing" "Kinich" "Klee" "Kokomi"
    "Lyney" "Mavuika" "Mona" "Mualani" "Nahida" "Navia" "Neuvillette"
    "Nilou" "Qiqi" "Raiden" "Shenhe" "Sigewinne" "Tartaglia"
    "Tighnari" "Venti" "Wanderer" "Wriothesley" "Xiao" "Xianyun"
    "Xilonen" "Yae" "Yelan" "Yoimiya" "Zhongli"
    "Aino" "Amber" "Barbara" "Beidou" "Bennett" "Candace"
    "Charlotte" "Chevreuse" "Chongyun" "Collei" "Dahlia" "Diona"
    "Dori" "Faruzan" "Fischl" "Freminet" "Gaming" "Gorou"
    "Heizou" "Kachina" "Kaeya" "Kaveh" "Kujou" "Kuki"
    "Layla" "Lisa" "Lynette" "Mika" "Ningguang" "Noelle"
    "Ororon" "Razor" "Rosaria" "Sayu" "Sethos" "Sucrose"
    "Thoma" "Traveler" "Xiangling" "Xingqiu" "Xinyan" "Yaoyao" "Yunjin"
)

echo "Скачування іконок персонажів Genshin Impact..."
echo "================================================"

success=0
failed=0

for char in "${characters[@]}"; do
    # Ім'я файлу в нижньому регістрі
    filename=$(echo "$char" | tr '[:upper:]' '[:lower:]')
    output_file="$OUTPUT_DIR/${filename}.png"
    
    # Перевірка чи файл вже існує
    if [ -f "$output_file" ]; then
        echo "✓ $char (вже існує)"
        ((success++))
        continue
    fi
    
    # Скачування іконки
    url="$BASE_URL/${char}.png"
    if wget -q "$url" -O "$output_file" 2>/dev/null; then
        if [ -s "$output_file" ]; then
            size=$(du -h "$output_file" | cut -f1)
            echo "✓ $char ($size)"
            ((success++))
        else
            rm "$output_file"
            echo "✗ $char (порожній файл)"
            ((failed++))
        fi
    else
        echo "✗ $char (не вдалося скачати)"
        ((failed++))
    fi
    
    # Невелика затримка щоб не перевантажувати сервер
    sleep 0.1
done

echo ""
echo "================================================"
echo "Завершено!"
echo "Успішно скачано: $success"
echo "Помилки: $failed"
echo "Папка: $OUTPUT_DIR"
