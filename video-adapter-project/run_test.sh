#!/bin/bash

set -e  # Exit on any error

echo "Starting video adaptation test in 5G environment..."

# Use $HOME instead of ~ for proper expansion
PROJECT_DIR="$HOME/video-adapter-project"

# Check if executables exist
if [ ! -f "$PROJECT_DIR/vAdapter/vadapter" ]; then
    echo "Error: vAdapter executable not found at $PROJECT_DIR/vAdapter/vadapter"
    echo "Please run ./build.sh first"
    exit 1
fi

if [ ! -f "$PROJECT_DIR/vqam/vqam" ]; then
    echo "Error: VQAM executable not found at $PROJECT_DIR/vqam/vqam"
    echo "Please run ./build.sh first"
    exit 1
fi

if [ ! -f "$PROJECT_DIR/sdn-vqo/sdn-vqo" ]; then
    echo "Error: SDN-VQO executable not found at $PROJECT_DIR/sdn-vqo/sdn-vqo"
    echo "Please run ./build.sh first"
    exit 1
fi

# Function to kill background processes
cleanup() {
    echo "Cleaning up processes..."
    if [ ! -z "$VADAPTER_PID" ]; then
        kill $VADAPTER_PID 2>/dev/null || true
        echo "Stopped vAdapter"
    fi
    if [ ! -z "$VQAM_PID" ]; then
        kill $VQAM_PID 2>/dev/null || true
        echo "Stopped VQAM"
    fi
    if [ ! -z "$SDNVQO_PID" ]; then
        kill $SDNVQO_PID 2>/dev/null || true
        echo "Stopped SDN-VQO"
    fi
    echo "Test stopped."
}

# Set up signal handling
trap cleanup INT TERM

# Start Free5GC (optional - comment out if already running)
echo "Starting Free5GC..."
cd ~/free5gc
./run.sh &
FREE5GC_PID=$!
sleep 10  # Give Free5GC time to initialize

# Start vAdapter
echo "Starting vAdapter..."
cd "$PROJECT_DIR/vAdapter"
./vadapter --interface ens33 --adapt true > vadapter.log 2>&1 &
VADAPTER_PID=$!
echo "vAdapter started with PID $VADAPTER_PID"

# Wait a moment for vAdapter to initialize
sleep 2

# Start VQAM
echo "Starting VQAM..."
cd "$PROJECT_DIR/vqam"
./vqam --port 8080 --interval 5 > vqam.log 2>&1 &
VQAM_PID=$!
echo "VQAM started with PID $VQAM_PID"

# Wait a moment for VQAM to initialize
sleep 2

# Start SDN-VQO
echo "Starting SDN-VQO..."
cd "$PROJECT_DIR/sdn-vqo"
./sdn-vqo --vqam "http://localhost:8080" --interval 10 > sdn-vqo.log 2>&1 &
SDNVQO_PID=$!
echo "SDN-VQO started with PID $SDNVQO_PID"

echo ""
echo "All components started successfully!"
echo "  - vAdapter PID: $VADAPTER_PID"
echo "  - VQAM PID: $VQAM_PID" 
echo "  - SDN-VQO PID: $SDNVQO_PID"
echo ""
echo "Log files:"
echo "  - vAdapter: $PROJECT_DIR/vAdapter/vadapter.log"
echo "  - VQAM: $PROJECT_DIR/vqam/vqam.log"
echo "  - SDN-VQO: $PROJECT_DIR/sdn-vqo/sdn-vqo.log"
echo ""
echo "VQAM API available at: http://localhost:8080/api/qoe"
echo ""
echo "Press Ctrl+C to stop all components."

# Wait for user to press Ctrl+C
wait