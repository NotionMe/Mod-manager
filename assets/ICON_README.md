# Іконка програми

Поки іконка не створена. Можеш:

1. Створити іконку 256x256 PNG
2. Покласти в `assets/icon.png`
3. Або використати одне з зображень модів як тимчасову іконку

Для AUR та .desktop файлу потрібна іконка.

## Швидке рішення:

```bash
# Використати існуюче зображення як іконку
cp assets/mod_images/pulchraHalfThiren.png assets/icon.png

# Або створити просту іконку з текстом
convert -size 256x256 xc:blue -font Arial -pointsize 72 \
  -fill white -gravity center -annotate +0+0 "MM" \
  assets/icon.png
```

## Або завантажити іконку з інтернету:

Пошукай на:
- https://www.flaticon.com/
- https://icon-icons.com/
- https://www.iconfinder.com/

Збережи як `assets/icon.png` (256x256 або 512x512 PNG)
