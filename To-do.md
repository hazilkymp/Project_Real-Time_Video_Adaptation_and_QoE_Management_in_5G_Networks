# Implementation Guide: Real-Time Video Adaptation in 5G Networks

I'll help you implement this project using free5GC and OpenAirInterface with your specific VM configurations. This guide will walk through setting up both environments and implementing the video adaptation system described in the research paper.

## 1. Environment Setup

### Free5GC VM (192.168.56.105)

First, let's set up the 5G core network on your free5GC VM:

```bash
# SSH into the free5GC VM
ssh username@192.168.56.105

# Update system packages
sudo apt update && sudo apt upgrade -y

# Install essential dependencies
sudo apt install -y curl git wget net-tools gcc make cmake autoconf libtool pkg-config libmnl-dev libyaml-dev
```

#### Install Go 1.21.8
```bash
wget https://go.dev/dl/go1.21.8.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.8.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bashrc
source ~/.bashrc
go version # Verify: should show go1.21.8
```

#### Install MongoDB 7.0
```bash
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod
```

#### Install gtp5g Kernel Module
```bash
git clone https://github.com/free5gc/gtp5g.git
cd gtp5g
make
sudo make install
```

#### Clone and Install Free5GC
```bash
cd ~
git clone --recursive -b v3.4.4 https://github.com/free5gc/free5gc.git
cd free5gc
make
```

#### Configure Free5GC
Edit configuration files to match your network setup:

```bash
cd ~/free5gc/config
# Edit the configuration files to match your IP addresses
# Main changes needed in amfcfg.yaml, smfcfg.yaml, and upfcfg.yaml
```

Edit `amfcfg.yaml` and update the ngapIpList to your VM IP:
```yaml
ngapIpList:
  - 192.168.56.105
```

Edit `smfcfg.yaml` to update the userplane information:
```yaml
userplane_information:
  # ...
  links:
    - A: gNB
      B: UPF
      # Adjust these IPs as needed
```

Edit `upfcfg.yaml` to set the correct interfaces:
```yaml
interfaces:
  - name: upf.5g.com
    ifname: ens33  # Adjust this to your VM's interface name
    ip: 192.168.56.105
```

### OpenAirInterface VM (192.168.56.108)

Now, let's set up the Radio Access Network (RAN) on your OpenAirInterface VM:

```bash
# SSH into the OpenAirInterface VM
ssh username@192.168.56.108

# Update system packages
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y git cmake build-essential libfftw3-dev libsctp-dev lksctp-tools libboost-all-dev libconfig++-dev
```

#### Clone and Build OpenAirInterface
```bash
git clone https://gitlab.eurecom.fr/oai/openairinterface5g.git
cd openairinterface5g
source oaienv
cd cmake_targets
./build_oai -I -w USRP # This will install dependencies and build OAI with USRP support
```

#### Configure OpenAirInterface
Create configuration files for the gNB (5G base station):

```bash
cd ~/openairinterface5g/targets/PROJECTS/GENERIC-NR-5GC/CONF
```

Create a new configuration file `gnb.conf` with the following content (adjust as needed):

