FROM python:3.11-slim-bookworm

ENV DEBIAN_FRONTEND=noninteractive

# Add Raspberry Pi repository for rpicam-apps
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    gnupg \
    && wget -qO - https://archive.raspberrypi.org/debian/raspberrypi.gpg.key | gpg --dearmor -o /usr/share/keyrings/raspberrypi-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/raspberrypi-archive-keyring.gpg] https://archive.raspberrypi.org/debian/ bookworm main" > /etc/apt/sources.list.d/raspi.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    ffmpeg \
    v4l-utils \
    netcat-openbsd \
    procps \
    rpicam-apps \
    libcamera0 \
    libcamera-tools \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY stream_camera.py /app/
RUN chmod +x /app/stream_camera.py

CMD ["python3", "-u", "/app/stream_camera.py"]
