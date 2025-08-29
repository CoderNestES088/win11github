#!/bin/bash
set -e

# ----------------------------
# Update and install dependencies
# ----------------------------
sudo apt update
sudo apt install -y \
    qemu-system-x86 qemu-utils qemu-kvm \
    tigervnc-standalone-server tigervnc-common \
    netcat-openbsd wget curl git python3 python3-pip npm nodejs

# ----------------------------
# Install noVNC and Websockify
# ----------------------------
sudo pip3 install --upgrade websockify
sudo npm install -g @novnc/novnc

# ----------------------------
# Create working directory
# ----------------------------
WORKDIR="$HOME/win11-novnc"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# ----------------------------
# Download Windows 11 Lite ISO
# ----------------------------
ISO_URL="https://download1527.mediafire.com/vkk7erux05yg0T7UOiqYHKxju2L8vaiX4VVxpELWbOxckzrQvIWo-wjxOrXF1ZoMbSVQJfTZry6awLjJGlIIY-thoAqqMgKKWoURDi93YgAqYV1gFXTCcfleEEsx5mYCxLdUUAiMbSL2NCO0yrqkgNdlVGxkgLek7yTqW2Dq_fI/x3911f43epuvpcf/Windows+X-Lite%5D+Micro+11+23H2+v2.iso"
ISO_PATH="$WORKDIR/Windows_11_Lite.iso"

if [ ! -f "$ISO_PATH" ]; then
    echo "Downloading Windows 11 Lite ISO..."
    wget -O "$ISO_PATH" "$ISO_URL"
else
    echo "ISO already downloaded."
fi

# ----------------------------
# Create QCOW2 virtual disk
# ----------------------------
IMG_PATH="$WORKDIR/win11.qcow2"
if [ ! -f "$IMG_PATH" ]; then
    echo "Creating new virtual disk: win11.qcow2 (40G)..."
    qemu-img create -f qcow2 "$IMG_PATH" 40G
else
    echo "Virtual disk already exists."
fi

# ----------------------------
# Start TigerVNC server
# ----------------------------
VNC_DISPLAY=":1"
VNC_PASSWORD="1234" # you can change
mkdir -p "$HOME/.vnc"
echo "$VNC_PASSWORD" | vncpasswd -f > "$HOME/.vnc/passwd"
chmod 600 "$HOME/.vnc/passwd"

echo "Starting TigerVNC server on display $VNC_DISPLAY..."
Xvnc $VNC_DISPLAY -geometry 1920x1080 -depth 24 -rfbauth "$HOME/.vnc/passwd" -nolisten tcp -SecurityTypes=VncAuth &

# Wait for VNC server
sleep 5

# ----------------------------
# Start QEMU with Windows 11
# ----------------------------
echo "Starting QEMU..."
qemu-system-x86_64 \
    -enable-kvm \
    -m 4G \
    -cpu host \
    -smp 2 \
    -vnc :1 \
    -hda "$IMG_PATH" \
    -cdrom "$ISO_PATH" \
    -boot d &

# ----------------------------
# Start noVNC
# ----------------------------
NOVNC_PORT=8080
echo "Starting noVNC on port $NOVNC_PORT..."
websockify $NOVNC_PORT localhost:5901 &
echo "noVNC running at http://localhost:$NOVNC_PORT"
