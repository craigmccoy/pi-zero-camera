# Raspberry Pi Zero Camera for Frigate

A Docker-based RTSP camera streamer optimized for Raspberry Pi Zero W with OV5647 camera module. Designed for seamless integration with Frigate NVR and Home Assistant.

## Hardware Requirements

- Raspberry Pi Zero W (or Zero 2 W)
- OV5647 5MP Camera Module
- MicroSD card (8GB+ recommended)
- Power supply (5V 2A recommended)

## Features

- 🐳 **Fully Dockerized** - Easy deployment and replication across multiple cameras
- 📹 **RTSP Streaming** - Standard protocol compatible with Frigate and all NVR systems
- ⚙️ **Multiple Resolution Presets** - Optimized for Pi Zero W performance
- 🔧 **Configurable** - Easy customization via environment variables
- 🚀 **Low Latency** - Optimized for real-time streaming
- 🔄 **Auto-restart** - Resilient to crashes and network issues

## Quick Start

### 1. Prerequisites on Pi Zero W

Ensure your Raspberry Pi Zero W has:
- Raspberry Pi OS Lite (Bookworm or newer recommended)
- Docker and Docker Compose installed
- Camera module connected and configured

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies (if not already installed)
sudo apt install -y \
    git \
    curl \

# Install Docker (if not already installed)
# This script installs Docker Engine with Docker Compose V2 plugin
# Note: Raspian Trixie does NOT have a Docker package - 2026-02-04
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Reboot or log out/in for group changes to take effect
# sudo reboot

# Enable camera legacy mode (required for v4l2 access)
# Edit /boot/firmware/config.txt and add:
sudo nano /boot/firmware/config.txt
# Add this line:
# camera_auto_detect=1
# start_x=1
# gpu_mem=128

# OR use raspi-config (on older Pi OS versions)
sudo raspi-config
# Navigate to: Interface Options -> Legacy Camera -> Enable

# Reboot after camera configuration
sudo reboot
```

### 2. Clone/Copy Project to Pi Zero

```bash
# Clone project from Github
git clone https://github.com/craigmccoy/pi-zero-camera.git
cd ~/pi-zero-camera
```

### 3. Configure Camera Settings

```bash
# Copy environment template
cp .env.example .env

# Edit configuration
nano .env
```

**Recommended settings for Pi Zero W:**
```env
CAMERA_NAME=pi-camera-living-room
RESOLUTION=1280x720
FRAMERATE=15
BITRATE=2000000
```

### 4. Start the Camera

```bash
docker compose up -d
```

### 5. Verify Stream

```bash
# Check logs
docker compose logs -f

# Test stream (from another machine)
ffplay rtsp://<PI_ZERO_IP>:8554/camera
```

## Resolution Presets

Choose based on your needs and network capacity:

| Preset | Resolution | FPS | Bitrate | Use Case |
|--------|-----------|-----|---------|----------|
| **Recommended** | 1280x720 | 15 | 2 Mbps | Balanced quality/performance |
| High Quality | 1920x1080 | 10 | 3 Mbps | Better detail, lower FPS |
| Smooth Motion | 640x480 | 30 | 1 Mbps | Fast motion detection |
| Lightweight | 640x480 | 20 | 800 Kbps | Minimal CPU/bandwidth |

## Frigate Integration

### Add Camera to Frigate Configuration

Edit your Frigate `config.yml` on your main server:

```yaml
cameras:
  pi_camera_living_room:
    enabled: True
    ffmpeg:
      inputs:
        - path: rtsp://192.168.1.100:8554/camera  # Replace with your Pi Zero IP
          roles:
            - detect
            - record
    detect:
      width: 1280
      height: 720
      fps: 15
    record:
      enabled: True
      retain:
        days: 7
        mode: motion
    snapshots:
      enabled: True
      retain:
        default: 14
    objects:
      track:
        - person
        - car
        - dog
        - cat
```

### Frigate Features You Can Use

With this RTSP setup, you get full Frigate functionality:

✅ **Object Detection** - Real-time AI object detection  
✅ **Recording** - Continuous and motion-based recording  
✅ **Snapshots** - Automatic snapshot capture  
✅ **Notifications** - Home Assistant notifications  
✅ **Timeline** - Event timeline and playback  
✅ **Zones** - Custom detection zones  
✅ **Masks** - Privacy and detection masks  
✅ **Sub-streams** - Use lower resolution for detection (configure multiple streams if needed)  

### Optimizing for Frigate

For best performance with Frigate's object detection:

1. **Use 720p @ 15fps** for the detect stream (already configured)
2. **Enable hardware acceleration** on your Frigate server (not Pi Zero)
3. **Configure motion masks** to reduce false detections
4. **Set up zones** for specific areas of interest

Example advanced Frigate config:
```yaml
cameras:
  pi_camera_living_room:
    ffmpeg:
      inputs:
        - path: rtsp://192.168.1.100:8554/camera
          roles:
            - detect
            - record
    detect:
      width: 1280
      height: 720
      fps: 15
    motion:
      mask:
        - 0,0,1280,100  # Mask top area (timestamp, etc.)
    zones:
      front_door:
        coordinates: 400,720,800,720,800,400,400,400
        objects:
          - person
