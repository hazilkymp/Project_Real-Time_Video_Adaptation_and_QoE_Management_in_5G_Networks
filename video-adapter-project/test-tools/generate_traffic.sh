#!/bin/bash

# Simple traffic generator for initial testing
# This generates traffic that simulates H.265 video streaming

# Configuration
TARGET_IP=${1:-"127.0.0.1"}
TARGET_PORT=${2:-"5000"}
DURATION=${3:-"60"}
BITRATE=${4:-"2M"}

echo "Starting traffic generation..."
echo "Target: $TARGET_IP:$TARGET_PORT"
echo "Duration: $DURATION seconds"
echo "Bitrate: $BITRATE"

# Function to generate RTP-like traffic
generate_rtp_traffic() {
    local target_ip=$1
    local target_port=$2
    local duration=$3
    
    # Use nc (netcat) to send data continuously
    (
        while true; do
            # Simulate RTP packets with H.265 NAL units
            # In a real scenario, this would be actual H.265 encoded data
            echo -n -e "\x80\x60\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00"  # RTP header
            # Add some payload data (simulated H.265)
            head -c 1000 /dev/urandom
            sleep 0.033  # ~30 FPS
        done
    ) | timeout $duration nc -u $target_ip $target_port
}

# Function to generate HTTP video traffic
generate_http_traffic() {
    local target_ip=$1
    local target_port=$2
    local duration=$3
    
    # Use wget to continuously request video segments
    # Simulate HLS or DASH streaming
    end_time=$((SECONDS + duration))
    segment=0
    
    while [ $SECONDS -lt $end_time ]; do
        # Simulate requesting video segments
        curl -s "http://$target_ip:$target_port/video/segment_$segment.m4s" > /dev/null 2>&1 || true
        segment=$((segment + 1))
        sleep 2  # Request new segment every 2 seconds
    done
}

# Setup traffic capture for analysis
tcpdump -i any -w traffic_capture.pcap port $TARGET_PORT &
TCPDUMP_PID=$!

# Cleanup function
cleanup() {
    echo "Stopping traffic generation..."
    kill $TCPDUMP_PID 2>/dev/null || true
    echo "Traffic capture saved to traffic_capture.pcap"
}
trap cleanup EXIT

# Generate different types of traffic
echo "Generating RTP video traffic..."
generate_rtp_traffic $TARGET_IP $TARGET_PORT $DURATION &

echo "Generating HTTP video traffic..."
generate_http_traffic $TARGET_IP $((TARGET_PORT + 1)) $DURATION &

# Wait for completion
wait

echo "Traffic generation complete!"
echo "Check traffic_capture.pcap for captured packets"