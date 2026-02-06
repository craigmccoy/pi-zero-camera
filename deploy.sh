#!/bin/bash
# Deployment script for Pi Zero Camera
# Usage: ./deploy.sh <camera-name>

set -e

CAMERA_NAME=$1
NEEDS_REBOOT=false

if [ -z "$CAMERA_NAME" ]; then
    echo "Usage: ./deploy.sh <camera-name>"
    echo "Example: ./deploy.sh pi-camera-bedroom"
    exit 1
fi

echo "=========================================="
echo "Deploying Pi Zero Camera: $CAMERA_NAME"
echo "=========================================="
echo ""

# Function to check if running on Raspberry Pi
check_raspberry_pi() {
    if [ ! -f /proc/device-tree/model ]; then
        echo "Warning: Not running on Raspberry Pi hardware"
        return 1
    fi
    return 0
}

# Function to check camera detection
check_camera_detected() {
    echo "Checking camera detection..."
    if command -v vcgencmd &> /dev/null; then
        CAMERA_STATUS=$(vcgencmd get_camera 2>/dev/null || echo "error")
        if [[ "$CAMERA_STATUS" == *"detected=1"* ]]; then
            echo "✓ Camera detected by system"
            return 0
        else
            echo "✗ Camera not detected: $CAMERA_STATUS"
            echo "  Please check hardware connection and /boot/firmware/config.txt"
            echo "  See CAMERA_SETUP.md for details"
            return 1
        fi
    else
        echo "⚠ vcgencmd not available, skipping camera detection check"
        return 0
    fi
}

# Function to check and load V4L2 driver
check_v4l2_driver() {
    echo "Checking V4L2 driver..."
    
    # Check if /dev/video0 exists
    if [ -e /dev/video0 ]; then
        echo "✓ /dev/video0 exists"
        return 0
    fi
    
    echo "✗ /dev/video0 not found"
    
    # Try to load the driver
    echo "  Attempting to load bcm2835-v4l2 driver..."
    if sudo modprobe bcm2835-v4l2 2>/dev/null; then
        sleep 2
        if [ -e /dev/video0 ]; then
            echo "✓ Driver loaded successfully, /dev/video0 now available"
            
            # Make it persistent
            if ! grep -q "bcm2835-v4l2" /etc/modules 2>/dev/null; then
                echo "  Adding driver to /etc/modules for persistence..."
                echo "bcm2835-v4l2" | sudo tee -a /etc/modules > /dev/null
                echo "✓ Driver will load on boot"
            fi
            return 0
        fi
    fi
    
    echo "✗ Failed to load V4L2 driver"
    echo "  You may need to enable legacy camera mode in /boot/firmware/config.txt"
    echo "  See CAMERA_SETUP.md for instructions"
    return 1
}

# Function to check user permissions
check_user_permissions() {
    echo "Checking user permissions..."
    
    if groups | grep -q '\bvideo\b'; then
        echo "✓ User is in 'video' group"
        return 0
    else
        echo "✗ User not in 'video' group"
        echo "  Adding user to 'video' group..."
        sudo usermod -aG video $USER
        echo "✓ User added to 'video' group"
        echo "⚠ You may need to log out and back in for group changes to take effect"
        return 0
    fi
}

# Function to check Docker
check_docker() {
    echo "Checking Docker installation..."
    
    if ! command -v docker &> /dev/null; then
        echo "✗ Docker not found"
        echo "  Install Docker with: curl -fsSL https://get.docker.com | sh"
        return 1
    fi
    
    if ! docker ps &> /dev/null; then
        echo "✗ Cannot connect to Docker daemon"
        echo "  Try: sudo usermod -aG docker $USER"
        echo "  Then log out and back in"
        return 1
    fi
    
    echo "✓ Docker is installed and accessible"
    return 0
}

# Run pre-deployment checks
echo "Running pre-deployment checks..."
echo "----------------------------------------"

check_raspberry_pi || true
check_camera_detected || echo "⚠ Camera check failed, but continuing..."
check_v4l2_driver || echo "⚠ V4L2 driver check failed, but continuing..."
check_user_permissions || true
check_docker || exit 1

echo "----------------------------------------"
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        echo "Creating .env from .env.example..."
        cp .env.example .env
    else
        echo "Error: .env.example not found!"
        exit 1
    fi
fi

# Update camera name in .env
echo "Updating camera name to: $CAMERA_NAME"
sed -i "s/CAMERA_NAME=.*/CAMERA_NAME=$CAMERA_NAME/" .env

# Get IP address
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# Pull latest images
echo "Pulling Docker images..."
docker compose pull

# Start services
echo "Starting camera services..."
docker compose up -d

# Wait for services to start
echo "Waiting for services to start..."
sleep 5

# Show status
echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo "Camera Name: $CAMERA_NAME"
echo "Pi Zero IP: $IP_ADDRESS"
echo "RTSP URL: rtsp://$IP_ADDRESS:8554/camera"
echo ""
echo "Add this to your Frigate config:"
echo "----------------------------------------"
echo "cameras:"
echo "  $CAMERA_NAME:"
echo "    ffmpeg:"
echo "      inputs:"
echo "        - path: rtsp://$IP_ADDRESS:8554/camera"
echo "          roles:"
echo "            - detect"
echo "            - record"
echo "    detect:"
echo "      width: 1280"
echo "      height: 720"
echo "      fps: 15"
echo "----------------------------------------"
echo ""
echo "Check logs: docker compose logs -f"
echo "Stop camera: docker compose down"
echo "=========================================="
