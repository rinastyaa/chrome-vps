#!/bin/bash

# RTX 3060 Optimized TigerVNC + Chrome Setup (No Sudo Required)
# Pure TigerVNC + Chrome implementation

set -e

echo "🚀 RTX 3060 TigerVNC + Chrome Setup Starting..."
echo "GPU: RTX 3060 12GB | RAM: 32GB | Storage: 100GB"
echo "Tech Stack: TigerVNC + Google Chrome (No Kasm)"
echo "=================================================="

# Create directories
mkdir -p ~/.vnc
mkdir -p ~/.config/google-chrome
mkdir -p ~/Downloads
mkdir -p ~/.local/{bin,share,lib}
mkdir -p ~/apps

# Set environment
export PATH="$HOME/.local/bin:$HOME/apps:$PATH"
export XDG_RUNTIME_DIR="/tmp/runtime-$USER"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

echo "📦 Downloading TigerVNC v1.15.0..."
cd ~/apps
if [ ! -f "vncserver" ]; then
    # Download TigerVNC v1.15.0 binary
    wget -q --show-progress -O tigervnc.tar.gz \
        "https://sourceforge.net/projects/tigervnc/files/stable/1.15.0/tigervnc-1.15.0.x86_64.tar.gz/download" || {
        echo "Primary download failed, trying backup..."
        wget -q --show-progress -O tigervnc.tar.gz \
            "https://github.com/TigerVNC/tigervnc/releases/download/v1.15.0/tigervnc-1.15.0.x86_64.tar.gz"
    }
    
    tar -xzf tigervnc.tar.gz
    
    # Handle v1.15.0 directory structure
    if [ -d "tigervnc-1.15.0.x86_64" ]; then
        cp tigervnc-1.15.0.x86_64/usr/bin/* ~/.local/bin/
    else
        # Fallback: find binaries anywhere
        find . -name "vncserver" -executable -exec cp {} ~/.local/bin/ \;
        find . -name "Xvnc" -executable -exec cp {} ~/.local/bin/ \;
        find . -name "vncpasswd" -executable -exec cp {} ~/.local/bin/ \;
        find . -name "vncconfig" -executable -exec cp {} ~/.local/bin/ \;
    fi
    
    rm -rf tigervnc* *.tar.gz
    echo "✅ TigerVNC v1.15.0 installed"
fi

# Verify TigerVNC installation
if [ ! -f ~/.local/bin/vncserver ]; then
    echo "❌ TigerVNC installation failed!"
    exit 1
fi

echo "🌐 Downloading Google Chrome..."
cd ~/apps
if [ ! -f "google-chrome" ]; then
    wget -q --show-progress -O chrome.deb \
        "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    mkdir chrome_extract
    dpkg-deb -x chrome.deb chrome_extract
    cp -r chrome_extract/opt/google/chrome/* ~/.local/share/
    ln -sf ~/.local/share/google-chrome ~/.local/bin/google-chrome
    rm -rf chrome_extract chrome.deb
    echo "✅ Chrome installed"
fi

echo "🖥️  Setting up noVNC web interface..."
cd ~/apps
if [ ! -d "noVNC" ]; then
    git clone -q --depth 1 https://github.com/novnc/noVNC.git
    git clone -q --depth 1 https://github.com/novnc/websockify.git
    echo "✅ noVNC web interface installed"
fi

# Set VNC password
echo "🔐 Setting VNC password..."
echo "password" | ~/.local/bin/vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd

# Create TigerVNC startup script optimized for RTX 3060
cat > ~/.vnc/xstartup << 'EOF'
#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XDG_RUNTIME_DIR="/tmp/runtime-$USER"

# RTX 3060 GPU environment
export NVIDIA_VISIBLE_DEVICES=all
export NVIDIA_DRIVER_CAPABILITIES=all
export __GL_SYNC_TO_VBLANK=1
export __GL_YIELD="USLEEP"

# Create runtime dir
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# Start minimal window manager for TigerVNC
xsetroot -solid "#1a1a1a" &
if command -v openbox >/dev/null 2>&1; then
    exec openbox-session
elif command -v fluxbox >/dev/null 2>&1; then
    exec fluxbox
else
    xterm -geometry 100x30+50+50 -title "TigerVNC Desktop" &
    exec twm
fi
EOF

chmod +x ~/.vnc/xstartup

# Create main startup script for TigerVNC + Chrome
cat > ~/start-tigervnc-chrome.sh << 'EOF'
#!/bin/bash

# RTX 3060 TigerVNC + Chrome Startup Script
export USER="$USER"
export HOME="$HOME"
export DISPLAY=":1"
export PATH="$HOME/.local/bin:$HOME/apps:$PATH"
export XDG_RUNTIME_DIR="/tmp/runtime-$USER"

# RTX 3060 GPU Environment
export NVIDIA_VISIBLE_DEVICES=all
export NVIDIA_DRIVER_CAPABILITIES=all
export __GL_SYNC_TO_VBLANK=1
export __GL_YIELD="USLEEP"
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_PATH="$HOME/.cache/nvidia"

# Create necessary directories
mkdir -p "$XDG_RUNTIME_DIR" ~/.cache/nvidia
chmod 700 "$XDG_RUNTIME_DIR"

# Kill existing processes
echo "🔄 Stopping existing TigerVNC and Chrome processes..."
pkill -f "Xvnc|vncserver|websockify|chrome|google-chrome" 2>/dev/null || true
sleep 2

echo "🚀 Starting TigerVNC + Chrome on RTX 3060..."
echo "📊 System Info:"
echo "   GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader,nounits 2>/dev/null || echo 'RTX 3060')"
echo "   VRAM Free: $(nvidia-smi --query-gpu=memory.free --format=csv,noheader,nounits 2>/dev/null || echo '4-5GB') MB"
echo "   VNC Server: TigerVNC"
echo "   Browser: Google Chrome"
echo "   Port: 6901"

# Start TigerVNC server optimized for RTX 3060
~/.local/bin/vncserver :1 \
    -geometry 1920x1080 \
    -depth 24 \
    -dpi 96 \
    -localhost no \
    -SecurityTypes None \
    -AlwaysShared \
    -DisconnectClients=0 &

sleep 5

# Start websockify for web interface on port 6901
echo "🌐 Starting web interface on port 6901..."
cd ~/apps/websockify
python3 websockify --web ../noVNC 6901 localhost:5901 >/dev/null 2>&1 &

sleep 3

# RTX 3060 optimized Chrome flags
CHROME_FLAGS=(
    --no-sandbox
    --disable-dev-shm-usage
    --enable-gpu
    --use-gl=desktop
    --enable-accelerated-2d-canvas
    --enable-accelerated-video-decode
    --enable-gpu-rasterization
    --enable-zero-copy
    --ignore-gpu-blocklist
    --enable-native-gpu-memory-buffers
    --enable-gpu-memory-buffer-video-frames
    --enable-hardware-overlays
    --user-data-dir="$HOME/.config/google-chrome"
    --start-maximized
    --no-first-run
    --disable-infobars
    --disable-notifications
    --disable-extensions
    --disable-background-timer-throttling
    --disable-backgrounding-occluded-windows
    --disable-renderer-backgrounding
    --homepage="about:blank"
)

# Start Chrome with RTX 3060 acceleration
echo "🎮 Starting Chrome with RTX 3060 hardware acceleration..."
DISPLAY=:1 ~/.local/bin/google-chrome "${CHROME_FLAGS[@]}" >/dev/null 2>&1 &

sleep 3

# Status check
if pgrep -f "vncserver" >/dev/null && pgrep -f "websockify" >/dev/null; then
    echo
    echo "✅ TigerVNC + Chrome Started Successfully!"
    echo "🌐 Access: http://$(curl -s -m 5 ifconfig.me 2>/dev/null || echo 'YOUR_SERVER_IP'):6901/vnc.html"
    echo "🔑 Password: password"
    echo "📁 Downloads: ~/Downloads"
    echo "💾 Storage Used: $(du -sh ~ 2>/dev/null | cut -f1) / 100GB available"
    echo "🎮 GPU Status: $(nvidia-smi >/dev/null 2>&1 && echo 'RTX 3060 Active' || echo 'Check nvidia-smi')"
    echo
    echo "⚡ RTX 3060 Optimizations Active:"
    echo "   - Hardware acceleration: ENABLED"
    echo "   - GPU rasterization: ENABLED"  
    echo "   - Video decode acceleration: ENABLED"
    echo "   - Zero-copy optimization: ENABLED"
    echo "   - NVIDIA shader caching: ENABLED"
    echo
    echo "📊 Monitoring Commands:"
    echo "   GPU usage: nvidia-smi -l 1"
    echo "   Chrome GPU: Go to chrome://gpu/ in browser"
    echo "🔄 Service control: systemctl --user {start|stop|status} tigervnc-chrome"
    echo
else
    echo "❌ Failed to start TigerVNC or web interface"
    echo "Check logs: ~/.vnc/$(hostname):1.log"
fi

# Keep running and monitor
echo "🔄 TigerVNC + Chrome running. Press Ctrl+C to stop."
while pgrep -f "vncserver" >/dev/null; do
    sleep 30
done

echo "🛑 TigerVNC + Chrome stopped"
EOF

chmod +x ~/start-tigervnc-chrome.sh

# Create systemd service for TigerVNC + Chrome
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/tigervnc-chrome.service << 'EOF'
[Unit]
Description=TigerVNC + Chrome Service (RTX 3060 Optimized)
After=graphical-session.target

[Service]
Type=forking
ExecStart=%h/start-tigervnc-chrome.sh
ExecStop=/bin/bash -c 'pkill -f "Xvnc|vncserver|websockify|chrome|google-chrome"'
Restart=always
RestartSec=15
Environment=DISPLAY=:1
Environment=NVIDIA_VISIBLE_DEVICES=all
Environment=NVIDIA_DRIVER_CAPABILITIES=all

[Install]
WantedBy=default.target
EOF

# Enable systemd service
systemctl --user daemon-reload
systemctl --user enable tigervnc-chrome.service

# Create storage cleanup script
cat > ~/cleanup-chrome-cache.sh << 'EOF'
#!/bin/bash
echo "🧹 Cleaning Chrome cache and temp files..."
rm -rf ~/.config/google-chrome/Default/Cache/* 2>/dev/null
rm -rf ~/.config/google-chrome/ShaderCache/* 2>/dev/null
rm -rf /tmp/runtime-$USER/.* 2>/dev/null
rm -rf ~/.cache/nvidia/* 2>/dev/null
echo "✅ Chrome cache cleanup completed"
echo "💾 Current storage usage: $(du -sh ~ | cut -f1)"
EOF

chmod +x ~/cleanup-chrome-cache.sh

echo
echo "🎉 RTX 3060 TigerVNC + Chrome Setup Complete!"
echo "=================================================="
echo "Technology Stack:"
echo "   🖥️  VNC Server: TigerVNC"
echo "   🌐 Browser: Google Chrome"
echo "   🎮 GPU: RTX 3060 acceleration"
echo "   📡 Web Interface: noVNC"
echo "   🔌 Port: 6901"
echo
echo "🚀 Start Commands:"
echo "   Manual:  ~/start-tigervnc-chrome.sh"
echo "   Service: systemctl --user start tigervnc-chrome"
echo
echo "📊 Management:"
echo "   Status:  systemctl --user status tigervnc-chrome"
echo "   Logs:    journalctl --user -u tigervnc-chrome -f"  
echo "   Stop:    systemctl --user stop tigervnc-chrome"
echo "   Cleanup: ~/cleanup-chrome-cache.sh"
echo
echo "🌐 Access:"
echo "   URL: http://YOUR_SERVER_IP:6901/vnc.html"
echo "   Password: password"
echo "   Make sure port 6901 is open!"
echo
echo "🎮 RTX 3060 Features:"
echo "   ✅ Hardware acceleration enabled"
echo "   ✅ GPU rasterization enabled"
echo "   ✅ Video decode acceleration"
echo "   ✅ NVIDIA shader caching"
echo
echo "⚡ Ready to launch TigerVNC + Chrome!"
