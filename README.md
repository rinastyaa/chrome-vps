# Setup a full Google Chrome browser on your VPS server with Kasm VNC

## Features

- Full Google Chrome browser experience
- High performance with GPU acceleration
- File upload/download support
- Audio support
- Copy/paste functionality
- Secure HTTPS connection
- Customizable login credentials

## System Requirements

- **OS**: Ubuntu 20.04+ or Debian 10+
- **RAM**: Minimum 2GB (recommended 4GB+)
- **CPU**: 1+ cores
- **Storage**: 5GB free space
- **Network**: Open port 6901

## Quick Install

### Method 1: Custom Password
```bash
KASM_PASSWORD="your_password" curl -s https://raw.githubusercontent.com/rinastyaa/chrome-vps/refs/heads/main/chrome.sh | bash
```

### Method 2: Set Password First
```bash
export KASM_PASSWORD="your_password"
curl -s https://raw.githubusercontent.com/rinastyaa/chrome-vps/refs/heads/main/chrome.sh | bash
```

## Manual Installation

If you prefer to download and run manually:

```bash
# Download script
wget https://raw.githubusercontent.com/rinastyaa/chrome-vps/refs/heads/main/chrome.sh

# Make executable
chmod +x chrome.sh

# Run with default password
./chrome.sh

# Or run with custom password
KASM_PASSWORD="your_password" ./chrome.sh
```

## Access Your Browser

After installation completes, you'll see output like:

```
✔ Chrome browser is running!

🌐 Access your browser at:
   https://YOUR_SERVER_IP:6901

🔐 Login credentials:
   User: kasm_user
   Password: your_password
```

### Steps to Access:

1. **Open URL**: Navigate to `https://YOUR_SERVER_IP:6901`
2. **Accept SSL Certificate**: Click "Advanced" → "Proceed to site" (ignore security warning)
3. **Login**: 
   - Username: `kasm_user`
   - Password: `password` (or your custom password)

## Management Commands

### Check Status
```bash
sudo docker ps | grep kasm-chrome
```

### View Logs
```bash
sudo docker logs kasm-chrome -f
```

### Stop Browser
```bash
cd ~/kasm-chrome
sudo docker compose down
```

### View realtime resources
```bash
docker stats
```

## Troubleshooting

### Container Won't Start
```bash
# Check logs
docker logs -f kasm-chrome

# Check if port is in use
sudo netstat -tlnp | grep 6901

### Can't Access Web Interface
```bash
# Check firewall
sudo ufw status
sudo ufw allow 6901/tcp

# Check if service is running
sudo docker ps | grep kasm-chrome
```

## File Transfer

### Download Files
1. In Chrome, download files normally
2. Files appear in `/home/kasm-user/Downloads` inside container
3. Access via Kasm interface file manager

### Upload Files
1. Use Kasm interface upload button
2. Files go to `/home/kasm-user/Uploads`
3. Access from Chrome file picker

## Security Notes

- This setup uses self-signed SSL certificates (browser warnings are normal)
- Change default password for production use
- Consider using VPN or restricting IP access for additional security
- Files are stored in Docker volumes, backup if needed

## Resource Usage

Typical resource consumption:
- **RAM**: 1-3GB (depending on browsing)
- **CPU**: 10-50% (depending on activity)
- **Storage**: 2-5GB for container and cache

## Updates

To update to latest version:
```bash
cd ~/kasm-chrome
sudo docker compose down
sudo docker pull kasmweb/chrome:1.15.0
sudo docker compose up -d
```

## License

This project uses Kasm Chrome image. Check their licensing terms for commercial use.

---
