#!/bin/sh

xset -dpms     # disable DPMS (Energy Star) features.
xset s off     # disable screen saver
xset s noblank # don't blank the video device

matchbox-window-manager -use_titlebar no &
unclutter &    # hide X mouse cursor unless mouse activated

#chromium --display=:0 --kiosk --incognito --window-position=0,0 https://jbhn.pl/
exec python3 /opt/kiosk/app.py