```

## Home Assistant Integration

Once added to Frigate, the camera automatically appears in Home Assistant:

1. **Live View**: Available in Frigate card
2. **Notifications**: Configure automations based on detections
3. **Camera Entity**: `camera.pi_camera_living_room`

Example automation:
```yaml
automation:
  - alias: "Notify on Person Detection"
    trigger:
      - platform: mqtt
        topic: frigate/events
    condition:
      - condition: template
        value_template: "{{ trigger.payload_json.after.camera == 'pi_camera_living_room' }}"
      - condition: template
        value_template: "{{ trigger.payload_json.after.label == 'person' }}"
    action:
      - service: notify.mobile_app
        data:
          message: "Person detected at living room"
          data:
            image: "{{ trigger.payload_json.after.snapshot_url }}"
```

## Deploying to Multiple Cameras

### Method 1: Clone SD Card
1. Set up first camera completely
2. Shut down Pi Zero: `sudo shutdown -h now`
3. Clone SD card using tool like Raspberry Pi Imager or `dd`
4. Boot new Pi Zero with cloned card
5. Update `.env` file with new camera name and verify IP

### Method 2: Automated Deployment Script

The included `deploy.sh` script automates deployment with built-in checks:

**Features:**
- ✓ Verifies camera hardware detection
- ✓ Checks and loads V4L2 driver automatically
- ✓ Adds user to `video` group if needed
- ✓ Validates Docker installation
- ✓ Creates and configures `.env` file
- ✓ Provides helpful error messages

**Usage:**
```bash
chmod +x deploy.sh
./deploy.sh pi-camera-bedroom
```

The script will:
1. Run pre-deployment checks
2. Auto-fix common issues (load driver, set permissions)
3. Configure camera name in `.env`
4. Pull Docker images
5. Start services
6. Display connection information

## Troubleshooting

### Camera Not Detected

```bash
# Check if camera is detected by the system
vcgencmd get_camera
# Should show: supported=1 detected=1

# Check if v4l2 device exists
ls -l /dev/video0
# Should show: crw-rw---- 1 root video ...

# If /dev/video0 doesn't exist, enable legacy camera mode
sudo nano /boot/firmware/config.txt
# Add these lines:
# camera_auto_detect=1
# start_x=1
# gpu_mem=128

# Load v4l2 driver manually (if needed)
sudo modprobe bcm2835-v4l2

# Make it permanent by adding to /etc/modules
echo "bcm2835-v4l2" | sudo tee -a /etc/modules

# Reboot
sudo reboot

# Test camera with v4l2
v4l2-ctl --list-devices
v4l2-ctl --list-formats-ext
```

### Stream Not Working

```bash
# Check container logs
docker compose logs camera-streamer

# Check MediaMTX logs
docker compose logs mediamtx

# Test camera directly
libcamera-hello --list-cameras

# Restart services
docker compose restart
```

### Performance Issues

```bash
# Lower resolution in .env
RESOLUTION=640x480
FRAMERATE=15
BITRATE=1000000

# Restart
docker compose down && docker compose up -d

# Monitor CPU usage
htop
```

### Network Issues

```bash
# Check if RTSP port is open
sudo netstat -tulpn | grep 8554

# Test from another machine
ffprobe rtsp://<PI_IP>:8554/camera
```

## Monitoring

### Check Stream Health

```bash
# View logs
docker compose logs -f camera-streamer

# Check resource usage
docker stats

# System resources
htop
```

### Useful Commands

```bash
# Start camera
docker compose up -d

# Stop camera
docker compose down

# Restart camera
docker compose restart

# View logs
docker compose logs -f

# Update containers
docker compose pull
docker compose up -d

# Clean up
docker compose down -v
docker system prune -a
```

## Performance Tips

1. **Use wired connection if possible** - More stable than WiFi
2. **Keep Pi Zero cool** - Consider heatsink for continuous operation
3. **Use quality power supply** - Prevents brownouts and crashes
4. **Optimize resolution** - Start with 720p@15fps, adjust as needed
5. **Update regularly** - Keep Docker images and OS updated

## Network Configuration

### Static IP (Recommended)

Edit `/etc/dhcpcd.conf`:
```bash
interface wlan0
static ip_address=192.168.1.100/24
static routers=192.168.1.1
static domain_name_servers=192.168.1.1 8.8.8.8
```

### Hostname

```bash
sudo hostnamectl set-hostname pi-camera-01
```

## Security Considerations

1. **Change default password**: `passwd`
2. **Use SSH keys**: Disable password authentication
3. **Firewall**: Only expose necessary ports
4. **Network isolation**: Consider VLAN for cameras
5. **Regular updates**: `sudo apt update && sudo apt upgrade`

## Advanced Configuration

### Custom MediaMTX Settings

Edit `mediamtx.yml` for advanced RTSP server configuration.

### Multiple Streams

To provide both high-quality recording and low-quality detection streams, you can run multiple instances with different resolutions.

### Audio Support

The OV5647 doesn't have audio, but you can add USB microphone support by modifying the FFmpeg command in `stream_camera.py`.

## License

MIT License - Feel free to use and modify for your projects.

## Support

For issues specific to:
- **Frigate**: https://github.com/blakeblackshear/frigate
- **Home Assistant**: https://community.home-assistant.io/
- **MediaMTX**: https://github.com/bluenviron/mediamtx

## Credits

Built for the Home Assistant and Frigate community.
