#!/usr/bin/env bash
set -e

# X powinien już działać (uruchamiane z ~/.xinitrc)
xset s off || true
xset s noblank || true
xset -dpms || true

unclutter -idle 0.2 -root &

exec chromium \
  --kiosk --app=http://127.0.0.1:8989/ \
  --ozone-platform=x11 \
  --enable-features=UseOzonePlatform \
  --disable-gpu-compositing \
  --disable-gpu-rasterization \
  --noerrdialogs \
  --disable-infobars \
  --disable-session-crashed-bubble \
  --overscroll-history-navigation=0 \
  --check-for-update-interval=31536000
