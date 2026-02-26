#!/bin/bash
set -e

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  🔥 VIRAL EMPIRE - ClawCloud Run Edition"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "📦 System Info:"
echo "  ├── n8n:     $(n8n --version 2>/dev/null || echo 'loading...')"
echo "  ├── Node.js: $(node --version)"
echo "  ├── FFmpeg:  $(ffmpeg -version 2>&1 | head -1 | awk '{print $3}')"
echo "  ├── yt-dlp:  $(yt-dlp --version 2>/dev/null || echo 'unknown')"
echo "  └── Python:  $(python3 --version 2>&1 | awk '{print $2}')"
echo ""

# Memory watchdog - clean temp files if memory > 80%
(while true; do
    MEM_TOTAL=$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)
    MEM_AVAIL=$(awk '/MemAvailable/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)
    if [ "$MEM_TOTAL" -gt 0 ]; then
        MEM_USED=$(( (MEM_TOTAL - MEM_AVAIL) * 100 / MEM_TOTAL ))
        if [ "$MEM_USED" -gt 80 ]; then
            echo "⚠️ Memory: ${MEM_USED}% - Cleaning temp files..."
            find /tmp/n8n-videos -type f -mmin +5 -delete 2>/dev/null || true
            find /tmp/n8n-clips -type f -mmin +5 -delete 2>/dev/null || true
            find /tmp/whisper_audio -type f -mmin +10 -delete 2>/dev/null || true
        fi
    fi
    sleep 60
done) &

# Ensure directories exist
mkdir -p /tmp/videos /tmp/whisper_audio /tmp/n8n-videos /tmp/n8n-clips 2>/dev/null || true
touch /data/cookies/cookies.txt 2>/dev/null || true

# Update yt-dlp in background
(yt-dlp -U >/dev/null 2>&1 || echo "yt-dlp up to date") &

echo "🔗 Webhook URL: ${WEBHOOK_URL:-NOT SET}"
echo "🌐 Port: ${N8N_PORT:-5678}"
echo "⏰ TZ: ${TZ:-UTC}"
echo ""
echo "🚀 Starting n8n..."
echo ""

exec n8n start
