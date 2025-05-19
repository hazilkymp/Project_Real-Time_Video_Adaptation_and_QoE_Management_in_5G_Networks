package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"os/exec"
	"os/signal"
	"syscall"
)

func main() {
	// Parse command line flags
	videoFile := flag.String("video", "", "H.265 video file to stream")
	targetIP := flag.String("ip", "127.0.0.1", "Target IP address")
	targetPort := flag.Int("port", 5000, "Target port")
	bitrate := flag.String("bitrate", "1M", "Video bitrate")

	flag.Parse()

	if *videoFile == "" {
		log.Fatal("Please specify a video file with -video")
	}

	fmt.Printf("Streaming %s to %s:%d at %s bitrate\n",
		*videoFile, *targetIP, *targetPort, *bitrate)

	// Build FFmpeg command to stream H.265 video over RTP
	cmd := exec.Command(
		"ffmpeg",
		"-re",            // Real-time mode
		"-i", *videoFile, // Input file
		"-c:v", "libx265", // H.265 codec
		"-b:v", *bitrate, // Video bitrate
		"-x265-params", "sps-id=1:pps-id=1", // Set SPS/PPS IDs
		"-f", "rtp", // RTP output format
		fmt.Sprintf("rtp://%s:%d", *targetIP, *targetPort), // Output
	)

	// Capture and log output
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	// Start streaming
	if err := cmd.Start(); err != nil {
		log.Fatalf("Failed to start streaming: %v", err)
	}

	fmt.Println("Streaming started. Press Ctrl+C to stop.")

	// Handle graceful shutdown
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)

	<-sigCh
	fmt.Println("Stopping stream...")

	if err := cmd.Process.Kill(); err != nil {
		log.Fatalf("Failed to stop streaming: %v", err)
	}

	fmt.Println("Streaming stopped.")
}
