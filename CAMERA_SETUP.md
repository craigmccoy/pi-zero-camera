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

The newer Raspberry Pi OS uses `libcamera`/`rpicam` by default. This setup uses the modern camera stack.

#### Enable Camera

Edit the boot configuration:
```bash
sudo nano /boot/firmware/config.txt
```

Ensure these lines are present:
```
# Enable camera
camera_auto_detect=1
start_x=1
gpu_mem=128
```

Save and exit (Ctrl+X, Y, Enter).

#### Install rpicam-apps

```bash
# Install camera tools
sudo apt update
sudo apt install -y rpicam-apps
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

### 1. List Available Cameras
```bash
rpicam-hello --list-cameras
```
Expected output:
```
Available cameras
-----------------
0 : ov5647 [2592x1944 10-bit GBRG] (/base/soc/i2c0mux/i2c@1/ov5647@36)
    Modes: 'SGBRG10_CSI2P' : 640x480, 1296x972, 1920x1080, 2592x1944
```

### 2. Test Camera Preview (if display connected)
```bash
rpicam-hello --timeout 5000
```
Should show camera preview for 5 seconds.

### 3. Capture Test Image
```bash
rpicam-still -o test.jpg
```
Should create `test.jpg` in current directory.

### 4. Test Video Capture
```bash
rpicam-vid -t 5000 -o test.h264
```
Should create 5-second H.264 video file.

### 5. Check Device Files
```bash
ls -l /dev/video* /dev/media*
```
Should show multiple video and media devices.

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
- **V4L2 Output Formats**: MJPEG, YUYV (raw), RGB
- **Note**: Camera outputs raw video that is encoded to H.264 by FFmpeg for streaming

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
