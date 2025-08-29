#!/bin/bash

# -----------------------
# Configurable variables
# -----------------------

IMG_PATH="$HOME/win11-lite.img"      # Path to Windows 11 Lite image
NOVNC_DIR="$HOME/noVNC"              # Local noVNC clone
MEMORY=4096                          # VM RAM
CPUS=2                               # VM CPUs
VNC_DISPLAY=:1                        # VNC display
NOVNC_PORT=6080                       # noVNC web port

# -----------------------
# Check for QEMU image
# -----------------------
if [ ! -f "$IMG_PATH" ]; then
    echo "ERROR: Windows 11 Lite image not found at $IMG_PATH"
    echo "Please download or move 'win11-lite.img' to $HOME"
    exit 1
fi

# -----------------------
# Check for noVNC
# -----------------------
if [ ! -d "$NOVNC_DIR" ]; then
    echo "noVNC not found, cloning..."
    git clone https://github.com/novnc/noVNC.git "$NOVNC_DIR"
fi

# -----------------------
# Start QEMU
# -----------------------
echo "Starting Windows 11 Lite VM..."
qemu-system-x86_64 \
  -m $MEMORY \
  -smp $CPUS \
  -cpu host \
  -hda "$IMG_PATH" \
  -vga qxl \
  -display vnc=$VNC_DISPLAY \
  -usb -device usb-tablet \
  -net nic -net user &

sleep 3

# -----------------------
# Start noVNC
# -----------------------
echo "Starting noVNC..."
websockify $NOVNC_PORT localhost:$(expr 5900 + ${VNC_DISPLAY#:}) --web=$NOVNC_DIR &

echo "Windows 11 Lite should be accessible via http://localhost:$NOVNC_PORT/"
