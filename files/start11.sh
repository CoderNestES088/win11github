#!/bin/bash

WORKDIR="$HOME/win11-novnc"
ISO_NAME="Windows+X-Lite%5D+Micro+11+23H2+v2.iso"
ISO_PATH="$WORKDIR/$ISO_NAME"
IMG_PATH="$WORKDIR/win11.qcow2"
VNC_DISPLAY=":1"
VNC_PORT=5901
NOVNC_PORT=8080

mkdir -p "$WORKDIR"
cd "$WORKDIR"

# ----------------------------
# Remove OpenSSH (optional)
# ----------------------------
sudo apt remove -y openssh-server openssh-client openssh-sftp-server

# ----------------------------
# Update and install dependencies
# ----------------------------
sudo apt update
sudo apt install -y qemu-system-x86 qemu-utils qemu-kvm \
    tigervnc-standalone-server tigervnc-common \
    net-tools wget curl git python3 python3-pip npm nodejs netcat

# Upgrade websockify
sudo pip3 install --upgrade websockify

# Install noVNC via npm
sudo npm install -g @novnc/novnc

# ----------------------------
# Download ISO if missing
# ----------------------------
if [ ! -f "$ISO_PATH" ]; then
    echo "Downloading Windows 11 Lite ISO..."
    wget --progress=bar:force -O "$ISO_PATH" "https://download1527.mediafire.com/vkk7erux05yg0T7UOiqYHKxju2L8vaiX4VVxpELWbOxckzrQvIWo-wjxOrXF1ZoMbSVQJfTZry6awLjJGlIIY-thoAqqMgKKWoURDi93YgAqYV1gFXTCcfleEEsx5mYCxLdUUAiMbSL2NCO0yrqkgNdlVGxkgLek7yTqW2Dq_fI/x3911f43epuvpcf/$ISO_NAME"
fi

# ----------------------------
# Create QCOW2 disk if missing
# ----------------------------
if [ ! -f "$IMG_PATH" ]; then
    echo "Creating new virtual disk: win11.qcow2 (40G)..."
    qemu-img create -f qcow2 "$IMG_PATH" 40G
fi

# ----------------------------
# Kill previous instances
# ----------------------------
pkill -f qemu-system-x86_64
pkill -f Xvnc
pkill -f websockify

# ----------------------------
# Start TigerVNC server
# ----------------------------
echo "Starting TigerVNC server on display $VNC_DISPLAY..."
Xvnc $VNC_DISPLAY -geometry 1920x1080 -depth 24 -rfbport $VNC_PORT -SecurityTypes None &

# Wait for VNC server
echo "Waiting for TigerVNC..."
while ! nc -z localhost $VNC_PORT; do
    sleep 1
done
echo "TigerVNC ready!"

# ----------------------------
# Start noVNC via npm
# ----------------------------
echo "Launching noVNC on port $NOVNC_PORT..."
websockify $NOVNC_PORT localhost:$VNC_PORT &

# ----------------------------
# Launch QEMU VM
# ----------------------------
echo "Launching QEMU VM..."
qemu-system-x86_64 \
    -enable-kvm \
    -m 4G \
    -cpu host \
    -smp 2 \
    -hda "$IMG_PATH" \
    -cdrom "$ISO_PATH" \
    -boot d \
    -vnc $VNC_DISPLAY \
    -vga virtio &

# ----------------------------
# Browser access
# ----------------------------
echo "Setup complete!"
echo "Open in browser:"
echo "http://localhost:$NOVNC_PORT/vnc.html?host=localhost&port=$NOVNC_PORT"

