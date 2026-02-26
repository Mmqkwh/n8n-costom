# ============================================
# n8n Custom Image with yt-dlp + FFmpeg + Python
# Designed for Viral Empire Workflow V37
# ============================================

# Stage 1: Get apk back from clean Alpine
FROM alpine:3.20 AS alpine-source

# Stage 2: Build the custom n8n image
FROM n8nio/n8n:latest

# Copy apk package manager from Alpine (removed in n8n v2.x hardened images)
COPY --from=alpine-source /sbin/apk /sbin/apk
COPY --from=alpine-source /etc/apk /etc/apk
COPY --from=alpine-source /usr/lib/libapk* /usr/lib/
COPY --from=alpine-source /lib/libcrypto* /lib/
COPY --from=alpine-source /lib/libssl* /lib/
COPY --from=alpine-source /lib/libz* /lib/

# Switch to root for installations
USER root

# Initialize apk and install all required tools
RUN apk add --no-cache --initdb \
    --repository https://dl-cdn.alpinelinux.org/alpine/v3.20/main \
    --repository https://dl-cdn.alpinelinux.org/alpine/v3.20/community \
    ffmpeg \
    python3 \
    py3-pip \
    curl \
    wget \
    bash \
    ca-certificates \
    && rm -rf /var/cache/apk/*

# Install yt-dlp via pip
RUN python3 -m pip install --no-cache-dir --break-system-packages yt-dlp

# Create required directories with proper permissions
RUN mkdir -p /tmp/n8n-videos /tmp/whisper_audio /tmp/n8n-clips /data \
    && chown -R node:node /tmp/n8n-videos /tmp/whisper_audio /tmp/n8n-clips /data

# Verify installations
RUN ffmpeg -version | head -1 && \
    ffprobe -version | head -1 && \
    yt-dlp --version && \
    python3 --version

# Switch back to node user (security best practice)
USER node

# n8n default port
EXPOSE 5678

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:5678/healthz || exit 1
