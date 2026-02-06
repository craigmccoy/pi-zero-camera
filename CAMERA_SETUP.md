# Camera Setup Guide for Raspberry Pi Zero W

This guide helps you configure the OV5647 camera module to work with the Docker-based streaming setup.

## Hardware Connection

1. **Power off** your Raspberry Pi Zero W
2. **Locate the camera connector** (between HDMI and USB ports)
3. **Lift the connector tab** gently
4. **Insert the ribbon cable** with contacts facing the PCB
5. **Press down the tab** to secure the cable
6. **Power on** the Pi

## Software Configuration

### For Raspberry Pi OS Bookworm (Recommended)

The newer Raspberry Pi OS uses `libcamera` by default, but Docker needs the legacy V4L2 interface.

#### Enable Legacy Camera Mode

Edit the boot configuration:
```bash
sudo nano /boot/firmware/config.txt
```

Add or modify these lines:
```
# Enable camera
camera_auto_detect=1
start_x=1
gpu_mem=128
```

Save and exit (Ctrl+X, Y, Enter).

#### Load V4L2 Driver

```bash
# Load the driver
sudo modprobe bcm2835-v4l2

# Make it load on boot
echo "bcm2835-v4l2" | sudo tee -a /etc/modules
```

#### Reboot
```bash
sudo reboot
```

### For Raspberry Pi OS Bullseye (Older)

```bash
sudo raspi-config
```
Navigate to: **Interface Options** → **Legacy Camera** → **Enable**

Reboot when prompted.

## Verify Camera Setup

After reboot, run these commands to verify:

### 1. Check Camera Detection
```bash
vcgencmd get_camera
```
Expected output: `supported=1 detected=1`

### 2. Check V4L2 Device
```bash
ls -l /dev/video0
```
Expected output: `crw-rw---- 1 root video ...`

### 3. List Camera Capabilities
```bash
v4l2-ctl --list-devices
```
Should show: `mmal service 16.1 (platform:bcm2835-v4l2)`

### 4. Check Supported Formats
```bash
v4l2-ctl --list-formats-ext
```
Should list H.264, MJPEG, and other formats.

### 5. Test Camera Capture
```bash
# Capture a test image
v4l2-ctl --set-fmt-video=width=1280,height=720,pixelformat=MJPG
v4l2-ctl --stream-mmap --stream-to=/tmp/test.jpg --stream-count=1

# View the file size (should be > 0)
ls -lh /tmp/test.jpg
```

## Troubleshooting

### Problem: `/dev/video0` doesn't exist

**Solution 1**: Load the V4L2 driver manually
```bash
sudo modprobe bcm2835-v4l2
ls -l /dev/video0
```

**Solution 2**: Check boot config
```bash
grep -E "camera|start_x|gpu_mem" /boot/firmware/config.txt
```

Ensure you have:
- `camera_auto_detect=1`
- `start_x=1`
- `gpu_mem=128`

### Problem: Camera detected but no video device

This usually means the V4L2 driver isn't loaded.

```bash
# Check loaded modules
lsmod | grep bcm2835

# If not listed, load it
sudo modprobe bcm2835-v4l2

# Add to /etc/modules for persistence
echo "bcm2835-v4l2" | sudo tee -a /etc/modules
```

### Problem: Permission denied accessing camera

Add your user to the `video` group:
```bash
sudo usermod -aG video $USER
```

Log out and back in for changes to take effect.

### Problem: Camera works but Docker can't access it

Ensure the device is mounted in docker-compose.yml:
```yaml
devices:
  - /dev/video0:/dev/video0
```

And the container runs with `privileged: true`.

## Camera Specifications (OV5647)

- **Resolution**: 5MP (2592 × 1944 pixels)
- **Video**: 1080p30, 720p60, 640x480p90
- **Interface**: CSI (Camera Serial Interface)
- **Supported formats**: H.264, MJPEG, YUV420, RGB

## Recommended Settings for Streaming

For Pi Zero W (limited CPU), use these settings in `.env`:

```env
# Balanced quality/performance
RESOLUTION=1280x720
FRAMERATE=15
BITRATE=2000000

# Or lighter load
RESOLUTION=640x480
FRAMERATE=20
BITRATE=800000
```

## Additional Resources

- [Raspberry Pi Camera Documentation](https://www.raspberrypi.com/documentation/accessories/camera.html)
- [V4L2 Documentation](https://www.kernel.org/doc/html/latest/userspace-api/media/v4l/v4l2.html)
- [FFmpeg V4L2 Input](https://trac.ffmpeg.org/wiki/Capture/Webcam)
