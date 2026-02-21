#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]; then
  echo "Run as su:"
  exit 1
fi

mkdir -p /opt/kiosk
chown pi:pi /opt/kiosk

install -m775 -o pi -g pi files/run-kiosk.sh /opt/kiosk/kiosk.sh