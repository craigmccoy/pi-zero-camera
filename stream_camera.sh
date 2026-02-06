#!/bin/bash
# Pi Zero Camera Streamer - Host-based (no Docker)
# Streams camera via rpicam-vid to MediaMTX RTSP server

set -e

# Load configuration
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Configuration with defaults
CAMERA_NAME=${CAMERA_NAME:-pi-camera}
RESOLUTION=${RESOLUTION:-1280x720}
FRAMERATE=${FRAMERATE:-15}
BITRATE=${BITRATE:-2000000}
RTSP_PORT=${RTSP_PORT:-8554}

# Parse resolution
WIDTH=$(echo $RESOLUTION | cut -d'x' -f1)
HEIGHT=$(echo $RESOLUTION | cut -d'x' -f2)

echo "============================================================"
echo "Pi Zero Camera Streamer"
echo "============================================================"
echo "Camera: $CAMERA_NAME"
echo "Resolution: ${WIDTH}x${HEIGHT} @ ${FRAMERATE}fps"
echo "Bitrate: ${BITRATE}"
echo "RTSP URL: rtsp://$(hostname -I | awk '{print $1}'):${RTSP_PORT}/camera"
echo "============================================================"

# Check if rpicam-vid is available
if ! command -v rpicam-vid &> /dev/null; then
    echo "Error: rpicam-vid not found. Install with: sudo apt install -y rpicam-apps"
    exit 1
fi

# Check if camera is detected
if ! rpicam-hello --list-cameras 2>&1 | grep -q "Available cameras"; then
    echo "Error: No camera detected. Check hardware connection."
    exit 1
fi

echo "Starting camera stream..."

# Stream camera to RTSP server
rpicam-vid \
    --width "$WIDTH" \
    --height "$HEIGHT" \
    --framerate "$FRAMERATE" \
    --bitrate "$BITRATE" \
    --codec h264 \
    --inline \
    --flush \
    -t 0 \
    -o - \
    | ffmpeg \
        -re \
        -f h264 \
        -i pipe:0 \
        -c:v copy \
        -f rtsp \
        -rtsp_transport tcp \
        "rtsp://localhost:${RTSP_PORT}/camera"
