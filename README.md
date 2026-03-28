# ⌚ Watch Drift Recorder

A clean and modern GUI tool for accurately measuring mechanical watch drift over days, weeks, or months.

## ✨ Features

- **🟢 Automatic baseline** — Your first recording is set as 0 drift automatically.
- **📈 Cumulative drift tracking** — Track drift over time — from seconds to days.
- **🌐 Live NTP time** — Uses network time (not your PC clock) for high accuracy.
- **🖥️ PC clock drift display** — See how your system time compares to real time.
- **⏱️ Optional 1-second progress bar** — Visual second-by-second tracking.
- **📊 Full log + trend graph** — View real drift values over time.
- **⌚ Multi-watch support** — Add or remove multiple watches.
- **🧹 Flexible data management** — Delete individual entries or clear all recordings.

## 🚀 Quick Start

### One-Click Installation (Recommended)

```bash
wget https://raw.githubusercontent.com/AvielMer/watch-drift/main/install-watchdrift.sh
chmod +x install-watchdrift.sh
./install-watchdrift.sh
```
### Uninstall
**To completely remove the app and desktop shortcut, run:**
```bash
Bash~/WatchDrift-App/install-watchdrift.sh --uninstall
```

### Manual Installation

```bash
git clone https://github.com/AvielMer/watch-drift.git
cd watch-drift

python3 -m venv venv
source venv/bin/activate

pip install -r requirements.txt
python watch_drift_gui.py
```



Made with ❤️ for watch enthusiasts who care about precision.
