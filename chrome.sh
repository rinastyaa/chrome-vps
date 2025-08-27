#!/bin/bash
set -e

function info() {
  echo -e "\033[1;34m[*]\033[0m $1"
}

function success() {
  echo -e "\033[1;32m[✔]\033[0m $1"
}

function error() {
  echo -e "\033[1;31m[✘]\033[0m $1" >&2
}

# Check Docker
if ! command -v docker &> /dev/null; then
  info "Installing Docker..."
  sudo apt update -y
  sudo apt install -y curl docker.io docker-compose
  sudo systemctl start docker
  sudo systemctl enable docker
else
  info "Docker already installed, skipping installation."
fi

# Open firewall port
info "Opening firewall port 6901..."
sudo ufw allow 6901/tcp || true

# Create directory
mkdir -p ~/kasm-chrome
cd ~/kasm-chrome

# Ask for VNC password
info "Enter VNC password (default: password):"
read -p "Password: " vnc_password
if [ -z "$vnc_password" ]; then
    vnc_password="password"
fi
echo ""
info "Password set to: $vnc_password"

# Create docker-compose.yml
cat > docker-compose.yml << EOF
version: '3.8'
services:
  chrome:
    image: kasmweb/chrome:1.15.0
    container_name: kasm-chrome
    environment:
      - VNC_PW=${vnc_password}
    ports:
      - "6901:6901"
    shm_size: 2g
    restart: unless-stopped
    volumes:
      - ./downloads:/home/kasm-user/Downloads
EOF

# Start service
info "Starting Chrome browser service..."
sudo docker compose up -d

# Wait for startup
info "Waiting for service to start..."
sleep 15

if sudo docker ps | grep -q kasm-chrome; then
  success "Chrome browser is running!"
  echo ""
  echo "🌐 Access your browser at:"
  echo "   https://$(curl -s ifconfig.me):6901"
  echo ""
  echo "🔐 Login credentials:"
  echo "   User: kasm_user"
  echo "   Password: $vnc_password"
  echo ""
  echo "✨ Features:"
  echo "   - Full Google Chrome"
  echo "   - High performance"
  echo "   - File transfer"
  echo "   - Audio support"
  echo "   - Copy/paste"
else
  error "Failed to start Chrome"
  echo "Check logs: sudo docker compose logs -f"
fi
