# ═══════════════════════════════════════════════════════════════
# VIRAL EMPIRE - ClawCloud Run Edition
# Optimized for: 4 vCPU, 8GB RAM, 10GB Storage
# Base: n8n official + ffmpeg + yt-dlp + Arabic fonts
# ═══════════════════════════════════════════════════════════════

FROM n8nio/n8n:2.9.4

USER root

# ═══════════════════════════════════════════════════════════════
# Install required tools
# n8n 2.x is based on Alpine Linux
# ═══════════════════════════════════════════════════════════════
RUN apk add --no-cache \
    bash \
    curl \
    wget \
    ffmpeg \
    python3 \
    py3-pip \
    jq \
    file \
    tzdata \
    tini \
    fontconfig \
    font-noto \
    font-noto-arabic \
    && fc-cache -f -v

# ═══════════════════════════════════════════════════════════════
# Install yt-dlp (latest)
# ═══════════════════════════════════════════════════════════════
RUN python3 -m pip install --break-system-packages --no-cache-dir yt-dlp \
    && yt-dlp --version

# ═══════════════════════════════════════════════════════════════
# Create required directories
# ═══════════════════════════════════════════════════════════════
RUN mkdir -p \
    /data/.n8n/config \
    /data/.n8n/custom \
    /data/cookies \
    /tmp/videos \
    /tmp/whisper_audio \
    /tmp/n8n-videos \
    /tmp/n8n-clips \
    && touch /data/cookies/cookies.txt \
    && chmod -R 777 /data /tmp/videos /tmp/whisper_audio /tmp/n8n-videos /tmp/n8n-clips

# ═══════════════════════════════════════════════════════════════
# Timezone
# ═══════════════════════════════════════════════════════════════
ENV TZ=Asia/Riyadh
ENV GENERIC_TIMEZONE=Asia/Riyadh

# ═══════════════════════════════════════════════════════════════
# n8n Core Settings
# These are DEFAULTS - override them in ClawCloud env vars
# ═══════════════════════════════════════════════════════════════
ENV N8N_PORT=5678
ENV N8N_HOST=0.0.0.0
ENV N8N_PROTOCOL=https
ENV NODE_ENV=production

# ═══════════════════════════════════════════════════════════════
# n8n Data Directory
# ═══════════════════════════════════════════════════════════════
ENV N8N_USER_FOLDER=/data/.n8n
ENV N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=false

# ═══════════════════════════════════════════════════════════════
# Task Runner (for long FFmpeg operations)
# ═══════════════════════════════════════════════════════════════
ENV N8N_RUNNERS_ENABLED=true
ENV N8N_RUNNERS_TASK_TIMEOUT=3600
ENV N8N_RUNNERS_MAX_PAYLOAD=1073741824
ENV EXECUTIONS_TIMEOUT=7200
ENV EXECUTIONS_TIMEOUT_MAX=14400

# ═══════════════════════════════════════════════════════════════
# Code Node Permissions (CRITICAL for yt-dlp + ffmpeg)
# ═══════════════════════════════════════════════════════════════
ENV NODE_FUNCTION_ALLOW_BUILTIN=*
ENV NODE_FUNCTION_ALLOW_EXTERNAL=*
ENV N8N_BLOCK_ENV_ACCESS_IN_NODE=false
ENV EXECUTIONS_PROCESS=main

# ═══════════════════════════════════════════════════════════════
# Database (SQLite)
# ═══════════════════════════════════════════════════════════════
ENV DB_TYPE=sqlite
ENV DB_SQLITE_DATABASE=/data/database.sqlite

# ═══════════════════════════════════════════════════════════════
# Execution pruning (save memory)
# ═══════════════════════════════════════════════════════════════
ENV EXECUTIONS_DATA_PRUNE=true
ENV EXECUTIONS_DATA_MAX_AGE=24
ENV EXECUTIONS_DATA_SAVE_ON_ERROR=all
ENV EXECUTIONS_DATA_SAVE_ON_SUCCESS=none
ENV EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS=true

# ═══════════════════════════════════════════════════════════════
# Memory optimization (4GB for n8n out of 8GB total)
# ═══════════════════════════════════════════════════════════════
ENV NODE_OPTIONS="--max-old-space-size=4096 --dns-result-order=ipv4first"

# ═══════════════════════════════════════════════════════════════
# Disable unnecessary features
# ═══════════════════════════════════════════════════════════════
ENV N8N_DIAGNOSTICS_ENABLED=false
ENV N8N_VERSION_NOTIFICATIONS_ENABLED=false
ENV N8N_TEMPLATES_ENABLED=true
ENV N8N_HIRING_BANNER_ENABLED=false
ENV N8N_PERSONALIZATION_ENABLED=false

# ═══════════════════════════════════════════════════════════════
# Startup script
# ═══════════════════════════════════════════════════════════════
COPY start.sh /start.sh
RUN chmod +x /start.sh

WORKDIR /data

EXPOSE 5678

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD wget -q --spider http://localhost:5678/healthz || exit 1

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/start.sh"]
