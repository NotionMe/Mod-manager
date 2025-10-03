# ZZZ Mod Manager

> Modern mod manager for Zenless Zone Zero with symbolic link management

[🇺🇦 Українська версія](./README.uk.md)

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Linux-lightgrey.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.8.1+-02569B.svg)

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Screenshots](#screenshots)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [F10 Auto-Reload](#f10-auto-reload)
- [Usage](#usage)
- [Configuration](#configuration)
- [Building from Source](#building-from-source)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## 🎯 Overview

ZZZ Mod Manager is a modern, user-friendly mod manager for Zenless Zone Zero built with Flutter. It provides a clean interface for managing character mods using symbolic links, making it easy to enable/disable mods without moving files around.

The application uses symbolic links to manage mods, which means:
- ✅ No file copying - instant mod activation/deactivation
- ✅ Saves disk space
- ✅ Original mod files remain untouched in their location
- ✅ Safe and reversible operations

## ✨ Features

### Core Features

- **🎮 Mod Management**: Easy enable/disable mods with a single click
- **👥 Character-based Organization**: Automatically organize mods by characters
- **🏷️ Auto-Tagging**: Automatic character detection from folder names
- **📦 Multiple Import Methods**:
  - Drag & Drop folders
  - Paste paths with Ctrl+V
  - File picker dialog
- **🔄 Single/Multi Mode**: Enable single or multiple mods per character
- **🎨 Modern UI**: Clean Material Design 3 interface
- **🌓 Dark/Light Theme**: Automatic theme switching
- **⚡ F10 Auto-Reload**: Automatically send F10 to game when activating mods
- **🧹 Auto-Cleanup**: Removes orphaned symbolic links and tags

### Advanced Features

- **📊 Mod Status Display**: Visual indication of active/inactive mods
- **🖼️ Character Avatars**: 38 character portraits included
- **🔍 Smart Tag Detection**: Recognizes all ZZZ characters
- **💾 Persistent Settings**: Saves your preferences and active mods
- **🪟 Window Management**: Customizable window size and position
- **📱 Responsive Design**: Adapts to different screen sizes

## 📸 Screenshots

*(The application features a modern dark/light theme interface with character cards, mod listings, and easy-to-use controls)*

## 📥 Installation

### Method 1: AUR (Arch Linux)

```bash
# Using yay
yay -S zzz-mod-manager-git

# Using paru
paru -S zzz-mod-manager-git

# Manual installation
git clone https://aur.archlinux.org/zzz-mod-manager-git.git
cd zzz-mod-manager-git
makepkg -si
```

### Method 2: Manual Installation

1. **Install dependencies**:
```bash
sudo pacman -S flutter gtk3 glib2 libx11
```

2. **Clone the repository**:
```bash
git clone https://github.com/NotionMe/Mod-manager.git
cd Mod-manager/mod_manager_flutter
```

3. **Install Flutter dependencies**:
```bash
flutter pub get
```

4. **Build the application**:
```bash
flutter build linux --release
```

5. **Run the application**:
```bash
./build/linux/x64/release/bundle/mod_manager_flutter
```

## 🚀 Quick Start

### First Launch

1. **Launch the application**:
   ```bash
   zzz-mod-manager
   ```

2. **Configure paths**:
   - Click the ⚙️ Settings button
   - Set your **Mods Path** (where 3DMigoto loads mods from)
   - Set your **SaveMods Path** (where you store your mod collection)

3. **Import mods**:
   - Use Drag & Drop to add mod folders
   - Or press Ctrl+V to paste paths
   - Or click the "+" card to use file picker

4. **Activate mods**:
   - Click on a mod card to enable/disable it
   - Use Single/Multi toggle to choose activation mode
   - Press F10 in game (or use auto-reload feature)

### Understanding Paths

- **Mods Path**: The directory where 3DMigoto loads active mods
  - Example: `/path/to/3DMigoto/Mods`
  - Active mod symbolic links are created here

- **SaveMods Path**: Your mod library/storage location
  - Example: `/path/to/3DMigoto/SaveMods`
  - Original mod folders are stored here

## ⚡ F10 Auto-Reload

The F10 Auto-Reload feature automatically sends the F10 key to the game when you activate/deactivate mods, eliminating the need to manually switch to the game and press F10.

### Setup (One-time, 2 minutes)

#### For Wayland Users:

```bash
# 1. Install required tools
sudo pacman -S ydotool wmctrl xdotool

# 2. Add yourself to the input group
sudo usermod -a -G input $USER

# 3. Enable ydotool service
sudo systemctl enable --now ydotool.service

# 4. Reboot (IMPORTANT!)
sudo reboot
```

#### For X11 Users:

```bash
# Install xdotool
sudo pacman -S xdotool wmctrl
```

### How to Use

#### Method 1: Alt+Tab Workflow ⭐ (Recommended)

```
1. Launch Zenless Zone Zero
2. Alt+Tab to the mod manager
3. Select/enable a mod
4. Alt+Tab back to the game
5. F10 is automatically sent! ✅
```

#### Method 2: Dual Monitor Setup 🖥️🖥️

```
Game on Monitor 1 (always visible)
Mod Manager on Monitor 2
Simply activate mods - works instantly! ✅
```

#### Method 3: Manual F10 Button

```
Click the "F10" button in the mod manager UI
```

### Important Notes for Wayland

- ✅ Game window must be **VISIBLE** (not minimized)
- ✅ ydotool daemon must be running
- ✅ You must be in the `input` group
- ✅ System must be rebooted after setup

### Troubleshooting F10

**Check 1: Permissions**
```bash
groups | grep input
# Should show: ... input ...
```

**Check 2: ydotool daemon**
```bash
ps aux | grep ydotool
# Should show a running process
```

**Check 3: Test F10**
```bash
# Test the Python script
python3 /opt/zzz-mod-manager/scripts/f10_reload.py /path/to/mods

# Manual test with ydotool
ydotool key 67:1 67:0
```

## 📖 Usage

### Adding Mods

#### Method 1: Drag & Drop
1. Open your file manager
2. Select one or more mod folders
3. Drag them into the mod manager window
4. Wait for import to complete

#### Method 2: Paste (Ctrl+V)
1. Copy a mod folder path (Ctrl+C in file manager)
2. Switch to mod manager
3. Press Ctrl+V
4. Wait for import to complete

#### Method 3: File Picker
1. Click the "+" card at the end of the mod list
2. Browse and select mod folders
3. Click "Select Folder"

### Managing Mods

#### Single Mode vs Multi Mode

- **Single Mode**: Only one mod can be active per character
  - Automatically deactivates other mods when enabling one
  - Best for character replacements

- **Multi Mode**: Multiple mods can be active per character
  - Enable as many mods as you want
  - Best for accessories, weapons, effects

#### Activating/Deactivating Mods

1. Click on a mod card to toggle its status
2. Active mods show with a checkmark (✓)
3. The symbolic link is created/removed automatically
4. F10 is sent automatically (if configured)

### Character Tags

Tags help organize mods by character. The system automatically detects characters from folder names:

- `Ellen_School_Girl` → Tagged as "Ellen" ✅
- `miyabi_winter_outfit` → Tagged as "Miyabi" ✅
- `Burnice-Casual` → Tagged as "Burnice" ✅

**Manual tagging**: Click the tag button on any mod card to assign/change character tags.

**Bulk auto-tagging**: Go to Settings → Auto-tagging → "Tag all mods" to automatically tag all untagged mods.

### Filtering Mods

- Click on a character avatar to show only mods for that character
- Click "All" to show all mods
- Use the search feature (if available) to find specific mods

## ⚙️ Configuration

Configuration is stored in: `~/.local/share/zzz-mod-manager/config.json`

### Settings Panel

Access via the ⚙️ button:

- **Mods Path**: Where active mods are loaded from
- **SaveMods Path**: Where your mod library is stored
- **Theme**: Dark/Light/Auto
- **Language**: English/Ukrainian
- **Auto-tagging**: Enable/disable automatic character detection

### Advanced Configuration

You can manually edit `config.json`:

```json
{
  "mods_path": "/path/to/3DMigoto/Mods",
  "save_mods_path": "/path/to/3DMigoto/SaveMods",
  "active_mods": ["mod1", "mod2"],
  "theme": "dark-blue",
  "language": "en",
  "mod_character_tags": {
    "mod_folder_name": "character_id"
  },
  "first_run": false
}
```

## 🔨 Building from Source

### Prerequisites

- Flutter SDK 3.8.1 or higher
- Linux (tested on Arch Linux)
- GTK 3
- GLib 2
- libX11

### Build Steps

```bash
# Clone the repository
git clone https://github.com/NotionMe/Mod-manager.git
cd Mod-manager/mod_manager_flutter

# Get dependencies
flutter pub get

# Run in development mode
flutter run -d linux

# Build release version
flutter build linux --release

# The executable will be in:
# build/linux/x64/release/bundle/mod_manager_flutter
```

### Build AUR Package

```bash
cd /path/to/Mod-manager
makepkg -si
```

## 🐛 Troubleshooting

### Mods Not Showing Up

1. **Check paths in Settings**:
   - Verify Mods Path points to the correct directory
   - Verify SaveMods Path contains your mods

2. **Check folder structure**:
   - Mods should be in individual folders
   - Each folder should contain mod files (INI, DDS, etc.)

3. **Restart the application**:
   - Sometimes a restart helps refresh the mod list

### Mods Not Activating in Game

1. **Verify 3DMigoto is working**:
   - Check if other mods work
   - Look for the 3DMigoto overlay (usually top-left)

2. **Check symbolic links**:
   ```bash
   ls -la /path/to/Mods/
   # Look for symbolic links (shown with ->)
   ```

3. **Press F10 in game**:
   - 3DMigoto needs F10 to reload mods
   - Use the auto-reload feature for convenience

### F10 Auto-Reload Not Working

**For Wayland**:
1. Verify you're in the input group: `groups | grep input`
2. Check ydotool is running: `systemctl status ydotool`
3. Ensure game window is visible (not minimized)
4. Reboot after initial setup

**For X11**:
1. Verify xdotool is installed: `which xdotool`
2. Test manually: `xdotool key F10`

### Application Crashes

1. **Check logs**:
   ```bash
   journalctl -xe
   ```

2. **Run from terminal** to see errors:
   ```bash
   zzz-mod-manager
   ```

3. **Clear config** (backup first!):
   ```bash
   mv ~/.local/share/zzz-mod-manager/config.json ~/.local/share/zzz-mod-manager/config.json.bak
   ```

### Permission Issues

```bash
# Ensure you have write permissions to mod directories
chmod -R u+w /path/to/Mods
chmod -R u+w /path/to/SaveMods
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### How to Contribute

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development Guidelines

- Follow Dart/Flutter best practices
- Maintain the existing code style
- Add comments for complex logic
- Test your changes thoroughly
- Update documentation as needed

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- Icons and assets from the Zenless Zone Zero community
- Thanks to all contributors and users

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/NotionMe/Mod-manager/issues)
- **Discussions**: [GitHub Discussions](https://github.com/NotionMe/Mod-manager/discussions)
- **Email**: c.ubohyi.stanislav@student.uzhnu.edu.ua

## 🔗 Links

- [GitHub Repository](https://github.com/NotionMe/Mod-manager)
- [AUR Package](https://aur.archlinux.org/packages/zzz-mod-manager-git)
- [Zenless Zone Zero](https://zenless.hoyoverse.com/)

---

**Enjoy modding!** 🎮✨
