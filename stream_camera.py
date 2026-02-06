#!/usr/bin/env python3
import os
import subprocess
import sys
import time
import signal
from pathlib import Path

class CameraStreamer:
    def __init__(self):
        self.camera_name = os.getenv('CAMERA_NAME', 'pi-camera')
        self.rtsp_server = os.getenv('RTSP_SERVER', 'mediamtx')
        self.rtsp_port = os.getenv('RTSP_PORT', '8554')
        self.resolution = os.getenv('RESOLUTION', '1280x720')
        self.framerate = int(os.getenv('FRAMERATE', '15'))
        self.bitrate = int(os.getenv('BITRATE', '2000000'))
        
        self.width, self.height = map(int, self.resolution.split('x'))
        self.rtsp_url = f"rtsp://{self.rtsp_server}:{self.rtsp_port}/camera"
        
        self.process = None
        signal.signal(signal.SIGTERM, self.signal_handler)
        signal.signal(signal.SIGINT, self.signal_handler)
    
    def signal_handler(self, signum, frame):
        print(f"\nReceived signal {signum}, shutting down gracefully...")
        self.cleanup()
        sys.exit(0)
    
    def cleanup(self):
        if self.process:
            print("Stopping camera stream...")
            self.process.terminate()
            try:
                self.process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                print("Force killing stream process...")
                self.process.kill()
    
    def wait_for_rtsp_server(self, max_retries=30):
        """Wait for MediaMTX server to be ready"""
        print(f"Waiting for RTSP server at {self.rtsp_server}:{self.rtsp_port}...")
        for i in range(max_retries):
            try:
                result = subprocess.run(
                    ['nc', '-z', self.rtsp_server, self.rtsp_port],
                    capture_output=True,
                    timeout=2
                )
                if result.returncode == 0:
                    print("RTSP server is ready!")
                    return True
            except (subprocess.TimeoutExpired, FileNotFoundError):
                pass
            
            if i < max_retries - 1:
                time.sleep(1)
        
        print("Warning: Could not verify RTSP server, proceeding anyway...")
        return False
    
    def detect_camera_method(self):
        """Detect which camera interface to use"""
        if Path('/dev/video0').exists():
            return 'v4l2'
        else:
            raise RuntimeError("No camera device found at /dev/video0")
    
    def build_ffmpeg_command(self):
        """Build FFmpeg command for streaming with OV5647 camera"""
        cmd = [
            'ffmpeg',
            '-f', 'v4l2',
            '-input_format', 'h264',
            '-video_size', self.resolution,
            '-framerate', str(self.framerate),
            '-i', '/dev/video0',
            '-c:v', 'copy',
            '-f', 'rtsp',
            '-rtsp_transport', 'tcp',
            self.rtsp_url
        ]
        return cmd
    
    def build_libcamera_command(self):
        """Build libcamera-vid command for streaming"""
        cmd = [
            'libcamera-vid',
            '--width', str(self.width),
            '--height', str(self.height),
            '--framerate', str(self.framerate),
            '--bitrate', str(self.bitrate),
            '--codec', 'h264',
            '--inline',
            '--listen',
            '-t', '0',
            '-o', '-',
            '|', 'ffmpeg',
            '-f', 'h264',
            '-i', 'pipe:0',
            '-c:v', 'copy',
            '-f', 'rtsp',
            '-rtsp_transport', 'tcp',
            self.rtsp_url
        ]
        return ' '.join(cmd)
    
    def start_stream(self):
        """Start the camera stream"""
        print(f"Starting camera stream: {self.camera_name}")
        print(f"Resolution: {self.resolution} @ {self.framerate}fps")
        print(f"Bitrate: {self.bitrate}")
        print(f"RTSP URL: {self.rtsp_url}")
        
        self.wait_for_rtsp_server()
        
        camera_method = self.detect_camera_method()
        print(f"Using camera method: {camera_method}")
        
        cmd = self.build_ffmpeg_command()
        print(f"Command: {' '.join(cmd)}")
        self.process = subprocess.Popen(cmd)
        
        print(f"\n{'='*60}")
        print(f"Camera stream is running!")
        print(f"Access stream at: {self.rtsp_url}")
        print(f"For Frigate, use: rtsp://<PI_IP>:{self.rtsp_port}/camera")
        print(f"{'='*60}\n")
        
        try:
            self.process.wait()
        except KeyboardInterrupt:
            print("\nInterrupted by user")
        finally:
            self.cleanup()

def main():
    print("="*60)
    print("Pi Zero Camera Streamer for Frigate")
    print("="*60)
    
    try:
        streamer = CameraStreamer()
        streamer.start_stream()
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
