#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]; then
  echo "Run as su:"
  exit 1
fi

set -e

echo "### STEP 1: apt update"
bash install_steps/step1.sh

echo "### STEP 2: X Window system and required components"
bash install_steps/step2.sh

echo "### STEP 3: Installing Chromium"
bash install_steps/step3.sh

echo "### Step 4: Create kiosk and startup script"
bash install_steps/step4.sh

echo "### Step 5: Add kiosk startup to .bashrc"
bash install_steps/step5.sh