# Real-Time Video Adaptation and QoE Management in 5G Networks

## Project Overview
This project aims to implement the system inspired from the paper [Real-Time Video Adaptation in Virtualised 5G Networks](https://ieeexplore.ieee.org/document/8990815) by Salva-Garcia et al.

The paper proposes the design and development of an intelligent, scalable video adaptation system for virtualized 5G networks. The system aims to enhance video Quality of Experience (QoE) by leveraging Software-Defined Networking (SDN) and Network Function Virtualization (NFV) techniques.

The paper explores a **context-aware SDN control-plane** and **real-time video adaptation** based on the latest scalable H.265/HEVC codecs, focusing on maintaining low latency, high reliability, and network scalability under the 5G architecture.

The implementation utilizes **free5GC**, an open-source 5G Core Network, alongside **OpenAirInterface (OAI)** for the Radio Access Network (RAN), providing a realistic and comprehensive virtualized 5G testing environment. Additionally, **GNS3** is used to simulate complex network topologies, facilitating robust testing and performance analysis.

## Objectives

- **Develop a Virtualized Video Adapter (vAdapter)**:
  - Capable of parsing and adapting 5G multimedia traffic.
  - Able to handle H.265 scalable video streams (SHVC) at different layers.

- **Design a Context-Aware QoE Management Framework**:
  - Implement a Video Quality Assurance Manager (VQAM).
  - Deploy an SDN Video Quality Orchestrator (SDN-VQO).

- **Leverage SDN and NFV Technologies**:
  - Virtualize network functions (vAdapterVNFs).
  - Ensure dynamic and scalable deployment.

- **Optimize Video Traffic for 5G Environments**:
  - Manage massive numbers of real-time video streams.
  - Dynamically adapt streams based on network conditions to save bandwidth.

## Background Motivation

- **Explosion of Multimedia Traffic**: Video accounts for 75% of mobile data traffic.
- **Challenges in 5G**: Massive device connections, UHD video demand, and ultra-low latency requirements.
- **Limitations of Traditional Video Tools**: Existing tools are not optimized for virtualized 5G networks or new codecs like H.265/HEVC.

## Proposed Architecture

![image](https://github.com/user-attachments/assets/ff598e71-2ac3-4699-9ef9-04edbd257901)

### 1. vAdapter Design
- Built as a VNF for easy deployment.
- Utilizes extended BSD Packet Filter (BPF) to inspect and adapt nested encapsulated traffic.
- Parses RTP streams with H.265 scalable layers.

### 2. Virtualized 5G Infrastructure
- LTE-based core fully virtualized with OpenStack + OpenDayLight SDN controller.
- Multi-tenant setup using VLAN/VXLAN encapsulation.
- Real-time monitoring of network conditions and video flows.

### 3. Context-Aware QoE Management
- **VQAM**: Collects network topology, flow states, and multimedia QoE metrics.
- **SDN-VQO**: Oversees global QoE and manages fairness among multiple streams.

### 4. Traffic Handling Mechanism
- **Scalable video encoding**: Base Layer (BL) and Enhancement Layers (EL).
- **Dynamic adaptation**: Dropping ELs when congestion is detected.
- **Failover path selection**: Primary and secondary path management for reliability.

## Key Benefits

- **Bandwidth Saving**: Selective adaptation reduces network load.
- **Low Latency**: Minimal delay even with increasing video flows.
- **QoE Preservation**: Maintain acceptable video quality during congestion.
- **Scalability**: Dynamic instantiation of multiple vAdapterVNFs.

## Target Deliverables

- Simulation/Testbed Implementation in a virtualized 5G network.
- Implementation within a virtualized 5G environment using free5GC, OpenAirInterface, and GNS3.
- Benchmarking against current multimedia traffic engineering solutions.

## References

- Real-Time Video Adaptation in Virtualised 5G Networks (Salva-Garcia et al.)
- Video Quality in 5G Networks: Context-Aware QoE Management in SDN (Awobuluyi et al.)
- [Free5GC and Openairinterface Integration](https://hackmd.io/@Hazilkymp/S1QAH3piJx)

---

## Team 5:
- Hazilky Muna Putra M11302811
- Jalu Veda M11302824


---
