# 📦 Публікація в AUR - Інструкція

## Швидкий гайд для публікації Mod Manager в Arch User Repository

---

## 🎯 Що потрібно зробити

### 1. Підготувати проект на GitHub

```bash
# 1.1 Створити репозиторій на GitHub
# Перейди на github.com та створи новий репо

# 1.2 Запушити код
git remote add origin https://github.com/yourusername/mod-manager.git
git add .
git commit -m "Initial commit"
git push -u origin main

# 1.3 Створити release (важливо для AUR!)
git tag -a v1.0.0 -m "First release"
git push origin v1.0.0
```

### 2. Налаштувати AUR акаунт

```bash
# 2.1 Зареєструватись на https://aur.archlinux.org/
# 2.2 Додати SSH ключ в акаунт AUR

# Генерація SSH ключа (якщо немає)
ssh-keygen -t ed25519 -C "your.email@example.com"

# Копіювати публічний ключ
cat ~/.ssh/id_ed25519.pub
# Додати на https://aur.archlinux.org/account/
```

### 3. Створити AUR пакет

```bash
# 3.1 Клонувати порожній AUR репо
git clone ssh://aur@aur.archlinux.org/mod-manager-git.git aur-mod-manager
cd aur-mod-manager

# 3.2 Скопіювати PKGBUILD
cp ../mod-manager/PKGBUILD .

# 3.3 Створити .SRCINFO
makepkg --printsrcinfo > .SRCINFO

# 3.4 Запушити в AUR
git add PKGBUILD .SRCINFO
git commit -m "Initial import of mod-manager-git"
git push
```

---

## 📝 Файли для AUR

У проекті вже є готові файли:

### ✅ PKGBUILD
```bash
cat PKGBUILD
```
Вже готовий! Просто відредагуй:
- Поміняй `yourusername` на свій GitHub username
- Додай своє ім'я та email в Maintainer

### ✅ mod-manager.desktop
```bash
cat mod-manager.desktop
```
Готовий desktop entry для меню програм.

---

## 🔧 Тестування перед публікацією

```bash
# В папці з PKGBUILD:
cd aur-mod-manager

# Перевірка PKGBUILD
namcap PKGBUILD

# Тестова збірка
makepkg -si

# Якщо все ок - можна пушити в AUR!
```

---

## 🚀 Публікація в AUR

### Перший раз:

```bash
cd aur-mod-manager

# 1. Копіюємо PKGBUILD
cp ../mod-manager/PKGBUILD .

# 2. Редагуємо (змінюємо URL на свій GitHub)
nano PKGBUILD

# 3. Генеруємо .SRCINFO
makepkg --printsrcinfo > .SRCINFO

# 4. Коммітимо
git add PKGBUILD .SRCINFO
git commit -m "Initial import: Mod Manager v1.0.0"

# 5. Пушимо в AUR
git push
```

### Оновлення пакету:

```bash
# 1. Оновлюємо PKGBUILD (pkgrel++ або pkgver++)
nano PKGBUILD

# 2. Перегенеруємо .SRCINFO
makepkg --printsrcinfo > .SRCINFO

# 3. Коммітимо
git add PKGBUILD .SRCINFO
git commit -m "Update to v1.1.0"

# 4. Пушимо
git push
```

---

## 📋 Чеклист перед публікацією

- [ ] Проект на GitHub з відкритим доступом
- [ ] Створено хоча б один release (git tag)
- [ ] PKGBUILD відредаговано (GitHub URL, maintainer)
- [ ] Локально протестовано `makepkg -si`
- [ ] Перевірено namcap
- [ ] SSH ключ доданий в AUR акаунт
- [ ] .desktop файл на місці
- [ ] README.md з інструкціями
- [ ] LICENSE файл

---

## 💡 Після публікації

Твої користувачі зможуть встановити так:

```bash
# Через yay
yay -S mod-manager-git

# Через paru
paru -S mod-manager-git

# Вручну
git clone https://aur.archlinux.org/mod-manager-git.git
cd mod-manager-git
makepkg -si
```

---

## 🔄 Підтримка пакету

### Коли робиш оновлення на GitHub:

1. Створи новий release:
   ```bash
   git tag -a v1.1.0 -m "New features"
   git push origin v1.1.0
   ```

2. Онови AUR пакет:
   ```bash
   cd aur-mod-manager
   nano PKGBUILD  # pkgrel++
   makepkg --printsrcinfo > .SRCINFO
   git commit -am "Update to v1.1.0"
   git push
   ```

---

## 📧 Корисні посилання

- **AUR Guidelines:** https://wiki.archlinux.org/title/AUR_submission_guidelines
- **PKGBUILD:** https://wiki.archlinux.org/title/PKGBUILD
- **AUR Git:** https://wiki.archlinux.org/title/AUR_submission_guidelines#Publishing_new_package_content

---

## ✨ Готово!

Тепер твій Mod Manager буде доступний для всіх Arch користувачів через:

```bash
yay -S mod-manager-git
```

**Profit! 🎉**