```
Active_gNBs = ( "gNB-Eurecom-5GNRBox");
# Asn1_verbosity, choice in: none, info, annoying
Asn1_verbosity = "none";

gNBs =
(
 {
    ////////// Identification parameters:
    gNB_ID    =  0xe00;
    gNB_name  =  "gNB-Eurecom-5GNRBox";

    // Tracking area code, 0x0000 and 0xfffe are reserved values
    tracking_area_code  =  1;
    plmn_list = ({ mcc = 208; mnc = 93; mnc_length = 2; snssaiList = ({ sst = 1; }) });

    nr_cellid = 12345678L;

    ////////// Physical parameters:
    min_rxtxtime = 6;
    
    servingCellConfigCommon = (
      {
 #spCellConfigCommon

        physCellId                                                    = 0;

        # downlinkConfigCommon
        # Adjust frequencies based on your specific spectrum
        # Downlink frequency
        dl_frequency                                                 = 3619200000L;
        # Downlink Bandwidth in Hz (available values: 5, 10, 15, 20, 25, 30, 40, 50, 60, 70, 80, 90, 100)
        dl_bandwidth                                              = 106;

        # uplink_frequency
        ul_frequency                                                 = 3619200000L;
        # Uplink Bandwidth in Hz (available values: 5, 10, 15, 20, 25, 30, 40, 50, 60, 70, 80, 90, 100)
        ul_bandwidth                                              = 106;

        # For operation with shared spectrum
        frame_type                                                   = "FDD";
        # ...
      }
    );

    # AMF connection parameters
    amf_ip_address      = {
      ipv4       = "192.168.56.105";
      ipv6       = "192:168:30::17";
      active     = "yes";
      preference = "ipv4";
    };

    NETWORK_INTERFACES : 
    {
      GNB_INTERFACE_NAME_FOR_NG_AMF            = "eth0";
      GNB_IPV4_ADDRESS_FOR_NG_AMF              = "192.168.56.108";
      GNB_INTERFACE_NAME_FOR_NGU               = "eth0";
      GNB_IPV4_ADDRESS_FOR_NGU                 = "192.168.56.108";
    };
  }
);
```

## 2. Implementing the Video Adaptation System

Now that we have the basic 5G environment set up, let's implement the video adaptation system from the paper. This will be developed on the free5GC VM:

### Set Up Development Environment for vAdapter

```bash
# SSH into the free5GC VM
ssh username@192.168.56.105

# Create a project directory
mkdir -p ~/video-adapter-project
cd ~/video-adapter-project

# Install additional dependencies for video processing
sudo apt install -y ffmpeg libavcodec-dev libavformat-dev libavutil-dev libswscale-dev
```

### Implementing the Virtualized Video Adapter (vAdapter)

Let's create the basic structure for the vAdapter:

```bash
mkdir -p ~/video-adapter-project/vAdapter
cd ~/video-adapter-project/vAdapter
```

Create a file called `vadapter.go`:

