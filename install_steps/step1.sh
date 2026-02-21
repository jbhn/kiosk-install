#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]; then
  echo "Run as su:"
  exit 1
fi

apt update