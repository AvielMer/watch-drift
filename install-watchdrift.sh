#!/usr/bin/env bash
echo "========================================"
echo "   Watch Drift Recorder - Universal Installer"
echo "========================================"

# Detect distro
if [ -f /etc/os-release ]; then
    . /etc/os-release
fi

echo "→ Detected: $NAME $VERSION_ID"

# Install system dependencies based on distro
if [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID_LIKE" == *"ubuntu"* || "$ID_LIKE" == *"debian"* ]]; then
    echo "→ Installing packages for Ubuntu/Debian/Kubuntu..."
    sudo apt update -y
    sudo apt install -y python3 python3-venv python3-pip python3-tk wget
elif [[ "$ID" == "manjaro" || "$ID" == "arch" || "$ID_LIKE" == *"arch"* ]]; then
    echo "→ Installing packages for Manjaro/Arch..."
    sudo pacman -Sy --noconfirm python python-pip python-venv tk wget
else
    echo "→ Unknown distro. Trying common packages..."
    sudo apt install -y python3 python3-venv python3-pip python3-tk wget 2>/dev/null || \
    sudo pacman -Sy --noconfirm python python-pip python-venv tk wget 2>/dev/null || \
    echo "Warning: Could not auto-install system packages. Please install python3-venv manually."
fi

# Create folder
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
