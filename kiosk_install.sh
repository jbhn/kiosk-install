#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]; then
  echo "Run as su:"
  exit 1
fi

set -e

FILES_DIR="./files"

echo "Install user: pi"
echo "Install dir : /home/pi"

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

mkdir -p /opt/kiosk
chown -R pi:pi /opt/kiosk

# --------------------------------------------------
# PYTHON ENV
# --------------------------------------------------

echo "=== PYTHON ENV SETUP ==="

sudo -u pi bash <<EOF
cd /opt/kiosk
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install fastapi uvicorn
EOF

# --------------------------------------------------
# FASTAPI APP
# --------------------------------------------------

echo "=== FASTAPI APP SETUP ==="

install -m 0644 "$FILES_DIR/opt_kiosk/app.py" "/opt/kiosk/app.py"
install -m 0755 "$FILES_DIR/opt_kiosk/start-kiosk.sh" "/opt/kiosk/start-kiosk.sh"
chown pi:pi "/opt/kiosk/app.py" "/opt/kiosk/start-kiosk.sh"


# --------------------------------------------------
# FASTAPI SERVICE
# --------------------------------------------------

echo "=== FASTAPI SERVICE SETUP ==="

install -m 0644 "$FILES_DIR/systemd/kiosk-api.service" /etc/systemd/system/kiosk-api.service

# --------------------------------------------------
# AUTOLOGIN SETUP
# --------------------------------------------------

mkdir -p /etc/systemd/system/getty@tty1.service.d
install -m 0644 "$FILES_DIR/systemd/getty@tty1-autologin.conf" /etc/systemd/system/getty@tty1.service.d/autologin.conf

install -m 0700 "$FILES_DIR/home_pi/.xinitrc" /home/pi/.xinitrc
chown pi:pi /home/pi/.xinitrc

BASH_PROFILE="/home/pi/.bash_profile"
MARK_BEGIN="# --- kiosk autostart begin ---"
if [ ! -f "$BASH_PROFILE" ]; then
  touch "$BASH_PROFILE"
  chown pi:pi "$BASH_PROFILE"
fi

systemctl daemon-reload
systemctl enable --now kiosk-api.service

echo "=== INSTALL DONE ==="
echo "Now time to start: sudo reboot"