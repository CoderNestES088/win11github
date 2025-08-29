#!/bin/bash

# Path to your Windows 11 Lite disk image
IMG_PATH="/data/data/com.termux/files/home/win11-lite.img"

# VM settings
MEMORY=4096          # RAM in MB
CPUS=2               # Number of CPU cores

# VNC/novnc settings
VNC_DISPLAY=:1       # VNC display number (5900 + 1 = 5901)
NOVNC_PORT=6080      # Browser access port

# Check if QEMU is installed
command -v qemu-system-x86_64 >/dev/null 2>&1 || { echo >&2 "QEMU not installed. Aborting."; exit 1; }

# Start Windows 11 Lite with fixes
qemu-system-x86_64 \
  -m $MEMORY \
  -smp $CPUS \
  -cpu host \
  -hda "$IMG_PATH" \
  -vga qxl \
  -display vnc=$VNC_DISPLAY \
  -usb -device usb-tablet \
  -net nic -net user &

# Wait a bit for QEMU to start
sleep 3

# Start noVNC web interface
websockify $NOVNC_PORT localhost:$(expr 5900 + ${VNC_DISPLAY#:}) --web=/usr/share/novnc/ &

echo "Windows 11 Lite should be accessible via http://localhost:$NOVNC_PORT/"
