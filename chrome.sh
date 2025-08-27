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

# Check if Docker is installed, install if not
if ! command -v docker &> /dev/null; then
  info "Docker not found, installing Docker..."
  sudo apt update -y
  sudo apt install -y curl docker.io docker-compose
else
  info "Docker already installed, skipping installation."
fi

# Ask for Chromium login credentials with default values
info "Enter a username for Chromium login (default: user):"
read -p "" chromium_user
chromium_user=${chromium_user:-user}
info "Enter a password for Chromium login (default: pass):"
read -p "" chromium_pass
chromium_pass=${chromium_pass:-pass}
echo ""

# Set up UFW port
info "Opening firewall port 3011..."
sudo ufw allow 3011/tcp || true

# Create project directory
mkdir -p ~/chromium-server
cd ~/chromium-server

# Create Dockerfile
cat <<EOF > Dockerfile
FROM zenika/alpine-chrome:with-node

RUN npm install -g serve

WORKDIR /app
COPY . .

CMD echo "Username: \$CHROME_USER" && echo "Password: \$CHROME_PASS" && google-chrome-stable --no-sandbox --disable-dev-shm-usage
EOF

# Create docker-compose.yml with unless-stopped and proper indentation
cat <<EOF > docker-compose.yml
version: '3'
services:
  chromium:
    build: .
    ports:
      - "3011:3001"
    environment:
      - CHROME_USER=$chromium_user
      - CHROME_PASS=$chromium_pass
    restart: unless-stopped
EOF

# Verify docker-compose.yml
if ! grep -q "restart: unless-stopped" docker-compose.yml; then
  error "Failed to create valid docker-compose.yml"
  exit 1
fi

# Build and start the Docker container
info "Building and starting Chromium service..."
if ! docker compose up --build -d 2> docker-error.log; then
  error "Failed to start Chromium service. Check docker-error.log for details."
  cat docker-error.log
  exit 1
fi

success "Chromium service is running!"
echo "Open in browser: http://<your-vps-ip>:3011/"
echo "Username: $chromium_user"
echo "Password: $chromium_pass"
