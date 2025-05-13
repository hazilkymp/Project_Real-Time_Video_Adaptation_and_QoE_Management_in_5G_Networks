# Free5GC, UERANSIM, and OpenAirInterface Implementation test

## System Environment Used
- Free5GC 3.4.4
  - Ubuntu 20.04 LTS
  - IP address: 192.168.10.31
  - Golang 1.21.8
  - MongoDB 7.0
  - gtp5g 0.9.3

- OpenAirInterface
  - Ubuntu 22.04 LTS
  - IP addres: 192.168.10.32
  - CU IP: 192.168.110.11
  - DU IP: 192.168.110.12 

## SSH into Free5GC's VM
![Screenshot 2025-05-06 105353](https://github.com/user-attachments/assets/237c32a7-f4d9-408e-947c-6457d801a9fb)

## SSH into OpenAirInterface's VM
![Screenshot 2025-05-06 105727](https://github.com/user-attachments/assets/2ea6dc8b-02b0-4717-86b2-021547b114f7)

## Free5GC's Web Console
![Screenshot 2025-05-06 105653](https://github.com/user-attachments/assets/27f810d0-f6c0-4267-b283-9c5841ae2092)

![Screenshot 2025-05-06 105342](https://github.com/user-attachments/assets/ffa19d0e-8d04-4bb0-9ac9-3cfeec5a8107)

# Implementation
## On Free5GC's VM:
If the VM is restarted:
```
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE
sudo systemctl stop ufw
```
First Terminal:
```
cd ~/free5gc/webconsole
go run server.go
```
Second terminal:
```
cd ~/free5gc
./run.sh
```

## On OpenAirInterface's VM

First Terminal
```
cd ~/openairinterface5g/cmake_targets/ran_build/build
sudo RFSIMULATOR=server ./nr-softmodem --rfsim --sa -O ../../../targets/PROJECTS/GENERIC-NR-5GC/CONF/cu_gnb.conf
```
Second Terminal
```
cd ~/openairinterface5g/cmake_targets/ran_build/build
sudo RFSIMULATOR=server ./nr-softmodem --rfsim --sa -O ../../../targets/PROJECTS/GENERIC-NR-5GC/CONF/du_gnb.conf
```
Third Terminal
```
cd ~/openairinterface5g/cmake_targets/ran_build/build
sudo RFSIMULATOR=127.0.0.1 ./nr-uesoftmodem -r 106 --numerology 1 --band 78 -C 3619200000 --rfsim --sa --nokrnmod -O ../../../targets/PROJECTS/GENERIC-NR-5GC/CONF/ue.conf
```
