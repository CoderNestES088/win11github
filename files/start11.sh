#!/bin/bash

# Working directory
WORKDIR="$HOME/win11-novnc"
ISO_PATH="$WORKDIR/Win11Lite.iso"
IMG_PATH="$WORKDIR/win11.img"

mkdir -p "$WORKDIR"
cd "$WORKDIR"

# Download ISO if missing
if [ ! -f "$ISO_PATH" ]; then
    echo "Windows 11 Lite ISO not found."
    echo "Downloading... Please wait."

    # Use wget with progress bar
    wget --progress=bar:force -O "$ISO_PATH" "https://download1527.mediafire.com/vkk7erux05yg0T7UOiqYHKxju2L8vaiX4VVxpELWbOxckzrQvIWo-wjxOrXF1ZoMbSVQJfTZry6awLjJGlIIY-thoAqqMgKKWoURDi93YgAqYV1gFXTCcfleEEsx5mYCxLdUUAiMbSL2NCO0yrqkgNdlVGxkgLek7yTqW2Dq_fI/x3911f43epuvpcf/%5BWindows+X-Lite%5D+Micro+11+23H2+v2.iso"

    if [ $? -ne 0 ]; then
        echo "Download failed! Please download the ISO manually and place it at $ISO_PATH"
        exit 1
    fi
fi

echo "ISO is ready!"

# Create Dockerfile
cat << 'EOF' > Dockerfile
FROM ubuntu:24.04
RUN apt-get update && apt-get install -y \
    qemu qemu-kvm libvirt-daemon-system libvirt-clients \
    wget curl python3 python3-pip novnc websockify x11vnc \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
WORKDIR /windows
COPY start.sh /windows/start.sh
RUN chmod +x /windows/start.sh
EXPOSE 80 5900 6080
CMD ["/windows/start.sh"]
EOF

# Create start.sh
cat << 'EOF' > start.sh
#!/bin/bash
IMG_PATH="/windows/win11.img"
ISO_PATH="/windows/Win11Lite.iso"

# Create disk if missing
if [ ! -f "$IMG_PATH" ]; then
    qemu-img create -f qcow2 "$IMG_PATH" 40G
fi

echo "Starting Windows 11 Lite..."
qemu-system-x86_64 \
    -m 4G \
    -cpu host \
    -smp 2 \
    -hda "$IMG_PATH" \
    -cdrom "$ISO_PATH" \
    -boot d \
    -vnc :0 \
    -vga virtio &

# Wait a second before starting noVNC
sleep 2
echo "Launching noVNC on port 80..."
websockify --web=/usr/share/novnc/ 80 localhost:5900
EOF

chmod +x start.sh

# Build Docker image
echo "Building Docker image..."
docker build -t win11-novnc .

# Run Docker container with port forwarding 8080:80
echo "Running Windows 11 Lite container..."
docker run -it -p 8080:80 win11-novnc

echo "Open your browser at http://localhost:8080"
