#!/bin/bash
# Deployment script for Pi Zero Camera
# Usage: ./deploy.sh <camera-name>

set -e

CAMERA_NAME=$1

if [ -z "$CAMERA_NAME" ]; then
    echo "Usage: ./deploy.sh <camera-name>"
    echo "Example: ./deploy.sh pi-camera-bedroom"
    exit 1
fi

echo "=========================================="
echo "Deploying Pi Zero Camera: $CAMERA_NAME"
echo "=========================================="

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
