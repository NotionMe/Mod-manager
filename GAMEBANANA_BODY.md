# 🎮 ZZZ Mod Manager - Your Ultimate Modding Companion

> **The modern, hassle-free way to manage your Zenless Zone Zero mods!** 🚀

---

## 🌟 Why Choose ZZZ Mod Manager?

Are you tired of:
- ❌ Manually copying mod files back and forth?
- ❌ Forgetting which mods are active?
- ❌ Wasting disk space with duplicate files?
- ❌ Struggling to organize dozens of character mods?
- ❌ Switching to game just to press F10?

**Say goodbye to all that!** This mod manager uses **symbolic links** to give you:
- ✅ **Instant activation/deactivation** - One click, done!
- ✅ **Zero file duplication** - Save precious disk space
- ✅ **Safe operations** - Original files never touched
- ✅ **Auto F10 reload** - No manual game switching needed
- ✅ **Beautiful interface** - Clean, modern Material Design 3

---

## ✨ Key Features

### 🎯 Smart Mod Management
- **One-Click Toggle** - Enable/disable mods instantly with a single click
- **Single/Multi Mode** - Choose between one mod or multiple mods per character
- **Symbolic Links** - No file copying, no duplication, just smart links
- **Auto Character Detection** - Automatically tags mods from folder names (e.g., `Ellen_Beach` → Ellen tag)

### 👥 Character Organization
- **38 Character Portraits** - Includes avatars for all ZZZ characters
- **Visual Filtering** - Click a character to see only their mods
- **Smart Tagging** - Automatic and manual tagging support
- **Mod Collections** - Organize your favorite mod combinations

### 🚀 Quality of Life
- **⚡ F10 Auto-Reload** - Automatically sends F10 to game when you activate mods (no more Alt+Tab!)
- **📦 Drag & Drop** - Just drag mod folders into the app
- **📋 Paste Import** - Copy paths and Ctrl+V to import
- **🌓 Dark/Light Theme** - Automatic theme switching
- **🌍 Localization** - English and Ukrainian languages
- **💾 Persistent Settings** - Remembers your preferences and active mods

### 🧹 Smart Maintenance
- **Auto-Cleanup** - Removes orphaned symbolic links automatically
- **Status Display** - See which mods are active at a glance
- **Safe Operations** - All changes are reversible
- **Window Memory** - Remembers your window size and position

---

## 📸 Screenshots

*[Screenshots would go here - showing the main interface, character selection, mod activation, settings panel]*

---

## 🎯 How It Works

### The Two-Folder System

**1. 📁 SaveMods Folder (Your Library)**
- Store ALL your downloaded mods here permanently
- Can be anywhere on your system
- Original files stay safe and untouched

**2. 🔗 Mods Folder (Active Mods)**
- Where 3DMigoto/XXMI loads mods from during gameplay
- Contains symbolic links to active mods only
- Managed automatically by the app

**Example:**
```
SaveMods (Library)              →     Mods (Active)
├── Ellen_BeachOutfit/          →     [link] → Ellen_BeachOutfit/
├── Miyabi_Kimono/                    (inactive, no link)
├── Burnice_Casual/             →     [link] → Burnice_Casual/
└── Jane_SchoolGirl/                  (inactive, no link)
```

**Benefits:**
- 💾 No duplicate files = Save disk space
- ⚡ Instant enable/disable = Just create/remove links  
- 🛡️ Safe = Original files never modified
- 📦 Organized = Library separate from active mods

---

## 🚀 Quick Start Guide

### Installation

**For Arch Linux Users (AUR):**
```bash
yay -S zzz-mod-manager-git
# or
paru -S zzz-mod-manager-git
```

**For Other Linux Users:**
1. Download the latest release
2. Extract and run: `./mod_manager_flutter`

**Requirements:**
- Linux (tested on Arch, should work on most distros)
- GTK 3
- 3DMigoto/XXMI installed for ZZZ

### First Launch - Welcome Screen

1. **Choose Your Language** 🌍
   - Select English or Українська

2. **Configure Directories** 📁
   - **Mods Folder**: Point to your `XXMI-Launcher/ZZMI/Mods` folder
   - **SaveMods Folder**: Choose where to store your mod library

3. **Start Modding!** 🎮
   - Import mods via Drag & Drop or Ctrl+V
   - Click mod cards to activate/deactivate
   - Enjoy!

### Using the Manager

**Import Mods:**
- 🖱️ Drag & Drop mod folders into the window
- ⌨️ Copy folder path and press Ctrl+V
- 📂 Click "+" card to use file picker

**Activate Mods:**
- 👆 Click a mod card to toggle it on/off
- ✓ Active mods show with a checkmark
- 🔄 F10 sent automatically (if configured)

