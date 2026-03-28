#!/usr/bin/env bash
# ========================================
#   Watch Drift Recorder - Install / Uninstall
# ========================================

if [[ "$1" == "--uninstall" ]]; then
    echo "========================================"
    echo "   Uninstalling Watch Drift Recorder..."
    echo "========================================"

    rm -rf ~/WatchDrift-App
    rm -f ~/Desktop/WatchDrift.desktop

    echo "✅ Uninstallation complete."
    echo "All files and desktop shortcut have been removed."
    exit 0
fi

# ====================== NORMAL INSTALLATION ======================
echo "========================================"
echo "   Watch Drift Recorder - Universal Installer"
echo "========================================"

echo "Detecting your Linux distribution..."

if [ -f /etc/os-release ]; then
    . /etc/os-release
fi

# Install system dependencies
if [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID_LIKE" == *"ubuntu"* || "$ID_LIKE" == *"debian"* ]]; then
    echo "→ Ubuntu/Debian/Kubuntu detected"
    sudo apt update -y
    sudo apt install -y python3 python3-venv python3-pip python3-tk wget
elif [[ "$ID" == "manjaro" || "$ID" == "arch" || "$ID_LIKE" == *"arch"* ]]; then
    echo "→ Manjaro/Arch detected"
    sudo pacman -Sy --noconfirm tk python-tk wget
else
    echo "→ Unknown distro. Trying common packages..."
    sudo apt install -y python3 python3-venv python3-pip python3-tk wget 2>/dev/null || \
    sudo pacman -Sy --noconfirm tk python-tk wget 2>/dev/null || true
fi

mkdir -p ~/WatchDrift-App
cd ~/WatchDrift-App

echo "→ Creating virtual environment..."
python3 -m venv venv
. venv/bin/activate

echo "→ Installing Python packages..."
pip install --upgrade pip
pip install customtkinter ntplib pillow pyinstaller

echo "→ Downloading the app..."
wget -q -O watch_drift_gui.py https://raw.githubusercontent.com/AvielMer/watch-drift/main/watch_drift_gui.py

echo "→ Downloading icon..."
wget -q -O watch_icon.png https://i.imgur.com/8vK7Z8P.png

echo "→ Building executable..."
pyinstaller --onefile --windowed --name "WatchDrift" --icon=watch_icon.png watch_drift_gui.py

cp dist/WatchDrift . 2>/dev/null || true
chmod +x WatchDrift

echo "→ Creating desktop shortcut..."
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
echo "✅ SUCCESS! Installation Complete!"
echo "You can now run the app from your desktop."
echo ""
read -p "Press any key to close..."
