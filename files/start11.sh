#!/bin/bash

# Working directory
WORKDIR="$HOME/win11-novnc"
ISO_PATH="$WORKDIR/Win11Lite.iso"
IMG_PATH="$WORKDIR/win11.img"
QEMU_DIR="$WORKDIR/qemu"

mkdir -p "$WORKDIR"
mkdir -p "$QEMU_DIR"
cd "$WORKDIR"

# 1️⃣ Download prebuilt QEMU if missing
if [ ! -f "$QEMU_DIR/qemu-system-x86_64" ]; then
    echo "Downloading prebuilt QEMU..."
    wget -O "$QEMU_DIR/qemu.tar.xz" "https://download.qemu.org/qemu-8.2.0.tar.xz"
    tar -xf qemu.tar.xz -C "$QEMU_DIR" --strip-components=1
    chmod +x "$QEMU_DIR/qemu-system-x86_64"
fi

# 2️⃣ Install Python3 + websockify/noVNC
sudo apt-get update
sudo apt-get install -y python3 python3-pip wget curl novnc websockify x11vnc || true

# 3️⃣ Download ISO if missing
if [ ! -f "$ISO_PATH" ]; then
    echo "Downloading Windows 11 Lite ISO..."
    wget --progress=bar:force -O "$ISO_PATH" "https://download1527.mediafire.com/vkk7erux05yg0T7UOiqYHKxju2L8vaiX4VVxpELWbOxckzrQvIWo-wjxOrXF1ZoMbSVQJfTZry6awLjJGlIIY-thoAqqMgKKWoURDi93YgAqYV1gFXTCcfleEEsx5mYCxLdUUAiMbSL2NCO0yrqkgNdlVGxkgLek7yTqW2Dq_fI/x3911f43epuvpcf/%5BWindows+X-Lite%5D+Micro+11+23H2+v2.iso"
fi

# 4️⃣ Create VM disk if missing
if [ ! -f "$IMG_PATH" ]; then
    echo "Creating virtual disk (40G)..."
    "$QEMU_DIR/qemu-img" create -f qcow2 "$IMG_PATH" 40G
fi

# 5️⃣ Kill previous instances
pkill -f qemu-system-x86_64
pkill -f websockify

# 6️⃣ Start QEMU VM
echo "Starting Windows 11 Lite in QEMU..."
"$QEMU_DIR/qemu-system-x86_64" \
    -m 4G \
    -cpu host \
    -smp 2 \
    -hda "$IMG_PATH" \
    -cdrom "$ISO_PATH" \
    -boot d \
    -vnc :0 \
    -vga virtio &

sleep 3

# 7️⃣ Start noVNC
echo "Starting noVNC on port 8080..."
websockify --web=/usr/share/novnc/ 8080 localhost:5900 &

echo "Setup complete! Open your browser at http://localhost:8080"



