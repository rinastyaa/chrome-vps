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

# Ask for Chromium login credentials
read -p "Enter a username for Chromium login: " chromium_user
read -p "Enter a password for Chromium login: " chromium_pass
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

# Create docker-compose.yml with unless-stopped
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

# Build and start the Docker container
info "Building and starting Chromium service..."
docker compose up --build -d

success "Chromium service is running!"
echo "Open in browser: http://<your-vps-ip>:3011/"
echo "Username: $chromium_user"
echo "Password: $chromium_pass"
