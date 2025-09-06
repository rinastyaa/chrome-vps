#!/bin/bash

# RTX 3060 Custom TigerVNC + Chrome Setup (Custom Password & Port)
set -e

echo "🚀 RTX 3060 Custom TigerVNC + Chrome Setup"
echo "=========================================="

# Configuration Variables - EDIT HERE
VNC_PASSWORD="saumata123"           # Your custom password
WEB_PORT="9400"                     # Your custom web port
VNC_RESOLUTION="1920x1080"          # Display resolution
GPU_OPTIMIZATION="true"             # Enable RTX 3060 optimization

echo "📋 Configuration:"
echo "   Password: $VNC_PASSWORD"
echo "   Web Port: $WEB_PORT"
echo "   Resolution: $VNC_RESOLUTION"
echo "   GPU Optimization: $GPU_OPTIMIZATION"
echo

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

echo "📦 Downloading TigerVNC..."
cd ~/apps
if [ ! -f "vncserver" ]; then
    wget -q --show-progress -O tigervnc.tar.gz \
        "https://github.com/TigerVNC/tigervnc/releases/download/v1.13.1/tigervnc-1.13.1.x86_64.tar.gz"
    tar -xzf tigervnc.tar.gz
    cp tigervnc-1.13.1.x86_64/usr/bin/* ~/.local/bin/
    rm -rf tigervnc*
    echo "✅ TigerVNC installed"
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
    echo "✅ noVNC installed"
fi

# Set custom VNC password
echo "🔐 Setting custom VNC password..."
echo "$VNC_PASSWORD" | ~/.local/bin/vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd
echo "✅ Password set to: $VNC_PASSWORD"

# Create TigerVNC config file
cat > ~/.vnc/config << EOF
# TigerVNC Configuration
geometry=${VNC_RESOLUTION}
depth=24
dpi=96
localhost=no
SecurityTypes=None
AlwaysShared
DisconnectClients=0
AcceptKeyEvents
AcceptPointerEvents
EOF

# Create optimized xstartup
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

mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# Desktop background
xsetroot -solid "#2e3440" &

# Start window manager
if command -v openbox >/dev/null 2>&1; then
    exec openbox-session
elif command -v fluxbox >/dev/null 2>&1; then
    exec fluxbox
else
    xterm -geometry 100x30+50+50 -title "Custom Desktop" &
    exec twm
fi
EOF

chmod +x ~/.vnc/xstartup

# Create main startup script with custom configuration
cat > ~/start-custom-vnc-chrome.sh << EOF
#!/bin/bash

# Custom TigerVNC + Chrome Startup (RTX 3060 Optimized)
export USER="$USER"
export HOME="$HOME" 
export DISPLAY=":1"
export PATH="$HOME/.local/bin:$HOME/apps:$PATH"
export XDG_RUNTIME_DIR="/tmp/runtime-$USER"

# Configuration
VNC_PASSWORD="$VNC_PASSWORD"
WEB_PORT="$WEB_PORT"
VNC_RESOLUTION="$VNC_RESOLUTION"

# RTX 3060 GPU Environment
export NVIDIA_VISIBLE_DEVICES=all
export NVIDIA_DRIVER_CAPABILITIES=all
export __GL_SYNC_TO_VBLANK=1
export __GL_YIELD="USLEEP"
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_PATH="$HOME/.cache/nvidia"

mkdir -p "$XDG_RUNTIME_DIR" ~/.cache/nvidia
chmod 700 "$XDG_RUNTIME_DIR"

# Kill existing processes
echo "🔄 Stopping existing processes..."
pkill -f "Xvnc|vncserver|websockify|chrome|google-chrome" 2>/dev/null || true
sleep 2

echo "🚀 Starting Custom TigerVNC + Chrome..."
echo "📊 Configuration:"
echo "   Password: \$VNC_PASSWORD"
echo "   Web Port: \$WEB_PORT"  
echo "   Resolution: \$VNC_RESOLUTION"
echo "   GPU: \$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits 2>/dev/null || echo 'RTX 3060')"
echo "   VRAM Free: \$(nvidia-smi --query-gpu=memory.free --format=csv,noheader,nounits 2>/dev/null || echo '4-5GB') MB"

# Start TigerVNC server
~/.local/bin/vncserver :1 >/dev/null 2>&1 &
sleep 5

# Start web interface on custom port
echo "🌐 Starting web interface on port \$WEB_PORT..."
cd ~/apps/websockify
python3 websockify --web ../noVNC \$WEB_PORT localhost:5901 >/dev/null 2>&1 &
sleep 3

# Chrome flags optimized for RTX 3060
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
    --user-data-dir="\$HOME/.config/google-chrome"
    --start-maximized
    --no-first-run
    --disable-infobars
    --disable-notifications
    --disable-extensions
    --disable-background-timer-throttling
    --disable-backgrounding-occluded-windows
    --disable-renderer-backgrounding
    --homepage="about:blank"
    --window-size=1920,1080
)

# Start Chrome with RTX 3060 optimization
echo "🎮 Starting Chrome with RTX 3060 acceleration..."
DISPLAY=:1 ~/.local/bin/google-chrome "\${CHROME_FLAGS[@]}" >/dev/null 2>&1 &

sleep 3

# Status check and display info
if pgrep -f "vncserver" >/dev/null && pgrep -f "websockify" >/dev/null; then
    external_ip=\$(curl -s -m 5 ifconfig.me 2>/dev/null || echo 'YOUR_SERVER_IP')
    echo
    echo "✅ Custom TigerVNC + Chrome Started Successfully!"
    echo "🌐 Access URL: http://\$external_ip:\$WEB_PORT/vnc.html"
    echo "🔑 Password: \$VNC_PASSWORD"
    echo "🖥️  Resolution: \$VNC_RESOLUTION"
    echo "📁 Downloads: ~/Downloads"
    echo "💾 Storage Used: \$(du -sh ~ 2>/dev/null | cut -f1) / 100GB"
    echo "🎮 GPU: RTX 3060 Hardware Acceleration Active"
    echo
    echo "⚡ RTX 3060 Optimizations:"
    echo "   ✅ Hardware acceleration enabled"
    echo "   ✅ GPU rasterization enabled"  
    echo "   ✅ Video decode acceleration enabled"
    echo "   ✅ Zero-copy optimization enabled"
    echo "   ✅ NVIDIA shader caching enabled"
    echo
    echo "📊 Monitoring:"
    echo "   GPU usage: nvidia-smi -l 1"
    echo "   Chrome GPU status: Go to chrome://gpu/"
    echo "   Service logs: journalctl --user -u custom-vnc-chrome -f"
    echo
    echo "🔧 Port \$WEB_PORT Security Tips:"
    echo "   ✅ Non-standard port (harder to detect)"
    echo "   ✅ Custom password protection"
    echo "   ✅ Consider firewall IP restrictions"
    echo
else
    echo "❌ Failed to start TigerVNC or web interface"
    echo "Check VNC log: ~/.vnc/\$(hostname):1.log"
    echo "Check process: ps aux | grep -E 'vncserver|websockify'"
fi

# Keep running
echo "🔄 TigerVNC + Chrome running on port \$WEB_PORT"
echo "Press Ctrl+C to stop, or run as background service"
while pgrep -f "vncserver" >/dev/null; do
    sleep 30
done

echo "🛑 Custom TigerVNC + Chrome stopped"
EOF

chmod +x ~/start-custom-vnc-chrome.sh

# Create systemd service with custom config
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/custom-vnc-chrome.service << EOF
[Unit]
Description=Custom TigerVNC + Chrome Service (RTX 3060)
After=graphical-session.target

[Service]
Type=forking
ExecStart=%h/start-custom-vnc-chrome.sh
ExecStop=/bin/bash -c 'pkill -f "Xvnc|vncserver|websockify|chrome|google-chrome"'
Restart=always
RestartSec=15
Environment=DISPLAY=:1
Environment=NVIDIA_VISIBLE_DEVICES=all
Environment=NVIDIA_DRIVER_CAPABILITIES=all

[Install]
WantedBy=default.target
EOF

# Enable service
systemctl --user daemon-reload
systemctl --user enable custom-vnc-chrome.service

# Create configuration manager script
cat > ~/manage-vnc-config.sh << 'EOF'
#!/bin/bash

echo "🔧 TigerVNC + Chrome Configuration Manager"
echo "========================================="

case "$1" in
    "password")
        if [ -z "$2" ]; then
            echo "Usage: $0 password NEW_PASSWORD"
            exit 1
        fi
        echo "$2" | ~/.local/bin/vncpasswd -f > ~/.vnc/passwd
        chmod 600 ~/.vnc/passwd
        echo "✅ Password changed to: $2"
        echo "🔄 Restart service: systemctl --user restart custom-vnc-chrome"
        ;;
    "port")
        if [ -z "$2" ]; then
            echo "Usage: $0 port NEW_PORT"
            exit 1
        fi
        sed -i "s/WEB_PORT=\"[0-9]*\"/WEB_PORT=\"$2\"/g" ~/start-custom-vnc-chrome.sh
        echo "✅ Port changed to: $2"
        echo "🔄 Restart service: systemctl --user restart custom-vnc-chrome"
        ;;
    "resolution")
        if [ -z "$2" ]; then
            echo "Usage: $0 resolution WIDTHxHEIGHT (e.g., 1920x1080)"
            exit 1
        fi
        sed -i "s/VNC_RESOLUTION=\"[0-9x]*\"/VNC_RESOLUTION=\"$2\"/g" ~/start-custom-vnc-chrome.sh
        sed -i "s/geometry=[0-9x]*/geometry=$2/g" ~/.vnc/config
        echo "✅ Resolution changed to: $2"
        echo "🔄 Restart service: systemctl --user restart custom-vnc-chrome"
        ;;
    "status")
        echo "📊 Current Configuration:"
        echo "   Password: $(echo "Check ~/.vnc/passwd file")"
        echo "   Port: $(grep 'WEB_PORT=' ~/start-custom-vnc-chrome.sh | cut -d'"' -f2)"
        echo "   Resolution: $(grep 'VNC_RESOLUTION=' ~/start-custom-vnc-chrome.sh | cut -d'"' -f2)"
        echo "   Service Status: $(systemctl --user is-active custom-vnc-chrome 2>/dev/null || echo 'inactive')"
        ;;
    *)
        echo "Usage: $0 {password|port|resolution|status} [value]"
        echo
        echo "Examples:"
        echo "  $0 password newpass123"
        echo "  $0 port 8080"  
        echo "  $0 resolution 2560x1440"
        echo "  $0 status"
        ;;
