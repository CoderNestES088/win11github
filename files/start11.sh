#!/bin/bash
set -e

# -----------------------
# Configurable variables
# -----------------------
WORKDIR="$HOME/win11-novnc"
IMG_PATH="$WORKDIR/win11.qcow2"
ISO_PATH="$WORKDIR/win11-lite.iso"
NOVNC_DIR="$WORKDIR/noVNC"
MEMORY=4096
CPUS=2
VNC_DISPLAY=:1
NOVNC_PORT=6080

ISO_URL="https://download1527.mediafire.com/vkk7erux05yg0T7UOiqYHKxju2L8vaiX4VVxpELWbOxckzrQvIWo-wjxOrXF1ZoMbSVQJfTZry6awLjJGlIIY-thoAqqMgKKWoURDi93YgAqYV1gFXTCcfleEEsx5mYCxLdUUAiMbSL2NCO0yrqkgNdlVGxkgLek7yTqW2Dq_fI/x3911f43epuvpcf/Windows+X-Lite%5D+Micro+11+23H2+v2.iso"

# -----------------------
# Prepare environment
# -----------------------
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# -----------------------
# Download ISO if missing
# -----------------------
if [ ! -f "$ISO_PATH" ]; then
    echo "Downloading Windows 11 Lite ISO..."
    wget -O "$ISO_PATH" "$ISO_URL"
else
    echo "ISO already present."
fi

# -----------------------
# Create disk if missing
# -----------------------
if [ ! -f "$IMG_PATH" ]; then
    echo "Creating new QCOW2 disk (40G)..."
    qemu-img create -f qcow2 "$IMG_PATH" 40G
else
    echo "QCOW2 disk already exists."
fi

# -----------------------
# Clone noVNC if missing
# -----------------------
if [ ! -d "$NOVNC_DIR" ]; then
    echo "Cloning noVNC..."
    git clone https://github.com/novnc/noVNC.git "$NOVNC_DIR"
fi

# -----------------------
# Start TigerVNC
# -----------------------
echo "Starting TigerVNC server..."
vncserver -kill $VNC_DISPLAY >/dev/null 2>&1 || true
vncserver $VNC_DISPLAY -geometry 1920x1080 -depth 24

# -----------------------
# Start QEMU
# -----------------------
echo "Starting QEMU..."
qemu-system-x86_64 \
  -m $MEMORY \
  -smp $CPUS \
  -cpu host \
  -hda "$IMG_PATH" \
  -cdrom "$ISO_PATH" \
  -boot d \
  -vga qxl \
  -display vnc=$VNC_DISPLAY \
  -usb -device usb-tablet \
  -net nic -net user &

sleep 5

# -----------------------
# Start noVNC
# -----------------------
echo "Starting noVNC on port $NOVNC_PORT..."
websockify $NOVNC_PORT localhost:5901 --web=$NOVNC_DIR &

echo "✅ Windows 11 Lite setup running!"
echo "🌍 Open in browser: http://localhost:$NOVNC_PORT"
