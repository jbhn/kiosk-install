#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]; then
  echo "Run as su:"
  exit 1
fi

cat files/bashrc-additions >> /home/pi/.bashrc