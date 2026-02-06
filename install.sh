#!/bin/bash
# Installation script for Pi Zero Camera (host-based, no Docker)

set -e

CAMERA_NAME=$1

if [ -z "$CAMERA_NAME" ]; then
    echo "Usage: ./install.sh <camera-name>"
    echo "Example: ./install.sh pi-camera-office"
    exit 1
fi

echo "============================================================"
echo "Installing Pi Zero Camera: $CAMERA_NAME"
echo "============================================================"

# Check if running on Raspberry Pi
if [ ! -f /proc/device-tree/model ]; then
    echo "Warning: Not running on Raspberry Pi hardware"
fi

# Install required packages
echo "Installing required packages..."
sudo apt update
sudo apt install -y \
    rpicam-apps \
    ffmpeg \
    wget

# Download and install MediaMTX
echo "Installing MediaMTX RTSP server..."
MEDIAMTX_VERSION="v1.16.0"
ARCH=$(uname -m)

if [ "$ARCH" = "armv6l" ] || [ "$ARCH" = "armv7l" ]; then
    MEDIAMTX_ARCH="armv6"
elif [ "$ARCH" = "aarch64" ]; then
    MEDIAMTX_ARCH="arm64v8"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

wget -q "https://github.com/bluenviron/mediamtx/releases/download/${MEDIAMTX_VERSION}/mediamtx_${MEDIAMTX_VERSION}_linux_${MEDIAMTX_ARCH}.tar.gz" -O /tmp/mediamtx.tar.gz
sudo tar -xzf /tmp/mediamtx.tar.gz -C /usr/local/bin/ mediamtx
sudo chmod +x /usr/local/bin/mediamtx
rm /tmp/mediamtx.tar.gz

# Copy MediaMTX config
sudo cp mediamtx.yml /etc/mediamtx.yml

# Create .env file
if [ ! -f .env ]; then
    cp .env.example .env
fi

# Update camera name in .env
sed -i "s/CAMERA_NAME=.*/CAMERA_NAME=$CAMERA_NAME/" .env

# Make scripts executable
chmod +x stream_camera.sh

# Create systemd service for MediaMTX
echo "Creating MediaMTX systemd service..."
sudo tee /etc/systemd/system/mediamtx.service > /dev/null <<EOF
[Unit]
Description=MediaMTX RTSP Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/mediamtx /etc/mediamtx.yml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Create systemd service for camera streamer
echo "Creating camera streamer systemd service..."
sudo tee /etc/systemd/system/camera-streamer.service > /dev/null <<EOF
[Unit]
Description=Pi Zero Camera Streamer
After=network.target mediamtx.service
Requires=mediamtx.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$(pwd)
ExecStart=$(pwd)/stream_camera.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Enable and start services
echo "Enabling services..."
sudo systemctl daemon-reload
sudo systemctl enable mediamtx.service
sudo systemctl enable camera-streamer.service

echo ""
echo "============================================================"
echo "Installation Complete!"
echo "============================================================"
echo "Camera Name: $CAMERA_NAME"
echo "Pi IP: $(hostname -I | awk '{print $1}')"
echo ""
echo "Start services with:"
echo "  sudo systemctl start mediamtx"
echo "  sudo systemctl start camera-streamer"
echo ""
echo "Check status with:"
echo "  sudo systemctl status mediamtx"
echo "  sudo systemctl status camera-streamer"
echo ""
echo "View logs with:"
echo "  sudo journalctl -u mediamtx -f"
echo "  sudo journalctl -u camera-streamer -f"
echo ""
echo "RTSP URL: rtsp://$(hostname -I | awk '{print $1}'):8554/camera"
echo "============================================================"
