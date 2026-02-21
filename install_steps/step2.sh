#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]; then
  echo "Run as su:"
  exit 1
fi

apt install -y \
    xserver-xorg \
    xinit \
    x11-xserver-utils \
    unclutter \
    matchbox-window-manager\
    fonts-liberation 

