
#!/bin/bash
echo "========================================"
echo "   Watch Drift Recorder - One Click Installer"
echo "========================================"

# Create folder
mkdir -p ~/WatchDrift-App
cd ~/WatchDrift-App

echo "Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

echo "Installing dependencies..."
pip install --upgrade pip
pip install customtkinter ntplib pillow pyinstaller

echo "Downloading the app code..."
cat > watch_drift_gui.py << 'EOL'
#!/usr/bin/env python3
"""
Watch Drift Recorder - Full GUI for Kubuntu
+ Button to manually sync PC to NTP
"""

import customtkinter as ctk
from tkinter import messagebox
import json
import time
import threading
from datetime import datetime
from pathlib import Path

try:
    import ntplib
except ImportError:
    ntplib = None

ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("dark-blue")

DATA_FILE = Path.home() / ".watch_drift.json"

def load_data():
    if DATA_FILE.exists():
        try:
            with open(DATA_FILE) as f:
                data = json.load(f)
                for r in data.get("readings", []):
                    if "ntpSeconds" not in r: r["ntpSeconds"] = 0
                    if "minuteAdjust" not in r: r["minuteAdjust"] = 0
                    if "totalOffsetSec" not in r: r["totalOffsetSec"] = 0
                return data
        except Exception:
            pass
    return {"watches": [], "readings": []}

def save_data(data):
    with open(DATA_FILE, "w") as f:
        json.dump(data, f, indent=2)

# NTP
ntp_offset = 0.0
def sync_ntp():
    global ntp_offset
    if ntplib:
        try:
            c = ntplib.NTPClient()
            r = c.request("pool.ntp.org", version=3)
            ntp_offset = r.offset
            return True
        except:
            return False
    return False

def ntp_now():
    return time.time() + ntp_offset

def raw_deviation(ntp_seconds):
    s = int(ntp_seconds) % 60
    return s if s <= 30 else s - 60

def total_deviation(ntp_seconds, minute_adjust):
    return raw_deviation(ntp_seconds) + minute_adjust * 60

def fmt_deviation(sec):
    sign = "+" if sec >= 0 else "−"
    a = abs(sec)
    if a == 0: return "0.00s EXACT"
    if a < 60: return f"{sign}{a:.1f}s"
    m, s = divmod(a, 60)
    return f"{sign}{int(m)}m {s:.0f}s"

def direction(sec):
    if sec == 0: return "exact"
    return "SLOW" if sec > 0 else "FAST"

def drift_per_day(readings):
    if len(readings) < 2: return None
    srt = sorted(readings, key=lambda r: r["ts"])
    days = (srt[-1]["ts"] - srt[0]["ts"]) / 86400
    if days < 0.001: return None
    return (srt[-1]["totalOffsetSec"] - srt[0]["totalOffsetSec"]) / days

def fmt_ts(ts):
    return datetime.fromtimestamp(ts).strftime("%Y-%m-%d %H:%M")

