#!/bin/bash

set -e  # Exit on any error

echo "Building vAdapter, VQAM, and SDN-VQO components..."

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "Error: Go is not installed or not in PATH"
    exit 1
fi

# Build vAdapter
echo "Building vAdapter..."
cd ~/video-adapter-project/vAdapter
if [ ! -f "go.mod" ]; then
    go mod init vadapter
fi
go build -o vadapter vadapter.go
if [ $? -eq 0 ]; then
    echo "✓ vAdapter built successfully"
else
    echo "✗ Failed to build vAdapter"
    exit 1
fi

# Build VQAM
echo "Building VQAM..."
cd ~/video-adapter-project/vqam
if [ ! -f "go.mod" ]; then
    go mod init vqam
fi
go build -o vqam vqam.go
if [ $? -eq 0 ]; then
    echo "✓ VQAM built successfully"
else
    echo "✗ Failed to build VQAM"
    exit 1
fi

# Build SDN-VQO
echo "Building SDN-VQO..."
cd ~/video-adapter-project/sdn-vqo
if [ ! -f "go.mod" ]; then
    go mod init sdn-vqo
fi
go build -o sdn-vqo sdn_vqo.go
if [ $? -eq 0 ]; then
    echo "✓ SDN-VQO built successfully"
else
    echo "✗ Failed to build SDN-VQO"
    exit 1
fi

echo ""
echo "✓ All components built successfully!"
echo "Executables located at:"
echo "  - ~/video-adapter-project/vAdapter/vadapter"
echo "  - ~/video-adapter-project/vqam/vqam"
echo "  - ~/video-adapter-project/sdn-vqo/sdn-vqo"