```go
package main

import (
	"flag"
	"fmt"
	"log"
	"net"
	"os"
	"os/signal"
	"syscall"
	"time"
)

// Configuration structure
type Config struct {
	InterfaceName      string
	MonitoringInterval int
	AdaptationEnabled  bool
	BaseLayerOnly      bool
}

// VideoFlow represents a detected video stream
type VideoFlow struct {
	SrcIP       net.IP
	DstIP       net.IP
	SrcPort     uint16
	DstPort     uint16
	Protocol    uint8
	LastSeen    time.Time
	Bitrate     int64
	PacketCount int64
	IsH265      bool
	HasBL       bool
	HasEL       bool
}

// vAdapter handles video stream detection and adaptation
type vAdapter struct {
	config       Config
	activeFlows  map[string]*VideoFlow
	networkStats map[string]int64
	quit         chan struct{}
}

func NewVAdapter(config Config) *vAdapter {
	return &vAdapter{
		config:       config,
		activeFlows:  make(map[string]*VideoFlow),
		networkStats: make(map[string]int64),
		quit:         make(chan struct{}),
	}
}

func (v *vAdapter) Start() error {
	fmt.Println("Starting vAdapter...")
	fmt.Printf("Monitoring interface: %s\n", v.config.InterfaceName)
	fmt.Printf("Adaptation enabled: %v\n", v.config.AdaptationEnabled)

	// Setup packet capture (this would use libpcap in a real implementation)
	// For now, we'll simulate with a monitoring routine
	
	go v.monitorNetwork()
	
	return nil
}

func (v *vAdapter) Stop() {
	fmt.Println("Stopping vAdapter...")
	close(v.quit)
}

func (v *vAdapter) monitorNetwork() {
	ticker := time.NewTicker(time.Duration(v.config.MonitoringInterval) * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			v.detectVideoFlows()
			v.adaptVideoIfNeeded()
		case <-v.quit:
			return
		}
	}
}

func (v *vAdapter) detectVideoFlows() {
	// In a real implementation, this would analyze network packets
	// to detect H.265 video streams
	fmt.Println("Detecting video flows...")
	
	// Simulated detection
	// In a real implementation, this would parse RTP packets and identify H.265 content
}

func (v *vAdapter) adaptVideoIfNeeded() {
	if !v.config.AdaptationEnabled {
		return
	}

	// Check network conditions
	congested := v.isNetworkCongested()
	
	if congested {
		fmt.Println("Network congestion detected, adapting video streams...")
		// In a real implementation, this would:
		// 1. Drop enhancement layers (EL) from H.265 scalable video
		// 2. Prioritize base layer (BL) traffic
		// 3. Update QoE metrics
		
		if v.config.BaseLayerOnly {
			fmt.Println("Dropping all enhancement layers to reduce bandwidth")
		} else {
			fmt.Println("Selective adaptation of enhancement layers")
		}
	}
}

func (v *vAdapter) isNetworkCongested() bool {
	// In a real implementation, this would check:
	// - Network utilization
	// - Packet loss
	// - Jitter
	// - Delay
	
	// Simulated congestion detection
	return false
}

func main() {
	// Parse command line flags
	interfaceName := flag.String("interface", "eth0", "Network interface to monitor")
	monitoringInterval := flag.Int("interval", 5, "Monitoring interval in seconds")
	adaptationEnabled := flag.Bool("adapt", true, "Enable video adaptation")
	baseLayerOnly := flag.Bool("baselayer", false, "Drop all enhancement layers when congested")
	
	flag.Parse()
	
	config := Config{
		InterfaceName:      *interfaceName,
		MonitoringInterval: *monitoringInterval,
		AdaptationEnabled:  *adaptationEnabled,
		BaseLayerOnly:      *baseLayerOnly,
	}
	
	vadapter := NewVAdapter(config)
	
	// Handle graceful shutdown
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
	
	if err := vadapter.Start(); err != nil {
		log.Fatalf("Failed to start vAdapter: %v", err)
	}
	
	<-sigCh
	vadapter.Stop()
}
```

### Implementing the QoE Management Framework

Create the Video Quality Assurance Manager (VQAM):

```bash
mkdir -p ~/video-adapter-project/vqam
cd ~/video-adapter-project/vqam
```

Create a file called `vqam.go`:

```go
package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
	"encoding/json"
)

// QoE metrics for a video stream
type QoEMetrics struct {
	FlowID        string  `json:"flowId"`
	Resolution    string  `json:"resolution"`
	Framerate     float64 `json:"framerate"`
	Bitrate       int64   `json:"bitrate"`
	PacketLoss    float64 `json:"packetLoss"`
	Jitter        float64 `json:"jitter"`
	Latency       float64 `json:"latency"`
	QualityScore  float64 `json:"qualityScore"`
	HasBaseLayer  bool    `json:"hasBaseLayer"`
	ActiveELs     int     `json:"activeEnhancementLayers"`
}

// NetworkState represents current network conditions
type NetworkState struct {
	Utilization    float64            `json:"utilization"`
	AvailableBW    int64              `json:"availableBandwidth"`
	ActiveFlows    int                `json:"activeFlows"`
	VideoFlows     int                `json:"videoFlows"`
	CongestionLevel string            `json:"congestionLevel"`
	FlowQoE        map[string]float64 `json:"flowQoE"`
}

// VQAM implements Video Quality Assurance Manager
type VQAM struct {
	metrics       map[string]*QoEMetrics
	networkState  NetworkState
	apiPort       int
	updateInterval int
	quit          chan struct{}
}

func NewVQAM(apiPort, updateInterval int) *VQAM {
	return &VQAM{
		metrics:        make(map[string]*QoEMetrics),
		networkState:   NetworkState{
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
```

