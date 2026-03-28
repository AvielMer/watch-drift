# Watch Drift Recorder

A clean, modern GUI tool to accurately measure **mechanical watch drift** over days, weeks or months.

**Features:**
- First recording = automatic 0 drift baseline
- Cumulative drift tracking (any size)
- Live NTP time (ignores your PC clock)
- PC Clock drift display
- 1-second progress bar (optional)
- Full Log + Trend graph with real numbers
- Add / remove watches
- Delete or clear recordings

## One-Click Installation (Recommended)

```bash
wget https://raw.githubusercontent.com/AvielMer/watch-drift/main/install-watchdrift.sh
chmod +x install-watchdrift.sh
./install-watchdrift.sh


**Manual Installation:**
Bashgit clone https://github.com/AvielMer/watch-drift.git
cd watch-drift
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python watch_drift_gui.py
Made with ❤️ for watch enthusiasts.
