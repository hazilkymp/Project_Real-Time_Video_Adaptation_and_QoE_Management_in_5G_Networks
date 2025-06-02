# Free5GC, UERANSIM, and OpenAirInterface Implementation test

## System Environment Used
- Free5GC 3.4.4
  - Ubuntu 20.04 LTS
  - IP address: 192.168.56.105
  - Golang 1.21.8
  - MongoDB 7.0
  - gtp5g 0.9.3

- OpenAirInterface
  - Ubuntu 22.04 LTS
  - IP addres: 192.168.56.108
  - CU IP: 192.168.110.11
  - DU IP: 192.168.110.12 

## SSH into Free5GC's VM
![Screenshot 2025-05-06 105353](https://github.com/user-attachments/assets/237c32a7-f4d9-408e-947c-6457d801a9fb)

## SSH into OpenAirInterface's VM
![Screenshot 2025-05-13 161347](https://github.com/user-attachments/assets/24bc3ebd-e752-4c21-aea5-6c690ec4843a)

## Free5GC's Web Console
![Screenshot 2025-05-06 105653](https://github.com/user-attachments/assets/27f810d0-f6c0-4267-b283-9c5841ae2092)

![Screenshot 2025-05-06 105342](https://github.com/user-attachments/assets/ffa19d0e-8d04-4bb0-9ac9-3cfeec5a8107)

# Free5GC and OpenAirInterface Setup Guide
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

Prerequisites

    Install Golang

    Free5gc is built and tested with Go 1.17.8. Check the version of Go on the system, from a command prompt:

go version

    If another version of Go is installed, remove the existing version and install Go 1.21.8:

sudo rm -rf /usr/local/go
wget https://dl.google.com/go/go1.21.8.linux-amd64.tar.gz
sudo tar -C /usr/local -zxvf go1.21.8.linux-amd64.tar.gz

    If Go is not installed on your system:

wget https://dl.google.com/go/go1.21.8.linux-amd64.tar.gz
sudo tar -C /usr/local -zxvf go1.21.8.linux-amd64.tar.gz
mkdir -p ~/go/{bin,pkg,src}
# The following assumes that your shell is bash:
echo 'export GOPATH=$HOME/go' >> ~/.bashrc
echo 'export GOROOT=/usr/local/go' >> ~/.bashrc
echo 'export PATH=$PATH:$GOPATH/bin:$GOROOT/bin' >> ~/.bashrc
echo 'export GO111MODULE=auto' >> ~/.bashrc
source ~/.bashrc

    Control-plane Supporting Packages

    Check AVX support

lscpu | grep avx

    MongoDB 5.0+ requires a CPU with AVX support. Or downgrade your MongoDB to 4.4. see Mongodb Failed Activation Guide

    If the system support AVX:

sudo apt -y update
sudo apt -y install wget git
sudo apt install -y gnupg curl
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor

    Create a list file for MongoDB

echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
sudo apt update
sudo apt install -y mongodb-org

    Run MongoDB Community Edition

sudo systemctl start mongod
sudo systemctl status mongod
sudo systemctl enable mongod    # optional

    User-plane Supporting Packages

sudo apt -y update
sudo apt -y install git gcc g++ cmake autoconf libtool pkg-config libmnl-dev libyaml-dev

    Linux Host Network Settings

sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -o <dn_interface> -j MASQUERADE     #Ex: sudo iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE

sudo iptables -A FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1400
sudo systemctl stop ufw
sudo systemctl disable ufw	# prevents the firewall to wake up after a OS reboot

    Note: change <dn_interface> with your wan interface. ex: enp0s3

Install Free5GC

    Install Control Plane Elements
    OAI doesn't support with all version of Free5GS, use Free5GC version 3.2.1

cd ~
git clone --recursive -b v3.2.1 -j `nproc` https://github.com/free5gc/free5gc.git

    To build all network functions:

cd ~/free5gc
make

Install User Plane Function (UPF)

uname -r
git clone -b v0.9.3 https://github.com/free5gc/gtp5g.git
cd gtp5g
make
sudo make install

Install WebConsole

    Install nodejs first:

curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - 
sudo apt update
sudo apt install -y nodejs
corepack enable # setup yarn automatically

if corepack permission denied, use sudo.

    Build WebConsole

cd ~/free5gc
make webconsole

Free5GC WebConsole

    start up the WebConsole server in Free5GC:

cd ~/free5gc/webconsole
go run server.go

    Open web browser from host machine, and enter the URL <free5gc ip>:5000. ex: http://192.168.56.101:5000

    On the login page, use default username and password:

    username: admin
    password: free5gc.

    Once logged in, widen the page until you see “Subscribers” on the left-hand side column.
    Click on the Subscribers tab and then on the New Subscriber button
        Scroll down to Operator Code Type and change it from "OPc" to "OP".
        Leave the other fields unchanged. This registration data is used for ease of testing and actual use later.
        Scroll all the way down and click on Submit.
    Once the data shows up on the "Subscribers" table, you can press Ctrl-C on the terminal to kill the WebConsole process on the free5gc VM

Setting free5GC Parameters

In free5gc VM, we need to edit three files: amfcfg.yaml, smfcfg.yaml and upfcfg.yaml.

    Change AMF config

cd ~/free5gc
nano ~/free5gc/config/amfcfg.yaml

...
  ngapIpList:  # the IP list of N2 interfaces on this AMF
  - 192.168.10.31  # your Free5GC IP

    Edit ~/free5gc/config/smfcfg.yaml:

nano ~/free5gc/config/smfcfg.yaml

...
  interfaces: # Interface list for this UPF
   - interfaceType: N3 # the type of the interface (N3 or N9)
     endpoints: # the IP address of this N3/N9 interface on this UPF
       - 192.168.10.31  # your Free5GC IP

    Edit ~/free5gc/config/upfcfg.yaml:

nano ~/free5gc/config/smfcfg.yaml

...
  gtpu:
    forwarder: gtp5g
    # The IP list of the N3/N9 interfaces on this UPF
    # If there are multiple connection, set addr to 0.0.0.0 or list all the addresses
    ifList:
      - addr: 192.168.10.31  # your Free5GC IP
        type: N3

Install Openairinterface
A. prepare the required interface

    Create new ubuntu version 22

    Check avx status

grep -o 'avx[^ ]*' /proc/cpuinfo

Create tun interface

    sudo nano create_tunnel.sh

    fill create_tunnel.sh file with this code:

#!/bin/bash

BRIDGE="oai_br0"
VETH1="tun_cu"
VETH2="tun_du"
IP1="192.168.110.11/24"
IP2="192.168.110.12/24"

create_tunnel() {
    echo "Setting up CU/DU tunnel..."

    # Remove existing interfaces (if any) to avoid conflicts
    ip link del $VETH1 2>/dev/null
    ip link del $BRIDGE 2>/dev/null

    # Create veth pair (CU <-> DU)
    ip link add $VETH1 type veth peer name $VETH2

    # Create network bridge
    ip link add $BRIDGE type bridge

    # Bring up interfaces
    ip link set $VETH1 up
    ip link set $VETH2 up
    ip link set $BRIDGE up

    # Assign IPs
    ip addr add $IP1 dev $VETH1
    ip addr add $IP2 dev $VETH2

    # Attach veth interfaces to bridge
    ip link set $VETH1 master $BRIDGE
    ip link set $VETH2 master $BRIDGE

    echo "Tunnel setup complete!"
}

clean_tunnel() {
    echo "Cleaning up CU/DU tunnel..."
    ip link del $VETH1 2>/dev/null
    ip link del $BRIDGE 2>/dev/null
    echo "Cleanup complete!"
}

# Handle user input
case "$1" in
    create) create_tunnel ;;
    clean) clean_tunnel ;;
    *)
        echo "Usage: $0 {create|clean}"
        exit 1
        ;;
esac

    Ensure that create_tunnel.sh is executable:

sudo chmod +x create_tunnel.sh

Run the create_tunnel.sh to create the tun interface

    sudo ./create_tunnel.sh create

B. Build OAI from Source Code

    Clone the source code and build Openairinterface5g

    sudo apt install git cmake build-essentials
    git clone https://gitlab.eurecom.fr/oai/openairinterface5g.git

    cd openairinterface5g
    source oaienv
    cd cmake_targets/
    ./build_oai -I --gNB --nrUE -w SIMU

C. set configuration

    setting cu_gnb.conf

    cd ~/openairinterface5g/cmake_targets/ran_build/build/
    sudo nano ../../../targets/PROJECTS/GENERIC-NR-5GC/CONF/cu_gnb.conf

    Edit CU & DU IP in

Active_gNBs = ( "gNB-Eurecom-CU");
# Asn1_verbosity, choice in: none, info, annoying
Asn1_verbosity = "none";
Num_Threads_PUSCH = 8;

gNBs =
(
 {
    ////////// Identification parameters:
    gNB_ID = 0xe00;

#     cell_type =  "CELL_MACRO_GNB";

    gNB_name  =  "gNB-Eurecom-CU";

    // Tracking area code, 0x0000 and 0xfffe are reserved values
    tracking_area_code  =  1;
    plmn_list = ({ mcc = 208; mnc = 93; mnc_length = 2; snssaiList = ({ sst = 1}) });
#                             mnc = 99;
    nr_cellid = 12345678L;

    tr_s_preference = "f1";

    local_s_address = "192.168.110.11"; //cu ip
    remote_s_address = "192.168.110.12"; //du ip
    local_s_portc   = 501;
    local_s_portd   = 2152;
    remote_s_portc  = 500;
    remote_s_portd  = 2152;

    # ------- SCTP definitions
    SCTP :
    {
        # Number of streams to use in input/output
        SCTP_INSTREAMS  = 2;
        SCTP_OUTSTREAMS = 2;
    };


    ////////// AMF parameters:
    amf_ip_address = ({ ipv4 = "192.168.10.31"; }); //amf & upf ip

    NETWORK_INTERFACES :
    {

        GNB_IPV4_ADDRESS_FOR_NG_AMF              = "192.168.10.32"; //cu to amf  
        GNB_IPV4_ADDRESS_FOR_NGU                 = "192.168.10.32"; //cu to upf
        GNB_PORT_FOR_S1U                         = 2152; # Spec 2152
        };

    DU configuration

sudo nano ../../../targets/PROJECTS/GENERIC-NR-5GC/CONF/du_gnb.conf

edit CU & DU IP

Active_gNBs = ( "gNB-Eurecom-DU");
# Asn1_verbosity, choice in: none, info, annoying
Asn1_verbosity = "none";

gNBs =
(
 {
    ////////// Identification parameters:
    gNB_ID = 0xe00;
    gNB_DU_ID = 0xe00;

#     cell_type =  "CELL_MACRO_GNB";

    gNB_name  =  "gNB-Eurecom-DU";

    // Tracking area code, 0x0000 and 0xfffe are reserved values
    tracking_area_code  =  1;
    plmn_list = ({ mcc = 208; mnc = 93; mnc_length = 2; snssaiList = ({ sst = 1 }) });

    nr_cellid = 12345678L;

    ////////// Physical parameters:

    min_rxtxtime                                              = 6;
    force_256qam_off = 1;

    servingCellConfigCommon = (
    {

...

MACRLCs = (
  {
    num_cc           = 1;
    tr_s_preference  = "local_L1";
    tr_n_preference  = "f1";
    local_n_address = "192.168.10.12"; //du ip
    remote_n_address = "192.168.10.11"; //cu ip
    local_n_portc   = 500;
    local_n_portd   = 2152;
    remote_n_portc  = 501;
    remote_n_portd  = 2152;
  }
);

...

rfsimulator: {
serveraddr = "server";
    serverport = 4043;
    options = (); #("saviq"); or/and "chanmod"
    modelname = "AWGN";
    IQfile = "/tmp/rfsimulator.iqs"
}

UE configuration

sudo nano ../../../targets/PROJECTS/GENERIC-NR-5GC/CONF/ue.conf

make sure all UE parameter same as free5gc webconsole

uicc0 = {
imsi = "2089300007487";
key = "fec86ba6eb707ed08905757b1bb44b8f";
opc= "C42449363BBAD02B66D16BC975D77CC1";
dnn= "internet";
nssai_sst=1;
nssai_sd=1;
}

position0 = {
    x = 0.0;
    y = 0.0;
    z = 6377900.0;
}

    Screenshot (121)

Testing free5GC-OAI

    SSH into free5gc. If you have rebooted free5gc, remember to run:

sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -o <dn_interface> -j MASQUERADE
sudo systemctl stop ufw

Note: In Ubuntu Server 20.04 and 22.04 the dn_interface may be called enp0s3 or enp0s4 by default.

In addition, execute the following command:

sudo iptables -I FORWARD 1 -j ACCEPT

Tip: As per the information on the appendix page, it's possible to use a script to reload the config above automatically after reboot

Also, make sure you have make proper changes to the free5GC configuration files, then run ./run.sh:

cd ~/free5gc
./run.sh

At this time free5GC has been started.

    Run CU
    Terminal 1 SSH into OAI, and run:

cd OAI-CU/cmake_targets/ran_build/build
sudo RFSIMULATOR=server ./nr-softmodem --rfsim --sa -O ../../../targets/PROJECTS/GENERIC-NR-5GC/CONF/cu_gnb.conf

    Run DU
    terminal 2 ssh into oai, and run du:

cd OAI-CU/cmake_targets/ran_build/build
sudo RFSIMULATOR=server ./nr-softmodem --rfsim --sa -O ../../../targets/PROJECTS/GENERIC-NR-5GC/CONF/du_gnb.conf

    Run UE
    terminal 3 ssh into oai, and run UE:

cd OAI-CU/cmake_targets/ran_build/build
sudo RFSIMULATOR=127.0.0.1 ./nr-uesoftmodem -r 106 --numerology 1 --band 78 -C 3619200000 --rfsim --sa --nokrnmod -O ../../../targets/PROJECTS/GENERIC-NR-5GC/CONF/ue.conf