### Implementing the SDN Video Quality Orchestrator (SDN-VQO)

```bash
mkdir -p ~/video-adapter-project/sdn-vqo
cd ~/video-adapter-project/sdn-vqo
```

Create a file called `sdn_vqo.go`:

```go
package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
	"encoding/json"
	"bytes"
	"io/ioutil"
)

// FlowRule represents an SDN flow rule
type FlowRule struct {
	ID          string `json:"id"`
	Priority    int    `json:"priority"`
	SrcIP       string `json:"srcIp"`
	DstIP       string `json:"dstIp"`
	SrcPort     int    `json:"srcPort"`
	DstPort     int    `json:"dstPort"`
	Protocol    string `json:"protocol"`
	Action      string `json:"action"`
	PathID      string `json:"pathId"`
}

// AdaptationPolicy defines how to adapt video flows
type AdaptationPolicy struct {
	FlowID           string `json:"flowId"`
	MaxBitrate       int64  `json:"maxBitrate"`
	MinQoE           float64 `json:"minQoE"`
	DropELThreshold  float64 `json:"dropELThreshold"`
	UseFallbackPath  bool   `json:"useFallbackPath"`
}

// NetworkTopology represents the network's physical and logical structure
type NetworkTopology struct {
	Nodes []string            `json:"nodes"`
	Links map[string][]string `json:"links"`
	Paths map[string][]string `json:"paths"`
}

// SDN-VQO orchestrates video QoE across the network
type SDNVQO struct {
	vqamEndpoint     string
	sdnControllerURL string
	policies         map[string]*AdaptationPolicy
	flowRules        map[string]*FlowRule
	topology         NetworkTopology
	updateInterval   int
	quit             chan struct{}
}

func NewSDNVQO(vqamEndpoint, sdnControllerURL string, updateInterval int) *SDNVQO {
	return &SDNVQO{
		vqamEndpoint:     vqamEndpoint,
		sdnControllerURL: sdnControllerURL,
		policies:         make(map[string]*AdaptationPolicy),
		flowRules:        make(map[string]*FlowRule),
		topology:         NetworkTopology{
			Links: make(map[string][]string),
			Paths: make(map[string][]string),
		},
		updateInterval:   updateInterval,
		quit:             make(chan struct{}),
	}
}

func (s *SDNVQO) Start() error {
	fmt.Println("Starting SDN Video Quality Orchestrator (SDN-VQO)...")
	fmt.Printf("VQAM endpoint: %s\n", s.vqamEndpoint)
	fmt.Printf("SDN controller: %s\n", s.sdnControllerURL)
	
	// Initialize SDN controller connection
	// In a real implementation, this would connect to an SDN controller
	
	// Start orchestration loop
	go s.orchestrationLoop()
	
	return nil
}

func (s *SDNVQO) Stop() {
	fmt.Println("Stopping SDN-VQO...")
	close(s.quit)
}

func (s *SDNVQO) orchestrationLoop() {
	ticker := time.NewTicker(time.Duration(s.updateInterval) * time.Second)
	defer ticker.Stop()
	
	for {
		select {
		case <-ticker.C:
			s.updateNetworkTopology()
			s.fetchQoEMetrics()
			s.optimizeVideoDelivery()
		case <-s.quit:
			return
		}
	}
}

func (s *SDNVQO) updateNetworkTopology() {
	// In a real implementation, this would:
	// 1. Query the SDN controller for network topology
	// 2. Update the local topology model
	
	fmt.Println("Updating network topology...")
	
	// Simulated topology update
	// In a real implementation, this would use SDN controller APIs
}

func (s *SDNVQO) fetchQoEMetrics() {
	// Fetch QoE metrics from VQAM
	fmt.Println("Fetching QoE metrics from VQAM...")
	
	resp, err := http.Get(s.vqamEndpoint + "/api/qoe")
	if err != nil {
		log.Printf("Error fetching QoE metrics: %v", err)
		return
	}
	defer resp.Body.Close()
	
	// In a real implementation, this would parse and process the response
	
	fmt.Println("Fetching network state from VQAM...")
	
	netResp, err := http.Get(s.vqamEndpoint + "/api/network")
	if err != nil {
		log.Printf("Error fetching network state: %v", err)
		return
	}
	defer netResp.Body.Close()
	
	// In a real implementation, this would parse and process the response
}

func (s *SDNVQO) optimizeVideoDelivery() {
	fmt.Println("Optimizing video delivery...")
	
	// Apply adaptation policies based on current conditions
	for flowID, policy := range s.policies {
		// Check if flow needs adaptation
		needsAdaptation, needsPathChange := s.evaluateFlowPolicy(flowID, policy)
		
		if needsAdaptation {
			s.sendAdaptationRequest(flowID, policy.MaxBitrate)
		}
		
		if needsPathChange && policy.UseFallbackPath {
			s.updateFlowPath(flowID)
		}
	}
}

func (s *SDNVQO) evaluateFlowPolicy(flowID string, policy *AdaptationPolicy) (bool, bool) {
	// In a real implementation, this would evaluate if a flow
	// needs adaptation or path change based on QoE metrics
	
	// Simulated policy evaluation
	return false, false
}

func (s *SDNVQO) sendAdaptationRequest(flowID string, maxBitrate int64) {
	// Send adaptation request to VQAM
	fmt.Printf("Requesting adaptation for flow %s to max bitrate %d\n", flowID, maxBitrate)
	
	// Create request body
	reqBody, _ := json.Marshal(map[string]interface{}{
		"flowId": flowID,
		"maxBitrate": maxBitrate,
	})
	
	// Send POST request to VQAM
	_, err := http.Post(s.vqamEndpoint + "/api/adapt", "application/json", bytes.NewBuffer(reqBody))
	if err != nil {
		log.Printf("Error sending adaptation request: %v", err)
	}
}

func (s *SDNVQO) updateFlowPath(flowID string) {
	// Update flow path in SDN controller
	fmt.Printf("Updating path for flow %s\n", flowID)
	
	// In a real implementation, this would:
	// 1. Find an alternative path in the topology
	// 2. Update flow rules in the SDN controller
}

func main() {
	// Parse command line flags
	vqamEndpoint := flag.String("vqam", "http://localhost:8080", "VQAM API endpoint")
	sdnController := flag.String("sdn", "http://localhost:8181", "SDN controller API endpoint")
	updateInterval := flag.Int("interval", 10, "Orchestration interval in seconds")
	
	flag.Parse()
	
	sdnvqo := NewSDNVQO(*vqamEndpoint, *sdnController, *updateInterval)
	
	// Handle graceful shutdown
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
	
	if err := sdnvqo.Start(); err != nil {
		log.Fatalf("Failed to start SDN-VQO: %v", err)
	}
	
	<-sigCh
	sdnvqo.Stop()
}
```

