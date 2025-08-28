#!/bin/bash

# Working directory
WORKDIR="$HOME/win11-novnc"
ISO_PATH="$WORKDIR/Win11Lite.iso"
IMG_PATH="$WORKDIR/win11.img"

mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "Installing required packages..."
sudo apt-get update
sudo apt-get install -y qemu qemu-kvm wget curl python3 python3-pip novnc websockify x11vnc

# Check installation
for cmd in qemu-system-x86_64 websockify wget; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd not installed correctly."
        exit 1
    fi
done
echo "All dependencies installed."

# Download ISO if missing
if [ ! -f "$ISO_PATH" ]; then
    echo "Windows 11 Lite ISO not found. Downloading..."
    wget --progress=bar:force -O "$ISO_PATH" "https://download1527.mediafire.com/vkk7erux05yg0T7UOiqYHKxju2L8vaiX4VVxpELWbOxckzrQvIWo-wjxOrXF1ZoMbSVQJfTZry6awLjJGlIIY-thoAqqMgKKWoURDi93YgAqYV1gFXTCcfleEEsx5mYCxLdUUAiMbSL2NCO0yrqkgNdlVGxkgLek7yTqW2Dq_fI/x3911f43epuvpcf/%5BWindows+X-Lite%5D+Micro+11+23H2+v2.iso"
fi

# Create virtual disk if missing
if [ ! -f "$IMG_PATH" ]; then
    echo "Creating virtual disk (40G)..."
    qemu-img create -f qcow2 "$IMG_PATH" 40G
fi

# Kill previous instances
pkill -f qemu-system-x86_64
pkill -f websockify

# Start QEMU VM
echo "Starting Windows 11 Lite in QEMU..."
qemu-system-x86_64 \
    -m 4G \
    -cpu host \
    -smp 2 \
    -hda "$IMG_PATH" \
    -cdrom "$ISO_PATH" \
    -boot d \
    -vnc :0 \
    -vga virtio &

sleep 3

# Start noVNC
echo "Launching noVNC on port 8080..."
websockify --web=/usr/share/novnc/ 8080 localhost:5900 &

echo "Setup complete! Open your browser at http://localhost:8080"



