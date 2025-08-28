#!/bin/bash

# Working directory
WORKDIR="$HOME/win11-novnc"
ISO_NAME="Windows+X-Lite%5D+Micro+11+23H2+v2.iso"
ISO_PATH="$WORKDIR/$ISO_NAME"
IMG_PATH="$WORKDIR/win11.qcow2"
NOVNC_DIR="$WORKDIR/novnc"

mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "Updating system and installing required packages..."
sudo apt update
sudo apt upgrade -y

sudo apt install -y \
    qemu-system qemu-utils qemu-kvm virt-manager \
    wget curl git python3 python3-pip novnc x11vnc net-tools unzip

# Install/upgrade websockify
sudo pip3 install --upgrade websockify

# Clone noVNC if missing
if [ ! -d "$NOVNC_DIR" ]; then
    echo "Downloading noVNC..."
    git clone https://github.com/novnc/noVNC.git "$NOVNC_DIR"
fi

# Download ISO if missing
if [ ! -f "$ISO_PATH" ]; then
    echo "Downloading Windows 11 Lite ISO..."
    wget --progress=bar:force -O "$ISO_PATH" "https://download1527.mediafire.com/vkk7erux05yg0T7UOiqYHKxju2L8vaiX4VVxpELWbOxckzrQvIWo-wjxOrXF1ZoMbSVQJfTZry6awLjJGlIIY-thoAqqMgKKWoURDi93YgAqYV1gFXTCcfleEEsx5mYCxLdUUAiMbSL2NCO0yrqkgNdlVGxkgLek7yTqW2Dq_fI/x3911f43epuvpcf/$ISO_NAME"
fi

# Create QCOW2 disk if missing
if [ ! -f "$IMG_PATH" ]; then
    echo "Creating new virtual disk: win11.qcow2 (40G)..."
    qemu-img create -f qcow2 "$IMG_PATH" 40G
fi

# Kill any previous instances
pkill -f qemu-system-x86_64
pkill -f websockify

# Start QEMU VM with VNC
echo "Starting Windows 11 Lite in QEMU..."
qemu-system-x86_64 \
    -enable-kvm \
    -m 4G \
    -cpu host \
    -smp 2 \
    -hda "$IMG_PATH" \
    -cdrom "$ISO_PATH" \
    -boot d \
    -vnc :0 \
    -vga virtio \
    &

sleep 5

# Start noVNC / websockify at the end
echo "Launching noVNC on port 8080..."
"$NOVNC_DIR/utils/novnc_proxy" --vnc localhost:5900 --listen 8080 &

# Confirm port 8080
sleep 2
echo "Checking open ports..."
ss -tulpn | grep 8080 || echo "Port 8080 not detected. noVNC may not be running."

echo "Setup complete! Open your browser at http://localhost:8080"