### Create Build Script

Create a script to build all components:

```bash
cd ~/video-adapter-project
```

Create a file called `build.sh`:

```bash
#!/bin/bash

echo "Building vAdapter, VQAM, and SDN-VQO components..."

cd ~/video-adapter-project/vAdapter
go build -o vadapter vadapter.go

cd ~/video-adapter-project/vqam
go build -o vqam vqam.go

cd ~/video-adapter-project/sdn-vqo
go build -o sdn-vqo sdn_vqo.go

echo "Build complete. Components are in their respective directories."
```

Make the script executable:

```bash
chmod +x build.sh
```

## 3. System Integration

Now let's integrate our components with the 5G network:

### Create a Test Script

```bash
cd ~/video-adapter-project
```

Create a file called `run_test.sh`:

```bash
#!/bin/bash

echo "Starting video adaptation test in 5G environment..."

# Start Free5GC (assuming it's already installed and configured)
cd ~/free5gc
./run.sh &
sleep 10  # Give Free5GC time to initialize

# Start vAdapter
cd ~/video-adapter-project/vAdapter
./vadapter --interface ens33 --adapt true &
VADAPTER_PID=$!

# Start VQAM
cd ~/video-adapter-project/vqam
./vqam --port 8080 --interval 5 &
VQAM_PID=$!

# Start SDN-VQO
cd ~/video-adapter-project/sdn-vqo
./sdn-vqo --vqam "http://localhost:8080" --interval 10 &
SDNVQO_PID=$!

echo "All components started. Press Ctrl+C to stop."

# Wait for user to press Ctrl+C
trap "kill $VADAPTER_PID $VQAM_PID $SDNVQO_PID; cd ~/free5gc; ./force_kill.sh; echo 'Test stopped.'" INT
wait
```

