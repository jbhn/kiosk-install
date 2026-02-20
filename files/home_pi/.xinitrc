#!/bin/sh
xset s off
xset -dpms
xset s noblank
unclutter -idle 0.2 -root &
exec /opt/kiosk/start-kiosk.sh
