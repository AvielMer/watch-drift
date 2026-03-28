# ⌚ Watch Drift Recorder

A clean and modern GUI tool for accurately measuring mechanical watch drift over days, weeks, or months. **Production-ready** with professional Linux integration.

## ✨ Features

- **🟢 Automatic baseline** — Your first recording is set as 0 drift automatically.
- **📈 Cumulative drift tracking** — Track drift over time — from seconds to days.
- **🌐 Live NTP time** — Uses network time (not your PC clock) for high accuracy.
- **🖥️ PC clock drift display** — See how your system time compares to real time.
- **⏱️ Optional 1-second progress bar** — Visual second-by-second tracking.
- **📊 Full log + trend graph** — View real drift values over time.
- **⌚ Multi-watch support** — Add or remove multiple watches.
- **🧹 Flexible data management** — Delete individual entries or clear all recordings.
- **💾 Atomic data saves** — Your data survives crashes (no corruption).
- **🎯 XDG-compliant** — Respects Linux standards (`~/.config/watchdrift/`).
- **📺 High-DPI support** — Works perfectly on 4K screens.
- **⚡ Non-blocking NTP sync** — UI stays responsive during network operations.

## 🚀 Quick Start

### ✅ One-Click Installation (Recommended)

Works on **Kubuntu, Ubuntu, Debian, Arch, Fedora, openSUSE** and most Linux distros.

```bash
wget https://raw.githubusercontent.com/AvielMer/watch-drift/main/install-watchdrift.sh
chmod +x install-watchdrift.sh
./install-watchdrift.sh
```

The app will be installed to `~/.local/share/WatchDrift/` and available in your application menu.

### 🗑️ Uninstall

```bash
bash install-watchdrift.sh --uninstall
```

This removes all app files and desktop shortcuts.

### 📖 Manual Installation

For development or running directly from source:

```bash
git clone https://github.com/AvielMer/watch-drift.git
cd watch-drift

python3 -m venv venv
source venv/bin/activate

pip install customtkinter ntplib pillow

# Run directly (no PyInstaller build)
python watch_drift_gui.py
```

## 🔧 Technical Details

### Data Storage

- **Location:** `~/.config/watchdrift/watch_data.json` (XDG-compliant)
- **Format:** Human-readable JSON with watch records
- **Safety:** Atomic writes prevent data corruption on crashes

### System Requirements

- Python 3.7+
- `python3-tk` or `python3-tkinter`
- Network connection for NTP synchronization

### Distro Support

| Distro | Package Manager | Status |
|--------|-----------------|--------|
| Ubuntu 24.04+ | apt | ✅ Full support (PEP 668 compliant) |
| Kubuntu | apt | ✅ Full support |
| Debian | apt | ✅ Full support |
| Arch Linux | pacman | ✅ Full support |
| Manjaro | pacman | ✅ Full support |
| Fedora | dnf | ✅ Full support |
| openSUSE | zypper | ✅ Full support |

### Virtual Environment

The installer creates a hidden virtual environment at `~/.local/share/WatchDrift/venv/`. This:

- ✅ Keeps your system Python clean
- ✅ Complies with PEP 668 (prevents "externally-managed-environment" errors)
- ✅ Isolates dependencies from other Python apps
- ✅ Is completely transparent to the user

## 🎯 Usage

1. Install via the one-click installer above
2. Search for "Watch Drift" in your application menu (or use `WatchDrift` command)
3. Add watches by clicking "+ Add New Watch"
4. Record when your watch shows exactly :00 seconds
5. View trends to see drift patterns over time

### 📋 Keyboard/UI

| Action | How |
|--------|-----|
| Add watch | Click "+ Add New Watch" button |
| Record drift | Click "RECORD WHEN WATCH SHOWS :00" |
| Fine-tune | Use "-1 min" / "+1 min" buttons |
| Sync PC | Click "↻ Sync PC to NTP" |
| Delete recording | Click "✕" next to an entry in Log tab |

## 🛠️ Development

### Building a Standalone Executable

```bash
cd ~/.local/share/WatchDrift
source venv/bin/activate
pyinstaller --onefile --windowed --name WatchDrift --icon=watch_icon.png watch_drift_gui.py
```

Output binary: `dist/WatchDrift`

### Code Structure

- `watch_drift_gui.py` — Main GUI application (401 lines)
- `install-watchdrift.sh` — Professional installer script
- `watch_data.json` — User data file (auto-created)

## 🐛 Troubleshooting

### "Externally managed environment" error

This should NOT happen with the provided installer (it uses a venv). If you're installing manually:

```bash
python3 -m venv venv
source venv/bin/activate
pip install customtkinter ntplib pillow
```

### NTP sync fails

- Check your internet connection
- Ensure ntplib is installed: `pip install ntplib`
- Try manually: `python -c "import ntplib; c = ntplib.NTPClient(); print(c.request('pool.ntp.org'))"

### GUI looks blurry on 4K

Edit `watch_drift_gui.py` line 17:

```python
ctk.set_widget_scaling(1.2)  # Increase from 1.0 to 1.1-1.5
```

### Data file not found

The app auto-creates `~/.config/watchdrift/watch_data.json` on first run. If missing:

```bash
mkdir -p ~/.config/watchdrift
```

## 📝 License

Made with ❤️ for watch enthusiasts who care about precision.

## 🔗 Links

- **GitHub:** https://github.com/AvielMer/watch-drift
- **Issues:** https://github.com/AvielMer/watch-drift/issues
- **Releases:** https://github.com/AvielMer/watch-drift/releases