# DirLock

A macOS menu bar app that locks/unlocks directories with one click, preventing AI tools, scripts, or other apps from reading your sensitive files.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5-orange) ![License](https://img.shields.io/badge/license-MIT-green)

---

## Features

- **Lock directories instantly** — sets permissions to `000`, blocking all reads and writes system-wide
- **Unlock and restore** — restores original permissions automatically
- **Manage multiple directories** — Lock All / Unlock All in one click
- **Drag & drop** — drag a folder directly onto the window to add it
- **Persistent state** — locked directories stay locked across reboots
- **Menu bar + main window** — lives in the menu bar, also accessible from the Dock

---

## Download

Grab the latest `DirLock.zip` from the [Releases](../../releases) page, unzip, and drag `DirLock.app` to `/Applications`.

**First launch:** right-click `DirLock.app` → **Open** → **Open** (required once to bypass Gatekeeper, since the app is unsigned)

---

## Build from Source

Requires macOS 13+ and Xcode Command Line Tools:

```bash
xcode-select --install
```

```bash
git clone https://github.com/HoKei2001/DirLock-macOS.git
cd DirLock-macOS
bash build.sh
cp -r .build/DirLock.app /Applications/
open /Applications/DirLock.app
```

---

## Usage

1. Click the lock icon in the menu bar (or open from Dock) to show the directory list
2. Click **Add Directory...** or drag a folder into the window
3. Click **Lock** on any directory — the icon turns red and access is blocked
4. Click **Unlock** to restore access

**Lock All / Unlock All** buttons apply to all managed directories at once.

### Launch at Login

System Settings → General → Login Items → click `+` → select `DirLock.app`

---

## How It Works

DirLock uses Unix permission bits — no third-party libraries, no kernel extensions:

```bash
# Lock: remove all permissions
chmod 000 /path/to/dir

# Unlock: restore original permissions
chmod 755 /path/to/dir   # (original permissions saved before locking)
```

- Works system-wide — any app, terminal script, or AI tool is blocked
- No `sudo` required — only works on directories you own
- Original permissions are saved and restored exactly on unlock

---

## Notes

| Situation | Details |
|-----------|---------|
| Forgot to unlock before shutdown | Locked state persists across reboots — open DirLock and unlock manually |
| Directory no longer exists | Shown with ⚠️ warning, other directories unaffected |
| Locking your home directory | Not recommended — you'll lose access to your own files |

---

## Project Structure

```
DirLock/
├── App/
│   ├── main.swift              # Entry point
│   └── AppDelegate.swift       # Menu bar + window management
├── Models/
│   ├── DirectoryItem.swift     # Data model
│   └── DirectoryStore.swift    # State management + UserDefaults persistence
├── Services/
│   └── ACLService.swift        # chmod wrapper
└── Views/
    ├── DirectoryListView.swift  # Main SwiftUI view
    ├── AddDirectoryView.swift   # NSOpenPanel wrapper
    └── AppPanel.swift           # Floating panel
scripts/
└── gen_icon.swift              # Icon generator (Core Graphics)
build.sh                        # Build script (no Xcode required)
```

---

## License

MIT
