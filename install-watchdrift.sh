#!/usr/bin/env bash
# Watch Drift Recorder - Professional Installer
# Works on Kubuntu, Ubuntu 24.04+, Arch, Manjaro, and more
# Fixed for systems where ensurepip fails

# ============= CONFIGURATION =============
APP_NAME="WatchDrift"
SHARE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
APP_DIR="$SHARE_DIR/$APP_NAME"
BIN_PATH="$BIN_DIR/$APP_NAME"
DESKTOP_FILE="$HOME/.local/share/applications/$APP_NAME.desktop"
OLD_APP_DIR="$HOME/WatchDrift-App"
GITHUB_RAW="https://raw.githubusercontent.com/AvielMer/watch-drift/main"

# ============= UNINSTALL =============
if [[ "$1" == "--uninstall" ]]; then
    echo "========================================"
    echo "   Uninstalling $APP_NAME..."
    echo "========================================"
    
    rm -rf "$APP_DIR" "$OLD_APP_DIR"
    rm -f "$BIN_PATH" "$DESKTOP_FILE" "$HOME/Desktop/$APP_NAME.desktop"
    update-desktop-database ~/.local/share/applications 2>/dev/null || true
    
    echo "✅ Uninstallation complete."
    exit 0
fi

# ============= INSTALLATION =============
set -e

echo "========================================"
echo "   $APP_NAME - Professional Installer"
echo "========================================"
echo ""

if [ -f /etc/os-release ]; then
    . /etc/os-release
else
    echo "❌ Could not detect OS."
    exit 1
fi

echo "📦 Detected: $ID (version $VERSION_ID)"

# Install dependencies based on distro
echo "→ Installing system dependencies..."
case "$ID" in
    ubuntu|kubuntu|debian|pop|mint|linuxmint)
        sudo apt-get update -qq
        sudo apt-get install -y \
            python3 python3-venv python3-tk python3-dev python3-pip \
            wget binutils build-essential
        ;;
    arch|manjaro)
        sudo pacman -S --noconfirm \
            python python-pip tk wget base-devel
        ;;
    fedora)
        sudo dnf install -y \
            python3 python3-venv python3-tkinter python3-devel python3-pip \
            wget gcc
        ;;
    opensuse*|suse)
        sudo zypper install -y \
            python3 python3-venv python3-tk python3-devel python3-pip \
            wget gcc
        ;;
    *)
        echo "⚠️  Unknown distro: $ID"
        echo "Installing with apt/pacman..."
        sudo apt-get install -y python3 python3-venv python3-pip python3-tk wget 2>/dev/null || \
        sudo pacman -S --noconfirm python python-pip tk wget 2>/dev/null || \
        echo "❌ Please manually install: python3, python3-pip, python3-tk, wget"
        exit 1
        ;;
esac

# Create directories
echo "→ Creating installation directory..."
mkdir -p "$APP_DIR" "$BIN_DIR"
cd "$APP_DIR"

# Create virtual environment with pip pre-installed
echo "→ Setting up isolated Python environment..."
if [ -d venv ]; then
    rm -rf venv
fi

# Create venv and upgrade pip using system pip first
python3 -m venv venv --system-site-packages || {
    # If that fails, try without system-site-packages
    python3 -m venv venv
}

# Activate venv
source venv/bin/activate

# Upgrade pip using the system pip or get-pip.py
echo "→ Upgrading pip..."
if ! venv/bin/pip install --upgrade pip setuptools wheel 2>/dev/null; then
    echo "⚠️  Warning: pip upgrade failed, using system pip..."
    python3 -m pip install --upgrade --target venv/lib/python*/site-packages pip setuptools wheel 2>/dev/null || true
fi

echo "→ Installing Python packages..."
venv/bin/pip install --no-cache-dir customtkinter ntplib pillow pyinstaller || {
    echo "⚠️  Warning: Some packages failed to install, retrying..."
    venv/bin/pip install --no-cache-dir customtkinter ntplib pillow pyinstaller --retries 5
}

# Download source code
echo "→ Downloading Watch Drift Recorder..."
wget -q -O watch_drift_gui.py "$GITHUB_RAW/watch_drift_gui.py" || {
    echo "❌ Failed to download watch_drift_gui.py"
    exit 1
}

wget -q -O watch_icon.png "https://i.imgur.com/8vK7Z8P.png" || {
    echo "⚠️  Warning: Icon download failed (non-critical)"
    touch watch_icon.png
}

# Build standalone executable using PyInstaller
echo "→ Building executable (this may take 1-2 minutes)..."
venv/bin/pyinstaller \
    --onefile \
    --windowed \
    --name "$APP_NAME" \
    --icon="watch_icon.png" \
    --distpath="$APP_DIR/bin" \
    --specpath="$APP_DIR/build" \
    watch_drift_gui.py 2>&1 | grep -v "WARNING"

# Copy executable to ~/.local/bin
if [ -f "$APP_DIR/bin/$APP_NAME" ]; then
    cp "$APP_DIR/bin/$APP_NAME" "$BIN_PATH"
    chmod +x "$BIN_PATH"
else
    echo "❌ PyInstaller build failed!"
    exit 1
fi

# Create XDG-compliant desktop entry
echo "→ Creating desktop entry..."
mkdir -p "$(dirname "$DESKTOP_FILE")"

cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Name=Watch Drift Recorder
Comment=Measure mechanical watch accuracy
Exec=$BIN_PATH
Icon=$APP_DIR/watch_icon.png
Type=Application
Categories=Utility;System;
Terminal=false
StartupNotify=true
EOF

chmod 644 "$DESKTOP_FILE"
cp "$DESKTOP_FILE" "$HOME/Desktop/$APP_NAME.desktop" 2>/dev/null || true

# Update desktop database
update-desktop-database ~/.local/share/applications 2>/dev/null || true

# Deactivate venv
deactivate 2>/dev/null || true

echo ""
echo "✅ SUCCESS! Installation Complete!"
echo "========================================"
echo ""
echo "📍 Installed to:  $APP_DIR"
echo "🔗 Binary at:     $BIN_PATH"
echo "🎯 Desktop entry: $DESKTOP_FILE"
echo ""
echo "🚀 Run the app:"
echo "   • Press Super and search 'Watch Drift'"
echo "   • Or run: WatchDrift"
echo "   • Or double-click desktop icon"
echo ""
echo "🗑️  To uninstall:"
echo "   bash $0 --uninstall"
echo ""
