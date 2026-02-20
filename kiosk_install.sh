#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]; then
  echo "Uruchom przez sudo:"
  echo "sudo bash install_kiosk.sh"
  exit 1
fi

set -e

APP_DIR="/opt/kiosk"
USER_NAME=pi
USER_HOME=/home/pi

echo "Install user: $USER_NAME"
echo "Install dir : $APP_DIR"

echo "=== KIOSK INSTALL START ==="

# --------------------------------------------------
# SYSTEM UPDATE
# --------------------------------------------------
apt update
apt install -y --no-install-recommends \
  python3 python3-venv python3-pip python3-dev python3-xdg \
  xserver-xorg x11-xserver-utils xinit openbox \
  chromium unclutter \
  fonts-dejavu curl

# --------------------------------------------------
# APP DIRECTORY
# --------------------------------------------------

echo "=== APP DIRECTORY SETUP ==="

mkdir -p ${APP_DIR}
chown -R ${USER_NAME}:${USER_NAME} ${APP_DIR}

# --------------------------------------------------
# PYTHON ENV
# --------------------------------------------------

echo "=== PYTHON ENV SETUP ==="

sudo -u ${USER_NAME} bash <<EOF
cd ${APP_DIR}
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install fastapi uvicorn
EOF

# --------------------------------------------------
# FASTAPI APP
# --------------------------------------------------

echo "=== FASTAPI APP SETUP ==="

cat > ${APP_DIR}/app.py <<'PY'
from fastapi import FastAPI
from fastapi.responses import HTMLResponse

app = FastAPI()

@app.get("/", response_class=HTMLResponse)
def root():
    return """
    <html>
    <body style="background:#111;color:#eee;font-family:sans-serif;">
        <h1>Kiosk OK</h1>
        <p>FastAPI działa</p>
    </body>
    </html>
    """
PY

chown ${USER_NAME}:${USER_NAME} ${APP_DIR}/app.py

# --------------------------------------------------
# FASTAPI SERVICE
# --------------------------------------------------

echo "=== FASTAPI SERVICE SETUP ==="

cat > /etc/systemd/system/kiosk-api.service <<EOF
[Unit]
Description=Kiosk FastAPI
After=network.target

[Service]
Type=simple
User=${USER_NAME}
WorkingDirectory=${APP_DIR}
ExecStart=${APP_DIR}/.venv/bin/uvicorn app:app --host 127.0.0.1 --port 8000
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

# --------------------------------------------------
# KIOSK START SCRIPT
# --------------------------------------------------

echo "=== KIOSK START SCRIPT SETUP ==="

cat > "${APP_DIR}/start-kiosk.sh" <<'SH'
#!/bin/bash

xset s off
xset s noblank
xset -dpms

unclutter -idle 0.1 -root &

exec chromium \
  --kiosk --app=http://127.0.0.1:8000/ \
  --ozone-platform=x11 \
  --enable-features=UseOzonePlatform \
  --disable-gpu-compositing \
  --disable-gpu-rasterization \
  --noerrdialogs \
  --disable-infobars \
  --disable-session-crashed-bubble \
  --overscroll-history-navigation=0 \
  --check-for-update-interval=31536000
SH

chmod +x "${APP_DIR}/start-kiosk.sh"
chown ${USER_NAME}:${USER_NAME} ${APP_DIR}/start-kiosk.sh

# --------------------------------------------------
# XINITRC (pewny start X)
# --------------------------------------------------

sudo -u "$USER_NAME" bash <<EOF
cat > "$USER_HOME/.xinitrc" <<XRC
#!/bin/sh
xset s off
xset -dpms
xset s noblank
unclutter -idle 0.2 -root &
exec $APP_DIR/start-kiosk.sh
XRC
chmod 700 "$USER_HOME/.xinitrc"
EOF

# -----------------------------
# Autologin on tty1 for KIOSK_USER
# ------------------

mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER_NAME --noclear %I \$TERM
EOF


# -----------------------------
# Start X automatically on tty1 (in .bash_profile)
# -----------------------------
# Dodajemy blok tylko jeśli go nie ma, żeby nie dublować
BASH_PROFILE="$KIOSK_HOME/.bash_profile"
MARK_BEGIN="# --- kiosk autostart begin ---"
MARK_END="# --- kiosk autostart end ---"

sudo -u "$KIOSK_USER" bash <<EOF
set -e
touch "$BASH_PROFILE"
if ! grep -qF "$MARK_BEGIN" "$BASH_PROFILE"; then
  cat >> "$BASH_PROFILE" <<'PROFILE'

# --- kiosk autostart begin ---
# Start X tylko na konsoli tty1, nie przez SSH
if [ -z "\$DISPLAY" ] && [ "\$(tty)" = "/dev/tty1" ]; then
  startx
fi
# --- kiosk autostart end ---
PROFILE
fi
EOF



# --------------------------------------------------
# ENABLE SERVICES
# --------------------------------------------------

echo "=== ENABLING SERVICES ==="

systemctl daemon-reload
systemctl enable kiosk-api.service

echo "=== INSTALL DONE ==="
echo "Reboot system now:"
echo "sudo reboot"
