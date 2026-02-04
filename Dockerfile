FROM python:3.11-slim-bookworm

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies and add RPi repository
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    gnupg \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 82B129927FA3303E \
    && echo "deb http://archive.raspberrypi.org/debian/ bookworm main" | tee /etc/apt/sources.list.d/raspberrypi.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    ffmpeg \
    v4l-utils \
    netcat-openbsd \
    procps \
    libcamera-apps \
    libcamera-tools \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY stream_camera.py /app/
RUN chmod +x /app/stream_camera.py

CMD ["python3", "-u", "/app/stream_camera.py"]