**Organize:**
- 🎭 Click character avatars to filter
- 🏷️ Auto-tagging detects characters from folder names
- 📊 See mod status at a glance

---

## ⚡ F10 Auto-Reload Setup

Never manually press F10 again! The app can automatically send F10 to the game.

### One-Time Setup (2 minutes):

**Wayland Users:**
```bash
sudo pacman -S ydotool wmctrl xdotool
sudo usermod -a -G input $USER
sudo systemctl enable --now ydotool.service
sudo reboot
```

**X11 Users:**
```bash
sudo pacman -S xdotool wmctrl
```

### How It Works:

**Method 1: Alt+Tab Workflow** ⭐
```
1. Launch Zenless Zone Zero
2. Alt+Tab to mod manager
3. Activate a mod
4. Alt+Tab back to game
5. F10 sent automatically! ✅
```

**Method 2: Dual Monitor** 🖥️🖥️
```
Game visible on Monitor 1
Mod Manager on Monitor 2
Activate mods = Instant reload! ✅
```

---

## 🎨 Interface Highlights

- **Modern Material Design 3** - Clean, beautiful, responsive
- **Character Cards** - Visual organization with portraits
- **Mod Cards** - Clear status indicators and controls
- **Settings Panel** - Easy configuration access
- **Theme Toggle** - Dark/Light/Auto modes
- **Smooth Animations** - Polished user experience

---

## 🔧 Technical Details

**Built With:**
- Flutter 3.8.1+ - Cross-platform framework
- Dart - Modern programming language
- GTK 3 - Native Linux integration

**Features:**
- Symbolic link management
- Window state persistence
- JSON configuration
- Process detection (for F10 feature)
- Cross-desktop compatibility (X11/Wayland)

---

## 🤝 Support & Community

**Need Help?**
- 🐛 [Report Issues](https://github.com/NotionMe/Mod-manager/issues)
- 💬 [Discussions](https://github.com/NotionMe/Mod-manager/discussions)
- 📖 [Full Documentation](https://github.com/NotionMe/Mod-manager/blob/main/README.md)

**Links:**
- 🔗 [GitHub Repository](https://github.com/NotionMe/Mod-manager)
- 📦 [AUR Package](https://aur.archlinux.org/packages/zzz-mod-manager-git)
- 📧 Email: c.ubohyi.stanislav@student.uzhnu.edu.ua

---

## 🛡️ Safety & Security

- ✅ **Open Source** - Full transparency, inspect the code
- ✅ **No Telemetry** - Your privacy is respected
- ✅ **Local Only** - No internet required after installation
- ✅ **Reversible** - All operations can be undone
- ✅ **Safe Links** - Original mod files never modified

---

## 📋 Requirements

- **OS**: Linux (Arch, Ubuntu, Fedora, etc.)
- **Desktop**: X11 or Wayland
- **Dependencies**: GTK3, GLib2, libX11
- **Game**: Zenless Zone Zero with 3DMigoto/XXMI
- **Disk Space**: ~50MB for the app

---

## 🎁 What's Included

- ✨ Full-featured mod manager application
- 🖼️ 38 character portrait assets
- 🌍 English and Ukrainian translations
- 📚 Comprehensive documentation
- 🔧 F10 auto-reload scripts
- 💻 Native Linux integration

---

## 🚀 Why This Matters

Managing mods shouldn't be a chore. This tool gives you:

- **More time gaming** - Less time managing files
- **Better organization** - Know what's active instantly
- **Disk space savings** - No duplicate files
- **Peace of mind** - Safe, reversible operations
- **Modern UX** - Beautiful, intuitive interface

---

## 📈 Roadmap

Future plans include:
- 🪟 Windows support (in progress!)
- 🔍 Search and filter improvements
- 📦 Mod preset/collection system
- 🖼️ In-app mod preview images
- 🌐 More language support
- ☁️ Optional cloud sync

---

## ⭐ Show Your Support

If you find this tool useful:
- ⭐ Star the [GitHub repo](https://github.com/NotionMe/Mod-manager)
- 📢 Share with other ZZZ modders
- 🐛 Report bugs and suggest features
- 🤝 Contribute to development

---

## 📜 License

MIT License - Free and open source!

---

<div align="center">

### 🎮 Ready to revolutionize your ZZZ modding experience?

**Download now and start managing mods the smart way!**

[⬇️ Download Latest Release](https://github.com/NotionMe/Mod-manager/releases) | [📖 Read Full Docs](https://github.com/NotionMe/Mod-manager) | [🐛 Report Issue](https://github.com/NotionMe/Mod-manager/issues)

---

**Made with ❤️ for the Zenless Zone Zero community**

*Happy Modding!* 🎉

</div>
