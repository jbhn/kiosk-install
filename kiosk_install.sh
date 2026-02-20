#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]; then
  echo "Uruchom przez sudo:"
  echo "sudo bash install_kiosk.sh"
  exit 1
fi

set -e

DEFAULT_APP_DIR="/opt/kiosk"

APP_DIR="${1:-$DEFAULT_APP_DIR}"

if [[ "$APP_DIR" != /* ]]; then
  echo "APP_DIR musi być ścieżką absolutną"
  exit 1
fi


USER_NAME="${SUDO_USER:-$(logname)}"
USER_HOME=$(eval echo "~$USER_NAME")

echo "Install user: $USER_NAME"
echo "Install dir : $APP_DIR"

echo "=== KIOSK INSTALL START ==="

# --------------------------------------------------
# SYSTEM UPDATE
# --------------------------------------------------
apt update
apt install -y --no-install-recommends \
  python3 python3-venv python3-pip \
  xserver-xorg x11-xserver-utils xinit openbox \
  chromium unclutter \
  fonts-dejavu curl

# --------------------------------------------------
# APP DIRECTORY
# --------------------------------------------------

echo "=== APP DIRECTORY SETUP ==="

mkdir -p "${APP_DIR}"
chown -R ${USER_NAME}:${USER_NAME} "${APP_DIR}"

# --------------------------------------------------
# PYTHON ENV
# --------------------------------------------------

echo "=== PYTHON ENV SETUP ==="

sudo -u ${USER_NAME} bash <<EOF
cd "${APP_DIR}"
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install fastapi "uvicorn[standard]"
EOF

# --------------------------------------------------
# FASTAPI APP
# --------------------------------------------------

echo "=== FASTAPI APP SETUP ==="

cat > "${APP_DIR}/app.py" <<'PY'
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

chown ${USER_NAME}:${USER_NAME} "${APP_DIR}/app.py"

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

chromium \
  --kiosk --app=http://127.0.0.1:8000/ \
  --noerrdialogs \
  --disable-infobars \
  --disable-session-crashed-bubble \
  --overscroll-history-navigation=0 \
  --check-for-update-interval=31536000
SH

chmod +x "${APP_DIR}/start-kiosk.sh"
chown ${USER_NAME}:${USER_NAME} "${APP_DIR}/start-kiosk.sh"

# --------------------------------------------------
# XINITRC (pewny start X)
# --------------------------------------------------

echo "=== XINITRC SETUP ==="

sudo -u ${USER_NAME} bash <<EOF
cat > "${USER_HOME}/.xinitrc" <<XRC
openbox-session &
sleep 2
exec ${APP_DIR}/start-kiosk.sh
XRC
EOF

# --------------------------------------------------
# UI SERVICE (X + Chromium)
# --------------------------------------------------

echo "=== UI SERVICE SETUP ==="

cat > /etc/systemd/system/kiosk-ui.service <<EOF
[Unit]
Description=Kiosk UI
After=systemd-user-sessions.service kiosk-api.service
Wants=kiosk-api.service

[Service]
User=${USER_NAME}
Environment=DISPLAY=:0
WorkingDirectory=${USER_HOME}
ExecStart=/usr/bin/startx
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# --------------------------------------------------
# ENABLE SERVICES
# --------------------------------------------------

echo "=== ENABLING SERVICES ==="

systemctl daemon-reload
systemctl enable kiosk-api.service
systemctl enable kiosk-ui.service

echo "=== INSTALL DONE ==="
echo "Reboot system now:"
echo "sudo reboot"
