FROM python:3.11-slim-bookworm

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    ffmpeg \
    v4l-utils \
    netcat-openbsd \
    procps \
    rpicam-apps \
    libcamera-tools \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY stream_camera.py /app/
RUN chmod +x /app/stream_camera.py

CMD ["python3", "-u", "/app/stream_camera.py"]