class WatchDriftApp(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("Watch Drift Recorder")
        self.geometry("1280x760")
        self.minsize(1150, 680)

        self.data = load_data()
        self.selected_id = None
        self.minute_adjust = 0
        self.show_progress_bar = False   # unchecked by default

        threading.Thread(target=sync_ntp, daemon=True).start()
        self.build_ui()

    def build_ui(self):
        sidebar = ctk.CTkFrame(self, width=260, corner_radius=0)
        sidebar.pack(side="left", fill="y")

        ctk.CTkLabel(sidebar, text="WATCHES", font=ctk.CTkFont(size=18, weight="bold")).pack(pady=20)

        self.watch_list = ctk.CTkScrollableFrame(sidebar)
        self.watch_list.pack(fill="both", expand=True, padx=15, pady=10)

        ctk.CTkButton(sidebar, text="+ Add New Watch", command=self.add_watch).pack(pady=10, padx=20)

        self.main = ctk.CTkFrame(self)
        self.main.pack(side="right", fill="both", expand=True, padx=20, pady=20)

        # Top bar
        top_bar = ctk.CTkFrame(self.main, height=40)
        top_bar.pack(fill="x", pady=5)

        self.selected_label = ctk.CTkLabel(top_bar, text="No watch selected", 
                                           font=ctk.CTkFont(size=16, weight="bold"))
        self.selected_label.pack(side="left", padx=20)

        # PC Drift + Sync button
        pc_frame = ctk.CTkFrame(top_bar)
        pc_frame.pack(side="right", padx=20)

        self.pc_drift_label = ctk.CTkLabel(pc_frame, text="PC Clock: 0 ms", 
                                           font=ctk.CTkFont(size=14), text_color="#6ec88a")
        self.pc_drift_label.pack(side="left", padx=8)
        self.update_pc_drift()

        ctk.CTkButton(pc_frame, text="↻ Sync PC to NTP", width=140, 
                      command=self.force_ntp_sync).pack(side="left", padx=8)

        # Tabs
        self.tabview = ctk.CTkTabview(self.main)
        self.tabview.pack(fill="both", expand=True, padx=10, pady=10)

        self.tabview.add("Record")
        self.tabview.add("Log")
        self.tabview.add("Trend")

        self.build_record_tab()
        self.build_log_tab()
        self.build_trend_tab()

        self.refresh_watch_list()

    def force_ntp_sync(self):
        success = sync_ntp()
        if success:
            self.pc_drift_label.configure(text_color="#6ec88a")
            messagebox.showinfo("Success", "PC successfully synced to NTP!")
        else:
            self.pc_drift_label.configure(text_color="#c06060")
            messagebox.showwarning("NTP Sync", "Could not reach NTP server.\nUsing system time.")

    def update_pc_drift(self):
        drift_ms = int(-ntp_offset * 1000)
        sign = "+" if drift_ms >= 0 else ""
        self.pc_drift_label.configure(text=f"PC Clock: {sign}{drift_ms} ms")
        self.after(500, self.update_pc_drift)

    # The rest of the code (record, log, trend) is unchanged
    def refresh_watch_list(self):
        for widget in self.watch_list.winfo_children():
            widget.destroy()
        for w in self.data["watches"]:
            frame = ctk.CTkFrame(self.watch_list)
            frame.pack(fill="x", padx=8, pady=4)
            btn = ctk.CTkButton(frame, text=w["name"], anchor="w",
                                command=lambda wid=w["id"]: self.select_watch(wid))
            btn.pack(side="left", fill="x", expand=True)
            del_btn = ctk.CTkButton(frame, text="✕", width=30, fg_color="#c06060",
                                    command=lambda wid=w["id"]: self.delete_watch(wid))
            del_btn.pack(side="right", padx=5)

    def add_watch(self):
        dialog = ctk.CTkInputDialog(title="New Watch", text="Enter watch name:")
        name = dialog.get_input()
        if name and name.strip():
            wid = str(int(time.time() * 1000))
            self.data["watches"].append({"id": wid, "name": name.strip(), "minuteAdjust": 0})
            save_data(self.data)
            self.refresh_watch_list()

    def delete_watch(self, wid):
        if messagebox.askyesno("Confirm", "Delete this watch and ALL recordings?"):
            self.data["watches"] = [w for w in self.data["watches"] if w["id"] != wid]
            self.data["readings"] = [r for r in self.data["readings"] if r["watchId"] != wid]
            save_data(self.data)
            if self.selected_id == wid:
                self.selected_id = None
            self.refresh_watch_list()
            self.build_log_tab()
            self.build_trend_tab()

    def select_watch(self, wid):
        self.selected_id = wid
        name = next((w["name"] for w in self.data["watches"] if w["id"] == wid), "Unknown")
        self.selected_label.configure(text=f"Selected: {name}")
        self.build_record_tab()
        self.build_log_tab()
        self.build_trend_tab()

    def build_record_tab(self):
        tab = self.tabview.tab("Record")
        for widget in tab.winfo_children():
            widget.destroy()

        ctk.CTkLabel(tab, text="Live NTP Time", font=ctk.CTkFont(size=14)).pack(pady=5)
        self.clock_label = ctk.CTkLabel(tab, text="--:--:--", font=ctk.CTkFont(size=36))
        self.clock_label.pack(pady=10)
        self.update_clock()

        self.progress_var = ctk.BooleanVar(value=False)
        ctk.CTkCheckBox(tab, text="Show 1-second progress bar (helps sync)", 
                        variable=self.progress_var, command=self.toggle_progress_bar).pack(pady=8)

        self.progress_canvas = ctk.CTkCanvas(tab, height=30, bg="#1a1a1a", highlightthickness=0)
        self.progress_canvas.pack(fill="x", padx=40, pady=5)

        self.record_btn = ctk.CTkButton(tab, text="RECORD WHEN WATCH SHOWS :00", 
                                       height=70, font=ctk.CTkFont(size=18),
                                       command=self.record_drift)
        self.record_btn.pack(pady=30, padx=40, fill="x")

        self.status_label = ctk.CTkLabel(tab, text="Press the button above", font=ctk.CTkFont(size=14))
        self.status_label.pack(pady=10)

        frame = ctk.CTkFrame(tab)
        frame.pack(pady=20)
        ctk.CTkButton(frame, text="−1 min", width=100, command=self.minus_min).pack(side="left", padx=10)
        self.adj_label = ctk.CTkLabel(frame, text="0 min", font=ctk.CTkFont(size=18))
        self.adj_label.pack(side="left", padx=30)
        ctk.CTkButton(frame, text="+1 min", width=100, command=self.plus_min).pack(side="left", padx=10)

        self.draw_progress_bar()

    def toggle_progress_bar(self):
        self.draw_progress_bar()

    def draw_progress_bar(self):
        self.progress_canvas.delete("all")
        if not self.progress_var.get():
            return
        now = ntp_now()
        ms = int((now % 1) * 1000)
        progress = ms / 1000.0
        w = self.progress_canvas.winfo_width() or 800
        fill_width = int(w * progress)
        self.progress_canvas.create_rectangle(0, 0, w, 30, fill="#2a2a2a", outline="")
        self.progress_canvas.create_rectangle(0, 0, fill_width, 30, fill="#c8a96e", outline="")
        self.progress_canvas.create_rectangle(0, 0, w, 30, outline="#555", width=2)
        self.after(30, self.draw_progress_bar)

    def update_clock(self):
        now = datetime.fromtimestamp(ntp_now())
        self.clock_label.configure(text=now.strftime("%H:%M:%S"))
        self.after(200, self.update_clock)

    def plus_min(self):
        self.minute_adjust += 1
        self.adj_label.configure(text=f"{self.minute_adjust:+d} min")

    def minus_min(self):
        self.minute_adjust -= 1
        self.adj_label.configure(text=f"{self.minute_adjust:+d} min")

    def record_drift(self):
        if not self.selected_id:
            self.status_label.configure(text="Please select a watch first", text_color="red")
            return

        t_ms = ntp_now()
        ntp_s = int(t_ms) % 60
        rs = [r for r in self.data["readings"] if r["watchId"] == self.selected_id]
        is_first = len(rs) == 0

        if is_first:
            total = 0
            msg = f"✓ FIRST RECORDING → 0 drift baseline"
            self.minute_adjust = 0
        else:
            raw = raw_deviation(ntp_s)
            total = total_deviation(ntp_s, self.minute_adjust)
            msg = f"✓ Recorded {fmt_deviation(total)} ({direction(total)})"

        reading = {
            "id": str(int(t_ms)), "watchId": self.selected_id, "ts": t_ms,
            "ntpSeconds": ntp_s, "minuteAdjust": self.minute_adjust,
            "totalOffsetSec": total
        }
        self.data["readings"].append(reading)
        save_data(self.data)

        self.status_label.configure(text=msg, text_color="green")
        self.after(3000, lambda: self.status_label.configure(text="Ready", text_color="white"))

        self.build_log_tab()
        self.build_trend_tab()

    # Log Tab, Trend Tab, delete/clear functions remain the same as previous version
    def build_log_tab(self):
        tab = self.tabview.tab("Log")
        for widget in tab.winfo_children():
            widget.destroy()
        if not self.selected_id:
            ctk.CTkLabel(tab, text="Select a watch to see log").pack(pady=100)
            return
        w = next((w for w in self.data["watches"] if w["id"] == self.selected_id), None)
        rs = [r for r in self.data["readings"] if r["watchId"] == self.selected_id]
        ctk.CTkLabel(tab, text=f"{w['name']} — {len(rs)} recordings", font=ctk.CTkFont(size=16, weight="bold")).pack(pady=10)
        ctk.CTkButton(tab, text="🗑 Clear Entire Log", fg_color="#c06060", command=self.clear_log).pack(pady=5)
        scroll = ctk.CTkScrollableFrame(tab)
        scroll.pack(fill="both", expand=True, padx=10, pady=10)
        for r in sorted(rs, key=lambda x: x["ts"], reverse=True):
            frame = ctk.CTkFrame(scroll)
            frame.pack(fill="x", pady=2, padx=5)
            total = r.get("totalOffsetSec", 0)
            line = f"{fmt_ts(r['ts'])}   NTP:{r.get('ntpSeconds',0):02d}   {fmt_deviation(total)} {direction(total)}"
            ctk.CTkLabel(frame, text=line, anchor="w").pack(side="left", padx=10, fill="x", expand=True)
            ctk.CTkButton(frame, text="✕", width=30, fg_color="#c06060",
                          command=lambda rid=r["id"]: self.delete_single_recording(rid)).pack(side="right", padx=5)

    def delete_single_recording(self, rid):
        self.data["readings"] = [r for r in self.data["readings"] if r["id"] != rid]
        save_data(self.data)
        self.build_log_tab()
        self.build_trend_tab()

    def clear_log(self):
        if self.selected_id and messagebox.askyesno("Clear Log", "Delete ALL recordings for this watch?"):
            self.data["readings"] = [r for r in self.data["readings"] if r["watchId"] != self.selected_id]
            save_data(self.data)
            self.build_log_tab()
            self.build_trend_tab()

    def build_trend_tab(self):
        tab = self.tabview.tab("Trend")
        for widget in tab.winfo_children():
            widget.destroy()
        if not self.selected_id:
            ctk.CTkLabel(tab, text="Select a watch to see trend").pack(pady=100)
            return
        rs = sorted([r for r in self.data["readings"] if r["watchId"] == self.selected_id], key=lambda r: r["ts"])
        if len(rs) < 2:
            ctk.CTkLabel(tab, text="Need at least 2 recordings for trend").pack(pady=100)
            return

        first = rs[0]
        last = rs[-1]
        total_drift = last.get("totalOffsetSec", 0) - first.get("totalOffsetSec", 0)
        days = (last["ts"] - first["ts"]) / 86400
        rate = drift_per_day(rs)

        summary = ctk.CTkFrame(tab)
        summary.pack(fill="x", padx=30, pady=15)
        ctk.CTkLabel(summary, text="SUMMARY", font=ctk.CTkFont(size=14, weight="bold")).pack(pady=5)
        ctk.CTkLabel(summary, text=f"Accumulative Drift:   {fmt_deviation(total_drift)}", font=ctk.CTkFont(size=18)).pack(pady=2)
        ctk.CTkLabel(summary, text=f"Daily Drift Rate:      {fmt_deviation(rate) if rate else '—'}", font=ctk.CTkFont(size=18)).pack(pady=2)
        ctk.CTkLabel(summary, text=f"Measured over:         {days:.1f} days", font=ctk.CTkFont(size=14)).pack(pady=2)

        canvas = ctk.CTkCanvas(tab, height=280, bg="#1a1a1a", highlightthickness=0)
        canvas.pack(fill="both", expand=True, padx=40, pady=10)

        vals = [r.get("totalOffsetSec", 0) for r in rs]
        lo, hi = min(vals), max(vals)
        span = hi - lo if hi != lo else 1
        w = 820
        h = 220

        for v in range(int(lo)-60, int(hi)+61, 60):
            y = 30 + int(h - ((v - lo) / span) * h)
            canvas.create_line(45, y, 50 + w, y, fill="#333", dash=(3,3))
            canvas.create_text(38, y, text=fmt_deviation(v), fill="#aaa", anchor="e", font=("Courier", 10))

        if lo < 0 < hi:
            zero_y = 30 + int(h - ((0 - lo) / span) * h)
            canvas.create_line(50, zero_y, 50 + w, zero_y, fill="#666", width=2)

        points = []
        for i, v in enumerate(vals):
            x = 50 + int((i / (len(vals)-1)) * w)
            y = 30 + int(h - ((v - lo) / span) * h)
            points.append((x, y))
            canvas.create_oval(x-4, y-4, x+4, y+4, fill="#c8a96e")

        for i in range(len(points)-1):
            canvas.create_line(points[i][0], points[i][1], points[i+1][0], points[i+1][1], fill="#c8a96e", width=3)

        canvas.create_text(50, h + 45, text="oldest", fill="#888", font=("Courier", 11))
        canvas.create_text(50 + w, h + 45, text="latest", fill="#888", font=("Courier", 11), anchor="e")

if __name__ == "__main__":
    app = WatchDriftApp()
    app.mainloop()
EOL

echo "Building executable..."
pyinstaller --onefile --windowed --name "WatchDrift" --icon=watch_icon.png watch_drift_gui.py 2>/dev/null || pyinstaller --onefile --windowed --name "WatchDrift" watch_drift_gui.py

echo "Downloading icon..."
wget -q -O watch_icon.png https://i.imgur.com/8vK7Z8P.png

cp dist/WatchDrift . 2>/dev/null || true
chmod +x WatchDrift

echo "Creating desktop shortcut..."
cat > ~/Desktop/WatchDrift.desktop << EOF
[Desktop Entry]
Name=Watch Drift Recorder
Exec=$(pwd)/WatchDrift
Icon=$(pwd)/watch_icon.png
Type=Application
Categories=Utility;
Terminal=false
EOF

chmod +x ~/Desktop/WatchDrift.desktop

echo ""
echo "✅ Installation Complete!"
echo "You can now run the app from your desktop."
echo ""
read -p "Press any key to close..."