Make the script executable:

```bash
chmod +x run_test.sh
```

## 4. Testing the System

### Create a Test Video Stream Generator

```bash
cd ~/video-adapter-project
mkdir -p test-tools
cd test-tools
```

Create a file called `video_generator.go`:

```go
package main

import (
	"flag"
	"fmt"
	"log"
	"net"
	"os"
	"os/exec"
	"os/signal"
	"syscall"
	"time"
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
		"-re",                          // Real-time mode
		"-i", *videoFile,               // Input file
		"-c:v", "libx265",              // H.265 codec
		"-b:v", *bitrate,               // Video bitrate
		"-x265-params", "sps-id=1:pps-id=1", // Set SPS/PPS IDs
		"-f", "rtp",                    // RTP output format
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
```

Build the video generator:

```bash
cd ~/video-adapter-project/test-tools
go build -o video_generator video_generator.go
```

### Testing End-to-End

To test the system, you'll need:

1. Run free5GC on the first VM
2. Run OpenAirInterface on the second VM
3. Run the video adaptation components on the first VM
4. Generate test video traffic

Here's a walkthrough of the testing process:

#### On the Free5GC VM (192.168.56.105):

```bash
# Start free5GC
cd ~/free5gc
./run.sh

# In another terminal, start the video adaptation system
cd ~/video-adapter-project
./build.sh
./run_test.sh
```

#### On the OpenAirInterface VM (192.168.56.108):

```bash
# Start OpenAirInterface gNB
cd ~/openairinterface5g
source oaienv
cd cmake_targets/ran_build/build
sudo ./nr-softmodem -O ../../../targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb.conf
```

#### Generate Test Traffic (on any machine with a test video file):

```bash
# Stream a test H.265 video
./video_generator -video test.mp4 -ip 192.168.56.105 -port 5000 -bitrate 5M
```

## 5. Monitoring and Evaluation

To monitor the system performance:

1. Check vAdapter logs for video flow detection and adaptation
2. Access VQAM metrics via the REST API: http://192.168.56.105:8080/api/qoe
3. Monitor network conditions: http://192.168.56.105:8080/api/network

You can create a simple dashboard by adding a web interface to VQAM, but that would be an extension to the current implementation.

## Next Steps and Extensions

Once you have the basic system working, you can extend it with:

1. More sophisticated H.265 video parsing and adaptation
2. Integration with a full SDN controller like OpenDaylight
3. Implementation of detailed QoE metrics calculation
4. Adding a web-based dashboard for monitoring
5. Implementing multiple adaptation policies
6. Setting up automated testing and benchmarking

This implementation provides a foundation for the project described in the paper, focusing on the core components: vAdapter, VQAM, and SDN-VQO within a virtualized 5G environment using free5GC and OpenAirInterface.
