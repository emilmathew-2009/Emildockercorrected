FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG AUDIVERIS_VERSION=5.11.0

ENV AUDIVERIS_VERSION=${AUDIVERIS_VERSION} \
    OMR_WORKDIR=/tmp/emil-omr \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

# Audiveris 5.11.0 is distributed as an Ubuntu 24.04 .deb, so use the
# matching Ubuntu base rather than a Debian python:slim image.
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-venv python3-pip \
    openjdk-17-jre-headless tesseract-ocr wget ca-certificates \
    libgl1 libglib2.0-0 libx11-6 libxext6 libxrender1 libxtst6 libxi6 \
    libfreetype6 fonts-dejavu ffmpeg \
    && rm -rf /var/lib/apt/lists/*

RUN wget -q -O /tmp/audiveris.deb \
    "https://github.com/Audiveris/audiveris/releases/download/${AUDIVERIS_VERSION}/Audiveris-${AUDIVERIS_VERSION}-ubuntu24.04-x86_64.deb" \
    && apt-get update \
    && apt-get install -y --no-install-recommends /tmp/audiveris.deb \
    && rm -f /tmp/audiveris.deb \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install --upgrade pip setuptools wheel

COPY requirements.txt /app/requirements.txt
RUN /opt/venv/bin/pip install --no-cache-dir -r /app/requirements.txt

COPY omr-service.py /app/omr-service.py
COPY audio_transcriber.py /app/audio_transcriber.py

EXPOSE 8000

CMD ["/opt/venv/bin/uvicorn", "omr-service:app", "--host", "0.0.0.0", "--port", "8000"]