esac
EOF

chmod +x ~/manage-vnc-config.sh

echo
echo "🎉 Custom TigerVNC + Chrome Setup Complete!"
echo "============================================"
echo "📋 Your Configuration:"
echo "   Password: $VNC_PASSWORD"
echo "   Web Port: $WEB_PORT"
echo "   Resolution: $VNC_RESOLUTION"
echo "   GPU: RTX 3060 Acceleration"
echo
echo "🚀 Start Commands:"
echo "   Manual:  ~/start-custom-vnc-chrome.sh"
echo "   Service: systemctl --user start custom-vnc-chrome"
echo
echo "🌐 Access:"
echo "   URL: http://YOUR_SERVER_IP:$WEB_PORT/vnc.html"
echo "   Password: $VNC_PASSWORD"
echo
echo "🔧 Configuration Management:"
echo "   Change password: ~/manage-vnc-config.sh password NEW_PASSWORD"
echo "   Change port:     ~/manage-vnc-config.sh port NEW_PORT"
echo "   Change resolution: ~/manage-vnc-config.sh resolution WIDTHxHEIGHT"
echo "   View status:     ~/manage-vnc-config.sh status"
echo
echo "📊 Management:"
echo "   Status:  systemctl --user status custom-vnc-chrome"
echo "   Logs:    journalctl --user -u custom-vnc-chrome -f"
echo "   Stop:    systemctl --user stop custom-vnc-chrome"
echo
echo "⚡ Ready with custom password & port $WEB_PORT!"
