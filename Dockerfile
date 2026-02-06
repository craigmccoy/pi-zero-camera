FROM python:3.11-slim-bookworm

ENV DEBIAN_FRONTEND=noninteractive

# Install only the tools needed inside the container
# Camera access is via /dev/video0 device mount, not via libcamera/rpicam
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    v4l-utils \
    netcat-openbsd \
    procps \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY stream_camera.py /app/
RUN chmod +x /app/stream_camera.py

CMD ["python3", "-u", "/app/stream_camera.py"]
