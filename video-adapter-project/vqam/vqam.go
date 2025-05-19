package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

// QoE metrics for a video stream
type QoEMetrics struct {
	FlowID       string  `json:"flowId"`
	Resolution   string  `json:"resolution"`
	Framerate    float64 `json:"framerate"`
	Bitrate      int64   `json:"bitrate"`
	PacketLoss   float64 `json:"packetLoss"`
	Jitter       float64 `json:"jitter"`
	Latency      float64 `json:"latency"`
	QualityScore float64 `json:"qualityScore"`
	HasBaseLayer bool    `json:"hasBaseLayer"`
	ActiveELs    int     `json:"activeEnhancementLayers"`
}

// NetworkState represents current network conditions
type NetworkState struct {
	Utilization     float64            `json:"utilization"`
	AvailableBW     int64              `json:"availableBandwidth"`
	ActiveFlows     int                `json:"activeFlows"`
	VideoFlows      int                `json:"videoFlows"`
	CongestionLevel string             `json:"congestionLevel"`
	FlowQoE         map[string]float64 `json:"flowQoE"`
}

// VQAM implements Video Quality Assurance Manager
type VQAM struct {
	metrics        map[string]*QoEMetrics
	networkState   NetworkState
	apiPort        int
	updateInterval int
	quit           chan struct{}
}

func NewVQAM(apiPort, updateInterval int) *VQAM {
	return &VQAM{
		metrics: make(map[string]*QoEMetrics),
		networkState: NetworkState{
			FlowQoE: make(map[string]float64),
		},
		apiPort:        apiPort,
		updateInterval: updateInterval,
		quit:           make(chan struct{}),
	}
}

func (v *VQAM) Start() error {
	fmt.Println("Starting Video Quality Assurance Manager (VQAM)...")
	fmt.Printf("API port: %d\n", v.apiPort)

	// Start REST API server
	go v.startAPIServer()

	// Start metrics collection
	go v.collectMetrics()

	return nil
}

func (v *VQAM) Stop() {
	fmt.Println("Stopping VQAM...")
	close(v.quit)
}

func (v *VQAM) startAPIServer() {
	// Define API endpoints
	http.HandleFunc("/api/qoe", v.handleQoERequest)
	http.HandleFunc("/api/network", v.handleNetworkRequest)
	http.HandleFunc("/api/adapt", v.handleAdaptRequest)

	// Start HTTP server
	addr := fmt.Sprintf(":%d", v.apiPort)
	log.Fatal(http.ListenAndServe(addr, nil))
}

func (v *VQAM) handleQoERequest(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method == "GET" {
		// Return all QoE metrics
		json.NewEncoder(w).Encode(v.metrics)
	} else {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

func (v *VQAM) handleNetworkRequest(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method == "GET" {
		// Return current network state
		json.NewEncoder(w).Encode(v.networkState)
	} else {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

func (v *VQAM) handleAdaptRequest(w http.ResponseWriter, r *http.Request) {
	if r.Method == "POST" {
		// Handle adaptation request
		// This would instruct vAdapter to adapt certain flows
		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, "Adaptation request processed")
	} else {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

func (v *VQAM) collectMetrics() {
	ticker := time.NewTicker(time.Duration(v.updateInterval) * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			v.updateQoEMetrics()
			v.updateNetworkState()
		case <-v.quit:
			return
		}
	}
}

func (v *VQAM) updateQoEMetrics() {
	// In a real implementation, this would:
	// 1. Collect metrics from video flows via vAdapter
	// 2. Calculate QoE scores based on objective metrics
	// 3. Update the metrics map

	fmt.Println("Updating QoE metrics...")

	// Simulated metrics update
	// In a real implementation, this would get data from monitoring tools
}

func (v *VQAM) updateNetworkState() {
	// Update network state based on current conditions
	// In a real implementation, this would use SDN controller APIs
	// to get network topology and utilization data

	fmt.Println("Updating network state...")

	// Calculate overall QoE scores
	totalQoE := 0.0
	for flowID, metrics := range v.metrics {
		v.networkState.FlowQoE[flowID] = metrics.QualityScore
		totalQoE += metrics.QualityScore
	}

	// Update network congestion level
	if v.networkState.Utilization > 0.9 {
		v.networkState.CongestionLevel = "high"
	} else if v.networkState.Utilization > 0.7 {
		v.networkState.CongestionLevel = "medium"
	} else {
		v.networkState.CongestionLevel = "low"
	}
}

func main() {
	// Parse command line flags
	apiPort := flag.Int("port", 8080, "API server port")
	updateInterval := flag.Int("interval", 5, "Metrics update interval in seconds")

	flag.Parse()

	vqam := NewVQAM(*apiPort, *updateInterval)

	// Handle graceful shutdown
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)

	if err := vqam.Start(); err != nil {
		log.Fatalf("Failed to start VQAM: %v", err)
	}

	<-sigCh
	vqam.Stop()
}
