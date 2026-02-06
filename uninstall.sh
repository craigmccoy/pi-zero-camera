#!/bin/bash
# Uninstall script for Pi Zero Camera

set -e

echo "Stopping and disabling services..."
sudo systemctl stop camera-streamer.service 2>/dev/null || true
sudo systemctl stop mediamtx.service 2>/dev/null || true
sudo systemctl disable camera-streamer.service 2>/dev/null || true
sudo systemctl disable mediamtx.service 2>/dev/null || true

echo "Removing systemd services..."
sudo rm -f /etc/systemd/system/camera-streamer.service
sudo rm -f /etc/systemd/system/mediamtx.service
sudo systemctl daemon-reload

echo "Removing MediaMTX..."
sudo rm -f /usr/local/bin/mediamtx
sudo rm -f /etc/mediamtx.yml

echo ""
echo "Uninstall complete!"
echo ""
echo "Note: rpicam-apps and ffmpeg were not removed."
echo "To remove them: sudo apt remove rpicam-apps ffmpeg"
